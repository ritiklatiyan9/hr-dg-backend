-- Bounded handler selection; attendance/leave approver lookup remains restricted.
CREATE FUNCTION app.hr_handler_allowed(target uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT app.has_site(app.site_id()) AND app.allowed('grievances.manage') AND app.allowed('grievances.field.confidential')
 AND COALESCE((app.policy_decision(target,app.site_id(),'grievances.review')->>'allowed')::boolean,false)
 AND app.policy_decision(target,app.site_id(),'grievances.review')->>'scope'='site'
 AND COALESCE((app.policy_decision(target,app.site_id(),'grievances.field.confidential')->>'allowed')::boolean,false)
 AND app.policy_decision(target,app.site_id(),'grievances.field.confidential')->>'scope'='site' $$;
REVOKE ALL ON FUNCTION app.hr_handler_allowed(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.hr_handler_allowed(uuid) TO hr_runtime;
