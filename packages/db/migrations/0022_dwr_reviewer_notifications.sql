CREATE OR REPLACE FUNCTION app.operation_notify(recipient uuid,mod text,entity uuid,event text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
 IF NOT app.has_site(app.site_id()) OR mod NOT IN ('attendance','leave','tasks','field_duty','my_dwr','dwr_review') OR NOT EXISTS(SELECT 1 FROM app.site_memberships WHERE organization_id=app.org_id() AND site_id=app.site_id() AND user_id=recipient AND active) THEN RETURN; END IF;
 INSERT INTO app.inbox_items(organization_id,site_id,user_id,module,entity_id,event_type) VALUES(app.org_id(),app.site_id(),recipient,mod,entity,event) ON CONFLICT DO NOTHING;
 INSERT INTO app.outbox(organization_id,site_id,event_type,payload) VALUES(app.org_id(),app.site_id(),'operations.changed',jsonb_build_object('module',mod,'entityId',entity,'recipientId',recipient));
END $$;
CREATE OR REPLACE FUNCTION app.dwr_notify_reviewers(report uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE r record; u record; BEGIN
 SELECT * INTO r FROM app.dwr_reports WHERE id=report AND organization_id=app.org_id() AND site_id=app.site_id() AND user_id=app.actor_id() AND status='submitted';
 IF r.id IS NULL OR NOT app.allowed('my_dwr.submit',r.employee_id) THEN RETURN; END IF;
 FOR u IN SELECT user_id FROM app.site_memberships WHERE organization_id=app.org_id() AND site_id=app.site_id() AND active AND user_id<>app.actor_id()
 AND (app.policy_decision(user_id,app.site_id(),'dwr_review.review',r.employee_id)->>'allowed')::boolean LOOP
 PERFORM app.operation_notify(u.user_id,'dwr_review',report,'dwr.submitted.v'||r.version);
 END LOOP;
END $$;
CREATE OR REPLACE FUNCTION app.pending_operation_push() RETURNS TABLE(inbox_id uuid,site uuid,module text,token_ciphertext text) LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE n record; BEGIN
 FOR n IN SELECT i.* FROM app.inbox_items i WHERE i.push_status IN ('unconfigured','pending','failed') AND i.push_attempts<5 ORDER BY i.created_at LIMIT 10 FOR UPDATE SKIP LOCKED LOOP
 PERFORM set_config('app.organization_id',n.organization_id::text,true),set_config('app.actor_id',n.user_id::text,true),set_config('app.site_id',n.site_id::text,true);
 IF app.has_site(n.site_id) AND (CASE
 WHEN n.module='dwr_review' THEN app.dwr_visible(n.entity_id)
 WHEN n.module='my_dwr' THEN app.dwr_visible(n.entity_id) OR (n.event_type LIKE 'dwr.reminder.%' AND app.allowed('my_dwr.submit'))
 ELSE app.allowed(CASE WHEN n.module='attendance' THEN 'my_attendance.view' WHEN n.module='leave' THEN 'my_leave.view' ELSE n.module||'.view' END) OR app.allowed(n.module||'.view') END) THEN
 RETURN QUERY SELECT n.id,n.site_id,n.module,d.token_ciphertext FROM app.push_devices d WHERE d.organization_id=n.organization_id AND d.site_id=n.site_id AND d.user_id=n.user_id AND d.active LIMIT 1;
 END IF;
 END LOOP; END $$;
