CREATE TABLE app.site_reference_items (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL,site_id uuid NOT NULL,
 kind text NOT NULL CHECK(kind IN ('department','designation','shift','holiday')),name text NOT NULL CHECK(length(name) BETWEEN 1 AND 100),
 details jsonb NOT NULL DEFAULT '{}'::jsonb,active boolean NOT NULL DEFAULT true,version int NOT NULL DEFAULT 1,
 UNIQUE(organization_id,site_id,id),UNIQUE(organization_id,site_id,kind,name),FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id));
CREATE TABLE app.site_preferences (
 organization_id uuid NOT NULL,site_id uuid NOT NULL,week_start int NOT NULL DEFAULT 1 CHECK(week_start BETWEEN 0 AND 6),contact_email text NOT NULL DEFAULT '',version int NOT NULL DEFAULT 1,
 PRIMARY KEY(organization_id,site_id),FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id));
CREATE TABLE app.employee_site_details (
 organization_id uuid NOT NULL,site_id uuid NOT NULL,employee_id uuid NOT NULL,shift_id uuid,
 PRIMARY KEY(organization_id,site_id,employee_id),FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id),FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id),FOREIGN KEY(organization_id,site_id,shift_id) REFERENCES app.site_reference_items(organization_id,site_id,id));
CREATE TABLE app.employee_sensitive_fields (
 organization_id uuid NOT NULL,employee_id uuid NOT NULL,field text NOT NULL CHECK(field IN ('salary','bank','identity')),value text NOT NULL,
 PRIMARY KEY(organization_id,employee_id,field),FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id));
CREATE TABLE app.profile_requests (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL,site_id uuid NOT NULL,employee_id uuid NOT NULL,requester_id uuid NOT NULL,
 phone text NOT NULL CHECK(length(phone)<=25),reason text NOT NULL CHECK(length(reason) BETWEEN 8 AND 500),status text NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','approved','rejected')),
 employee_version int NOT NULL,version int NOT NULL DEFAULT 1,created_at timestamptz NOT NULL DEFAULT now(),reviewed_at timestamptz,reviewer_id uuid,review_note text,
 FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id),FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id),FOREIGN KEY(organization_id,requester_id) REFERENCES auth.users(organization_id,id),FOREIGN KEY(organization_id,reviewer_id) REFERENCES auth.users(organization_id,id));
CREATE UNIQUE INDEX one_pending_profile_request ON app.profile_requests(organization_id,site_id,employee_id) WHERE status='pending';
CREATE TABLE app.employee_drafts (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL,site_id uuid NOT NULL,author_id uuid NOT NULL,
 details jsonb NOT NULL,status text NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','approved')),version int NOT NULL DEFAULT 1,created_at timestamptz NOT NULL DEFAULT now(),
 FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id),FOREIGN KEY(organization_id,author_id) REFERENCES auth.users(organization_id,id));
