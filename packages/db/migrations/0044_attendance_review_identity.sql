-- Record the decision instant and expose only the identities of attendance
-- reviewers whose decisions the current actor may see at the selected site.
ALTER TABLE app.event_verifications ADD COLUMN reviewed_at timestamptz;
ALTER TABLE app.attendance_adjustments ADD COLUMN reviewed_at timestamptz;

CREATE FUNCTION app.attendance_actor_names(users uuid[])
RETURNS TABLE(user_id uuid,name text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT u.id,COALESCE(e.display_name,u.email)
 FROM auth.users u
 LEFT JOIN app.employees e ON e.organization_id=u.organization_id AND e.user_id=u.id
 WHERE u.organization_id=app.org_id() AND u.id=ANY(users[1:1000])
  AND app.has_site(app.site_id())
  AND (
   (u.id=(SELECT (p.rules->>'attendanceApproverId')::uuid
     FROM app.operation_policies p
     WHERE p.organization_id=app.org_id() AND p.site_id=app.site_id()
     ORDER BY p.version DESC LIMIT 1)
    AND (app.allowed('attendance.view') OR app.allowed('attendance.approve')))
   OR EXISTS(
    SELECT 1 FROM app.event_verifications v
    WHERE v.organization_id=app.org_id() AND v.site_id=app.site_id()
     AND v.reviewer_id=u.id
     AND (app.allowed('attendance.view',v.employee_id)
       OR app.allowed('attendance.approve',v.employee_id)))
   OR EXISTS(
    SELECT 1 FROM app.attendance_adjustments a
    WHERE a.organization_id=app.org_id() AND a.site_id=app.site_id()
     AND a.reviewer_id=u.id
     AND (app.allowed('attendance.view',a.employee_id)
       OR app.allowed('attendance.approve',a.employee_id)))
  ) $$;
REVOKE ALL ON FUNCTION app.attendance_actor_names(uuid[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.attendance_actor_names(uuid[]) TO hr_runtime;
