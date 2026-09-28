import { createHash } from "node:crypto";
import { fail, type Actor } from "../../../packages/authz/src/index.js";
import type { Tx } from "../../../packages/db/src/index.js";
import type { Tracking, TrackingSample } from "./tracking.js";

export async function offlinePermit(
  service: Tracking,
  c: Tx,
  actor: Actor,
  expected: { rosterId: string; rosterVersion: number; policyVersion: number },
) {
  const me = await service.mine(c);
  await service.allowed(c, "my_attendance.create", me.id);
  await c.query("SELECT pg_advisory_xact_lock(hashtextextended($1,0))", [
    `${actor.organizationId}:tracking-sample:${me.id}`,
  ]);
  await c.query("SELECT pg_advisory_xact_lock(hashtextextended($1,0))", [
    `${actor.organizationId}:roster:${me.id}`,
  ]);
  await c.query(
    "SELECT pg_advisory_xact_lock_shared(hashtextextended(app.org_id()::text||':tracking:'||app.site_id()::text,0))",
  );
  const policy = await service.trackingPolicy(c);
  const activeWindow = await service.trackingWindow(c, me.id, policy);
  const window =
    activeWindow ??
    (policy?.enabled && policy.mode === "roster"
      ? (
          await c.query(
            "SELECT r.* FROM app.shift_rosters r WHERE r.employee_id=$1 AND r.id=$2 AND r.starts_at>now() AND r.starts_at<=now()+interval '24 hours' AND app.allowed('my_attendance.create',r.employee_id)",
            [me.id, expected.rosterId],
          )
        ).rows[0]
      : null);
  if (
    !window ||
    window.id !== expected.rosterId ||
    window.version !== expected.rosterVersion ||
    policy.version !== expected.policyVersion
  )
    fail(
      "CONFLICT",
      "Refresh the HR duty window before preparing offline tracking",
    );
  const device = (
    await c.query("SELECT app.operation_device($1) id", [actor.sessionId])
  ).rows[0]?.id;
  if (!device) fail("UNAUTHENTICATED", "Device session expired");
  const operation = await service.policy(c);
  const fence = (
    await c.query(
      "SELECT version FROM app.geofence_versions ORDER BY version DESC LIMIT 1",
    )
  ).rows[0];
  if (!fence) fail("CONFIGURATION_REQUIRED", "Geofence is required");
  const active = (
    await c.query(
      "SELECT * FROM app.tracking_offline_grants WHERE employee_id=$1 AND roster_id=$2 AND roster_version=$3 AND policy_version=$4 AND ends_at>now() ORDER BY created_at DESC",
      [me.id, window.id, window.version, policy.version],
    )
  ).rows;
  if (active.some((g) => g.device_id !== device))
    fail(
      "CONFLICT",
      "This duty window already has an offline grant on another device",
    );
  const prior = active.find(
    (g) =>
      g.roster_id === window.id &&
      g.roster_version === window.version &&
      g.policy_version === policy.version &&
      g.operation_version === operation.version &&
      g.geofence_version === fence.version,
  );
  if (prior) return prior;
  // Keep Postgres microsecond precision at future roster boundaries. Converting
  // starts_at through a JavaScript Date could move it just before the RLS bound.
  return (
    await c.query(
      `WITH bounds AS (
      SELECT GREATEST(clock_timestamp(),starts_at) capture_start,ends_at FROM app.shift_rosters WHERE id=$3
    ), span AS (SELECT capture_start,LEAST(ends_at,capture_start+interval '24 hours') capture_end FROM bounds)
    INSERT INTO app.tracking_offline_grants(organization_id,site_id,employee_id,user_id,device_id,roster_id,roster_version,policy_version,geofence_version,operation_version,starts_at,ends_at,upload_until)
    SELECT app.org_id(),app.site_id(),$1,app.actor_id(),$2,$3,$4,$5,$6,$7,capture_start,capture_end,capture_end+interval '7 days' FROM span RETURNING *`,
      [
        me.id,
        device,
        window.id,
        window.version,
        policy.version,
        fence.version,
        operation.version,
      ],
    )
  ).rows[0];
}

