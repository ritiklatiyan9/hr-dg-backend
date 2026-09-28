-- Employee lifecycle on the directory: status per site, app login state and
-- HR-issued credentials, login enable/disable, rehire, and exit revoking login.
CREATE INDEX IF NOT EXISTS auth_events_user ON auth.events(user_id,action);
-- Only plain employee accounts may be managed from the directory. Anyone with a
-- higher role, capability grant, allow override or delegation keeps the
-- email-based invitation/recovery path so HR cannot take over their identity.
-- User ids are globally unique, so this holds outside a site context too.
CREATE FUNCTION app.login_protected(target uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT EXISTS(SELECT 1 FROM app.access_grants WHERE user_id=target AND role IS DISTINCT FROM 'employee')
 OR EXISTS(SELECT 1 FROM app.access_overrides WHERE user_id=target AND effect='allow')
 OR EXISTS(SELECT 1 FROM app.access_delegations WHERE user_id=target) $$;
REVOKE ALL ON FUNCTION app.login_protected(uuid) FROM PUBLIC;
-- active: current assignment here; joining: future assignment here;
-- moved: still employed but not assigned here; former: no open employment.
CREATE FUNCTION app.employee_status(target uuid) RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 WITH d AS (SELECT (now() AT TIME ZONE timezone)::date AS today FROM app.sites WHERE organization_id=app.org_id() AND id=app.site_id())
 SELECT CASE
  WHEN NOT app.field_allowed('employment',target) THEN NULL
  WHEN NOT EXISTS(SELECT 1 FROM app.employment_records r WHERE r.organization_id=app.org_id() AND r.employee_id=target AND COALESCE(r.ends_on,'infinity'::date)>=d.today) THEN 'former'
  WHEN EXISTS(SELECT 1 FROM app.site_assignments a WHERE a.organization_id=app.org_id() AND a.site_id=app.site_id() AND a.employee_id=target AND a.starts_on<=d.today AND COALESCE(a.ends_on,'infinity'::date)>=d.today) THEN 'active'
  WHEN EXISTS(SELECT 1 FROM app.site_assignments a WHERE a.organization_id=app.org_id() AND a.site_id=app.site_id() AND a.employee_id=target AND a.starts_on>d.today) THEN 'joining'
  ELSE 'moved' END FROM d $$;
REVOKE ALL ON FUNCTION app.employee_status(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.employee_status(uuid) TO hr_runtime;
-- Login state without exposing auth tables to the runtime role.
CREATE FUNCTION app.employee_login(target uuid) RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT jsonb_build_object(
  'status',CASE WHEN u.id IS NULL THEN 'none' WHEN NOT u.active THEN 'disabled'
   WHEN EXISTS(SELECT 1 FROM auth.events v WHERE v.user_id=u.id AND v.action IN ('auth.login','auth.invitation_completed','auth.recovery_completed','auth.password_issued')) THEN 'active'
   ELSE 'pending' END,
  'loginId',u.email,
  'lastSignInAt',(SELECT max(v.created_at) FROM auth.events v WHERE v.user_id=u.id AND v.action='auth.login'),
  'devices',(SELECT count(*) FROM auth.devices d WHERE d.organization_id=u.organization_id AND d.user_id=u.id),
  'protected',u.id IS NOT NULL AND app.login_protected(u.id))
 FROM app.employees e LEFT JOIN auth.users u ON (u.organization_id,u.id)=(e.organization_id,e.user_id)
 WHERE e.organization_id=app.org_id() AND e.id=target AND app.has_site(app.site_id())
 AND app.allowed('employees.create',target) AND app.field_allowed('contact',target) $$;
REVOKE ALL ON FUNCTION app.employee_login(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.employee_login(uuid) TO hr_runtime;
-- set_password | disable_login | enable_login | rehire. Maker is HR with
-- edit+approve on the employee; every change revokes sessions and is audited.
CREATE FUNCTION app.employee_lifecycle(operation text,payload jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE target uuid:=(payload->>'employeeId')::uuid; e record; u record; dt date; v int; employed boolean;
BEGIN
 IF NOT app.has_site(app.site_id()) OR NOT app.allowed('employees.edit',target) OR NOT app.allowed('employees.approve',target) OR NOT app.field_allowed('contact',target) OR NOT app.field_allowed('employment',target) THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001'; END IF;
 SELECT * INTO e FROM app.employees WHERE organization_id=app.org_id() AND id=target FOR UPDATE;
 IF e.id IS NULL THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0001'; END IF;
 IF e.version<>(payload->>'expectedVersion')::int THEN RAISE EXCEPTION 'CONFLICT' USING ERRCODE='P0001'; END IF;
 IF e.user_id IS NULL THEN RAISE EXCEPTION 'NO_LOGIN' USING ERRCODE='P0001'; END IF;
 IF e.user_id=app.actor_id() THEN RAISE EXCEPTION 'SELF_ESCALATION' USING ERRCODE='P0001'; END IF;
 IF app.login_protected(e.user_id) THEN RAISE EXCEPTION 'PROTECTED_ACCOUNT' USING ERRCODE='P0001'; END IF;
 SELECT * INTO u FROM auth.users WHERE organization_id=app.org_id() AND id=e.user_id FOR UPDATE;
 SELECT (now() AT TIME ZONE timezone)::date INTO dt FROM app.sites WHERE organization_id=app.org_id() AND id=app.site_id();
 employed:=EXISTS(SELECT 1 FROM app.employment_records WHERE organization_id=app.org_id() AND employee_id=target AND COALESCE(ends_on,'infinity'::date)>=dt);
 IF operation='set_password' THEN
  IF NOT employed THEN RAISE EXCEPTION 'EMPLOYEE_EXITED' USING ERRCODE='P0001'; END IF;
  IF length(payload->>'passwordHash')<20 THEN RAISE EXCEPTION 'BAD_INPUT' USING ERRCODE='P0001'; END IF;
  UPDATE auth.users SET password_hash=payload->>'passwordHash',active=true WHERE id=u.id;
  UPDATE auth.action_tokens SET used_at=now() WHERE user_id=u.id AND used_at IS NULL;
 ELSIF operation='enable_login' THEN
  IF NOT employed THEN RAISE EXCEPTION 'EMPLOYEE_EXITED' USING ERRCODE='P0001'; END IF;
  UPDATE auth.users SET active=true WHERE id=u.id;
 ELSIF operation='disable_login' THEN
  UPDATE auth.users SET active=false WHERE id=u.id;
 ELSIF operation='rehire' THEN
  IF employed THEN RAISE EXCEPTION 'CONFLICT' USING ERRCODE='P0001'; END IF;
  IF (payload->>'startsOn')::date<=(SELECT max(ends_on) FROM app.employment_records WHERE organization_id=app.org_id() AND employee_id=target) THEN RAISE EXCEPTION 'ASSIGNMENT_OVERLAP' USING ERRCODE='P0001'; END IF;
  IF NOT EXISTS(SELECT 1 FROM app.legal_employers WHERE organization_id=app.org_id() AND id=(payload->>'legalEmployerId')::uuid) THEN RAISE EXCEPTION 'BAD_INPUT' USING ERRCODE='P0001'; END IF;
  INSERT INTO app.employment_records(organization_id,employee_id,legal_employer_id,starts_on) VALUES(app.org_id(),target,(payload->>'legalEmployerId')::uuid,(payload->>'startsOn')::date);
  INSERT INTO app.site_assignments(organization_id,site_id,employee_id,starts_on) VALUES(app.org_id(),app.site_id(),target,(payload->>'startsOn')::date);
  IF NOT EXISTS(SELECT 1 FROM app.access_grants WHERE organization_id=app.org_id() AND site_id=app.site_id() AND user_id=u.id AND role='employee') THEN
   INSERT INTO app.access_grants(organization_id,site_id,user_id,role) VALUES(app.org_id(),app.site_id(),u.id,'employee');
  END IF;
  UPDATE auth.users SET active=true WHERE id=u.id;
 ELSE RAISE EXCEPTION 'BAD_INPUT' USING ERRCODE='P0001';
 END IF;
 UPDATE auth.sessions SET revoked_at=now() WHERE user_id=u.id AND revoked_at IS NULL;
 INSERT INTO auth.events(organization_id,user_id,action) VALUES(app.org_id(),u.id,'auth.'||CASE operation WHEN 'set_password' THEN 'password_issued' WHEN 'disable_login' THEN 'login_disabled' ELSE 'login_enabled' END);
 UPDATE app.employees SET version=version+1,updated_at=now() WHERE id=target RETURNING version INTO v;
 INSERT INTO app.audit_records(organization_id,site_id,actor_id,action,entity_id,metadata) VALUES(app.org_id(),app.site_id(),app.actor_id(),'employee.'||operation,target,jsonb_build_object('fields',ARRAY(SELECT jsonb_object_keys(payload-'passwordHash')),'version',v));
 INSERT INTO app.outbox(organization_id,site_id,event_type,payload) VALUES(app.org_id(),app.site_id(),'foundation.updated',jsonb_build_object('entityId',target,'operation',operation));
 RETURN jsonb_build_object('id',target,'version',v);
END $$;
REVOKE ALL ON FUNCTION app.employee_lifecycle(text,jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.employee_lifecycle(text,jsonb) TO hr_runtime;
-- An approved exit that has taken effect ends app access with the employment.
-- ponytail: future-dated exits are not revisited on their date; the directory
-- flags "Exited · login active" for a one-click disable. Add a worker sweep if needed.
CREATE FUNCTION app.exit_revokes_login() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE uid uuid; dt date;
BEGIN
 SELECT (now() AT TIME ZONE timezone)::date INTO dt FROM app.sites WHERE organization_id=NEW.organization_id AND id=app.site_id();
 IF NEW.ends_on IS NULL OR NEW.ends_on>COALESCE(dt,(now() AT TIME ZONE 'UTC')::date) THEN RETURN NEW; END IF;
 IF EXISTS(SELECT 1 FROM app.employment_records WHERE organization_id=NEW.organization_id AND employee_id=NEW.employee_id AND id<>NEW.id AND COALESCE(ends_on,'infinity'::date)>=COALESCE(dt,NEW.ends_on)) THEN RETURN NEW; END IF;
 SELECT user_id INTO uid FROM app.employees WHERE organization_id=NEW.organization_id AND id=NEW.employee_id;
 IF uid IS NULL OR app.login_protected(uid) THEN RETURN NEW; END IF;
 UPDATE auth.users SET active=false WHERE organization_id=NEW.organization_id AND id=uid AND active;
 IF FOUND THEN
  UPDATE auth.sessions SET revoked_at=now() WHERE user_id=uid AND revoked_at IS NULL;
  INSERT INTO auth.events(organization_id,user_id,action) VALUES(NEW.organization_id,uid,'auth.login_disabled');
 END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION app.exit_revokes_login() FROM PUBLIC;
CREATE TRIGGER exit_revokes_login AFTER UPDATE OF ends_on ON app.employment_records FOR EACH ROW WHEN (NEW.ends_on IS DISTINCT FROM OLD.ends_on) EXECUTE FUNCTION app.exit_revokes_login();
