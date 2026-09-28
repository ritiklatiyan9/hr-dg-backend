-- Attendance reviewers need the site policy and boundary to assess evidence.
-- These settings contain no individual location records. Event RLS is unchanged.
ALTER POLICY scoped_read ON app.operation_policies USING (
 organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id)
 AND (app.allowed('site_settings.view') OR app.allowed('site_settings.manage')
 OR app.allowed('my_attendance.view') OR app.allowed('my_attendance.create')
 OR app.allowed('attendance.view') OR app.allowed('attendance.approve') OR app.allowed('my_leave.view'))
);
ALTER POLICY scoped_read ON app.geofence_versions USING (
 organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id)
 AND (app.allowed('site_settings.view') OR app.allowed('site_settings.manage')
 OR app.allowed('my_attendance.view') OR app.allowed('my_attendance.create')
 OR app.allowed('attendance.view') OR app.allowed('attendance.approve'))
);
