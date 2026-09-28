-- Tighten contextual scope semantics, session rechecks, protected accounts and self-escalation.
CREATE OR REPLACE FUNCTION app.policy_decision(target uuid,selected uuid,permission text,record_id uuid DEFAULT NULL,proposed jsonb DEFAULT NULL) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE d jsonb; dep jsonb; m record; needed text; dt date;
 BEGIN
 d:=app.policy_rule(target,selected,permission,proposed);
 IF NOT (d->>'allowed')::boolean THEN RETURN d; END IF;
 SELECT mc.*,pc.action INTO m FROM app.permission_catalogue pc JOIN app.module_catalogue mc ON mc.id=pc.module_id WHERE pc.key=permission;
 IF (left(m.id,3)='my_' AND d->>'scope'<>'own') OR (m.id IN ('access','organization','site_settings','audit') AND d->>'scope'<>'site') OR (m.id='employees' AND m.action='create' AND d->>'scope'<>'site') THEN
 RETURN jsonb_build_object('allowed',false,'scope',d->>'scope','rule','invalid_module_scope'); END IF;
 IF m.action<>'view' THEN
 dep:=app.policy_rule(target,selected,m.id||'.view',proposed);
 IF NOT (dep->>'allowed')::boolean OR app.scope_rank(dep->>'scope')<app.scope_rank(d->>'scope') THEN RETURN jsonb_build_object('allowed',false,'scope',d->>'scope','rule','dependency:'||m.id||'.view'); END IF;
 END IF;
 FOREACH needed IN ARRAY m.dependencies LOOP
 dep:=app.policy_rule(target,selected,needed,proposed);
 IF NOT (dep->>'allowed')::boolean THEN RETURN jsonb_build_object('allowed',false,'scope',d->>'scope','rule','dependency:'||needed); END IF;
 END LOOP;
 IF d->>'scope'='organization' AND (m.id NOT IN ('reports','analytics') OR m.action NOT IN ('view','export') OR d->>'rule'<>'user_site_allow') THEN
 RETURN jsonb_build_object('allowed',false,'scope','organization','rule','organization_reporting_only'); END IF;
 IF record_id IS NOT NULL THEN
 SELECT (now() AT TIME ZONE timezone)::date INTO dt FROM app.sites WHERE id=selected AND organization_id=app.org_id();
 IF NOT EXISTS(SELECT 1 FROM app.site_assignments WHERE organization_id=app.org_id() AND site_id=selected AND employee_id=record_id AND ((m.id='employees' AND d->>'scope'='site') OR (starts_on<=dt AND (ends_on IS NULL OR ends_on>=dt)))) THEN
 RETURN jsonb_build_object('allowed',false,'scope',d->>'scope','rule','record_outside_site'); END IF;
 IF d->>'scope'='own' AND NOT EXISTS(SELECT 1 FROM app.employees WHERE organization_id=app.org_id() AND id=record_id AND user_id=target) THEN RETURN jsonb_build_object('allowed',false,'scope','own','rule','record_not_own'); END IF;
 IF d->>'scope'='team' AND NOT EXISTS(SELECT 1 FROM app.team_assignments WHERE organization_id=app.org_id() AND site_id=selected AND manager_id=target AND employee_id=record_id AND ((m.id='employees' AND d->>'scope'='site') OR (starts_on<=dt AND (ends_on IS NULL OR ends_on>=dt)))) THEN RETURN jsonb_build_object('allowed',false,'scope','team','rule','record_outside_team'); END IF;
 END IF;
 RETURN d || jsonb_build_object('available',m.phase<=2);
 END $$;
