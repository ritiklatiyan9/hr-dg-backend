-- Use the row values for INSERT RETURNING; a STABLE lookup cannot see a row inserted in the same statement.
DROP POLICY dwr_read ON app.dwr_reports;
CREATE POLICY dwr_read ON app.dwr_reports FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND
 ((user_id=app.actor_id() AND app.allowed('my_dwr.view',employee_id)) OR (status<>'draft' AND app.allowed('dwr_review.view',employee_id))));
DROP POLICY dwr_update ON app.dwr_reports;
CREATE POLICY dwr_update ON app.dwr_reports FOR UPDATE USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND
 ((user_id=app.actor_id() AND (app.allowed('my_dwr.edit',employee_id) OR app.allowed('my_dwr.submit',employee_id)))
 OR (user_id<>app.actor_id() AND status<>'draft' AND (app.allowed('dwr_review.review',employee_id) OR app.allowed('dwr_review.approve',employee_id)))));
