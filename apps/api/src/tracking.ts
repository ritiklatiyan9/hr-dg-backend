import {
  offlinePermit,
  offlineBatch,
  offlineHeartbeat,
} from "./tracking-offline.js";
import { createHash } from "node:crypto";
import { z } from "zod";
import { Operations, policySchema } from "./operations.js";
import { fail, type Actor } from "../../../packages/authz/src/index.js";
import type { Tx } from "../../../packages/db/src/index.js";
import { trackingStatus } from "../../../packages/attendance/src/tracking.js";
const settings = z
  .object({
    expectedVersion: z.number().int().min(0),
    enabled: z.boolean(),
    mode: z.enum(["roster", "checked_in"]),
    sampleSeconds: z.number().int().min(15).max(300),
    staleSeconds: z.number().int().min(30).max(1800),
    notice: z.string().trim().min(20).max(2000),
    reason: z.string().trim().min(8).max(1000),
  })
  .strict()
  .refine(
    (p) => p.staleSeconds >= p.sampleSeconds * 2,
    "Stale threshold must cover at least two sample intervals",
  );
const sample = z
  .object({
    clientId: z.uuid(),
    rosterId: z.uuid(),
    rosterVersion: z.number().int().positive(),
    policyVersion: z.number().int().positive(),
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
    accuracyM: z.number().min(0).max(100000),
    observedAt: z.iso.datetime({ offset: true }),
    mocked: z.boolean(),
  })
  .strict();
export type TrackingSample = z.infer<typeof sample>;
const monitorInput = z
  .object({
    after: z.uuid().optional(),
    employeeId: z.uuid().optional(),
    rosterId: z.uuid().optional(),
    sampleAfter: z
      .object({ at: z.iso.datetime({ offset: true }), id: z.uuid() })
      .strict()
      .optional(),
  })
  .strict();
