-- Phone liveness is separate from location evidence. A still phone receives no new
-- GPS fixes, yet HR must see that it is connected. One grant row per device and duty
-- window is updated in place (throttled by the API), so heartbeats add no rows.
ALTER TABLE app.tracking_offline_grants
 ADD COLUMN last_seen_at timestamptz,
 ADD COLUMN device_state text CHECK(device_state IN ('tracking','location_off'));
-- Free page space keeps these frequent single-row updates HOT (no index changes).
ALTER TABLE app.tracking_offline_grants SET (fillfactor=80);
GRANT UPDATE(last_seen_at,device_state) ON app.tracking_offline_grants TO hr_runtime;
CREATE POLICY tracking_grant_presence ON app.tracking_offline_grants FOR UPDATE USING(
 organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id)
 AND user_id=app.actor_id() AND app.allowed('my_attendance.create',employee_id));
