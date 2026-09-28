-- Recheck inbox permission as well as parent access immediately before delivery.
CREATE OR REPLACE FUNCTION app.pending_operation_push() RETURNS TABLE(inbox_id uuid,site uuid,module text,token_ciphertext text) LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE n record; BEGIN
 FOR n IN SELECT i.* FROM app.inbox_items i WHERE i.push_status IN ('unconfigured','pending','failed') AND i.push_attempts<5 ORDER BY i.created_at LIMIT 10 FOR UPDATE SKIP LOCKED LOOP
 PERFORM set_config('app.organization_id',n.organization_id::text,true),set_config('app.actor_id',n.user_id::text,true),set_config('app.site_id',n.site_id::text,true);
 IF app.has_site(n.site_id) AND app.allowed('inbox.view') AND (CASE
 WHEN n.event_type LIKE 'hr.%' THEN app.hr_visible(n.entity_id)
 WHEN n.module='my_payroll' THEN app.payroll_visible(n.entity_id)
 WHEN n.module='dwr_review' THEN app.dwr_visible(n.entity_id)
 WHEN n.module='my_dwr' THEN app.dwr_visible(n.entity_id) OR (n.event_type LIKE 'dwr.reminder.%' AND app.allowed('my_dwr.submit'))
 ELSE app.allowed(CASE WHEN n.module='attendance' THEN 'my_attendance.view' WHEN n.module='leave' THEN 'my_leave.view' ELSE n.module||'.view' END) OR app.allowed(n.module||'.view') END) THEN
 RETURN QUERY SELECT n.id,n.site_id,n.module,d.token_ciphertext FROM app.push_devices d WHERE d.organization_id=n.organization_id AND d.site_id=n.site_id AND d.user_id=n.user_id AND d.active LIMIT 1;
 END IF;
 END LOOP; END $$;

