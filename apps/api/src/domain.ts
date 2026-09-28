import { readJson } from "../../../packages/db/src/read-json.js";
import type pg from "pg";
import { catalogue } from "../../../packages/authz/src/catalogue.js";
import { and, eq, inArray } from "drizzle-orm";
import { z } from "zod";
import {
  verifiedScoped,
  orm,
  type Tx,
} from "../../../packages/db/src/index.js";
import { employees } from "../../../packages/db/src/schema.js";
import {
  type Actor,
  fail,
  workDate,
} from "../../../packages/authz/src/index.js";
const id = z.uuid();
export class Domain {
  constructor(readonly pool: pg.Pool) {}
  async bootstrap(actor: Actor) {
    return verifiedScoped(this.pool, actor, null, async (c) => {
      const data = await readJson(c, {
        organization: ["SELECT id,name FROM app.organizations"],
        sites: ["SELECT id,name,timezone FROM app.sites ORDER BY name"],
      });
      return {
        organization: data.organization[0],
        actor: { id: actor.id, permissionVersion: actor.permissionVersion },
        sites: data.sites,
      };
    });
  }
  async site<T>(actor: Actor, siteId: string, fn: (c: Tx) => Promise<T>) {
    return verifiedScoped(this.pool, actor, id.parse(siteId), async (c) => {
      try {
        return await fn(c);
      } catch (error) {
        const e = error as { code?: string; message?: string };
        if (e.code === "P0001")
          fail(
            e.message ?? "FORBIDDEN",
            (
              {
                CONFLICT: "This record changed. Reload before saving.",
                DELEGATION_LIMIT:
                  "This change exceeds your delegated authority.",
                SELF_ESCALATION: "You cannot change your own access.",
                PROTECTED_ACCOUNT:
                  "Only a Super Admin can change this account.",
                LAST_SUPER_ADMIN:
                  "Keep at least one recoverable Super Admin with access management.",
                REASON_REQUIRED: "Give a reason of 8–500 characters.",
                REQUEST_PENDING:
                  "A profile request is already awaiting review.",
                ASSIGNMENT_OVERLAP: "These assignment dates overlap.",
                REPORTING_CYCLE:
                  "This reporting relationship would create a cycle.",
                REPORT_LOCKED:
                  "That day's DWR is already submitted, so its messages are locked.",
                BAD_INPUT: "Check the submitted fields.",
                EMPLOYEE_EXITED:
                  "This employee has exited. Rehire them before enabling login.",
                NO_LOGIN: "This employee has no login account.",
              } as Record<string, string>
            )[e.message ?? ""] ?? "This action is not permitted",
            409,
          );
        if (e.code === "23P01")
          fail("CONFLICT", "Effective dates overlap an existing record.", 409);
        if (e.code === "23505")
          fail("CONFLICT", "A record with these details already exists.", 409);
        throw error;
      }
    });
  }
  async require(c: Tx, cap: string) {
    if (
      !(await c.query("SELECT app.can($1) AS allowed", [cap])).rows[0]?.allowed
    )
      fail("FORBIDDEN", "This action is not permitted", 403);
  }
  async scope(actor: Actor, siteId: string) {
    return this.site(actor, siteId, async (c) => {
      const data = await readJson(c, {
        site: ["SELECT id,name,timezone FROM app.sites WHERE id=$1", [siteId]],
        decisions: [
          "SELECT key,app.decision(key) AS decision FROM app.permission_catalogue ORDER BY key",
        ],
        legacy: [
          "SELECT key FROM unnest($1::text[]) AS keys(key) WHERE app.can(key)",
          [
            [
              "employees.read",
              "employees.write",
              "hr.access",
              "audit.read",
              "invitations.send",
            ],
          ],
        ],
      });
      const site = data.site[0],
        decisions = data.decisions;
      const caps = [
        ...decisions.filter((r) => r.decision.allowed).map((r) => r.key),
        ...data.legacy.map((r) => r.key),
      ];
      return {
        site,
        capabilities: caps,
        decisions,
        modules: catalogue.map((m) => ({ ...m, available: m.phase <= 6 })),
        workDate: workDate(new Date(), site.timezone),
      };
    });
  }
  async expand(c: Tx, actor: Actor, e: typeof employees.$inferSelect) {
    return (await this.expandMany(c, actor, [e]))[0]!;
  }
  async expandMany(
    c: Tx,
    actor: Actor,
    records: (typeof employees.$inferSelect)[],
  ) {
    if (!records.length) return [];
    // One round trip for the entire page, on the existing scoped connection.
    // Every table and permission function still uses the runtime role and RLS.
    const details = await c.query(
      `WITH visible AS MATERIALIZED (
        SELECT e.id,e.personal,
          app.field_allowed('contact',e.id) AS contact,
          app.field_allowed('employment',e.id) AS work
        FROM app.employees e WHERE e.id=ANY($1::uuid[])
      )
      SELECT v.id,v.contact,v.work,
        CASE WHEN v.contact THEN v.personal END AS personal,
        p.updated_at AS "photoUpdatedAt",
        app.employee_status(v.id) AS status,app.employee_login(v.id) AS login,
        CASE WHEN v.work THEN (
          SELECT payload FROM app.hr_records
          WHERE kind='lifecycle' AND status='approved' AND employee_id=v.id
            AND payload->>'event'='promotion'
            AND (payload->>'effectiveOn')::date <= (now() AT TIME ZONE
              (SELECT timezone FROM app.sites WHERE id=app.site_id()))::date
          ORDER BY payload->>'effectiveOn' DESC,updated_at DESC LIMIT 1
        ) END AS promotion,
        COALESCE((SELECT json_agg(x) FROM (
          SELECT er.id,er.starts_on::text AS "startsOn",er.ends_on::text AS "endsOn",
            json_build_object('id',le.id,'name',le.name) AS "legalEmployer"
          FROM app.employment_records er
          JOIN app.legal_employers le ON (le.organization_id,le.id)=(er.organization_id,er.legal_employer_id)
          WHERE v.work AND er.employee_id=v.id ORDER BY er.starts_on DESC LIMIT 100
        ) x),'[]'::json) AS employment,
        COALESCE((SELECT json_agg(x) FROM (
          SELECT a.id,a.starts_on::text AS "startsOn",a.ends_on::text AS "endsOn",
            json_build_object('id',s.id,'name',s.name,'timezone',s.timezone) AS site
          FROM app.site_assignments a
          JOIN app.sites s ON (s.organization_id,s.id)=(a.organization_id,a.site_id)
          WHERE v.work AND a.employee_id=v.id ORDER BY a.starts_on DESC LIMIT 100
        ) x),'[]'::json) AS assignments,
        COALESCE((SELECT json_agg(json_build_object('field',field,'value',value))
          FROM app.employee_sensitive_fields WHERE employee_id=v.id),'[]'::json) AS sensitive,
        COALESCE((SELECT json_agg(action) FROM app.permission_catalogue
          WHERE module_id='employees' AND action NOT LIKE 'field.%'
            AND app.allowed(key,v.id)),'[]'::json) AS "allowedActions"
      FROM visible v LEFT JOIN app.employee_photos p
        ON p.organization_id=app.org_id() AND p.employee_id=v.id`,
      [records.map((e) => e.id)],
    );
    const byId = new Map(details.rows.map((row) => [row.id, row]));
    return records.flatMap((e) => {
      const d = byId.get(e.id);
      if (!d) return [];
      const sensitive = d.sensitive as { field: string; value: unknown }[];
      return [
        {
          ...e,
          status: d.status,
          login: d.login,
          workEmail: d.contact ? e.workEmail : null,
          phone: d.contact ? e.phone : null,
          personal: d.personal ?? null,
          photoUpdatedAt: d.photoUpdatedAt ?? null,
          jobTitle: d.work ? d.promotion?.designation || e.jobTitle : null,
          department: d.work ? d.promotion?.department || e.department : null,
          isSelf: e.userId === actor.id,
          employment: d.employment,
          assignments: d.assignments,
          salary: sensitive.find((r) => r.field === "salary")?.value ?? null,
          bank: sensitive.find((r) => r.field === "bank")?.value ?? null,
          identity:
            sensitive.find((r) => r.field === "identity")?.value ?? null,
          permittedFields: [
            ...(d.contact ? ["contact"] : []),
            ...(d.work ? ["employment"] : []),
            ...sensitive.map((r) => r.field),
          ],
          allowedActions: d.allowedActions,
          userId: e.userId,
        },
      ];
    });
  }
  async list(
    actor: Actor,
    siteId: string,
    first = 20,
    after?: string,
    search = "",
    department = "",
    status = "current",
  ) {
    return this.site(actor, siteId, async (c) => {
      await this.require(c, "employees.read");
      z.number().int().min(1).max(50).parse(first);
      z.string().max(100).parse(search);
      z.string().max(100).parse(department);
      z.enum(["current", "former", "all"]).parse(status);
      let cursor = "00000000-0000-0000-0000-000000000000";
      if (after) {
        try {
          const parsed = JSON.parse(Buffer.from(after, "base64url").toString());
          if (
            parsed.siteId !== siteId ||
            parsed.actorId !== actor.id ||
            parsed.version !== actor.permissionVersion ||
            parsed.search !== search ||
            parsed.department !== department ||
            parsed.status !== status
          )
            fail("BAD_CURSOR", "Cursor belongs to another scope");
          cursor = id.parse(parsed.id);
        } catch {
          fail("BAD_CURSOR", "Invalid pagination cursor");
        }
      }
      const raw = (
        await c.query(
          // Without the employment field every visible record counts as current.
          "SELECT id FROM app.employees WHERE app.allowed('employees.view',id) AND id>$1 AND (display_name ILIKE '%'||$3||'%' OR employee_code ILIKE '%'||$3||'%') AND ($4='' OR (app.field_allowed('employment',id) AND department=$4)) AND ($5='all' OR (COALESCE(app.employee_status(id),'active') IN ('active','joining'))=($5='current')) ORDER BY id LIMIT $2",
          [cursor, first + 1, search, department, status],
        )
      ).rows;
      const pageIds = raw.slice(0, first).map((r) => r.id as string);
      const records = pageIds.length
        ? await orm(c)
            .select()
            .from(employees)
            .where(inArray(employees.id, pageIds))
            .orderBy(employees.id)
        : [];
      const nodes = await this.expandMany(c, actor, records);
      return {
        nodes,
        hasNextPage: raw.length > first,
        endCursor: nodes.length
          ? Buffer.from(
              JSON.stringify({
                id: nodes.at(-1)!.id,
                siteId,
                actorId: actor.id,
                version: actor.permissionVersion,
                search,
                department,
                status,
              }),
            ).toString("base64url")
          : null,
      };
    });
  }
  async profile(actor: Actor, siteId: string, employeeId?: string) {
    return this.site(actor, siteId, async (c) => {
      const e = (
        await orm(c)
          .select()
          .from(employees)
          .where(
            employeeId
              ? eq(employees.id, id.parse(employeeId))
              : eq(employees.userId, actor.id),
          )
      )[0];
      return e ? this.expand(c, actor, e) : null;
    });
  }
  async update(
    actor: Actor,
    siteId: string,
    input: { employeeId: string; phone: string; expectedVersion: number },
  ) {
    id.parse(input.employeeId);
    z.string()
      .max(25)
      .regex(/^[+0-9()\s-]*$/)
      .parse(input.phone);
    z.number().int().min(1).parse(input.expectedVersion);
    return this.site(actor, siteId, async (c) => {
      const e = (
        await orm(c)
          .select()
          .from(employees)
          .where(eq(employees.id, input.employeeId))
      )[0];
      if (!e) fail("NOT_FOUND", "Employee not found", 404);
      if (
        !(
          await c.query(
            "SELECT app.allowed('employees.edit',$1) AND app.allowed('employees.approve',$1) AND app.field_allowed('contact',$1) AS ok",
            [e.id],
          )
        ).rows[0].ok
      )
        fail("FORBIDDEN", "Submit a profile update request for review.", 403);
      const updated = (
        await orm(c)
          .update(employees)
          .set({
            phone: input.phone,
            version: e.version + 1,
            updatedAt: new Date(),
          })
          .where(
            and(
              eq(employees.id, e.id),
              eq(employees.version, input.expectedVersion),
            ),
          )
          .returning()
      )[0];
      if (!updated)
        fail("CONFLICT", "This profile changed. Refresh before saving.", 409);
      await c.query(
        "INSERT INTO app.audit_records(organization_id,site_id,actor_id,action,entity_id,metadata) VALUES($1,$2,$3,'employee.profile_updated',$4,$5)",
        [
          actor.organizationId,
          siteId,
          actor.id,
          e.id,
          JSON.stringify({ fields: ["phone"], version: updated.version }),
        ],
      );
      await c.query(
        "INSERT INTO app.outbox(organization_id,site_id,event_type,payload) VALUES($1,$2,'employee.profile_updated',$3)",
        [
          actor.organizationId,
          siteId,
          JSON.stringify({ employeeId: e.id, version: updated.version }),
        ],
      );
      return this.expand(c, actor, updated);
    });
  }
}
