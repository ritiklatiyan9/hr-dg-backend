ALTER TABLE app.inbox_items ADD COLUMN push_attempts integer NOT NULL DEFAULT 0;
CREATE FUNCTION app.pending_operation_push() RETURNS TABLE(inbox_id uuid,site uuid,module text,token_ciphertext text) LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE n record; BEGIN
 FOR n IN SELECT i.* FROM app.inbox_items i WHERE i.push_status IN ('unconfigured','pending','failed') AND i.push_attempts<5 ORDER BY i.created_at LIMIT 10 FOR UPDATE SKIP LOCKED LOOP
 PERFORM set_config('app.organization_id',n.organization_id::text,true),set_config('app.actor_id',n.user_id::text,true),set_config('app.site_id',n.site_id::text,true);
 IF app.has_site(n.site_id) AND (app.allowed(CASE WHEN n.module='attendance' THEN 'my_attendance.view' WHEN n.module='leave' THEN 'my_leave.view' ELSE n.module||'.view' END) OR app.allowed(n.module||'.view')) THEN
 RETURN QUERY SELECT n.id,n.site_id,n.module,d.token_ciphertext FROM app.push_devices d WHERE d.organization_id=n.organization_id AND d.site_id=n.site_id AND d.user_id=n.user_id AND d.active LIMIT 1;
 END IF;
 END LOOP; END $$;
CREATE FUNCTION app.mark_operation_push(target uuid,delivered boolean) RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path=pg_catalog AS $$
 UPDATE app.inbox_items SET push_status=CASE WHEN delivered THEN 'delivered' ELSE 'failed' END,push_attempts=push_attempts+1 WHERE id=target AND push_attempts<5 $$;
REVOKE ALL ON FUNCTION app.pending_operation_push(),app.mark_operation_push(uuid,boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.pending_operation_push(),app.mark_operation_push(uuid,boolean) TO hr_worker;