/** Fixed 100-row batches, one transaction, set-based validation and persistence. */
export async function offlineBatch(
  service: Tracking,
  c: Tx,
  actor: Actor,
  input: { grantId: string; samples: TrackingSample[] },
) {
  const me = await service.mine(c);
  await service.allowed(c, "my_attendance.create", me.id);
  await c.query("SELECT pg_advisory_xact_lock(hashtextextended($1,0))", [
    `${actor.organizationId}:tracking-sample:${me.id}`,
  ]);
  await c.query("SELECT pg_advisory_xact_lock(hashtextextended($1,0))", [
    `${actor.organizationId}:roster:${me.id}`,
  ]);
  const grant = (
    await c.query(
      `SELECT g.*,r.version current_roster_version,p.rules FROM app.tracking_offline_grants g
    JOIN app.shift_rosters r ON r.id=g.roster_id JOIN app.operation_policies p ON p.version=g.operation_version
    WHERE g.id=$1 AND g.user_id=app.actor_id() AND g.employee_id=$2`,
      [input.grantId, me.id],
    )
  ).rows[0];
  if (!grant)
    fail(
      "FORBIDDEN",
      "Offline grant does not belong to this employee and site",
    );
  await c.query("SELECT pg_advisory_xact_lock_shared(hashtextextended($1,0))", [
    `${actor.organizationId}:tracking:${grant.site_id}`,
  ]);
  const device = (
    await c.query("SELECT app.operation_device($1) id", [actor.sessionId])
  ).rows[0]?.id;
  if (!device || grant.device_id !== device)
    fail("FORBIDDEN", "Offline grant belongs to another device");
  const policy = await service.trackingPolicy(c);
  // Return per-item outcomes even after revocation so a poison item cannot block the queue.
  const grantFailure =
    Date.now() > +grant.upload_until
      ? "UPLOAD_EXPIRED"
      : !policy?.enabled ||
          policy.version !== grant.policy_version ||
          grant.current_roster_version !== grant.roster_version
        ? "AUTHORIZATION_CHANGED"
        : null;
  const ids = new Set<string>();
  for (const p of input.samples) {
    if (ids.has(p.clientId))
      fail("BAD_INPUT", "Duplicate IDs within a batch are not allowed");
    ids.add(p.clientId);
  }
  const rows = input.samples.map((p) => ({
    ...p,
    payloadHash: createHash("sha256").update(JSON.stringify(p)).digest("hex"),
  }));
  const result = await c.query(
    `WITH incoming AS (
    SELECT * FROM jsonb_to_recordset($1::jsonb) AS i("clientId" uuid,"rosterId" uuid,"rosterVersion" int,"policyVersion" int,latitude float8,longitude float8,"accuracyM" float8,"observedAt" timestamptz,mocked bool,"payloadHash" text)
  ), checked AS (
    SELECT i.*,old.id existing,old.payload_hash,
      CASE WHEN old.id IS NOT NULL THEN CASE WHEN old.payload_hash=i."payloadHash" THEN NULL ELSE 'ID_CONFLICT' END
        WHEN $2::text IS NOT NULL THEN $2
        WHEN i."rosterId"<>$3 OR i."rosterVersion"<>$4 OR i."policyVersion"<>$5 THEN 'AUTHORIZATION_CHANGED'
        WHEN i."observedAt"<$6 OR i."observedAt">=$7 OR i."observedAt">clock_timestamp()+interval '5 seconds' THEN 'OUTSIDE_WINDOW'
        WHEN i.mocked OR i."accuracyM">$8 THEN 'INVALID_LOCATION'
        ELSE NULL END reason
    FROM incoming i LEFT JOIN app.tracking_samples old ON old.organization_id=app.org_id() AND old.user_id=app.actor_id() AND old.client_id=i."clientId"
  ), candidates AS (
    SELECT *, lag("observedAt") OVER(ORDER BY "observedAt","clientId") previous_in_batch FROM checked WHERE reason IS NULL AND existing IS NULL
  ), spaced AS (
    SELECT n.*, CASE WHEN n."observedAt"-n.previous_in_batch < $9::int*interval '1 second'
      OR EXISTS(SELECT 1 FROM app.tracking_samples t WHERE t.organization_id=app.org_id() AND t.site_id=app.site_id() AND t.roster_id=$3
        AND t.observed_at>n."observedAt"-$9::int*interval '1 second' AND t.observed_at<n."observedAt"+$9::int*interval '1 second')
      THEN 'SAMPLE_TOO_CLOSE' ELSE NULL END spacing_reason FROM candidates n
  ), accepted AS (
    INSERT INTO app.tracking_samples(organization_id,site_id,employee_id,user_id,device_id,client_id,payload_hash,roster_id,roster_version,policy_version,geofence_version,observed_at,point,accuracy_m,classification,offline_grant_id)
    SELECT app.org_id(),app.site_id(),$10,app.actor_id(),$11,n."clientId",n."payloadHash",$3,$4,$5,$12,n."observedAt",loc.point,n."accuracyM",
      CASE WHEN ST_Distance(ST_Boundary(f.boundary::geometry)::geography,loc.point)<=n."accuracyM" THEN 'unknown' WHEN ST_Covers(f.boundary::geometry,loc.point::geometry) THEN 'inside' ELSE 'outside' END,$13
    FROM spaced n JOIN app.geofence_versions f ON f.version=$12
    CROSS JOIN LATERAL(SELECT ST_SetSRID(ST_MakePoint(n.longitude,n.latitude),4326)::geography point) loc
    WHERE n.spacing_reason IS NULL RETURNING client_id,id
  ) SELECT ch."clientId" AS "clientId", COALESCE(a.id,ch.existing) id,
      CASE WHEN ch.reason IS NULL AND (a.id IS NOT NULL OR ch.existing IS NOT NULL) THEN 'accepted' ELSE 'rejected' END status,
      COALESCE(ch.reason,s.spacing_reason) reason
    FROM checked ch LEFT JOIN spaced s ON s."clientId"=ch."clientId" LEFT JOIN accepted a ON a.client_id=ch."clientId"`,
    [
      JSON.stringify(rows),
      grantFailure,
      grant.roster_id,
      grant.roster_version,
      grant.policy_version,
      grant.starts_at,
      grant.ends_at,
      grant.rules.maxAccuracyM,
      Math.max(1, (policy?.sample_seconds ?? 15) - 1),
      me.id,
      device,
      grant.geofence_version,
      grant.id,
    ],
  );
  return {
    results: result.rows,
    serverTime: new Date().toISOString(),
    limit: 100,
  };
}

