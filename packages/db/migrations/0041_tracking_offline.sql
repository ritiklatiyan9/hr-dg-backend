-- Bounded, device-bound offline capture grants. Existing telemetry is retained.
CREATE TABLE app.tracking_offline_grants (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 employee_id uuid NOT NULL, user_id uuid NOT NULL, device_id uuid NOT NULL,
 roster_id uuid NOT NULL, roster_version integer NOT NULL, policy_version integer NOT NULL,
 geofence_version integer NOT NULL, operation_version integer NOT NULL,
 starts_at timestamptz NOT NULL, ends_at timestamptz NOT NULL, upload_until timestamptz NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(),
 CHECK(ends_at>starts_at AND ends_at<=starts_at+interval '24 hours'),
 CHECK(upload_until=ends_at+interval '7 days'),
 UNIQUE(organization_id,id),
 FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id),
 FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id),
 FOREIGN KEY(organization_id,roster_id) REFERENCES app.shift_rosters(organization_id,id),
 FOREIGN KEY(organization_id,site_id,policy_version) REFERENCES app.tracking_policies(organization_id,site_id,version)
);
ALTER TABLE app.tracking_offline_grants ENABLE ROW LEVEL SECURITY;
CREATE POLICY tracking_grant_read ON app.tracking_offline_grants FOR SELECT USING(
 organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND
 ((user_id=app.actor_id() AND app.allowed('my_attendance.view',employee_id)) OR app.allowed('employee_tracking.view',employee_id)));
CREATE POLICY tracking_grant_issue ON app.tracking_offline_grants FOR INSERT WITH CHECK(
 organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND user_id=app.actor_id()
 AND app.allowed('my_attendance.create',employee_id)
 AND starts_at>=now()-interval '5 seconds' AND starts_at<=now()+interval '24 hours 5 seconds'
 AND EXISTS(SELECT 1 FROM app.employees e WHERE e.id=employee_id AND e.user_id=app.actor_id())
 AND EXISTS(SELECT 1 FROM app.shift_rosters r WHERE r.id=roster_id AND r.employee_id=tracking_offline_grants.employee_id AND r.version=roster_version AND tracking_offline_grants.starts_at>=r.starts_at AND tracking_offline_grants.ends_at<=r.ends_at)
 AND EXISTS(SELECT 1 FROM app.tracking_policies p WHERE p.version=policy_version AND p.enabled AND p.version=(SELECT max(version) FROM app.tracking_policies))
 AND geofence_version=(SELECT max(version) FROM app.geofence_versions)
 AND operation_version=(SELECT max(version) FROM app.operation_policies));
GRANT SELECT,INSERT ON app.tracking_offline_grants TO hr_runtime;
CREATE INDEX tracking_grant_active ON app.tracking_offline_grants(organization_id,site_id,employee_id,ends_at DESC);
ALTER TABLE app.tracking_samples ADD COLUMN offline_grant_id uuid;
ALTER TABLE app.tracking_samples ADD CONSTRAINT tracking_sample_grant_fk FOREIGN KEY(organization_id,offline_grant_id) REFERENCES app.tracking_offline_grants(organization_id,id);
DROP POLICY tracking_sample_insert ON app.tracking_samples;
CREATE POLICY tracking_sample_insert ON app.tracking_samples FOR INSERT WITH CHECK(offline_grant_id IS NULL AND organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND user_id=app.actor_id() AND app.allowed('my_attendance.create',employee_id) AND EXISTS(SELECT 1 FROM app.tracking_policies p WHERE p.version=tracking_samples.policy_version AND p.enabled AND p.version=(SELECT max(version) FROM app.tracking_policies)) AND EXISTS(SELECT 1 FROM app.employees e WHERE e.id=employee_id AND e.user_id=app.actor_id()) AND EXISTS(SELECT 1 FROM app.shift_rosters r WHERE r.id=roster_id AND r.employee_id=tracking_samples.employee_id AND r.version=roster_version AND observed_at>=r.starts_at AND observed_at<r.ends_at AND now()>=r.starts_at AND now()<r.ends_at));
-- Delayed inserts must carry a real grant; merely backdating a sample cannot pass RLS.
CREATE POLICY tracking_offline_insert ON app.tracking_samples FOR INSERT WITH CHECK(
 organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND user_id=app.actor_id()
 AND app.allowed('my_attendance.create',employee_id)
 AND EXISTS(SELECT 1 FROM app.tracking_offline_grants g
   JOIN app.shift_rosters r ON r.id=g.roster_id
   JOIN app.tracking_policies p ON p.version=g.policy_version
   WHERE g.id=offline_grant_id AND g.employee_id=tracking_samples.employee_id AND g.user_id=app.actor_id()
   AND g.device_id=tracking_samples.device_id AND g.roster_id=tracking_samples.roster_id
   AND g.roster_version=tracking_samples.roster_version AND g.policy_version=tracking_samples.policy_version
   AND g.geofence_version=tracking_samples.geofence_version
   AND observed_at>=g.starts_at AND observed_at<g.ends_at AND observed_at<=now()+interval '5 seconds' AND now()<=g.upload_until
   AND r.version=g.roster_version AND p.enabled AND p.version=(SELECT max(version) FROM app.tracking_policies)));
-- BRIN is compact and supports operational time-range inspection of append-only data.
CREATE INDEX tracking_received_brin ON app.tracking_samples USING brin(received_at) WITH (pages_per_range=64);
ALTER TABLE app.tracking_samples SET (autovacuum_analyze_scale_factor=0.02, autovacuum_vacuum_insert_scale_factor=0.05);