CREATE OR REPLACE FUNCTION app.access_snapshot(target uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE result jsonb; BEGIN
 SELECT jsonb_build_object('id',u.id,'email',u.email,'name',COALESCE(e.display_name,u.email),'version',u.permission_version,
 'protected',EXISTS(SELECT 1 FROM app.access_grants protected_role WHERE protected_role.organization_id=app.org_id() AND protected_role.user_id=u.id AND protected_role.role='super_admin'),'active',COALESCE(sm.active,false),
 'role',COALESCE((SELECT g.role FROM app.access_grants g WHERE g.organization_id=app.org_id() AND g.user_id=target AND g.site_id=app.site_id() AND g.role IS NOT NULL ORDER BY CASE g.role WHEN 'super_admin' THEN 0 WHEN 'admin' THEN 1 WHEN 'hr' THEN 2 WHEN 'jr_hr' THEN 3 ELSE 4 END LIMIT 1),'employee'),
 'sites',COALESCE((SELECT jsonb_agg(jsonb_build_object('id',s.id,'name',s.name,'active',ms.active) ORDER BY s.name) FROM app.site_memberships ms JOIN app.sites s ON (s.organization_id,s.id)=(ms.organization_id,ms.site_id) WHERE ms.organization_id=app.org_id() AND ms.user_id=target AND (app.is_super_admin(app.actor_id()) OR app.has_site(s.id))),'[]'::jsonb),
 'rules',COALESCE((SELECT jsonb_agg(jsonb_build_object('key',key,'effect',effect,'scope',scope) ORDER BY key) FROM app.access_overrides WHERE organization_id=app.org_id() AND user_id=target AND site_id=app.site_id()),'[]'::jsonb),
 'delegations',COALESCE((SELECT jsonb_agg(jsonb_build_object('key',key,'scope',scope) ORDER BY key) FROM app.access_delegations WHERE organization_id=app.org_id() AND user_id=target AND site_id=app.site_id()),'[]'::jsonb)) INTO result
 FROM auth.users u LEFT JOIN app.employees e ON (e.organization_id,e.user_id)=(u.organization_id,u.id) LEFT JOIN app.site_memberships sm ON (sm.organization_id,sm.user_id,sm.site_id)=(u.organization_id,u.id,app.site_id()) WHERE u.organization_id=app.org_id() AND u.id=target;
 RETURN result; END $$;
CREATE OR REPLACE FUNCTION app.access_admin(operation text,target uuid DEFAULT NULL,payload jsonb DEFAULT '{}'::jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE result jsonb; before_state jsonb; after_state jsonb; changes jsonb:='[]'::jsonb; d_before jsonb; d_after jsonb; own_rule jsonb; bound_scope text;
 k record; item jsonb; v int; super boolean; now_version int; reason text; remains boolean;
 BEGIN
 IF NOT app.has_site(app.site_id()) OR NOT app.allowed('access.view') THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001'; END IF;
 super:=app.is_super_admin(app.actor_id());
 IF operation='users' THEN
 SELECT COALESCE(jsonb_agg(x),'[]'::jsonb) INTO result FROM (
 SELECT u.id,u.email,COALESCE(e.display_name,u.email) AS name,u.permission_version AS version,EXISTS(SELECT 1 FROM app.access_grants protected_role WHERE protected_role.organization_id=app.org_id() AND protected_role.user_id=u.id AND protected_role.role='super_admin') AS protected,
 COALESCE(sm.active,false) AS active FROM auth.users u LEFT JOIN app.employees e ON (e.organization_id,e.user_id)=(u.organization_id,u.id)
 LEFT JOIN app.site_memberships sm ON (sm.organization_id,sm.user_id,sm.site_id)=(u.organization_id,u.id,app.site_id())
 WHERE u.organization_id=app.org_id() AND (super OR sm.user_id IS NOT NULL) AND (COALESCE(e.display_name,'') ILIKE '%'||left(COALESCE(payload->>'search',''),100)||'%' OR u.email ILIKE '%'||left(COALESCE(payload->>'search',''),100)||'%') ORDER BY COALESCE(e.display_name,u.email) LIMIT 100) x;
 RETURN jsonb_build_object('users',result,'isSuperAdmin',super,'canManage',app.allowed('access.manage'));
 END IF;
 before_state:=app.access_snapshot(target);
 IF before_state IS NULL OR (NOT super AND NOT EXISTS(SELECT 1 FROM app.site_memberships WHERE organization_id=app.org_id() AND site_id=app.site_id() AND user_id=target)) THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0001'; END IF;
 IF operation='get' THEN
 SELECT COALESCE(jsonb_agg(jsonb_build_object('key',p.key,'decision',app.policy_decision(target,app.site_id(),p.key)) ORDER BY p.key),'[]') INTO result FROM app.permission_catalogue p;
 RETURN before_state||jsonb_build_object('effective',result,'audit',COALESCE((SELECT jsonb_agg(x) FROM (SELECT id,action,created_at AS "createdAt",metadata,actor_id AS "actorId" FROM app.audit_records WHERE organization_id=app.org_id() AND site_id=app.site_id() AND entity_id=target AND action='access.updated' ORDER BY created_at DESC LIMIT 30) x),'[]'::jsonb));
 END IF;
 IF operation NOT IN ('preview','save') OR NOT app.allowed('access.manage') THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001'; END IF;
 -- Serialize all administrator changes before locking the target. No stale read can overwrite another edit.
 PERFORM 1 FROM app.organizations WHERE id=app.org_id() FOR UPDATE;
 SELECT permission_version INTO v FROM auth.users WHERE organization_id=app.org_id() AND id=target FOR UPDATE;
 IF v<>(payload->>'expectedVersion')::int THEN RAISE EXCEPTION 'CONFLICT' USING ERRCODE='P0001'; END IF;
 before_state:=app.access_snapshot(target);
 IF target=app.actor_id() AND NOT super THEN RAISE EXCEPTION 'SELF_ESCALATION' USING ERRCODE='P0001'; END IF;
 IF NOT super AND ((before_state->>'protected')::boolean OR payload->>'role'='super_admin') THEN RAISE EXCEPTION 'PROTECTED_ACCOUNT' USING ERRCODE='P0001'; END IF;
 IF payload->>'role' NOT IN ('super_admin','admin','hr','jr_hr','employee','manager','supervisor') OR jsonb_typeof(payload->'active')<>'boolean' OR jsonb_typeof(payload->'rules')<>'array' OR jsonb_typeof(payload->'delegations')<>'array' THEN RAISE EXCEPTION 'BAD_INPUT' USING ERRCODE='P0001'; END IF;
 IF jsonb_array_length(payload->'rules')>250 OR jsonb_array_length(payload->'delegations')>250 THEN RAISE EXCEPTION 'BAD_INPUT' USING ERRCODE='P0001'; END IF;
 IF (SELECT count(*) FROM jsonb_array_elements(payload->'rules'))<>(SELECT count(DISTINCT value->>'key') FROM jsonb_array_elements(payload->'rules')) OR (SELECT count(*) FROM jsonb_array_elements(payload->'delegations'))<>(SELECT count(DISTINCT value->>'key') FROM jsonb_array_elements(payload->'delegations')) THEN RAISE EXCEPTION 'BAD_INPUT' USING ERRCODE='P0001'; END IF;
 FOR item IN SELECT value FROM jsonb_array_elements(payload->'rules') LOOP
 IF NOT EXISTS(SELECT 1 FROM app.permission_catalogue WHERE key=item->>'key') OR item->>'effect' NOT IN ('allow','deny','inherit') OR item->>'scope' NOT IN ('own','team','site','organization') OR (item->>'scope'='organization' AND item->>'key' NOT IN ('reports.view','reports.export','analytics.view','analytics.export')) THEN RAISE EXCEPTION 'BAD_INPUT' USING ERRCODE='P0001'; END IF;
 END LOOP;
 FOR item IN SELECT value FROM jsonb_array_elements(payload->'delegations') LOOP
 IF NOT EXISTS(SELECT 1 FROM app.permission_catalogue WHERE key=item->>'key') OR item->>'scope' NOT IN ('own','team','site') THEN RAISE EXCEPTION 'BAD_INPUT' USING ERRCODE='P0001'; END IF;
 END LOOP;
 IF NOT super AND EXISTS(SELECT 1 FROM ((SELECT value->>'key' AS key,value->>'scope' AS scope FROM jsonb_array_elements(payload->'delegations') EXCEPT SELECT key,scope FROM app.access_delegations WHERE organization_id=app.org_id() AND user_id=target AND site_id=app.site_id()) UNION ALL (SELECT key,scope FROM app.access_delegations WHERE organization_id=app.org_id() AND user_id=target AND site_id=app.site_id() EXCEPT SELECT value->>'key',value->>'scope' FROM jsonb_array_elements(payload->'delegations'))) diff) THEN RAISE EXCEPTION 'DELEGATION_LIMIT' USING ERRCODE='P0001'; END IF;
 FOR k IN SELECT key FROM app.permission_catalogue ORDER BY key LOOP
 d_before:=app.policy_decision(target,app.site_id(),k.key);
 d_after:=app.policy_decision(target,app.site_id(),k.key,NULL,payload);
 IF target=app.actor_id() AND (d_after->>'allowed')::boolean AND (NOT (d_before->>'allowed')::boolean OR app.scope_rank(d_after->>'scope')>app.scope_rank(d_before->>'scope')) THEN RAISE EXCEPTION 'SELF_ESCALATION' USING ERRCODE='P0001'; END IF;
 IF target=app.actor_id() AND EXISTS(SELECT 1 FROM jsonb_array_elements(payload->'rules') x WHERE x->>'key'=k.key AND x->>'effect'='allow' AND (NOT (app.policy_rule(target,app.site_id(),k.key)->>'allowed')::boolean OR app.scope_rank(x->>'scope')>app.scope_rank(app.policy_rule(target,app.site_id(),k.key)->>'scope'))) THEN RAISE EXCEPTION 'SELF_ESCALATION' USING ERRCODE='P0001'; END IF;

 -- Compare underlying allows as well as effective results: a disabled module or dependency
 -- must not let an Admin plant an undelegated grant that becomes effective later.
 IF NOT super AND (app.policy_rule(target,app.site_id(),k.key) IS DISTINCT FROM app.policy_rule(target,app.site_id(),k.key,payload)) THEN
 own_rule:=app.policy_decision(app.actor_id(),app.site_id(),k.key);
 SELECT scope INTO bound_scope FROM app.access_delegations WHERE organization_id=app.org_id() AND site_id=app.site_id() AND user_id=app.actor_id() AND key=k.key;
 IF bound_scope IS NULL OR NOT (own_rule->>'allowed')::boolean OR k.key LIKE 'access.%' OR app.scope_rank(COALESCE((app.policy_rule(target,app.site_id(),k.key,payload)->>'scope'),'site'))>LEAST(app.scope_rank(bound_scope),app.scope_rank(own_rule->>'scope')) THEN RAISE EXCEPTION 'DELEGATION_LIMIT' USING ERRCODE='P0001'; END IF;
 END IF;
 IF d_before IS DISTINCT FROM d_after THEN changes:=changes||jsonb_build_array(jsonb_build_object('key',k.key,'before',d_before,'after',d_after)); END IF;
 END LOOP;
 -- Raw role/rule differences are separately bounded, even when module_disabled masks both results.
 IF NOT super THEN
 FOR k IN SELECT pc.key,COALESCE(x.scope,t.scope) AS scope FROM app.permission_catalogue pc
 LEFT JOIN LATERAL (SELECT value->>'scope' AS scope FROM jsonb_array_elements(payload->'rules') WHERE value->>'key'=pc.key AND value->>'effect'='allow') x ON true
 LEFT JOIN app.role_templates t ON t.key=pc.key AND t.role=payload->>'role'
 WHERE (x.scope IS NOT NULL OR t.scope IS NOT NULL) AND NOT EXISTS(SELECT 1 FROM app.access_overrides o WHERE o.organization_id=app.org_id() AND o.user_id=target AND o.site_id=app.site_id() AND o.key=pc.key AND o.effect='allow' AND o.scope=COALESCE(x.scope,t.scope)) AND NOT EXISTS(SELECT 1 FROM app.access_grants g JOIN app.role_templates rt ON rt.role=g.role AND rt.key=pc.key WHERE g.organization_id=app.org_id() AND g.user_id=target AND g.site_id=app.site_id() AND rt.scope=COALESCE(x.scope,t.scope)) LOOP
 SELECT scope INTO bound_scope FROM app.access_delegations WHERE organization_id=app.org_id() AND site_id=app.site_id() AND user_id=app.actor_id() AND key=k.key;
 IF bound_scope IS NULL OR k.key LIKE 'access.%' OR app.scope_rank(k.scope)>app.scope_rank(bound_scope) OR NOT app.allowed(k.key) THEN RAISE EXCEPTION 'DELEGATION_LIMIT' USING ERRCODE='P0001'; END IF;
 END LOOP;
 END IF;
 -- Recoverable means active, password credential present, and a working Super Admin
 -- access-management path at at least one site (MFA enrollment/verification still mandatory).
 IF (before_state->>'protected')::boolean THEN
 remains:=false;
 FOR k IN SELECT DISTINCT u.id,g.site_id FROM auth.users u JOIN app.organization_memberships om ON (om.organization_id,om.user_id)=(u.organization_id,u.id)
 JOIN app.access_grants g ON (g.organization_id,g.user_id)=(u.organization_id,u.id) WHERE u.organization_id=app.org_id() AND u.active AND om.active AND length(u.password_hash)>0 AND g.role='super_admin' LOOP
 IF k.id=target AND k.site_id=app.site_id() THEN
 IF payload->>'role'='super_admin' AND (app.policy_decision(target,k.site_id,'access.manage',NULL,payload)->>'allowed')::boolean THEN remains:=true; END IF;
 ELSIF (app.policy_decision(k.id,k.site_id,'access.manage')->>'allowed')::boolean THEN remains:=true;
 END IF;
 END LOOP;
 IF NOT remains THEN RAISE EXCEPTION 'LAST_SUPER_ADMIN' USING ERRCODE='P0001'; END IF;
 END IF;
 IF operation='preview' THEN RETURN jsonb_build_object('changes',changes,'version',v,'before',before_state,'after',payload); END IF;
 reason:=trim(COALESCE(payload->>'reason',''));
 IF length(reason)<8 OR length(reason)>500 THEN RAISE EXCEPTION 'REASON_REQUIRED' USING ERRCODE='P0001'; END IF;
 INSERT INTO app.site_memberships(organization_id,site_id,user_id,active) VALUES(app.org_id(),app.site_id(),target,(payload->>'active')::boolean) ON CONFLICT(organization_id,site_id,user_id) DO UPDATE SET active=EXCLUDED.active;
 DELETE FROM app.access_grants WHERE organization_id=app.org_id() AND site_id=app.site_id() AND user_id=target;
 INSERT INTO app.access_grants(organization_id,site_id,user_id,role) VALUES(app.org_id(),app.site_id(),target,payload->>'role');
 DELETE FROM app.access_overrides WHERE organization_id=app.org_id() AND site_id=app.site_id() AND user_id=target;
 INSERT INTO app.access_overrides SELECT app.org_id(),app.site_id(),target,value->>'key',value->>'effect',value->>'scope' FROM jsonb_array_elements(payload->'rules') WHERE value->>'effect'<>'inherit';
 DELETE FROM app.access_delegations WHERE organization_id=app.org_id() AND site_id=app.site_id() AND user_id=target;
 INSERT INTO app.access_delegations SELECT app.org_id(),app.site_id(),target,value->>'key',value->>'scope' FROM jsonb_array_elements(payload->'delegations');
 UPDATE auth.users SET permission_version=permission_version+1,requires_mfa=requires_mfa OR payload->>'role' IN ('super_admin','admin','hr','jr_hr') OR EXISTS(SELECT 1 FROM jsonb_array_elements(payload->'rules') WHERE value->>'effect'='allow' AND value->>'key' NOT LIKE 'my_%') WHERE organization_id=app.org_id() AND id=target RETURNING permission_version INTO now_version;
 -- Every permission edit invalidates all existing sessions for the target, including queued exports.
 UPDATE auth.sessions SET revoked_at=COALESCE(revoked_at,now()) WHERE organization_id=app.org_id() AND user_id=target;
 after_state:=app.access_snapshot(target);
 INSERT INTO app.audit_records(organization_id,site_id,actor_id,action,entity_id,metadata) VALUES(app.org_id(),app.site_id(),app.actor_id(),'access.updated',target,jsonb_build_object('reason',reason,'before',before_state-'email'-'name'-'sites','after',after_state-'email'-'name'-'sites','changes',changes,'version',now_version));
 INSERT INTO app.outbox(organization_id,site_id,event_type,payload) VALUES(app.org_id(),app.site_id(),'access.updated',jsonb_build_object('userId',target,'version',now_version));
 RETURN jsonb_build_object('version',now_version,'changes',changes);
 END $$;
CREATE FUNCTION app.check_request(session uuid,expected int) RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$ BEGIN
 IF NOT app.check_access_version(expected) THEN RETURN false; END IF;
 RETURN EXISTS(SELECT 1 FROM auth.sessions s JOIN auth.users u ON (u.organization_id,u.id)=(s.organization_id,s.user_id) WHERE s.id=session AND s.organization_id=app.org_id() AND s.user_id=app.actor_id() AND s.revoked_at IS NULL AND s.expires_at>now() AND s.absolute_expires_at>now() AND (NOT(u.requires_mfa OR u.mfa_enabled) OR s.mfa_verified));
 END $$;
REVOKE ALL ON FUNCTION app.check_request(uuid,int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.check_request(uuid,int) TO hr_runtime;
-- Avoid PL/pgSQL variable/column shadowing in the request workflow.
CREATE OR REPLACE FUNCTION app.employee_foundation(operation text,payload jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE target uuid; result jsonb; r record; v int; dt date; new_id uuid; created_user uuid; has_approval boolean; item_id uuid; k text;
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
 created_user:=gen_random_uuid(); new_id:=gen_random_uuid();
 INSERT INTO auth.users(id,organization_id,email,password_hash) VALUES(created_user,app.org_id(),lower(payload->>'workEmail'),payload->>'passwordHash');
 INSERT INTO app.employees(id,organization_id,user_id,employee_code,display_name,work_email,phone,job_title,department) VALUES(new_id,app.org_id(),created_user,payload->>'employeeCode',payload->>'displayName',lower(payload->>'workEmail'),COALESCE(payload->>'phone',''),payload->>'designation',payload->>'department');
 INSERT INTO app.employment_records(organization_id,employee_id,legal_employer_id,starts_on) VALUES(app.org_id(),new_id,(payload->>'legalEmployerId')::uuid,(payload->>'startsOn')::date);
 INSERT INTO app.site_assignments(organization_id,site_id,employee_id,starts_on) VALUES(app.org_id(),app.site_id(),new_id,(payload->>'startsOn')::date);
 INSERT INTO app.access_grants(organization_id,site_id,user_id,role) VALUES(app.org_id(),app.site_id(),created_user,'employee');
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
 INSERT INTO app.site_preferences(organization_id,site_id) VALUES(app.org_id(),app.site_id()) ON CONFLICT DO NOTHING;
 UPDATE app.site_preferences SET version=version+1 WHERE organization_id=app.org_id() AND site_id=app.site_id() AND version=(payload->>'expectedVersion')::int RETURNING version INTO v;
 IF v IS NULL THEN RAISE EXCEPTION 'CONFLICT' USING ERRCODE='P0001'; END IF;
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
