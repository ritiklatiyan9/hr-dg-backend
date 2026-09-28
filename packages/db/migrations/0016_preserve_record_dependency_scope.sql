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
 RETURN d || jsonb_build_object('available',m.phase<=3);
 END $$;
