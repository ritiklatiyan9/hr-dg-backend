-- Phase 3 additive operational storage. Applied migrations are immutable.
CREATE FUNCTION app.operation_allowed(permission text,employee uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$ SELECT app.allowed(permission,employee) $$;
REVOKE ALL ON FUNCTION app.operation_allowed(text,uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.operation_allowed(text,uuid) TO hr_runtime;
CREATE TABLE app.operation_policies (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), version integer NOT NULL, rules jsonb NOT NULL, reason text NOT NULL, UNIQUE(organization_id,site_id,version),
 UNIQUE(organization_id,id), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id)
 );
 ALTER TABLE app.operation_policies ENABLE ROW LEVEL SECURITY;
 CREATE POLICY scoped_read ON app.operation_policies FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('site_settings.view') OR app.allowed('my_attendance.view') OR app.allowed('my_leave.view')));
 CREATE POLICY scoped_insert ON app.operation_policies FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('site_settings.manage')));
 GRANT SELECT,INSERT ON app.operation_policies TO hr_runtime;
 CREATE INDEX operation_policies_scope ON app.operation_policies(organization_id,site_id);
 CREATE TABLE app.geofence_versions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), version integer NOT NULL, boundary geography(Polygon,4326) NOT NULL, label text NOT NULL, reason text NOT NULL, UNIQUE(organization_id,site_id,version),
 UNIQUE(organization_id,id), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id)
 );
 ALTER TABLE app.geofence_versions ENABLE ROW LEVEL SECURITY;
 CREATE POLICY scoped_read ON app.geofence_versions FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('site_settings.view') OR app.allowed('my_attendance.view')));
 CREATE POLICY scoped_insert ON app.geofence_versions FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('site_settings.manage')));
 GRANT SELECT,INSERT ON app.geofence_versions TO hr_runtime;
 CREATE INDEX geofence_versions_scope ON app.geofence_versions(organization_id,site_id);
 CREATE TABLE app.duty_sessions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), employee_id uuid NOT NULL, user_id uuid NOT NULL, device_id uuid NOT NULL, policy_version integer NOT NULL, geofence_version integer NOT NULL, status text NOT NULL DEFAULT 'open' CHECK(status IN ('open','closed')), opened_at timestamptz NOT NULL, closed_at timestamptz, last_sequence integer NOT NULL DEFAULT 0, version integer NOT NULL DEFAULT 1,
 UNIQUE(organization_id,id), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id)
 );
 ALTER TABLE app.duty_sessions ENABLE ROW LEVEL SECURITY;
 CREATE POLICY scoped_read ON app.duty_sessions FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('my_attendance.view',employee_id) OR app.allowed('attendance.view',employee_id) OR app.allowed('field_duty.view',employee_id)));
 CREATE POLICY scoped_insert ON app.duty_sessions FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (user_id=app.actor_id() AND app.allowed('my_attendance.create',employee_id) OR app.allowed('attendance.approve',employee_id)));
 GRANT SELECT,INSERT ON app.duty_sessions TO hr_runtime;
 CREATE INDEX duty_sessions_scope ON app.duty_sessions(organization_id,site_id);
 CREATE POLICY scoped_update ON app.duty_sessions FOR UPDATE USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (user_id=app.actor_id() AND app.allowed('my_attendance.create',employee_id) OR app.allowed('attendance.approve',employee_id))) WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (user_id=app.actor_id() AND app.allowed('my_attendance.create',employee_id) OR app.allowed('attendance.approve',employee_id)));
 GRANT UPDATE ON app.duty_sessions TO hr_runtime;
 ALTER TABLE app.duty_sessions ADD FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id);
