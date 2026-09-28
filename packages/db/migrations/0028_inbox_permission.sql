DROP POLICY scoped_read ON app.inbox_items;
CREATE POLICY scoped_read ON app.inbox_items FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND user_id=app.actor_id() AND app.has_site(site_id) AND app.allowed('inbox.view') AND CASE WHEN event_type LIKE 'hr.%' THEN app.hr_visible(entity_id) WHEN module='my_payroll' THEN app.payroll_visible(entity_id) ELSE true END);
