-- Only expose the bounded approver check, not general internal policy evaluation.
CREATE FUNCTION app.operation_approver_allowed(target uuid,permission text) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT app.has_site(app.site_id()) AND (app.allowed('site_settings.manage') OR app.allowed('attendance.review') OR app.allowed('leave.review')) AND permission IN ('attendance.approve','leave.approve') AND COALESCE((app.policy_decision(target,app.site_id(),permission)->>'allowed')::boolean,false) $$;
REVOKE ALL ON FUNCTION app.operation_approver_allowed(uuid,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.operation_approver_allowed(uuid,text) TO hr_runtime;
-- PostGIS types/functions live in public. USAGE conveys no table ownership or data grants.
GRANT USAGE ON SCHEMA public TO hr_runtime;