CREATE TABLE app.duty_events (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), employee_id uuid NOT NULL, user_id uuid NOT NULL, duty_id uuid NOT NULL, client_event_id uuid NOT NULL, device_id uuid NOT NULL, sequence integer NOT NULL CHECK(sequence>0), kind text NOT NULL CHECK(kind IN ('IN','OUT','FIELD_START','FIELD_END','BREAK_START','BREAK_END','LOCATION','VISIT_START','VISIT_END')), captured_at timestamptz NOT NULL, received_at timestamptz NOT NULL DEFAULT now(), payload_version integer NOT NULL, payload_hash text NOT NULL, payload jsonb NOT NULL, UNIQUE(organization_id,user_id,client_event_id),
 UNIQUE(organization_id,id), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id)
 );
 ALTER TABLE app.duty_events ENABLE ROW LEVEL SECURITY;
 CREATE POLICY scoped_read ON app.duty_events FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('my_attendance.view',employee_id) OR app.allowed('attendance.view',employee_id) OR app.allowed('field_duty.view',employee_id)));
 CREATE POLICY scoped_insert ON app.duty_events FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (user_id=app.actor_id() AND app.allowed('my_attendance.create',employee_id)));
 GRANT SELECT,INSERT ON app.duty_events TO hr_runtime;
 CREATE INDEX duty_events_scope ON app.duty_events(organization_id,site_id);
 ALTER TABLE app.duty_events ADD FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id);
CREATE TABLE app.geofence_observations (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), employee_id uuid NOT NULL, event_id uuid NOT NULL, geofence_version integer NOT NULL, point geography(Point,4326), accuracy_m double precision, observed_at timestamptz, classification text NOT NULL CHECK(classification IN ('inside','outside','unknown')), reason text NOT NULL, UNIQUE(organization_id,event_id),
 UNIQUE(organization_id,id), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id)
 );
 ALTER TABLE app.geofence_observations ENABLE ROW LEVEL SECURITY;
 CREATE POLICY scoped_read ON app.geofence_observations FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('my_attendance.view',employee_id) OR app.allowed('attendance.view',employee_id) OR app.allowed('field_duty.view',employee_id)));
 CREATE POLICY scoped_insert ON app.geofence_observations FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('my_attendance.create',employee_id)));
 GRANT SELECT,INSERT ON app.geofence_observations TO hr_runtime;
 CREATE INDEX geofence_observations_scope ON app.geofence_observations(organization_id,site_id);
 ALTER TABLE app.geofence_observations ADD FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id);
CREATE TABLE app.event_verifications (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), employee_id uuid NOT NULL, event_id uuid NOT NULL, status text NOT NULL CHECK(status IN ('accepted','pending_verification','rejected')), reason text NOT NULL, effective_at timestamptz, reviewer_id uuid, UNIQUE(organization_id,event_id),
 UNIQUE(organization_id,id), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id)
 );
 ALTER TABLE app.event_verifications ENABLE ROW LEVEL SECURITY;
 CREATE POLICY scoped_read ON app.event_verifications FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('my_attendance.view',employee_id) OR app.allowed('attendance.view',employee_id) OR app.allowed('field_duty.view',employee_id)));
 CREATE POLICY scoped_insert ON app.event_verifications FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('my_attendance.create',employee_id) OR app.allowed('attendance.approve',employee_id)));
 GRANT SELECT,INSERT ON app.event_verifications TO hr_runtime;
 CREATE INDEX event_verifications_scope ON app.event_verifications(organization_id,site_id);
 CREATE POLICY scoped_update ON app.event_verifications FOR UPDATE USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('my_attendance.create',employee_id) OR app.allowed('attendance.approve',employee_id))) WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('my_attendance.create',employee_id) OR app.allowed('attendance.approve',employee_id)));
 GRANT UPDATE ON app.event_verifications TO hr_runtime;
 ALTER TABLE app.event_verifications ADD FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id);
