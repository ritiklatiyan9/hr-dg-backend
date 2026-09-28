-- Visible push notifications. The worker needs the event type and entity to
-- write a generic, content-free title and to deep-link on tap. A device
-- belongs to its user, not to the site that registered it, so every active
-- device of the recipient receives pushes from any site the recipient can
-- still open; authorization is re-checked per item exactly as before.
DROP FUNCTION app.pending_operation_push();
DROP FUNCTION app.authorized_operation_push(uuid);
CREATE FUNCTION app.authorized_operation_push(target uuid)
 RETURNS TABLE(inbox_id uuid,site uuid,module text,event_type text,entity_id uuid,device_id uuid,token_ciphertext text)
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE n record;BEGIN
 SELECT * INTO n FROM app.inbox_items WHERE id=target AND push_status<>'delivered' AND push_attempts<5;
 IF NOT FOUND THEN RETURN;END IF;
 PERFORM set_config('app.organization_id',n.organization_id::text,true),set_config('app.actor_id',n.user_id::text,true),set_config('app.site_id',n.site_id::text,true);
 IF app.has_site(n.site_id) AND app.allowed('inbox.view') AND (CASE
 WHEN n.event_type LIKE 'hr.%' THEN app.hr_visible(n.entity_id)
 WHEN n.module='my_payroll' THEN app.payroll_visible(n.entity_id)
 WHEN n.module IN ('dwr_review','my_dwr') THEN app.dwr_visible(n.entity_id) OR (n.module='my_dwr' AND n.event_type LIKE 'dwr.reminder.%' AND app.allowed('my_dwr.submit')) OR (n.event_type='dwr.group.added' AND app.dwr_member_role(n.entity_id) IS NOT NULL)
 ELSE app.allowed(CASE WHEN n.module='attendance' THEN 'my_attendance.view' WHEN n.module='leave' THEN 'my_leave.view' ELSE n.module||'.view' END) OR app.allowed(n.module||'.view') END) THEN
  RETURN QUERY SELECT n.id,n.site_id,n.module,n.event_type,n.entity_id,d.id,d.token_ciphertext FROM app.push_devices d
   WHERE d.organization_id=n.organization_id AND d.user_id=n.user_id AND d.active ORDER BY d.created_at DESC LIMIT 5;
 END IF;
END $$;
-- Only recent items, and only items raised around or after a device
-- registered: enabling push never replays an old inbox as a burst.
CREATE FUNCTION app.pending_operation_push()
 RETURNS TABLE(inbox_id uuid,site uuid,module text,event_type text,entity_id uuid,device_id uuid,token_ciphertext text)
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE n record;BEGIN
 FOR n IN SELECT i.id FROM app.inbox_items i
  WHERE i.push_status IN ('unconfigured','pending','failed') AND i.push_attempts<5 AND i.push_next_attempt_at<=now()
   AND i.created_at>now()-interval '2 days'
   AND EXISTS(SELECT 1 FROM app.push_devices d WHERE d.organization_id=i.organization_id AND d.user_id=i.user_id AND d.active AND d.created_at<=i.created_at+interval '10 minutes')
  ORDER BY i.push_next_attempt_at,i.created_at LIMIT 20 FOR UPDATE SKIP LOCKED LOOP
  UPDATE app.inbox_items SET push_next_attempt_at=now()+interval '5 minutes' WHERE id=n.id;
  RETURN QUERY SELECT * FROM app.authorized_operation_push(n.id);
 END LOOP;
END $$;
-- FCM reported the token as unregistered/invalid: stop using it.
CREATE FUNCTION app.retire_push_device(device uuid) RETURNS void
 LANGUAGE sql SECURITY DEFINER SET search_path=pg_catalog AS $$
 UPDATE app.push_devices SET active=false WHERE id=device $$;
CREATE INDEX inbox_push_recent ON app.inbox_items(created_at)
 WHERE push_status IN ('unconfigured','pending','failed') AND push_attempts<5;
CREATE INDEX push_devices_user ON app.push_devices(organization_id,user_id) WHERE active;
REVOKE ALL ON FUNCTION app.authorized_operation_push(uuid),app.pending_operation_push(),app.retire_push_device(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.authorized_operation_push(uuid),app.pending_operation_push(),app.retire_push_device(uuid) TO hr_worker;
