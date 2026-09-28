-- Preserve the Phase 2 recursive record-scoped dependency guard when publishing Phase 3 modules.
-- Dependencies are checked against the same record, not only the scope rank.
CREATE OR REPLACE FUNCTION app.policy_decision(target uuid,selected uuid,permission text,record_id uuid DEFAULT NULL,proposed jsonb DEFAULT NULL) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE d jsonb; dep jsonb; m record; needed text; dt date;
 BEGIN
 d:=app.policy_rule(target,selected,permission,proposed);
 IF NOT (d->>'allowed')::boolean THEN RETURN d; END IF;
 SELECT mc.*,pc.action INTO m FROM app.permission_catalogue pc JOIN app.module_catalogue mc ON mc.id=pc.module_id WHERE pc.key=permission;
 IF (left(m.id,3)='my_' AND d->>'scope'<>'own') OR (m.id IN ('access','organization','site_settings','audit') AND d->>'scope'<>'site') OR (m.id='employees' AND m.action='create' AND d->>'scope'<>'site') THEN
 RETURN jsonb_build_object('allowed',false,'scope',d->>'scope','rule','invalid_module_scope'); END IF;
 IF m.action<>'view' THEN
 dep:=app.policy_decision(target,selected,m.id||'.view',record_id,proposed);
 IF NOT (dep->>'allowed')::boolean OR app.scope_rank(dep->>'scope')<app.scope_rank(d->>'scope') THEN RETURN jsonb_build_object('allowed',false,'scope',d->>'scope','rule','dependency:'||m.id||'.view'); END IF;
 END IF;
 FOREACH needed IN ARRAY m.dependencies LOOP
 dep:=app.policy_decision(target,selected,needed,record_id,proposed);
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
 RETURN d || jsonb_build_object('available',m.phase<=5);
 END $$;


CREATE OR REPLACE FUNCTION app.operation_notify(recipient uuid,mod text,entity uuid,event text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
 IF NOT app.has_site(app.site_id()) OR mod NOT IN ('attendance','leave','tasks','field_duty','my_dwr','dwr_review','my_payroll') OR NOT EXISTS(SELECT 1 FROM app.site_memberships WHERE organization_id=app.org_id() AND site_id=app.site_id() AND user_id=recipient AND active) THEN RETURN; END IF;
 INSERT INTO app.inbox_items(organization_id,site_id,user_id,module,entity_id,event_type) VALUES(app.org_id(),app.site_id(),recipient,mod,entity,event) ON CONFLICT DO NOTHING;
 INSERT INTO app.outbox(organization_id,site_id,event_type,payload) VALUES(app.org_id(),app.site_id(),'operations.changed',jsonb_build_object('module',mod,'entityId',entity,'recipientId',recipient));
END $$;

CREATE OR REPLACE FUNCTION app.pending_operation_push() RETURNS TABLE(inbox_id uuid,site uuid,module text,token_ciphertext text) LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE n record; BEGIN
 FOR n IN SELECT i.* FROM app.inbox_items i WHERE i.push_status IN ('unconfigured','pending','failed') AND i.push_attempts<5 ORDER BY i.created_at LIMIT 10 FOR UPDATE SKIP LOCKED LOOP
 PERFORM set_config('app.organization_id',n.organization_id::text,true),set_config('app.actor_id',n.user_id::text,true),set_config('app.site_id',n.site_id::text,true);
 IF app.has_site(n.site_id) AND (CASE
 WHEN n.event_type LIKE 'hr.%' THEN app.hr_visible(n.entity_id)
 WHEN n.module='my_payroll' THEN app.payroll_visible(n.entity_id)
 WHEN n.module='dwr_review' THEN app.dwr_visible(n.entity_id)
 WHEN n.module='my_dwr' THEN app.dwr_visible(n.entity_id) OR (n.event_type LIKE 'dwr.reminder.%' AND app.allowed('my_dwr.submit'))
 ELSE app.allowed(CASE WHEN n.module='attendance' THEN 'my_attendance.view' WHEN n.module='leave' THEN 'my_leave.view' ELSE n.module||'.view' END) OR app.allowed(n.module||'.view') END) THEN
 RETURN QUERY SELECT n.id,n.site_id,n.module,d.token_ciphertext FROM app.push_devices d WHERE d.organization_id=n.organization_id AND d.site_id=n.site_id AND d.user_id=n.user_id AND d.active LIMIT 1;
 END IF;
 END LOOP; END $$;

-- Newly released template capabilities invalidate prior capability caches.
UPDATE auth.users SET permission_version=permission_version+1;