CREATE TABLE app.duty_segments (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), employee_id uuid NOT NULL, duty_id uuid NOT NULL, revision integer NOT NULL, engine_version integer NOT NULL, starts_at timestamptz NOT NULL, ends_at timestamptz NOT NULL CHECK(ends_at>starts_at), kind text NOT NULL CHECK(kind IN ('office','field','break','outside','unknown')), source_ids jsonb NOT NULL, assumption text NOT NULL, visit_id uuid,
 UNIQUE(organization_id,id), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id)
 );
 ALTER TABLE app.duty_segments ENABLE ROW LEVEL SECURITY;
 CREATE POLICY scoped_read ON app.duty_segments FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('my_attendance.view',employee_id) OR app.allowed('attendance.view',employee_id) OR app.allowed('field_duty.view',employee_id)));
 CREATE POLICY scoped_insert ON app.duty_segments FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('my_attendance.create',employee_id) OR app.allowed('attendance.approve',employee_id)));
 GRANT SELECT,INSERT ON app.duty_segments TO hr_runtime;
 CREATE INDEX duty_segments_scope ON app.duty_segments(organization_id,site_id);
 ALTER TABLE app.duty_segments ADD FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id);
CREATE TABLE app.attendance_adjustments (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), employee_id uuid NOT NULL, duty_id uuid NOT NULL, requester_id uuid NOT NULL, reviewer_id uuid, starts_at timestamptz NOT NULL, ends_at timestamptz NOT NULL CHECK(ends_at>starts_at), kind text NOT NULL CHECK(kind IN ('office','field','break','outside','unknown','overtime')), close_session boolean NOT NULL DEFAULT false, reason text NOT NULL, decision_note text, status text NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','approved','rejected')), version integer NOT NULL DEFAULT 1,
 UNIQUE(organization_id,id), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id)
 );
 ALTER TABLE app.attendance_adjustments ENABLE ROW LEVEL SECURITY;
 CREATE POLICY scoped_read ON app.attendance_adjustments FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('my_attendance.view',employee_id) OR app.allowed('attendance.review',employee_id)));
 CREATE POLICY scoped_insert ON app.attendance_adjustments FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (requester_id=app.actor_id() AND app.allowed('my_attendance.submit',employee_id) OR app.allowed('attendance.approve',employee_id)));
 GRANT SELECT,INSERT ON app.attendance_adjustments TO hr_runtime;
 CREATE INDEX attendance_adjustments_scope ON app.attendance_adjustments(organization_id,site_id);
 CREATE POLICY scoped_update ON app.attendance_adjustments FOR UPDATE USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (requester_id=app.actor_id() AND app.allowed('my_attendance.submit',employee_id) OR app.allowed('attendance.approve',employee_id))) WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (requester_id=app.actor_id() AND app.allowed('my_attendance.submit',employee_id) OR app.allowed('attendance.approve',employee_id)));
 GRANT UPDATE ON app.attendance_adjustments TO hr_runtime;
 ALTER TABLE app.attendance_adjustments ADD FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id);
CREATE TABLE app.shift_rosters (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), employee_id uuid NOT NULL, shift_id uuid NOT NULL, work_date date NOT NULL, starts_at timestamptz NOT NULL, ends_at timestamptz NOT NULL CHECK(ends_at>starts_at), version integer NOT NULL DEFAULT 1, UNIQUE(organization_id,employee_id,work_date),
 UNIQUE(organization_id,id), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id)
 );
 ALTER TABLE app.shift_rosters ENABLE ROW LEVEL SECURITY;
 CREATE POLICY scoped_read ON app.shift_rosters FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('my_attendance.view',employee_id) OR app.allowed('attendance.view',employee_id)));
 CREATE POLICY scoped_insert ON app.shift_rosters FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('attendance.edit',employee_id)));
 GRANT SELECT,INSERT ON app.shift_rosters TO hr_runtime;
 CREATE INDEX shift_rosters_scope ON app.shift_rosters(organization_id,site_id);
 CREATE POLICY scoped_update ON app.shift_rosters FOR UPDATE USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('attendance.edit',employee_id))) WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('attendance.edit',employee_id)));
 GRANT UPDATE ON app.shift_rosters TO hr_runtime;
 ALTER TABLE app.shift_rosters ADD FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id);
