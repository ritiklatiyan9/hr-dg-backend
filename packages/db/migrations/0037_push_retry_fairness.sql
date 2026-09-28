-- Missing devices or revoked grants must not starve newer inbox records.
-- A short persisted lease also allows network calls outside a DB transaction.
ALTER TABLE app.inbox_items ADD COLUMN push_next_attempt_at timestamptz NOT NULL DEFAULT now();
CREATE INDEX inbox_push_due ON app.inbox_items(push_next_attempt_at,created_at)
 WHERE push_status IN ('unconfigured','pending','failed') AND push_attempts<5;
CREATE FUNCTION app.authorized_operation_push(target uuid)
 RETURNS TABLE(inbox_id uuid,site uuid,module text,token_ciphertext text)
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE n record;BEGIN
 SELECT * INTO n FROM app.inbox_items WHERE id=target AND push_status<>'delivered' AND push_attempts<5;
 IF NOT FOUND THEN RETURN;END IF;
 PERFORM set_config('app.organization_id',n.organization_id::text,true),set_config('app.actor_id',n.user_id::text,true),set_config('app.site_id',n.site_id::text,true);
 IF app.has_site(n.site_id) AND app.allowed('inbox.view') AND (CASE
 WHEN n.event_type LIKE 'hr.%' THEN app.hr_visible(n.entity_id)
 WHEN n.module='my_payroll' THEN app.payroll_visible(n.entity_id)
 WHEN n.module IN ('dwr_review','my_dwr') THEN app.dwr_visible(n.entity_id) OR (n.module='my_dwr' AND n.event_type LIKE 'dwr.reminder.%' AND app.allowed('my_dwr.submit'))
 ELSE app.allowed(CASE WHEN n.module='attendance' THEN 'my_attendance.view' WHEN n.module='leave' THEN 'my_leave.view' ELSE n.module||'.view' END) OR app.allowed(n.module||'.view') END) THEN
  RETURN QUERY SELECT n.id,n.site_id,n.module,d.token_ciphertext FROM app.push_devices d
   WHERE d.organization_id=n.organization_id AND d.site_id=n.site_id AND d.user_id=n.user_id AND d.active ORDER BY d.id LIMIT 1;
 END IF;
END $$;
CREATE OR REPLACE FUNCTION app.pending_operation_push()
 RETURNS TABLE(inbox_id uuid,site uuid,module text,token_ciphertext text)
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE n record;BEGIN
 FOR n IN SELECT i.id FROM app.inbox_items i
  WHERE i.push_status IN ('unconfigured','pending','failed') AND i.push_attempts<5 AND i.push_next_attempt_at<=now()
   AND EXISTS(SELECT 1 FROM app.push_devices d WHERE d.organization_id=i.organization_id AND d.site_id=i.site_id AND d.user_id=i.user_id AND d.active)
  ORDER BY i.push_next_attempt_at,i.created_at LIMIT 10 FOR UPDATE SKIP LOCKED LOOP
  UPDATE app.inbox_items SET push_next_attempt_at=now()+interval '5 minutes' WHERE id=n.id;
  RETURN QUERY SELECT * FROM app.authorized_operation_push(n.id);
 END LOOP;
END $$;
REVOKE ALL ON FUNCTION app.authorized_operation_push(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.authorized_operation_push(uuid) TO hr_worker;
