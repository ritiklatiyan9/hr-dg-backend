-- Approval dashboards filter submission creation time, independently of work date.
-- The measured 116,298-report workload spent seconds filtering this relation.
CREATE INDEX dwr_pending_window ON app.dwr_reports(organization_id,site_id,created_at) WHERE status='submitted';