CREATE TABLE app.field_visits (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), employee_id uuid NOT NULL, assignee_id uuid NOT NULL, title text NOT NULL, scheduled_at timestamptz NOT NULL, latitude double precision NOT NULL, longitude double precision NOT NULL, radius_m integer NOT NULL, notes text NOT NULL DEFAULT '', status text NOT NULL DEFAULT 'assigned', version integer NOT NULL DEFAULT 1,
 UNIQUE(organization_id,id), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id)
 );
 ALTER TABLE app.field_visits ENABLE ROW LEVEL SECURITY;
 CREATE POLICY scoped_read ON app.field_visits FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('field_duty.view',employee_id)));
 CREATE POLICY scoped_insert ON app.field_visits FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('field_duty.create',employee_id) OR assignee_id=app.actor_id() AND app.allowed('field_duty.submit',employee_id)));
 GRANT SELECT,INSERT ON app.field_visits TO hr_runtime;
 CREATE INDEX field_visits_scope ON app.field_visits(organization_id,site_id);
 CREATE POLICY scoped_update ON app.field_visits FOR UPDATE USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('field_duty.create',employee_id) OR assignee_id=app.actor_id() AND app.allowed('field_duty.submit',employee_id))) WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('field_duty.create',employee_id) OR assignee_id=app.actor_id() AND app.allowed('field_duty.submit',employee_id)));
 GRANT UPDATE ON app.field_visits TO hr_runtime;
 ALTER TABLE app.field_visits ADD FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id);
CREATE TABLE app.private_files (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), employee_id uuid NOT NULL, owner_id uuid NOT NULL, client_id uuid NOT NULL, purpose text NOT NULL CHECK(purpose IN ('attendance','task','visit')), parent_id uuid, declared_type text NOT NULL, byte_limit integer NOT NULL, original_hash text, content_hash text, object_key text NOT NULL, status text NOT NULL DEFAULT 'awaiting_upload' CHECK(status IN ('awaiting_upload','ready','quarantined','rejected')), scan_result text NOT NULL DEFAULT 'not_scanned', expires_at timestamptz NOT NULL DEFAULT now()+interval '1 hour', UNIQUE(organization_id,owner_id,client_id),
 UNIQUE(organization_id,id), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id)
 );
 ALTER TABLE app.private_files ENABLE ROW LEVEL SECURITY;
 CREATE POLICY scoped_read ON app.private_files FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (owner_id=app.actor_id() OR app.allowed('attendance.view',employee_id) OR app.allowed('tasks.view',employee_id)));
 CREATE POLICY scoped_insert ON app.private_files FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (owner_id=app.actor_id()));
 GRANT SELECT,INSERT ON app.private_files TO hr_runtime;
 CREATE INDEX private_files_scope ON app.private_files(organization_id,site_id);
 CREATE POLICY scoped_update ON app.private_files FOR UPDATE USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (owner_id=app.actor_id())) WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (owner_id=app.actor_id()));
 GRANT UPDATE ON app.private_files TO hr_runtime;
 ALTER TABLE app.private_files ADD FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id);
