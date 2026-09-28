-- Duty telemetry is independent of attendance sequencing and never establishes attendance.
INSERT INTO app.module_catalogue VALUES('employee_tracking','Duty location','ड्यूटी स्थान','Operations',3,ARRAY['view','manage'],ARRAY[]::text[],ARRAY['employees.view','attendance.view']);
INSERT INTO app.permission_catalogue VALUES('employee_tracking.view','employee_tracking','view'),('employee_tracking.manage','employee_tracking','manage');
INSERT INTO app.role_templates(role,key,scope) SELECT r,k,'site' FROM unnest(ARRAY['super_admin','admin','hr']) r CROSS JOIN unnest(ARRAY['employee_tracking.view','employee_tracking.manage']) k;
CREATE TABLE app.tracking_policies (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 version integer NOT NULL CHECK(version>0), enabled boolean NOT NULL, mode text NOT NULL CHECK(mode IN ('roster','checked_in')),
 sample_seconds integer NOT NULL CHECK(sample_seconds BETWEEN 15 AND 300), stale_seconds integer NOT NULL CHECK(stale_seconds BETWEEN sample_seconds*2 AND 1800),
 notice text NOT NULL CHECK(length(notice) BETWEEN 20 AND 2000), reason text NOT NULL, author_id uuid NOT NULL, created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(organization_id,site_id,version), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id),
 FOREIGN KEY(organization_id,author_id) REFERENCES auth.users(organization_id,id)
);
ALTER TABLE app.tracking_policies ENABLE ROW LEVEL SECURITY;
CREATE POLICY tracking_policy_read ON app.tracking_policies FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('my_attendance.view') OR app.allowed('employee_tracking.view')));
CREATE POLICY tracking_policy_insert ON app.tracking_policies FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND app.allowed('employee_tracking.manage') AND (app.decision('employee_tracking.manage')->>'scope')='site' AND author_id=app.actor_id());
GRANT SELECT,INSERT ON app.tracking_policies TO hr_runtime;
CREATE TABLE app.tracking_samples (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 employee_id uuid NOT NULL, user_id uuid NOT NULL, device_id uuid NOT NULL, client_id uuid NOT NULL, payload_hash text NOT NULL,
 roster_id uuid NOT NULL, roster_version integer NOT NULL, policy_version integer NOT NULL, geofence_version integer NOT NULL,
 observed_at timestamptz NOT NULL, received_at timestamptz NOT NULL DEFAULT now(), point geography(Point,4326) NOT NULL,
 accuracy_m double precision NOT NULL CHECK(accuracy_m>=0 AND accuracy_m<=500), classification text NOT NULL CHECK(classification IN ('inside','outside','unknown')),
 UNIQUE(organization_id,user_id,client_id), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id),
 FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id),
 FOREIGN KEY(organization_id,roster_id) REFERENCES app.shift_rosters(organization_id,id),
 FOREIGN KEY(organization_id,site_id,policy_version) REFERENCES app.tracking_policies(organization_id,site_id,version)
);
ALTER TABLE app.tracking_samples ENABLE ROW LEVEL SECURITY;
CREATE POLICY tracking_sample_read ON app.tracking_samples FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND ((user_id=app.actor_id() AND app.allowed('my_attendance.view',employee_id)) OR app.allowed('employee_tracking.view',employee_id)));
CREATE POLICY tracking_sample_insert ON app.tracking_samples FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND user_id=app.actor_id() AND app.allowed('my_attendance.create',employee_id) AND EXISTS(SELECT 1 FROM app.tracking_policies p WHERE p.version=tracking_samples.policy_version AND p.enabled AND p.version=(SELECT max(version) FROM app.tracking_policies)) AND EXISTS(SELECT 1 FROM app.employees e WHERE e.id=employee_id AND e.user_id=app.actor_id()) AND EXISTS(SELECT 1 FROM app.shift_rosters r WHERE r.id=roster_id AND r.employee_id=tracking_samples.employee_id AND r.version=roster_version AND observed_at>=r.starts_at AND observed_at<r.ends_at AND now()>=r.starts_at AND now()<r.ends_at));
GRANT SELECT,INSERT ON app.tracking_samples TO hr_runtime;
CREATE INDEX tracking_latest ON app.tracking_samples(organization_id,site_id,roster_id,observed_at DESC,id DESC);
CREATE INDEX tracking_roster_window ON app.shift_rosters(organization_id,site_id,ends_at,starts_at);
-- Serialize roster edits per employee across sites; detect hidden overlapping shifts too.
CREATE FUNCTION app.prevent_roster_overlap() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
 PERFORM pg_advisory_xact_lock(hashtextextended(NEW.organization_id::text||':roster:'||NEW.employee_id::text,0));
 IF EXISTS(SELECT 1 FROM app.shift_rosters r WHERE r.organization_id=NEW.organization_id AND r.employee_id=NEW.employee_id AND r.id<>NEW.id AND NOT (TG_OP='INSERT' AND r.site_id=NEW.site_id AND r.work_date=NEW.work_date) AND tstzrange(r.starts_at,r.ends_at,'[)') && tstzrange(NEW.starts_at,NEW.ends_at,'[)')) THEN RAISE EXCEPTION 'Roster overlaps an assigned shift' USING ERRCODE='23P01'; END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION app.prevent_roster_overlap() FROM PUBLIC;
CREATE TRIGGER guard_roster_overlap BEFORE INSERT OR UPDATE ON app.shift_rosters FOR EACH ROW EXECUTE FUNCTION app.prevent_roster_overlap();
UPDATE auth.users SET permission_version=permission_version+1;
