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
 RETURN d || jsonb_build_object('available',m.phase<=4);
 END $$;

UPDATE app.module_catalogue SET fields=ARRAY['provenance'] WHERE id='dwr_review';
CREATE OR REPLACE FUNCTION app.operation_notify(recipient uuid,mod text,entity uuid,event text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
 IF NOT app.has_site(app.site_id()) OR mod NOT IN ('attendance','leave','tasks','field_duty','my_dwr') OR NOT EXISTS(SELECT 1 FROM app.site_memberships WHERE organization_id=app.org_id() AND site_id=app.site_id() AND user_id=recipient AND active) THEN RETURN; END IF;
 INSERT INTO app.inbox_items(organization_id,site_id,user_id,module,entity_id,event_type) VALUES(app.org_id(),app.site_id(),recipient,mod,entity,event) ON CONFLICT DO NOTHING;
 INSERT INTO app.outbox(organization_id,site_id,event_type,payload) VALUES(app.org_id(),app.site_id(),'operations.changed',jsonb_build_object('module',mod,'entityId',entity,'recipientId',recipient));
END $$;
CREATE FUNCTION app.dwr_notify_reviewers(report uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE r record; u record; BEGIN
 SELECT * INTO r FROM app.dwr_reports WHERE id=report AND organization_id=app.org_id() AND site_id=app.site_id() AND user_id=app.actor_id() AND status='submitted';
 IF r.id IS NULL OR NOT app.allowed('my_dwr.submit',r.employee_id) THEN RETURN; END IF;
 FOR u IN SELECT user_id FROM app.site_memberships WHERE organization_id=app.org_id() AND site_id=app.site_id() AND active AND user_id<>app.actor_id()
 AND (app.policy_decision(user_id,app.site_id(),'dwr_review.review',r.employee_id)->>'allowed')::boolean LOOP
 PERFORM app.operation_notify(u.user_id,'my_dwr',report,'dwr.submitted.v'||r.version);
 END LOOP;
END $$;
REVOKE ALL ON FUNCTION app.dwr_notify_reviewers(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.dwr_notify_reviewers(uuid) TO hr_runtime;
CREATE FUNCTION app.dwr_tick() RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE r record; BEGIN
 FOR r IN SELECT ds.organization_id,ds.site_id,e.user_id,e.id employee_id,
 ((now() AT TIME ZONE s.timezone)::date-ds.deadline_day_offset) dt
 FROM app.dwr_settings ds JOIN app.sites s ON s.id=ds.site_id AND s.organization_id=ds.organization_id
 JOIN app.site_assignments a ON a.organization_id=ds.organization_id AND a.site_id=ds.site_id
 JOIN app.employees e ON e.organization_id=a.organization_id AND e.id=a.employee_id
 WHERE e.user_id IS NOT NULL AND (now() AT TIME ZONE s.timezone)::date BETWEEN a.starts_on AND COALESCE(a.ends_on,'infinity'::date)
 AND (now() AT TIME ZONE s.timezone)::time >= ds.deadline-(ds.reminder_minutes*interval '1 minute')
 LIMIT 1000 LOOP
 PERFORM set_config('app.organization_id',r.organization_id::text,true),set_config('app.site_id',r.site_id::text,true),set_config('app.actor_id',r.user_id::text,true);
 IF app.has_site(r.site_id) AND app.allowed('my_dwr.submit',r.employee_id)
 AND NOT EXISTS(SELECT 1 FROM app.dwr_reports WHERE organization_id=r.organization_id AND site_id=r.site_id AND employee_id=r.employee_id AND work_date=r.dt AND status IN ('submitted','approved')) THEN
 INSERT INTO app.dwr_reminders VALUES(r.organization_id,r.site_id,r.user_id,r.dt) ON CONFLICT DO NOTHING;
 IF FOUND THEN PERFORM app.operation_notify(r.user_id,'my_dwr',gen_random_uuid(),'dwr.reminder.'||r.dt); END IF;
 END IF;
 END LOOP;
END $$;
CREATE FUNCTION app.dwr_expired_audio() RETURNS TABLE(id uuid,object_key text) LANGUAGE sql SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT id,object_key FROM app.dwr_voice WHERE expires_at<now() AND deleted_at IS NULL AND (lease_until IS NULL OR lease_until<now()) ORDER BY expires_at LIMIT 20 $$;
CREATE FUNCTION app.dwr_audio_deleted(target uuid) RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path=pg_catalog AS $$
 UPDATE app.dwr_voice SET deleted_at=now() WHERE id=target AND expires_at<now() $$;
REVOKE ALL ON FUNCTION app.dwr_tick(),app.dwr_expired_audio(),app.dwr_audio_deleted(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.dwr_tick(),app.dwr_expired_audio(),app.dwr_audio_deleted(uuid) TO hr_worker;