/** Phone liveness without a new fix: a still phone gets no GPS callbacks, so the
 *  app reports "connected" (and whether device location is off) on its poll. */
export async function offlineHeartbeat(
  service: Tracking,
  c: Tx,
  actor: Actor,
  input: { grantId: string; state: "tracking" | "location_off" },
) {
  const me = await service.mine(c);
  await service.allowed(c, "my_attendance.create", me.id);
  const device = (
    await c.query("SELECT app.operation_device($1) id", [actor.sessionId])
  ).rows[0]?.id;
  if (!device) fail("UNAUTHENTICATED", "Device session expired");
  const grant = (
    await c.query(
      `SELECT g.id,now()>=g.starts_at AND now()<g.ends_at in_window,
        r.version=g.roster_version AND p.enabled AND p.version=g.policy_version current
      FROM app.tracking_offline_grants g JOIN app.shift_rosters r ON r.id=g.roster_id
      CROSS JOIN LATERAL(SELECT enabled,version FROM app.tracking_policies ORDER BY version DESC LIMIT 1) p
      WHERE g.id=$1 AND g.user_id=app.actor_id() AND g.employee_id=$2 AND g.device_id=$3`,
      [input.grantId, me.id, device],
    )
  ).rows[0];
  if (!grant)
    fail("FORBIDDEN", "Offline grant belongs to another device or employee");
  const serverTime = new Date().toISOString();
  if (!grant.current)
    return { status: "rejected", reason: "AUTHORIZATION_CHANGED", serverTime };
  if (!grant.in_window)
    return { status: "rejected", reason: "OUTSIDE_WINDOW", serverTime };
  // ponytail: 10 s write throttle per grant; repeated pings cost one read.
  await c.query(
    `UPDATE app.tracking_offline_grants SET last_seen_at=now(),device_state=$2
    WHERE id=$1 AND (last_seen_at IS NULL OR last_seen_at<now()-interval '10 seconds' OR device_state IS DISTINCT FROM $2)`,
    [grant.id, input.state],
  );
  return { status: "accepted", serverTime };
}