export class Tracking extends Operations {
  async trackingPolicy(c: Tx) {
    return (
      (
        await c.query(
          "SELECT * FROM app.tracking_policies ORDER BY version DESC LIMIT 1",
        )
      ).rows[0] ?? null
    );
  }
  async trackingWindow(c: Tx, employee: string, policy: any) {
    if (!policy?.enabled) return null;
    const roster = (
      await c.query(
        `SELECT r.* FROM app.shift_rosters r WHERE employee_id=$1 AND starts_at<=now() AND ends_at>now()
      AND app.allowed('my_attendance.create',employee_id) ORDER BY starts_at LIMIT 1`,
        [employee],
      )
    ).rows[0];
    if (!roster) return null;
    let endsAt = roster.ends_at;
    if (policy.mode === "checked_in") {
      const duty = (
        await c.query(
          `SELECT s.* FROM app.duty_sessions s WHERE s.employee_id=$1 AND s.status='open' AND s.opened_at<=now()
        AND EXISTS(SELECT 1 FROM app.duty_events e JOIN app.event_verifications v ON v.event_id=e.id WHERE e.duty_id=s.id AND e.kind='IN' AND v.status='accepted')
        ORDER BY s.opened_at DESC LIMIT 1`,
          [employee],
        )
      ).rows[0];
      if (!duty) return null;
      const rules = (
        await c.query(
          "SELECT rules FROM app.operation_policies WHERE version=$1",
          [duty.policy_version],
        )
      ).rows[0]?.rules;
      const end = Math.min(
        +roster.ends_at,
        +duty.opened_at + (rules?.maxSessionHours ?? 0) * 3600000,
      );
      if (end <= Date.now()) return null;
      endsAt = new Date(end);
      roster.starts_at = new Date(Math.max(+roster.starts_at, +duty.opened_at));
    }
    return { ...roster, ends_at: endsAt };
  }
  async trackingContext(actor: Actor, siteId: string) {
    return this.site(actor, siteId, async (c) => {
      const me = await this.mine(c);
      await this.allowed(c, "my_attendance.create", me.id);
      const policy = await this.trackingPolicy(c);
      const configured = (
        await c.query(
          "SELECT EXISTS(SELECT 1 FROM app.operation_policies) AND EXISTS(SELECT 1 FROM app.geofence_versions) ok",
        )
      ).rows[0].ok;
      const window = configured
        ? await this.trackingWindow(c, me.id, policy)
        : null;
      const upcomingWindow =
        !window && configured && policy?.enabled && policy.mode === "roster"
          ? ((
              await c.query(
                `SELECT r.* FROM app.shift_rosters r WHERE r.employee_id=$1 AND r.starts_at>now() AND r.starts_at<=now()+interval '24 hours'
          AND app.allowed('my_attendance.create',r.employee_id) ORDER BY r.starts_at LIMIT 1`,
                [me.id],
              )
            ).rows[0] ?? null)
          : null;
      const rules = configured ? (await this.policy(c)).rules : null;
      const now = Date.now();
      return {
        locationRules: rules
          ? {
              maxAccuracyM: rules.maxAccuracyM,
              freshnessSeconds: rules.freshnessSeconds,
            }
          : null,
        serverTime: new Date(now).toISOString(),
        policy,
        window,
        upcomingWindow,
        configured,
        leaseUntil: window
          ? new Date(Math.min(now + 120000, +window.ends_at)).toISOString()
          : null,
      };
    });
  }
  async trackingCommand(
    actor: Actor,
    siteId: string,
    operation: string,
    raw: unknown,
  ) {
    if (operation === "offlinePermit") {
      const p = sample
        .pick({ rosterId: true, rosterVersion: true, policyVersion: true })
        .parse(raw);
      return this.site(actor, siteId, (c) => offlinePermit(this, c, actor, p));
    }
    if (operation === "batch") {
      const p = z
        .object({ grantId: z.uuid(), samples: z.array(sample).min(1).max(100) })
        .strict()
        .parse(raw);
      return this.site(actor, siteId, (c) => offlineBatch(this, c, actor, p));
    }
    if (operation === "heartbeat") {
      const p = z
        .object({
          grantId: z.uuid(),
          state: z.enum(["tracking", "location_off"]),
        })
        .strict()
        .parse(raw);
      return this.site(actor, siteId, (c) =>
        offlineHeartbeat(this, c, actor, p),
      );
    }
    if (operation !== "settings" && operation !== "sample")
      fail("BAD_INPUT", "Unknown tracking operation");
    if (operation === "settings") {
      const p = settings.parse(raw);
      return this.site(actor, siteId, async (c) => {
        await this.allowed(c, "employee_tracking.manage");
        // Settings apply to the entire site, so a team grant cannot change them.
        const decision = (
          await c.query("SELECT app.decision('employee_tracking.manage') d")
        ).rows[0].d;
        if (decision.scope !== "site")
          fail("FORBIDDEN", "Site-wide tracking management is required");
        await c.query("SELECT pg_advisory_xact_lock(hashtextextended($1,0))", [
          `${actor.organizationId}:tracking:${siteId}`,
        ]);
        const old = await this.trackingPolicy(c);
        if ((old?.version ?? 0) !== p.expectedVersion)
          fail("CONFLICT", "Tracking settings changed; reload");
        if (p.enabled) {
          await this.policy(c);
          if (
            !(await c.query("SELECT 1 FROM app.geofence_versions LIMIT 1"))
              .rowCount
          )
            fail(
              "CONFIGURATION_REQUIRED",
              "Configure the attendance geofence first",
            );
        }
        const result = (
          await c.query(
            `INSERT INTO app.tracking_policies(organization_id,site_id,version,enabled,mode,sample_seconds,stale_seconds,notice,reason,author_id)
          VALUES(app.org_id(),app.site_id(),$1,$2,$3,$4,$5,$6,$7,app.actor_id()) RETURNING id,version`,
            [
              p.expectedVersion + 1,
              p.enabled,
              p.mode,
              p.sampleSeconds,
              p.staleSeconds,
              p.notice,
              p.reason,
            ],
          )
        ).rows[0];
        await this.auditOperation(c, "tracking.settings", result.id, [
          "enabled",
          "mode",
          "intervals",
          "notice",
        ]);
        return result;
      });
    }
    const p = sample.parse(raw);
    return this.site(actor, siteId, async (c) => {
      const me = await this.mine(c);
      await this.allowed(c, "my_attendance.create", me.id);
      await c.query("SELECT pg_advisory_xact_lock(hashtextextended($1,0))", [
        `${actor.organizationId}:tracking-sample:${me.id}`,
      ]);
      await c.query("SELECT pg_advisory_xact_lock(hashtextextended($1,0))", [
        `${actor.organizationId}:roster:${me.id}`,
      ]);
      const hash = createHash("sha256").update(JSON.stringify(p)).digest("hex");
      const duplicate = (
        await c.query(
          "SELECT id,payload_hash FROM app.tracking_samples WHERE user_id=app.actor_id() AND client_id=$1",
          [p.clientId],
        )
      ).rows[0];
      if (duplicate) {
        if (duplicate.payload_hash !== hash)
          fail("CONFLICT", "Sample ID already has different data");
        return { id: duplicate.id, status: "accepted" };
      }
      await c.query(
        "SELECT pg_advisory_xact_lock_shared(hashtextextended($1,0))",
        [`${actor.organizationId}:tracking:${siteId}`],
      );
      const policy = await this.trackingPolicy(c),
        window = await this.trackingWindow(c, me.id, policy);
      const observed = Date.parse(p.observedAt),
        now = Date.now();
      if (
        !window ||
        observed < +window.starts_at ||
        observed >= +window.ends_at
      )
        fail(
          "FORBIDDEN",
          "Location sharing is outside the HR-authorized duty window",
        );
      if (
        p.rosterId !== window.id ||
        p.rosterVersion !== window.version ||
        p.policyVersion !== policy.version
      )
        fail(
          "CONFLICT",
          "Duty schedule or tracking settings changed; refresh authorization",
        );
      const rules = policySchema.parse((await this.policy(c)).rules);
      if (
        p.mocked ||
        p.accuracyM > rules.maxAccuracyM ||
        observed > now + 5000 ||
        now - observed > rules.freshnessSeconds * 1000
      )
        fail("BAD_INPUT", "A fresh, accurate, non-mock location is required");
      const device = (
        await c.query("SELECT app.operation_device($1) id", [actor.sessionId])
      ).rows[0]?.id;
      if (!device) fail("UNAUTHENTICATED", "Device session expired");
      const last = (
        await c.query(
          "SELECT device_id,observed_at,received_at FROM app.tracking_samples WHERE roster_id=$1 ORDER BY observed_at DESC,id DESC LIMIT 1",
          [window.id],
        )
      ).rows[0];
      if (last && last.device_id !== device && now - +last.received_at < 120000)
        fail(
          "CONFLICT",
          "Another device is actively sharing location for this shift",
        );
      if (last && observed <= +last.observed_at)
        fail(
          "CONFLICT",
          "Location clock moved backward or sample is out of order",
        );
      if (
        last &&
        observed - +last.observed_at < policy.sample_seconds * 1000 - 1000
      )
        fail("RATE_LIMITED", "Wait for the configured sample interval");
      const fence = (
        await c.query(
          `SELECT version,ST_Covers(boundary::geometry,p::geometry) inside,
        ST_Distance(ST_Boundary(boundary::geometry)::geography,p) edge FROM app.geofence_versions
        CROSS JOIN (SELECT ST_SetSRID(ST_MakePoint($1,$2),4326)::geography p) x ORDER BY version DESC LIMIT 1`,
          [p.longitude, p.latitude],
        )
      ).rows[0];
      if (!fence) fail("CONFIGURATION_REQUIRED", "Geofence is not configured");
      const classification =
        fence.edge <= p.accuracyM
          ? "unknown"
          : fence.inside
            ? "inside"
            : "outside";
      const result = (
        await c.query(
          `INSERT INTO app.tracking_samples(organization_id,site_id,employee_id,user_id,device_id,client_id,payload_hash,roster_id,roster_version,policy_version,geofence_version,observed_at,point,accuracy_m,classification)
        VALUES(app.org_id(),app.site_id(),$1,app.actor_id(),$2,$3,$4,$5,$6,$7,$8,$9,ST_SetSRID(ST_MakePoint($10,$11),4326)::geography,$12,$13) RETURNING id`,
          [
            me.id,
            device,
            p.clientId,
            hash,
            window.id,
            window.version,
            policy.version,
            fence.version,
            p.observedAt,
            p.longitude,
            p.latitude,
            p.accuracyM,
            classification,
          ],
        )
      ).rows[0];
      return { ...result, status: "accepted", classification };
    });
  }
  async trackingMonitor(actor: Actor, siteId: string, raw: unknown) {
    const p = monitorInput.parse(raw ?? {});
    return this.site(actor, siteId, async (c) => {
      await this.allowed(c, "employee_tracking.view");
      const policy = await this.trackingPolicy(c),
        now = Date.now();
      const columns =
        "t.id,t.observed_at,t.received_at,t.offline_grant_id,t.accuracy_m,t.classification,t.roster_version,t.policy_version,t.geofence_version,ST_Y(t.point::geometry) latitude,ST_X(t.point::geometry) longitude";
      if (p.rosterId) {
        const roster = (
          await c.query(
            "SELECT r.*,e.display_name FROM app.shift_rosters r JOIN app.employees e ON e.id=r.employee_id WHERE r.id=$1",
            [p.rosterId],
          )
        ).rows[0];
        if (!roster) fail("NOT_FOUND", "Duty roster not found");
        await this.allowed(c, "employee_tracking.view", roster.employee_id);
        const rows = (
          await c.query(
            `SELECT ${columns} FROM app.tracking_samples t WHERE roster_id=$1 AND ($2::timestamptz IS NULL OR (observed_at,id)<($2,$3::uuid)) ORDER BY observed_at DESC,id DESC LIMIT 501`,
            [p.rosterId, p.sampleAfter?.at ?? null, p.sampleAfter?.id ?? null],
          )
        ).rows;
        const points = rows.slice(0, 500),
          last = points.at(-1);
        return {
          serverTime: new Date(now).toISOString(),
          policy,
          roster,
          points,
          next:
            rows.length > 500
              ? { at: last.observed_at.toISOString(), id: last.id }
              : null,
        };
      }
      // Check-in state is only evaluated for the checked_in mode (CASE is lazy).
      // Presence comes from the phone's latest heartbeat for the current versions.
      const rows = (
        await c.query(
          `SELECT r.*,e.display_name,to_jsonb(l) location,d.last_seen_at heartbeat_at,d.device_state,
        CASE WHEN $2='checked_in' THEN EXISTS(SELECT 1 FROM app.duty_sessions s JOIN app.operation_policies op ON op.version=s.policy_version WHERE s.employee_id=r.employee_id AND s.status='open' AND s.opened_at<=now()
        AND s.opened_at+((op.rules->>'maxSessionHours')::int*interval '1 hour')>now()
        AND EXISTS(SELECT 1 FROM app.duty_events de JOIN app.event_verifications v ON v.event_id=de.id WHERE de.duty_id=s.id AND de.kind='IN' AND v.status='accepted')) END checked_in
        FROM (
          -- One row per employee: the running duty window, else the nearest one.
          SELECT DISTINCT ON (r.employee_id) r.* FROM app.shift_rosters r
          WHERE r.starts_at<now()+interval '24 hours' AND r.ends_at>now()-interval '24 hours' AND app.allowed('employee_tracking.view',r.employee_id)
          AND ($4::uuid IS NULL OR r.employee_id=$4)
          ORDER BY r.employee_id,(r.starts_at<=now() AND r.ends_at>now()) DESC,GREATEST(r.starts_at-now(),now()-r.ends_at)
        ) r JOIN app.employees e ON e.id=r.employee_id
        LEFT JOIN LATERAL(SELECT ${columns} FROM app.tracking_samples t WHERE t.roster_id=r.id ORDER BY observed_at DESC,id DESC LIMIT 1) l ON true
        LEFT JOIN LATERAL(SELECT g.last_seen_at,g.device_state FROM app.tracking_offline_grants g WHERE g.employee_id=r.employee_id AND g.roster_id=r.id
          AND g.roster_version=r.version AND g.policy_version=$3 AND g.last_seen_at IS NOT NULL ORDER BY g.last_seen_at DESC LIMIT 1) d ON true
        WHERE ($1::uuid IS NULL OR r.id>$1) ORDER BY r.id LIMIT 51`,
          [
            p.after ?? null,
            policy?.mode ?? "roster",
            policy?.version ?? 0,
            p.employeeId ?? null,
          ],
        )
      ).rows;
      const employees = rows.slice(0, 50).map((r) => {
        const eligible =
          +r.starts_at <= now &&
          +r.ends_at > now &&
          (policy?.mode === "roster" || r.checked_in);
        const matching =
          r.location?.roster_version === r.version &&
          r.location?.policy_version === policy?.version;
        // Last contact: an accepted upload or a heartbeat, whichever is newer.
        const received = matching ? Date.parse(r.location.received_at) : 0,
          heartbeat = r.heartbeat_at ? +r.heartbeat_at : 0,
          seen = Math.max(received || 0, heartbeat);
        const { heartbeat_at, device_state, ...row } = r;
        const locationOff =
          device_state === "location_off" && heartbeat >= (received || 0);
        return {
          ...row,
          seen_at: seen ? new Date(seen).toISOString() : null,
          location_off: locationOff,
          status: trackingStatus({
            enabled: policy?.enabled ?? false,
            eligible,
            observedAt: matching ? r.location?.observed_at : null,
            seenAt: seen ? new Date(seen) : null,
            locationOff,
            now,
            staleSeconds: policy?.stale_seconds ?? 120,
          }),
        };
      });
      return {
        serverTime: new Date(now).toISOString(),
        policy,
        employees,
        next: rows.length > 50 ? employees.at(-1).id : null,
        geofence:
          (
            await c.query(
              "SELECT ST_AsGeoJSON(boundary::geometry)::json geojson FROM app.geofence_versions ORDER BY version DESC LIMIT 1",
            )
          ).rows[0]?.geojson ?? null,
      };
    });
  }
}
