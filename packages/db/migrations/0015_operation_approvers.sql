-- Configuration can select authorized approvers without conferring permission administration.
CREATE FUNCTION app.operation_approvers() RETURNS TABLE(id uuid,name text) LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT u.id,COALESCE(e.display_name,u.email) FROM auth.users u
 JOIN app.site_memberships sm ON sm.organization_id=u.organization_id AND sm.user_id=u.id AND sm.site_id=app.site_id() AND sm.active
 LEFT JOIN app.employees e ON e.organization_id=u.organization_id AND e.user_id=u.id
 WHERE u.organization_id=app.org_id() AND app.allowed('site_settings.manage')
 AND ((app.policy_decision(u.id,app.site_id(),'attendance.approve')->>'allowed')::boolean OR (app.policy_decision(u.id,app.site_id(),'leave.approve')->>'allowed')::boolean)
 ORDER BY COALESCE(e.display_name,u.email) LIMIT 100 $$;
REVOKE ALL ON FUNCTION app.operation_approvers() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.operation_approvers() TO hr_runtime;