CREATE TABLE app.leave_types (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), code text NOT NULL, label text NOT NULL, half_days boolean NOT NULL, include_weekends boolean NOT NULL, include_holidays boolean NOT NULL, approver_id uuid NOT NULL, active boolean NOT NULL DEFAULT true, version integer NOT NULL DEFAULT 1, UNIQUE(organization_id,site_id,code),
 UNIQUE(organization_id,id), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id)
 );
 ALTER TABLE app.leave_types ENABLE ROW LEVEL SECURITY;
 CREATE POLICY scoped_read ON app.leave_types FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('my_leave.view') OR app.allowed('leave.view')));
 CREATE POLICY scoped_insert ON app.leave_types FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('site_settings.manage')));
 GRANT SELECT,INSERT ON app.leave_types TO hr_runtime;
 CREATE INDEX leave_types_scope ON app.leave_types(organization_id,site_id);
 CREATE POLICY scoped_update ON app.leave_types FOR UPDATE USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('site_settings.manage'))) WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('site_settings.manage')));
 GRANT UPDATE ON app.leave_types TO hr_runtime;
 CREATE TABLE app.leave_requests (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), employee_id uuid NOT NULL, user_id uuid NOT NULL, client_id uuid NOT NULL, type_id uuid NOT NULL, starts_on date NOT NULL, ends_on date NOT NULL CHECK(ends_on>=starts_on), half text NOT NULL CHECK(half IN ('full','am','pm')), units numeric(8,1) NOT NULL CHECK(units>0), reason text NOT NULL, status text NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','approved','rejected')), approver_id uuid NOT NULL, reviewer_id uuid, decision_note text, version integer NOT NULL DEFAULT 1, UNIQUE(organization_id,user_id,client_id),
 UNIQUE(organization_id,id), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id)
 );
 ALTER TABLE app.leave_requests ENABLE ROW LEVEL SECURITY;
 CREATE POLICY scoped_read ON app.leave_requests FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('my_leave.view',employee_id) OR app.allowed('leave.view',employee_id)));
 CREATE POLICY scoped_insert ON app.leave_requests FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (user_id=app.actor_id() AND app.allowed('my_leave.submit',employee_id) OR app.allowed('leave.approve',employee_id)));
 GRANT SELECT,INSERT ON app.leave_requests TO hr_runtime;
 CREATE INDEX leave_requests_scope ON app.leave_requests(organization_id,site_id);
 CREATE POLICY scoped_update ON app.leave_requests FOR UPDATE USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (user_id=app.actor_id() AND app.allowed('my_leave.submit',employee_id) OR app.allowed('leave.approve',employee_id))) WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (user_id=app.actor_id() AND app.allowed('my_leave.submit',employee_id) OR app.allowed('leave.approve',employee_id)));
 GRANT UPDATE ON app.leave_requests TO hr_runtime;
 ALTER TABLE app.leave_requests ADD FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id);
CREATE TABLE app.leave_ledger (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), employee_id uuid NOT NULL, type_id uuid NOT NULL, request_id uuid, units numeric(8,1) NOT NULL CHECK(units<>0), reason text NOT NULL, author_id uuid NOT NULL, effective_on date NOT NULL, UNIQUE(organization_id,request_id),
 UNIQUE(organization_id,id), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id)
 );
 ALTER TABLE app.leave_ledger ENABLE ROW LEVEL SECURITY;
 CREATE POLICY scoped_read ON app.leave_ledger FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('my_leave.view',employee_id) OR app.allowed('leave.view',employee_id)));
 CREATE POLICY scoped_insert ON app.leave_ledger FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('leave.approve',employee_id)));
 GRANT SELECT,INSERT ON app.leave_ledger TO hr_runtime;
 CREATE INDEX leave_ledger_scope ON app.leave_ledger(organization_id,site_id);
 ALTER TABLE app.leave_ledger ADD FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id);
CREATE TABLE app.work_tasks (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), employee_id uuid NOT NULL, assignee_id uuid NOT NULL, author_id uuid NOT NULL, client_id uuid NOT NULL, title text NOT NULL, description text NOT NULL DEFAULT '', deadline timestamptz NOT NULL, priority text NOT NULL CHECK(priority IN ('low','normal','high','urgent')), status text NOT NULL DEFAULT 'todo' CHECK(status IN ('todo','in_progress','blocked','done')), version integer NOT NULL DEFAULT 1, UNIQUE(organization_id,author_id,client_id),
 UNIQUE(organization_id,id), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id)
 );
 ALTER TABLE app.work_tasks ENABLE ROW LEVEL SECURITY;
 CREATE POLICY scoped_read ON app.work_tasks FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('tasks.view',employee_id)));
 CREATE POLICY scoped_insert ON app.work_tasks FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('tasks.create',employee_id) OR assignee_id=app.actor_id() AND app.allowed('tasks.submit',employee_id)));
 GRANT SELECT,INSERT ON app.work_tasks TO hr_runtime;
 CREATE INDEX work_tasks_scope ON app.work_tasks(organization_id,site_id);
 CREATE POLICY scoped_update ON app.work_tasks FOR UPDATE USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('tasks.create',employee_id) OR assignee_id=app.actor_id() AND app.allowed('tasks.submit',employee_id))) WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('tasks.create',employee_id) OR assignee_id=app.actor_id() AND app.allowed('tasks.submit',employee_id)));
 GRANT UPDATE ON app.work_tasks TO hr_runtime;
 ALTER TABLE app.work_tasks ADD FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id);
