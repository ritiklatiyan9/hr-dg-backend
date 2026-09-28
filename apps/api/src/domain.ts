import type pg from "pg";
import { catalogue } from "../../../packages/authz/src/catalogue.js";
import { and, eq } from "drizzle-orm";
import { z } from "zod";
import { scoped, orm, type Tx } from "../../../packages/db/src/index.js";
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
    return scoped(this.pool, actor, null, async (c) => {
      if (
        !(
          await c.query("SELECT app.check_request($1,$2) AS ok", [
            actor.sessionId,
            actor.permissionVersion,
          ])
        ).rows[0]?.ok
      )
        fail("SCOPE_CHANGED", "Access changed. Sign in again.", 409);
      const org = (await c.query("SELECT id,name FROM app.organizations"))
        .rows[0];
      const sites = (
        await c.query("SELECT id,name,timezone FROM app.sites ORDER BY name")
      ).rows;
      return {
        organization: org,
        actor: { id: actor.id, permissionVersion: actor.permissionVersion },
        sites,
      };
    });
  }
  async site<T>(actor: Actor, siteId: string, fn: (c: Tx) => Promise<T>) {
    return scoped(this.pool, actor, id.parse(siteId), async (c) => {
      if (
        !(
          await c.query("SELECT app.check_request($1,$2) AS ok", [
            actor.sessionId,
            actor.permissionVersion,
          ])
        ).rows[0]?.ok
      )
        fail("SCOPE_CHANGED", "Access changed. Reload your workspace.", 409);
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
      const site = (
        await c.query("SELECT id,name,timezone FROM app.sites WHERE id=$1", [
          siteId,
        ])
      ).rows[0];
      const decisions = (
        await c.query(
          "SELECT key,app.decision(key) AS decision FROM app.permission_catalogue ORDER BY key",
        )
      ).rows;
      const caps = decisions
        .filter((r) => r.decision.allowed)
        .map((r) => r.key);
      for (const legacy of [
        "employees.read",
        "employees.write",
        "hr.access",
        "audit.read",
        "invitations.send",
      ])
        if ((await c.query("SELECT app.can($1) AS ok", [legacy])).rows[0].ok)
          caps.push(legacy);
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
    const employment = (
      await c.query(
        `SELECT er.id,er.starts_on::text AS "startsOn",er.ends_on::text AS "endsOn",
   json_build_object('id',le.id,'name',le.name) AS "legalEmployer" FROM app.employment_records er
   JOIN app.legal_employers le ON (le.organization_id,le.id)=(er.organization_id,er.legal_employer_id)
   WHERE er.employee_id=$1 ORDER BY er.starts_on DESC LIMIT 100`,
        [e.id],
      )
    ).rows;
    const assignments = (
      await c.query(
        `SELECT a.id,a.starts_on::text AS "startsOn",a.ends_on::text AS "endsOn",
   json_build_object('id',s.id,'name',s.name,'timezone',s.timezone) AS site FROM app.site_assignments a
   JOIN app.sites s ON (s.organization_id,s.id)=(a.organization_id,a.site_id) WHERE a.employee_id=$1 ORDER BY a.starts_on DESC LIMIT 100`,
        [e.id],
      )
    ).rows;
    const contact = (
      await c.query("SELECT app.field_allowed('contact',$1) AS ok", [e.id])
    ).rows[0].ok;
    const work = (
      await c.query("SELECT app.field_allowed('employment',$1) AS ok", [e.id])
    ).rows[0].ok;
    // Basic details are contact data; the photo follows employee visibility.
    const extra = (
      await c.query(
        'SELECT CASE WHEN $2 THEN e.personal END AS personal,p.updated_at AS "photoUpdatedAt" FROM app.employees e LEFT JOIN app.employee_photos p ON (p.organization_id,p.employee_id)=(e.organization_id,e.id) WHERE e.id=$1',
        [e.id, contact],
      )
    ).rows[0];
    const sensitive = (
      await c.query(
        "SELECT field,value FROM app.employee_sensitive_fields WHERE employee_id=$1",
        [e.id],
      )
    ).rows;
    const promotion = work
      ? (
          await c.query(
            "SELECT payload FROM app.hr_records WHERE kind='lifecycle' AND status='approved' AND employee_id=$1 AND payload->>'event'='promotion' AND (payload->>'effectiveOn')::date<=(now() AT TIME ZONE (SELECT timezone FROM app.sites WHERE id=app.site_id()))::date ORDER BY payload->>'effectiveOn' DESC,updated_at DESC LIMIT 1",
            [e.id],
          )
        ).rows[0]?.payload
      : null;
    const lifecycle = (
      await c.query(
        "SELECT app.employee_status($1) AS status,app.employee_login($1) AS login",
        [e.id],
      )
    ).rows[0];
    return {
      ...e,
      status: lifecycle.status,
      login: lifecycle.login,
      workEmail: contact ? e.workEmail : null,
      phone: contact ? e.phone : null,
      personal: extra?.personal ?? null,
      photoUpdatedAt: extra?.photoUpdatedAt ?? null,
      jobTitle: work ? promotion?.designation || e.jobTitle : null,
      department: work ? promotion?.department || e.department : null,
      isSelf: e.userId === actor.id,
      employment: work ? employment : [],
      assignments: work ? assignments : [],
      salary: sensitive.find((r) => r.field === "salary")?.value ?? null,
      bank: sensitive.find((r) => r.field === "bank")?.value ?? null,
      identity: sensitive.find((r) => r.field === "identity")?.value ?? null,
      permittedFields: [
        ...(contact ? ["contact"] : []),
        ...(work ? ["employment"] : []),
        ...sensitive.map((r) => r.field),
      ],
      allowedActions: (
        await c.query(
          "SELECT action FROM app.permission_catalogue WHERE module_id='employees' AND action NOT LIKE 'field.%' AND app.allowed(key,$1)",
          [e.id],
        )
      ).rows.map((r) => r.action),
      userId: e.userId,
    };
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
      const nodes = [];
      for (const r of raw.slice(0, first)) {
        const e = (
          await orm(c).select().from(employees).where(eq(employees.id, r.id))
        )[0]!;
        nodes.push(await this.expand(c, actor, e));
      }
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