CREATE FUNCTION app.field_allowed(field_name text,employee uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT app.visible_employee(employee) AND (app.allowed('employees.field.'||field_name,employee) OR (field_name IN ('contact','employment') AND app.allowed('my_hr.field.'||field_name,employee))) $$;
ALTER TABLE app.site_reference_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.site_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.employee_site_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.employee_sensitive_fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.profile_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.employee_drafts ENABLE ROW LEVEL SECURITY;
CREATE POLICY reference_read ON app.site_reference_items FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND (app.allowed('site_settings.view') OR app.allowed('my_hr.view')));
CREATE POLICY preferences_read ON app.site_preferences FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id));
CREATE POLICY employee_details_read ON app.employee_site_details FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.field_allowed('employment',employee_id));
CREATE POLICY sensitive_read ON app.employee_sensitive_fields FOR SELECT USING(organization_id=app.org_id() AND app.field_allowed(field,employee_id));
CREATE POLICY requests_read ON app.profile_requests FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND ((requester_id=app.actor_id() AND app.allowed('my_hr.view',employee_id)) OR (app.allowed('employees.review',employee_id) AND app.field_allowed('contact',employee_id))));
CREATE POLICY drafts_read ON app.employee_drafts FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.allowed('employees.create') AND (author_id=app.actor_id() OR app.allowed('employees.approve')));
GRANT SELECT ON app.site_reference_items,app.site_preferences,app.employee_site_details,app.employee_sensitive_fields,app.profile_requests,app.employee_drafts TO hr_runtime;
-- Retire direct self-edit policy: every employee contact change is now a request.
DROP POLICY IF EXISTS employees_update ON app.employees;
DO $$ DECLARE p record; BEGIN FOR p IN SELECT policyname FROM pg_policies WHERE schemaname='app' AND tablename='employees' AND cmd='UPDATE' LOOP EXECUTE format('DROP POLICY %I ON app.employees',p.policyname); END LOOP; END $$;
CREATE POLICY employee_admin_update ON app.employees FOR UPDATE USING(organization_id=app.org_id() AND app.allowed('employees.edit',id) AND app.allowed('employees.approve',id) AND app.field_allowed('contact',id)) WITH CHECK(organization_id=app.org_id() AND app.visible_employee(id));
CREATE FUNCTION app.employee_foundation(operation text,payload jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE target uuid; result jsonb; r record; v int; dt date; new_id uuid; user_id uuid; has_approval boolean; item_id uuid; k text;
 BEGIN
 IF NOT app.has_site(app.site_id()) THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001'; END IF;
 SELECT (now() AT TIME ZONE timezone)::date INTO dt FROM app.sites WHERE organization_id=app.org_id() AND id=app.site_id();
 IF operation='request_profile' THEN
 SELECT * INTO r FROM app.employees WHERE organization_id=app.org_id() AND user_id=app.actor_id();
 IF r.id IS NULL OR NOT app.allowed('my_hr.submit',r.id) OR NOT app.field_allowed('contact',r.id) THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001'; END IF;
 IF r.version<>(payload->>'expectedVersion')::int THEN RAISE EXCEPTION 'CONFLICT' USING ERRCODE='P0001'; END IF;
 IF EXISTS(SELECT 1 FROM app.profile_requests WHERE organization_id=app.org_id() AND site_id=app.site_id() AND employee_id=r.id AND status='pending') THEN RAISE EXCEPTION 'REQUEST_PENDING' USING ERRCODE='P0001'; END IF;
 INSERT INTO app.profile_requests(organization_id,site_id,employee_id,requester_id,phone,reason,employee_version) VALUES(app.org_id(),app.site_id(),r.id,app.actor_id(),payload->>'phone',payload->>'reason',r.version) RETURNING id INTO new_id;
 result:=jsonb_build_object('id',new_id,'status','pending');target:=r.id;
 ELSIF operation='review_profile' THEN
 SELECT * INTO r FROM app.profile_requests WHERE organization_id=app.org_id() AND site_id=app.site_id() AND id=(payload->>'id')::uuid FOR UPDATE;
 IF r.id IS NULL THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0001'; END IF;
 IF r.requester_id=app.actor_id() OR NOT app.allowed('employees.approve',r.employee_id) OR NOT app.field_allowed('contact',r.employee_id) THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001'; END IF;
 IF r.version<>(payload->>'expectedVersion')::int OR r.status<>'pending' THEN RAISE EXCEPTION 'CONFLICT' USING ERRCODE='P0001'; END IF;
 IF (payload->>'approve')::boolean THEN
 UPDATE app.employees SET phone=r.phone,version=version+1,updated_at=now() WHERE organization_id=app.org_id() AND id=r.employee_id AND version=r.employee_version;
 IF NOT FOUND THEN RAISE EXCEPTION 'CONFLICT' USING ERRCODE='P0001'; END IF;
 END IF;
 UPDATE app.profile_requests SET status=CASE WHEN (payload->>'approve')::boolean THEN 'approved' ELSE 'rejected' END,version=version+1,reviewed_at=now(),reviewer_id=app.actor_id(),review_note=payload->>'note' WHERE id=r.id;
 result:=jsonb_build_object('id',r.id);target:=r.employee_id;
 ELSIF operation IN ('create_employee','approve_draft') THEN
 IF NOT app.allowed('employees.create') THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001'; END IF;
 has_approval:=app.allowed('employees.approve');
 IF operation='approve_draft' THEN
 IF NOT has_approval THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001'; END IF;
 SELECT * INTO r FROM app.employee_drafts WHERE organization_id=app.org_id() AND site_id=app.site_id() AND id=(payload->>'draftId')::uuid FOR UPDATE;
 IF r.id IS NULL OR r.status<>'draft' OR r.version<>(payload->>'expectedVersion')::int THEN RAISE EXCEPTION 'CONFLICT' USING ERRCODE='P0001'; END IF;
 IF r.author_id=app.actor_id() THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001'; END IF;
 payload:=r.details||jsonb_build_object('passwordHash',payload->>'passwordHash');
 UPDATE app.employee_drafts SET status='approved',version=version+1 WHERE id=r.id;
 END IF;
 IF NOT has_approval THEN
 INSERT INTO app.employee_drafts(organization_id,site_id,author_id,details) VALUES(app.org_id(),app.site_id(),app.actor_id(),payload-'passwordHash') RETURNING id INTO new_id;
 result:=jsonb_build_object('id',new_id,'status','draft');target:=new_id;
 ELSE
 IF NOT EXISTS(SELECT 1 FROM app.legal_employers WHERE organization_id=app.org_id() AND id=(payload->>'legalEmployerId')::uuid) THEN RAISE EXCEPTION 'BAD_INPUT' USING ERRCODE='P0001'; END IF;
 IF EXISTS(SELECT 1 FROM auth.users WHERE organization_id=app.org_id() AND email=lower(payload->>'workEmail')) THEN RAISE EXCEPTION 'DUPLICATE_EMPLOYEE' USING ERRCODE='P0001'; END IF;
 user_id:=gen_random_uuid(); new_id:=gen_random_uuid();
 INSERT INTO auth.users(id,organization_id,email,password_hash) VALUES(user_id,app.org_id(),lower(payload->>'workEmail'),payload->>'passwordHash');
 INSERT INTO app.employees(id,organization_id,user_id,employee_code,display_name,work_email,phone,job_title,department) VALUES(new_id,app.org_id(),user_id,payload->>'employeeCode',payload->>'displayName',lower(payload->>'workEmail'),COALESCE(payload->>'phone',''),payload->>'designation',payload->>'department');
 INSERT INTO app.employment_records(organization_id,employee_id,legal_employer_id,starts_on) VALUES(app.org_id(),new_id,(payload->>'legalEmployerId')::uuid,(payload->>'startsOn')::date);
 INSERT INTO app.site_assignments(organization_id,site_id,employee_id,starts_on) VALUES(app.org_id(),app.site_id(),new_id,(payload->>'startsOn')::date);
 INSERT INTO app.access_grants(organization_id,site_id,user_id,role) VALUES(app.org_id(),app.site_id(),user_id,'employee');
 result:=jsonb_build_object('id',new_id,'status','created');target:=new_id;
 END IF;
 ELSIF operation='edit_employee' THEN
 target:=(payload->>'employeeId')::uuid;
 IF NOT app.allowed('employees.edit',target) OR NOT app.allowed('employees.approve',target) OR NOT app.field_allowed('employment',target) THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001'; END IF;
 UPDATE app.employees SET display_name=payload->>'displayName',department=payload->>'department',job_title=payload->>'designation',version=version+1,updated_at=now() WHERE organization_id=app.org_id() AND id=target AND version=(payload->>'expectedVersion')::int RETURNING version INTO v;
 IF v IS NULL THEN RAISE EXCEPTION 'CONFLICT' USING ERRCODE='P0001'; END IF;
 result:=jsonb_build_object('id',target,'version',v);
 ELSIF operation IN ('assign_site','end_assignment','assign_team','assign_shift') THEN
 target:=(payload->>'employeeId')::uuid;
 -- New site assignments require the employee to be visible at a separately validated source site.
 IF operation='assign_site' THEN
 IF NOT app.allowed('employees.approve') OR NOT app.allowed('employees.edit') OR NOT app.has_site((payload->>'sourceSiteId')::uuid) OR NOT (app.policy_decision(app.actor_id(),(payload->>'sourceSiteId')::uuid,'employees.edit',target)->>'allowed')::boolean THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001'; END IF;
 ELSE
 IF NOT app.allowed('employees.edit',target) OR NOT app.allowed('employees.approve',target) OR NOT app.field_allowed('employment',target) THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001'; END IF;
 END IF;
 SELECT * INTO r FROM app.employees WHERE organization_id=app.org_id() AND id=target FOR UPDATE;
 IF r.id IS NULL THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0001'; END IF;
 IF r.version<>(payload->>'expectedVersion')::int THEN RAISE EXCEPTION 'CONFLICT' USING ERRCODE='P0001'; END IF;
 IF operation='assign_site' THEN
 IF EXISTS(SELECT 1 FROM app.site_assignments WHERE organization_id=app.org_id() AND site_id=app.site_id() AND employee_id=target AND (ends_on IS NULL OR ends_on>=(payload->>'startsOn')::date)) THEN RAISE EXCEPTION 'ASSIGNMENT_OVERLAP' USING ERRCODE='P0001'; END IF;
 INSERT INTO app.site_assignments(organization_id,site_id,employee_id,starts_on) VALUES(app.org_id(),app.site_id(),target,(payload->>'startsOn')::date);
 IF r.user_id IS NOT NULL THEN INSERT INTO app.access_grants(organization_id,site_id,user_id,role) VALUES(app.org_id(),app.site_id(),r.user_id,'employee'); END IF;
 ELSIF operation='end_assignment' THEN
 UPDATE app.site_assignments SET ends_on=(payload->>'endsOn')::date WHERE organization_id=app.org_id() AND site_id=app.site_id() AND employee_id=target AND id=(payload->>'assignmentId')::uuid AND ends_on IS NULL AND starts_on<=(payload->>'endsOn')::date;
 IF NOT FOUND THEN RAISE EXCEPTION 'CONFLICT' USING ERRCODE='P0001'; END IF;
 ELSIF operation='assign_team' THEN
 IF (payload->>'managerId')::uuid=r.user_id OR NOT EXISTS(SELECT 1 FROM app.site_memberships WHERE organization_id=app.org_id() AND site_id=app.site_id() AND user_id=(payload->>'managerId')::uuid AND active) THEN RAISE EXCEPTION 'BAD_INPUT' USING ERRCODE='P0001'; END IF;
 IF EXISTS(SELECT 1 FROM app.team_assignments WHERE organization_id=app.org_id() AND site_id=app.site_id() AND employee_id=target AND starts_on>=(payload->>'startsOn')::date) THEN RAISE EXCEPTION 'ASSIGNMENT_OVERLAP' USING ERRCODE='P0001'; END IF;
 -- Prevent reporting cycles through all currently open reporting links.
 IF EXISTS(WITH RECURSIVE chain(employee_id,user_id) AS (
 SELECT e.id,e.user_id FROM app.employees e WHERE e.organization_id=app.org_id() AND e.user_id=(payload->>'managerId')::uuid
 UNION SELECT e.id,e.user_id FROM chain ch JOIN app.team_assignments t ON t.employee_id=ch.employee_id AND t.organization_id=app.org_id() AND t.site_id=app.site_id() AND t.ends_on IS NULL JOIN app.employees e ON e.user_id=t.manager_id AND e.organization_id=app.org_id()) SELECT 1 FROM chain WHERE employee_id=target) THEN RAISE EXCEPTION 'REPORTING_CYCLE' USING ERRCODE='P0001'; END IF;
 UPDATE app.team_assignments SET ends_on=(payload->>'startsOn')::date-1 WHERE organization_id=app.org_id() AND site_id=app.site_id() AND employee_id=target AND ends_on IS NULL;
 INSERT INTO app.team_assignments(organization_id,site_id,employee_id,manager_id,starts_on) VALUES(app.org_id(),app.site_id(),target,(payload->>'managerId')::uuid,(payload->>'startsOn')::date);
 ELSIF operation='assign_shift' THEN
 IF NOT EXISTS(SELECT 1 FROM app.site_reference_items WHERE organization_id=app.org_id() AND site_id=app.site_id() AND id=(payload->>'shiftId')::uuid AND kind='shift' AND active) THEN RAISE EXCEPTION 'BAD_INPUT' USING ERRCODE='P0001'; END IF;
 INSERT INTO app.employee_site_details(organization_id,site_id,employee_id,shift_id) VALUES(app.org_id(),app.site_id(),target,(payload->>'shiftId')::uuid) ON CONFLICT(organization_id,site_id,employee_id) DO UPDATE SET shift_id=EXCLUDED.shift_id;
 END IF;
 UPDATE app.employees SET version=version+1,updated_at=now() WHERE organization_id=app.org_id() AND id=target RETURNING version INTO v;
 result:=jsonb_build_object('id',target,'version',v);
 ELSIF operation IN ('reference','site_settings','module') THEN
 IF NOT app.allowed('site_settings.manage') THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001'; END IF;
 IF operation='reference' THEN
 item_id:=COALESCE((payload->>'id')::uuid,gen_random_uuid());
 IF payload->>'id' IS NULL THEN
 INSERT INTO app.site_reference_items(id,organization_id,site_id,kind,name,details) VALUES(item_id,app.org_id(),app.site_id(),payload->>'kind',payload->>'name',payload->'details');
 ELSE
 UPDATE app.site_reference_items SET name=payload->>'name',details=payload->'details',active=(payload->>'active')::boolean,version=version+1 WHERE organization_id=app.org_id() AND site_id=app.site_id() AND id=item_id AND kind=payload->>'kind' AND version=(payload->>'expectedVersion')::int;
 IF NOT FOUND THEN RAISE EXCEPTION 'CONFLICT' USING ERRCODE='P0001'; END IF;
 END IF;
 result:=jsonb_build_object('id',item_id);target:=item_id;
 ELSIF operation='site_settings' THEN
 INSERT INTO app.site_preferences(organization_id,site_id) VALUES(app.org_id(),app.site_id()) ON CONFLICT DO NOTHING;
 UPDATE app.site_preferences SET week_start=(payload->>'weekStart')::int,contact_email=payload->>'contactEmail',version=version+1 WHERE organization_id=app.org_id() AND site_id=app.site_id() AND version=(payload->>'expectedVersion')::int RETURNING version INTO v;
 IF v IS NULL THEN RAISE EXCEPTION 'CONFLICT' USING ERRCODE='P0001'; END IF;
 UPDATE app.sites SET name=payload->>'name',timezone=payload->>'timezone' WHERE organization_id=app.org_id() AND id=app.site_id();
 result:=jsonb_build_object('version',v);target:=app.site_id();
 ELSE
 -- Module switches can alter every user's effective permissions; only Super Admin may change them.
 IF NOT app.is_super_admin(app.actor_id()) OR payload->>'moduleId' IN ('access','my_hr') THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001'; END IF;
 INSERT INTO app.site_modules(organization_id,site_id,module_id,enabled) VALUES(app.org_id(),app.site_id(),payload->>'moduleId',(payload->>'enabled')::boolean) ON CONFLICT(organization_id,site_id,module_id) DO UPDATE SET enabled=EXCLUDED.enabled;
 result:=jsonb_build_object('id',app.site_id());target:=app.site_id();
 END IF;
 ELSIF operation='organization' THEN
 IF NOT app.allowed('organization.manage') OR NOT app.is_super_admin(app.actor_id()) THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001'; END IF;
 UPDATE app.organizations SET name=payload->>'name' WHERE id=app.org_id();result:=jsonb_build_object('id',app.org_id());target:=app.org_id();
 ELSE RAISE EXCEPTION 'BAD_INPUT' USING ERRCODE='P0001';
 END IF;
 INSERT INTO app.audit_records(organization_id,site_id,actor_id,action,entity_id,metadata) VALUES(app.org_id(),app.site_id(),app.actor_id(),'foundation.'||operation,target,jsonb_build_object('fields',ARRAY(SELECT jsonb_object_keys(payload-'passwordHash')),'version',v));
 INSERT INTO app.outbox(organization_id,site_id,event_type,payload) VALUES(app.org_id(),app.site_id(),'foundation.updated',jsonb_build_object('entityId',target,'operation',operation));
 RETURN result;
 END $$;
REVOKE ALL ON FUNCTION app.field_allowed(text,uuid),app.employee_foundation(text,jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.field_allowed(text,uuid),app.employee_foundation(text,jsonb) TO hr_runtime;
