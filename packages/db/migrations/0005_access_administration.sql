CREATE FUNCTION app.access_snapshot(target uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE result jsonb; BEGIN
 SELECT jsonb_build_object('id',u.id,'email',u.email,'name',COALESCE(e.display_name,u.email),'version',u.permission_version,
 'protected',app.is_super_admin(u.id),'active',COALESCE(sm.active,false),
 'role',COALESCE((SELECT g.role FROM app.access_grants g WHERE g.organization_id=app.org_id() AND g.user_id=target AND g.site_id=app.site_id() AND g.role IS NOT NULL ORDER BY CASE g.role WHEN 'super_admin' THEN 0 WHEN 'admin' THEN 1 WHEN 'hr' THEN 2 WHEN 'jr_hr' THEN 3 ELSE 4 END LIMIT 1),'employee'),
 'sites',COALESCE((SELECT jsonb_agg(jsonb_build_object('id',s.id,'name',s.name,'active',ms.active) ORDER BY s.name) FROM app.site_memberships ms JOIN app.sites s ON (s.organization_id,s.id)=(ms.organization_id,ms.site_id) WHERE ms.organization_id=app.org_id() AND ms.user_id=target AND (app.is_super_admin(app.actor_id()) OR app.has_site(s.id))),'[]'::jsonb),
 'rules',COALESCE((SELECT jsonb_agg(jsonb_build_object('key',key,'effect',effect,'scope',scope) ORDER BY key) FROM app.access_overrides WHERE organization_id=app.org_id() AND user_id=target AND site_id=app.site_id()),'[]'::jsonb),
 'delegations',COALESCE((SELECT jsonb_agg(jsonb_build_object('key',key,'scope',scope) ORDER BY key) FROM app.access_delegations WHERE organization_id=app.org_id() AND user_id=target AND site_id=app.site_id()),'[]'::jsonb)) INTO result
 FROM auth.users u LEFT JOIN app.employees e ON (e.organization_id,e.user_id)=(u.organization_id,u.id) LEFT JOIN app.site_memberships sm ON (sm.organization_id,sm.user_id,sm.site_id)=(u.organization_id,u.id,app.site_id()) WHERE u.organization_id=app.org_id() AND u.id=target;
 RETURN result; END $$;
CREATE FUNCTION app.access_admin(operation text,target uuid DEFAULT NULL,payload jsonb DEFAULT '{}'::jsonb) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE result jsonb; before_state jsonb; after_state jsonb; changes jsonb:='[]'::jsonb; d_before jsonb; d_after jsonb; own_rule jsonb; bound_scope text;
 k record; item jsonb; v int; super boolean; now_version int; reason text; remains boolean;
 BEGIN
 IF NOT app.has_site(app.site_id()) OR NOT app.allowed('access.view') THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001'; END IF;
 super:=app.is_super_admin(app.actor_id());
 IF operation='users' THEN
 SELECT COALESCE(jsonb_agg(x),'[]'::jsonb) INTO result FROM (
 SELECT u.id,u.email,COALESCE(e.display_name,u.email) AS name,u.permission_version AS version,app.is_super_admin(u.id) AS protected,
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
REVOKE ALL ON FUNCTION app.access_snapshot(uuid),app.access_admin(text,uuid,jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.access_admin(text,uuid,jsonb) TO hr_runtime;
