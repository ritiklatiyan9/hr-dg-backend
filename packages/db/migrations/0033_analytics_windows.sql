-- Baseline: 129,717 duties / 518,868 segments. Whole-history aggregation hit
-- the 8-second statement limit. Bound candidate windows before revision lookup.
CREATE INDEX duty_segments_window ON app.duty_segments(organization_id,site_id,ends_at,starts_at);
CREATE INDEX duty_segments_latest ON app.duty_segments(organization_id,site_id,duty_id,revision DESC);
CREATE INDEX duty_sessions_window ON app.duty_sessions(organization_id,site_id,opened_at);
CREATE INDEX shift_rosters_window ON app.shift_rosters(organization_id,site_id,work_date,employee_id);
CREATE INDEX dwr_reports_window ON app.dwr_reports(organization_id,site_id,work_date,employee_id);
CREATE INDEX work_tasks_deadline ON app.work_tasks(organization_id,site_id,deadline);
