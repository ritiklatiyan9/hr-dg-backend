ALTER TABLE auth.sessions ADD CONSTRAINT sessions_org_id UNIQUE(organization_id,id);
CREATE TABLE app.export_jobs (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL,site_id uuid NOT NULL,user_id uuid NOT NULL,session_id uuid NOT NULL,
 permission_version int NOT NULL,fields text[] NOT NULL,status text NOT NULL DEFAULT 'queued' CHECK(status IN ('queued','ready','denied')),
 created_at timestamptz NOT NULL DEFAULT now(),expires_at timestamptz NOT NULL DEFAULT now()+interval '15 minutes',checked_at timestamptz,
 FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id),FOREIGN KEY(organization_id,user_id) REFERENCES auth.users(organization_id,id),FOREIGN KEY(organization_id,session_id) REFERENCES auth.sessions(organization_id,id));
ALTER TABLE app.export_jobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY export_read ON app.export_jobs FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND user_id=app.actor_id() AND app.has_site(site_id) AND app.allowed('employees.export'));
CREATE FUNCTION app.export_authorized(fields text[]) RETURNS boolean LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE f text; BEGIN
 IF NOT app.has_site(app.site_id()) OR NOT app.allowed('employees.export') THEN RETURN false; END IF;
 FOREACH f IN ARRAY fields LOOP
 IF f NOT IN ('employeeCode','displayName','department','jobTitle','phone','salary','bank','identity') THEN RETURN false; END IF;
 IF f IN ('salary','bank','identity') AND NOT app.allowed('employees.field.'||f) THEN RETURN false; END IF;
 IF f='phone' AND NOT app.allowed('employees.field.contact') THEN RETURN false; END IF;
 IF f IN ('department','jobTitle') AND NOT app.allowed('employees.field.employment') THEN RETURN false; END IF;
 END LOOP;
 RETURN cardinality(fields) BETWEEN 1 AND 8; END $$;
CREATE FUNCTION app.queue_export(session uuid,expected int,fields text[]) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE job uuid; BEGIN
 IF NOT app.export_authorized(fields) OR NOT EXISTS(SELECT 1 FROM auth.sessions s JOIN auth.users u ON (u.organization_id,u.id)=(s.organization_id,s.user_id) WHERE s.organization_id=app.org_id() AND s.user_id=app.actor_id() AND s.id=session AND s.revoked_at IS NULL AND s.expires_at>now() AND s.absolute_expires_at>now() AND u.active AND u.permission_version=expected AND (NOT (u.requires_mfa OR u.mfa_enabled) OR s.mfa_verified)) THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001'; END IF;
 INSERT INTO app.export_jobs(organization_id,site_id,user_id,session_id,permission_version,fields) VALUES(app.org_id(),app.site_id(),app.actor_id(),session,expected,fields) RETURNING id INTO job;
 INSERT INTO app.audit_records(organization_id,site_id,actor_id,action,entity_id,metadata) VALUES(app.org_id(),app.site_id(),app.actor_id(),'export.queued',job,jsonb_build_object('fields',fields));
 RETURN job; END $$;
-- The worker cannot select employee data. It only prepares authorized manifests.
-- File contents are generated under RLS and reauthorized at authenticated download time.
CREATE FUNCTION app.prepare_exports() RETURNS int LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE j record; valid boolean; count int:=0; BEGIN
 FOR j IN SELECT * FROM app.export_jobs WHERE status='queued' ORDER BY created_at LIMIT 10 FOR UPDATE SKIP LOCKED LOOP
 PERFORM set_config('app.organization_id',j.organization_id::text,true),set_config('app.actor_id',j.user_id::text,true),set_config('app.site_id',j.site_id::text,true);
 valid:=j.expires_at>now() AND EXISTS(SELECT 1 FROM auth.sessions s JOIN auth.users u ON (u.organization_id,u.id)=(s.organization_id,s.user_id) WHERE s.id=j.session_id AND s.organization_id=j.organization_id AND s.user_id=j.user_id AND s.revoked_at IS NULL AND s.expires_at>now() AND s.absolute_expires_at>now() AND u.active AND u.permission_version=j.permission_version AND (NOT (u.requires_mfa OR u.mfa_enabled) OR s.mfa_verified)) AND app.export_authorized(j.fields);
 UPDATE app.export_jobs SET status=CASE WHEN valid THEN 'ready' ELSE 'denied' END,checked_at=now() WHERE id=j.id;
 count:=count+1;
 END LOOP; RETURN count; END $$;
CREATE FUNCTION app.organization_report() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE result jsonb; decision jsonb; BEGIN
 decision:=app.decision('reports.view');
 IF NOT app.has_site(app.site_id()) OR NOT (decision->>'allowed')::boolean OR decision->>'scope'<>'organization' THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001'; END IF;
 SELECT COALESCE(jsonb_agg(x ORDER BY x.name),'[]'::jsonb) INTO result FROM (
 SELECT s.id,s.name,s.timezone,(SELECT count(DISTINCT a.employee_id)::int FROM app.site_assignments a WHERE a.organization_id=s.organization_id AND a.site_id=s.id AND a.starts_on<=(now() AT TIME ZONE s.timezone)::date AND (a.ends_on IS NULL OR a.ends_on>=(now() AT TIME ZONE s.timezone)::date)) AS employees FROM app.sites s WHERE s.organization_id=app.org_id()) x;
 RETURN jsonb_build_object('readOnly',true,'sites',result,'rule',decision->>'rule'); END $$;
GRANT SELECT ON app.export_jobs TO hr_runtime;
REVOKE ALL ON FUNCTION app.export_authorized(text[]),app.queue_export(uuid,int,text[]),app.prepare_exports(),app.organization_report() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.export_authorized(text[]),app.queue_export(uuid,int,text[]),app.organization_report() TO hr_runtime;
GRANT EXECUTE ON FUNCTION app.prepare_exports() TO hr_worker;