CREATE TABLE app.task_comments (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), employee_id uuid NOT NULL, task_id uuid NOT NULL, author_id uuid NOT NULL, client_id uuid NOT NULL, body text NOT NULL, attachment_id uuid, UNIQUE(organization_id,author_id,client_id),
 UNIQUE(organization_id,id), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id)
 );
 ALTER TABLE app.task_comments ENABLE ROW LEVEL SECURITY;
 CREATE POLICY scoped_read ON app.task_comments FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('tasks.view',employee_id)));
 CREATE POLICY scoped_insert ON app.task_comments FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('tasks.view',employee_id) AND author_id=app.actor_id() AND (app.allowed('tasks.edit',employee_id) OR app.allowed('tasks.submit',employee_id))));
 GRANT SELECT,INSERT ON app.task_comments TO hr_runtime;
 CREATE INDEX task_comments_scope ON app.task_comments(organization_id,site_id);
 ALTER TABLE app.task_comments ADD FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id);
CREATE TABLE app.inbox_items (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), user_id uuid NOT NULL, module text NOT NULL, entity_id uuid NOT NULL, event_type text NOT NULL, read_at timestamptz, push_status text NOT NULL DEFAULT 'unconfigured' CHECK(push_status IN ('unconfigured','pending','delivered','failed')), UNIQUE(organization_id,user_id,entity_id,event_type),
 UNIQUE(organization_id,id), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id)
 );
 ALTER TABLE app.inbox_items ENABLE ROW LEVEL SECURITY;
 CREATE POLICY scoped_read ON app.inbox_items FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (user_id=app.actor_id()));
 CREATE POLICY scoped_insert ON app.inbox_items FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (user_id=app.actor_id()));
 GRANT SELECT,INSERT ON app.inbox_items TO hr_runtime;
 CREATE INDEX inbox_items_scope ON app.inbox_items(organization_id,site_id);
 CREATE POLICY scoped_update ON app.inbox_items FOR UPDATE USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (user_id=app.actor_id())) WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (user_id=app.actor_id()));
 GRANT UPDATE ON app.inbox_items TO hr_runtime;
 CREATE TABLE app.push_devices (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), user_id uuid NOT NULL, token_ciphertext text NOT NULL, platform text NOT NULL, active boolean NOT NULL DEFAULT true, UNIQUE(organization_id,user_id,token_ciphertext),
 UNIQUE(organization_id,id), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id)
 );
 ALTER TABLE app.push_devices ENABLE ROW LEVEL SECURITY;
 CREATE POLICY scoped_read ON app.push_devices FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (user_id=app.actor_id()));
 CREATE POLICY scoped_insert ON app.push_devices FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (user_id=app.actor_id()));
 GRANT SELECT,INSERT ON app.push_devices TO hr_runtime;
 CREATE INDEX push_devices_scope ON app.push_devices(organization_id,site_id);
 CREATE POLICY scoped_update ON app.push_devices FOR UPDATE USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (user_id=app.actor_id())) WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (user_id=app.actor_id()));
 GRANT UPDATE ON app.push_devices TO hr_runtime;
 ALTER TABLE app.duty_events ADD FOREIGN KEY(organization_id,duty_id) REFERENCES app.duty_sessions(organization_id,id);
ALTER TABLE app.geofence_observations ADD FOREIGN KEY(organization_id,event_id) REFERENCES app.duty_events(organization_id,id);
ALTER TABLE app.event_verifications ADD FOREIGN KEY(organization_id,event_id) REFERENCES app.duty_events(organization_id,id);
ALTER TABLE app.duty_segments ADD FOREIGN KEY(organization_id,duty_id) REFERENCES app.duty_sessions(organization_id,id);
ALTER TABLE app.attendance_adjustments ADD FOREIGN KEY(organization_id,duty_id) REFERENCES app.duty_sessions(organization_id,id);
ALTER TABLE app.leave_requests ADD FOREIGN KEY(organization_id,type_id) REFERENCES app.leave_types(organization_id,id);
ALTER TABLE app.leave_ledger ADD FOREIGN KEY(organization_id,type_id) REFERENCES app.leave_types(organization_id,id);
ALTER TABLE app.leave_ledger ADD FOREIGN KEY(organization_id,request_id) REFERENCES app.leave_requests(organization_id,id);
ALTER TABLE app.task_comments ADD FOREIGN KEY(organization_id,task_id) REFERENCES app.work_tasks(organization_id,id);
ALTER TABLE app.task_comments ADD FOREIGN KEY(organization_id,attachment_id) REFERENCES app.private_files(organization_id,id);
CREATE INDEX geofence_boundary_gist ON app.geofence_versions USING gist(boundary);
CREATE INDEX observation_point_gist ON app.geofence_observations USING gist(point);
CREATE UNIQUE INDEX one_open_duty ON app.duty_sessions(organization_id,employee_id) WHERE status='open';
CREATE INDEX events_session ON app.duty_events(organization_id,duty_id,sequence);
CREATE FUNCTION app.operation_device(session uuid) RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT COALESCE(device_id,id) FROM auth.sessions WHERE id=session AND organization_id=app.org_id() AND user_id=app.actor_id() AND revoked_at IS NULL AND expires_at>now() $$;
REVOKE ALL ON FUNCTION app.operation_device(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.operation_device(uuid) TO hr_runtime;
-- Notification insertion is bounded to an active recipient in the same scope. Payloads are IDs only.
CREATE FUNCTION app.operation_notify(recipient uuid,mod text,entity uuid,event text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
 BEGIN
 IF NOT app.has_site(app.site_id()) OR mod NOT IN ('attendance','leave','tasks','field_duty') OR NOT EXISTS(SELECT 1 FROM app.site_memberships WHERE organization_id=app.org_id() AND site_id=app.site_id() AND user_id=recipient AND active) THEN RETURN; END IF;
 INSERT INTO app.inbox_items(organization_id,site_id,user_id,module,entity_id,event_type) VALUES(app.org_id(),app.site_id(),recipient,mod,entity,event) ON CONFLICT DO NOTHING;
 INSERT INTO app.outbox(organization_id,site_id,event_type,payload) VALUES(app.org_id(),app.site_id(),'operations.changed',jsonb_build_object('module',mod,'entityId',entity,'recipientId',recipient));
 END $$;
REVOKE ALL ON FUNCTION app.operation_notify(uuid,text,uuid,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.operation_notify(uuid,text,uuid,text) TO hr_runtime;
INSERT INTO app.role_templates(role,key,scope) SELECT r,k,'own' FROM unnest(ARRAY['super_admin','admin','hr','jr_hr','employee','manager','supervisor']) r CROSS JOIN unnest(ARRAY['tasks.view','tasks.submit','field_duty.view','field_duty.create','field_duty.submit']) k ON CONFLICT(role,key) DO NOTHING;
INSERT INTO app.role_templates(role,key,scope) SELECT r,k,'site' FROM unnest(ARRAY['super_admin','admin','hr']) r CROSS JOIN unnest(ARRAY['tasks.view','tasks.create','tasks.edit','tasks.review','tasks.approve','field_duty.view','field_duty.create','field_duty.edit','field_duty.review','field_duty.approve']) k ON CONFLICT(role,key) DO UPDATE SET scope=excluded.scope;
CREATE POLICY task_attachment_read ON app.private_files FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND purpose='task' AND EXISTS(SELECT 1 FROM app.work_tasks t WHERE t.id=parent_id AND app.allowed('tasks.view',t.employee_id)));
