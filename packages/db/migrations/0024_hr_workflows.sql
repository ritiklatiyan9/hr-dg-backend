INSERT INTO app.module_catalogue VALUES('helpdesk','HR helpdesk','एचआर सहायता','People',5,ARRAY['view','create','submit','review','manage'],ARRAY[]::text[],ARRAY[]::text[]);
INSERT INTO app.permission_catalogue SELECT 'helpdesk.'||a,'helpdesk',a FROM unnest(ARRAY['view','create','submit','review','manage']) a;
INSERT INTO app.permission_catalogue VALUES('documents.field.bank','documents','field.bank'),('my_documents.field.bank','my_documents','field.bank');
UPDATE app.module_catalogue SET fields=ARRAY['identity','bank'] WHERE id IN ('documents','my_documents');
INSERT INTO app.role_templates(role,key,scope) SELECT r,k,'own' FROM unnest(ARRAY['super_admin','admin','hr','jr_hr','employee','manager','supervisor']) r CROSS JOIN unnest(ARRAY['expenses.view','expenses.create','expenses.edit','expenses.submit','assets.view','assets.submit','helpdesk.view','helpdesk.create','helpdesk.submit','grievances.view','grievances.create','grievances.submit','announcements.view','announcements.submit','inbox.view','my_documents.field.bank']) k ON CONFLICT DO NOTHING;
-- Ordinary HR operations need explicit site grants; confidential access never follows a job title.
CREATE TABLE app.hr_case_handlers(organization_id uuid NOT NULL,site_id uuid NOT NULL,user_id uuid NOT NULL,PRIMARY KEY(organization_id,site_id,user_id),FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id),FOREIGN KEY(organization_id,user_id) REFERENCES auth.users(organization_id,id));
ALTER TABLE app.hr_case_handlers ENABLE ROW LEVEL SECURITY;
CREATE POLICY handler_read ON app.hr_case_handlers FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id));
CREATE POLICY handler_write ON app.hr_case_handlers FOR ALL USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.allowed('grievances.manage') AND app.allowed('grievances.field.confidential')) WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.allowed('grievances.manage') AND app.allowed('grievances.field.confidential'));
GRANT SELECT,INSERT,DELETE ON app.hr_case_handlers TO hr_runtime;
CREATE TABLE app.hr_records(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL,site_id uuid NOT NULL,
 kind text NOT NULL CHECK(kind IN ('expense','asset','helpdesk','grievance','document','policy','announcement','lifecycle')),
 employee_id uuid NOT NULL,user_id uuid NOT NULL,created_by uuid NOT NULL,status text NOT NULL DEFAULT 'draft',version int NOT NULL DEFAULT 1,
 payload jsonb NOT NULL,attachments uuid[] NOT NULL DEFAULT '{}',handlers uuid[] NOT NULL DEFAULT '{}',audience uuid[] NOT NULL DEFAULT '{}',
 created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(organization_id,id),FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id),
 FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id),FOREIGN KEY(organization_id,user_id) REFERENCES auth.users(organization_id,id)
);
CREATE UNIQUE INDEX asset_tag_unique ON app.hr_records(organization_id,(payload->>'assetTag')) WHERE kind='asset';
CREATE INDEX hr_record_scope ON app.hr_records(organization_id,site_id,kind,status,created_at DESC);
CREATE FUNCTION app.hr_module(kind text) RETURNS text LANGUAGE sql IMMUTABLE AS $$ SELECT CASE kind WHEN 'expense' THEN 'expenses' WHEN 'asset' THEN 'assets' WHEN 'helpdesk' THEN 'helpdesk' WHEN 'grievance' THEN 'grievances' WHEN 'document' THEN 'documents' WHEN 'policy' THEN 'documents' WHEN 'announcement' THEN 'announcements' ELSE 'employees' END $$;
CREATE FUNCTION app.hr_row_access(kind text,employee uuid,owner_id uuid,creator uuid,state text,handlers uuid[],audience uuid[],payload jsonb,action text DEFAULT 'view') RETURNS boolean LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE mod text; d jsonb; BEGIN
 IF NOT app.has_site(app.site_id()) THEN RETURN false;END IF;
 mod:=app.hr_module(kind);
 IF kind='grievance' THEN
 IF owner_id=app.actor_id() THEN RETURN app.allowed('grievances.'||CASE WHEN action='edit' THEN 'submit' ELSE action END,employee) AND action IN ('view','create','edit','submit');END IF;
 RETURN state<>'draft' AND app.actor_id()=ANY(handlers) AND app.allowed('grievances.field.confidential') AND app.allowed('grievances.'||action) AND app.decision('grievances.'||action)->>'scope'='site';
 END IF;
 IF kind IN ('policy','announcement') AND state='published' AND app.actor_id()=ANY(audience) AND action IN ('view','submit') THEN RETURN app.allowed(CASE WHEN kind='policy' THEN 'my_documents.'||CASE WHEN action='submit' THEN 'submit' ELSE 'view' END ELSE 'announcements.'||action END);END IF;
 IF kind='document' THEN
 mod:=CASE WHEN owner_id=app.actor_id() THEN 'my_documents' ELSE 'documents' END;
 IF payload->>'category' IN ('bank','identity') AND NOT app.allowed(mod||'.field.'||(payload->>'category'),employee) THEN RETURN false;END IF;
 IF owner_id=app.actor_id() AND action='edit' THEN action:='submit';END IF;
 END IF;
 IF kind='lifecycle' AND owner_id=app.actor_id() AND action='view' THEN RETURN state='approved' AND app.allowed('my_hr.view',employee) AND app.allowed('my_hr.field.employment',employee);END IF;
 IF owner_id<>app.actor_id() AND state='draft' AND creator<>app.actor_id() THEN RETURN false;END IF;
 d:=app.decision(mod||'.'||action,CASE WHEN kind IN ('policy','announcement') THEN NULL ELSE employee END);
 IF kind IN ('policy','announcement') OR (kind='asset' AND action<>'submit' AND action<>'view') THEN RETURN (d->>'allowed')::boolean AND d->>'scope'='site';END IF;
 RETURN (d->>'allowed')::boolean;
END $$;
CREATE FUNCTION app.hr_visible(record_id uuid,action text DEFAULT 'view') RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT EXISTS(SELECT 1 FROM app.hr_records r WHERE r.id=record_id AND r.organization_id=app.org_id() AND r.site_id=app.site_id() AND app.hr_row_access(r.kind,r.employee_id,r.user_id,r.created_by,r.status,r.handlers,r.audience,r.payload,action)) $$;
REVOKE ALL ON FUNCTION app.hr_module(text),app.hr_row_access(text,uuid,uuid,uuid,text,uuid[],uuid[],jsonb,text),app.hr_visible(uuid,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.hr_module(text),app.hr_row_access(text,uuid,uuid,uuid,text,uuid[],uuid[],jsonb,text),app.hr_visible(uuid,text) TO hr_runtime;
ALTER TABLE app.hr_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY hr_read ON app.hr_records FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.hr_row_access(kind,employee_id,user_id,created_by,status,handlers,audience,payload));
CREATE POLICY hr_insert ON app.hr_records FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND created_by=app.actor_id() AND app.hr_row_access(kind,employee_id,user_id,created_by,status,handlers,audience,payload,'create'));
CREATE POLICY hr_update ON app.hr_records FOR UPDATE USING(app.hr_visible(id)) WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id));
GRANT SELECT,INSERT,UPDATE ON app.hr_records TO hr_runtime;
CREATE TABLE app.hr_history(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL,site_id uuid NOT NULL,record_id uuid NOT NULL,version int NOT NULL,actor_id uuid NOT NULL,event text NOT NULL,note text NOT NULL,payload jsonb NOT NULL,created_at timestamptz NOT NULL DEFAULT now(),UNIQUE(record_id,version),FOREIGN KEY(organization_id,record_id) REFERENCES app.hr_records(organization_id,id));
ALTER TABLE app.hr_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY history_read ON app.hr_history FOR SELECT USING(app.hr_visible(record_id));
CREATE POLICY history_insert ON app.hr_history FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND actor_id=app.actor_id() AND app.hr_visible(record_id));
GRANT SELECT,INSERT ON app.hr_history TO hr_runtime;
CREATE TABLE app.hr_acknowledgments(organization_id uuid NOT NULL,site_id uuid NOT NULL,record_id uuid NOT NULL,user_id uuid NOT NULL,created_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(record_id,user_id),FOREIGN KEY(organization_id,record_id) REFERENCES app.hr_records(organization_id,id));
ALTER TABLE app.hr_acknowledgments ENABLE ROW LEVEL SECURITY;
CREATE POLICY ack_read ON app.hr_acknowledgments FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.hr_visible(record_id));
CREATE POLICY ack_insert ON app.hr_acknowledgments FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND user_id=app.actor_id() AND app.hr_visible(record_id,'submit'));
GRANT SELECT,INSERT ON app.hr_acknowledgments TO hr_runtime;
ALTER TABLE app.private_files DROP CONSTRAINT private_files_purpose_check;
ALTER TABLE app.private_files ADD CONSTRAINT private_files_purpose_check CHECK(purpose IN ('attendance','task','visit','dwr','hr'));
DROP POLICY scoped_read ON app.private_files;
CREATE POLICY scoped_read ON app.private_files FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND
 CASE WHEN purpose='hr' THEN app.hr_visible(parent_id) WHEN purpose='dwr' THEN app.dwr_visible(parent_id) ELSE owner_id=app.actor_id() OR app.allowed('attendance.view',employee_id) OR app.allowed('tasks.view',employee_id) END);
CREATE FUNCTION app.apply_hr_lifecycle(record_id uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE r record;e record;dt date;destination uuid;a record;BEGIN
 SELECT * INTO r FROM app.hr_records WHERE id=record_id AND organization_id=app.org_id() AND site_id=app.site_id() AND kind='lifecycle' AND status='submitted' FOR UPDATE;
 IF r.id IS NULL OR r.user_id=app.actor_id() OR r.created_by=app.actor_id() OR NOT app.allowed('employees.approve',r.employee_id) OR NOT app.allowed('employees.field.employment',r.employee_id) THEN RAISE EXCEPTION 'FORBIDDEN';END IF;
 SELECT * INTO e FROM app.employment_records WHERE id=(r.payload->>'employmentId')::uuid AND organization_id=app.org_id() AND employee_id=r.employee_id FOR UPDATE;
 dt:=(r.payload->>'effectiveOn')::date;
 IF e.id IS NULL OR dt<e.starts_on OR dt>COALESCE(e.ends_on,'infinity'::date) THEN RAISE EXCEPTION 'INVALID_EMPLOYMENT';END IF;
 IF r.payload->>'event'='salary_revision' AND NOT app.payroll_admin('payroll.approve',r.employee_id) THEN RAISE EXCEPTION 'FORBIDDEN';END IF;
 IF r.payload->>'event'='promotion' AND (length(r.payload->>'designation')<1 OR length(r.payload->>'department')<1) THEN RAISE EXCEPTION 'BAD_INPUT';END IF;
 IF r.payload->>'event'='transfer' THEN
 destination:=(r.payload->>'destinationSiteId')::uuid;
 IF destination IS NULL OR destination=app.site_id() OR NOT app.has_site(destination) OR NOT (app.policy_decision(app.actor_id(),destination,'employees.edit')->>'allowed')::boolean OR app.policy_decision(app.actor_id(),destination,'employees.edit')->>'scope'<>'site' THEN RAISE EXCEPTION 'FORBIDDEN';END IF;
 IF EXISTS(SELECT 1 FROM app.site_assignments WHERE organization_id=app.org_id() AND employee_id=r.employee_id AND site_id=destination AND starts_on<=COALESCE(e.ends_on,'infinity'::date) AND COALESCE(ends_on,'infinity'::date)>=dt) THEN RAISE EXCEPTION 'ASSIGNMENT_OVERLAP';END IF;
 UPDATE app.site_assignments SET ends_on=dt-1 WHERE organization_id=app.org_id() AND employee_id=r.employee_id AND site_id=app.site_id() AND starts_on<dt AND COALESCE(ends_on,'infinity'::date)>=dt;
 IF NOT FOUND THEN RAISE EXCEPTION 'CONFLICT';END IF;
 INSERT INTO app.site_assignments(organization_id,site_id,employee_id,starts_on,ends_on) VALUES(app.org_id(),destination,r.employee_id,dt,e.ends_on);
 ELSIF r.payload->>'event'='exit' THEN
 IF EXISTS(SELECT 1 FROM app.employment_records WHERE organization_id=app.org_id() AND employee_id=r.employee_id AND id<>e.id AND COALESCE(ends_on,'infinity'::date)>dt) THEN RAISE EXCEPTION 'OTHER_EMPLOYMENT_REVIEW_REQUIRED';END IF;
 IF EXISTS(SELECT 1 FROM app.hr_records WHERE organization_id=app.org_id() AND employee_id=r.employee_id AND kind='asset' AND status IN ('assigned','acknowledged','return_requested','returned')) THEN RAISE EXCEPTION 'ASSET_CLEARANCE_REQUIRED';END IF;
 FOR a IN SELECT DISTINCT site_id FROM app.site_assignments WHERE organization_id=app.org_id() AND employee_id=r.employee_id AND COALESCE(ends_on,'infinity'::date)>dt LOOP
 IF NOT app.has_site(a.site_id) OR NOT (app.policy_decision(app.actor_id(),a.site_id,'employees.approve')->>'allowed')::boolean OR app.policy_decision(app.actor_id(),a.site_id,'employees.approve')->>'scope'<>'site' THEN RAISE EXCEPTION 'FORBIDDEN';END IF;END LOOP;
 IF EXISTS(SELECT 1 FROM app.site_assignments WHERE organization_id=app.org_id() AND employee_id=r.employee_id AND starts_on>dt) THEN RAISE EXCEPTION 'FUTURE_ASSIGNMENT_REVIEW_REQUIRED';END IF;
 UPDATE app.employment_records SET ends_on=dt WHERE id=e.id;
 UPDATE app.site_assignments SET ends_on=dt WHERE organization_id=app.org_id() AND employee_id=r.employee_id AND COALESCE(ends_on,'infinity'::date)>dt;
 END IF;
 UPDATE app.employees SET version=version+1,updated_at=now() WHERE id=r.employee_id AND organization_id=app.org_id();
END $$;
REVOKE ALL ON FUNCTION app.apply_hr_lifecycle(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.apply_hr_lifecycle(uuid) TO hr_runtime;
CREATE FUNCTION app.hr_guard() RETURNS trigger LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN
 IF NEW.organization_id<>OLD.organization_id OR NEW.site_id<>OLD.site_id OR NEW.kind<>OLD.kind OR NEW.created_by<>OLD.created_by OR NEW.handlers<>OLD.handlers OR NEW.version<>OLD.version+1 THEN RAISE EXCEPTION 'CONFLICT';END IF;
 IF OLD.status<>'draft' AND (NEW.payload<>OLD.payload OR NEW.attachments<>OLD.attachments OR NEW.audience<>OLD.audience) THEN RAISE EXCEPTION 'IMMUTABLE_DECISION';END IF;
 IF (NEW.employee_id<>OLD.employee_id OR NEW.user_id<>OLD.user_id) AND NOT (OLD.kind='asset' AND OLD.status IN ('available','returned') AND NEW.status='assigned' AND app.allowed('assets.manage',NEW.employee_id)) THEN RAISE EXCEPTION 'FORBIDDEN';END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER hr_guard BEFORE UPDATE ON app.hr_records FOR EACH ROW EXECUTE FUNCTION app.hr_guard();
REVOKE ALL ON FUNCTION app.hr_guard() FROM PUBLIC;
CREATE FUNCTION app.hr_notify(record_id uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE r record;u record;prior_actor text;mod text;BEGIN
 SELECT * INTO r FROM app.hr_records WHERE id=record_id AND organization_id=app.org_id() AND site_id=app.site_id();
 IF r.id IS NULL OR NOT app.hr_visible(r.id) OR r.status='draft' THEN RETURN;END IF;
 mod:=CASE WHEN r.kind='document' OR r.kind='policy' THEN 'my_documents' ELSE app.hr_module(r.kind) END;
 prior_actor:=app.actor_id()::text;
 FOR u IN SELECT user_id FROM app.site_memberships WHERE organization_id=app.org_id() AND site_id=app.site_id() AND active LOOP
 PERFORM set_config('app.actor_id',u.user_id::text,true);
 IF app.hr_visible(r.id) THEN
 INSERT INTO app.inbox_items(organization_id,site_id,user_id,module,entity_id,event_type) VALUES(app.org_id(),app.site_id(),u.user_id,mod,r.id,'hr.'||r.kind||'.'||r.status||'.v'||r.version) ON CONFLICT DO NOTHING;
 INSERT INTO app.outbox(organization_id,site_id,event_type,payload) VALUES(app.org_id(),app.site_id(),'operations.changed',jsonb_build_object('module',mod,'entityId',r.id,'recipientId',u.user_id));
 END IF;
 END LOOP;
 PERFORM set_config('app.actor_id',prior_actor,true);
END $$;
REVOKE ALL ON FUNCTION app.hr_notify(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.hr_notify(uuid) TO hr_runtime;
CREATE TABLE app.hr_settings(organization_id uuid NOT NULL,site_id uuid NOT NULL,version int NOT NULL DEFAULT 1,reminder_days int CHECK(reminder_days BETWEEN 1 AND 365),reason text NOT NULL,PRIMARY KEY(organization_id,site_id),FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id));
ALTER TABLE app.hr_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY hr_settings_read ON app.hr_settings FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id));
CREATE POLICY hr_settings_write ON app.hr_settings FOR ALL USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.allowed('documents.manage')) WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.allowed('documents.manage'));
GRANT SELECT,INSERT,UPDATE ON app.hr_settings TO hr_runtime;
CREATE FUNCTION app.hr_tick() RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE r record;u record;BEGIN
 FOR r IN SELECT h.*,s.timezone,c.reminder_days FROM app.hr_records h JOIN app.hr_settings c ON c.organization_id=h.organization_id AND c.site_id=h.site_id JOIN app.sites s ON s.id=h.site_id WHERE h.kind='document' AND h.status='approved' AND c.reminder_days IS NOT NULL AND h.payload->>'expiresOn' IS NOT NULL AND (h.payload->>'expiresOn')::date BETWEEN (now() AT TIME ZONE s.timezone)::date AND (now() AT TIME ZONE s.timezone)::date+c.reminder_days LOOP
 PERFORM set_config('app.organization_id',r.organization_id::text,true),set_config('app.site_id',r.site_id::text,true);
 FOR u IN SELECT user_id FROM app.site_memberships WHERE organization_id=r.organization_id AND site_id=r.site_id AND active LOOP
 PERFORM set_config('app.actor_id',u.user_id::text,true);
 IF app.hr_visible(r.id) THEN
 INSERT INTO app.inbox_items(organization_id,site_id,user_id,module,entity_id,event_type) VALUES(r.organization_id,r.site_id,u.user_id,'my_documents',r.id,'hr.document.expiry.'||(r.payload->>'expiresOn')) ON CONFLICT DO NOTHING;
 IF FOUND THEN INSERT INTO app.outbox(organization_id,site_id,event_type,payload) VALUES(r.organization_id,r.site_id,'operations.changed',jsonb_build_object('module','my_documents','entityId',r.id,'recipientId',u.user_id));END IF;
 END IF;END LOOP;END LOOP;
END $$;
REVOKE ALL ON FUNCTION app.hr_tick() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.hr_tick() TO hr_worker;
-- Inbox contents recheck the parent, including confidential/salary field revocation.
DROP POLICY scoped_read ON app.inbox_items;
CREATE POLICY scoped_read ON app.inbox_items FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND user_id=app.actor_id() AND app.has_site(site_id) AND CASE WHEN event_type LIKE 'hr.%' THEN app.hr_visible(entity_id) WHEN module='my_payroll' THEN app.payroll_visible(entity_id) ELSE true END);
CREATE TABLE app.hr_handler_config(organization_id uuid NOT NULL,site_id uuid NOT NULL,version int NOT NULL,PRIMARY KEY(organization_id,site_id),FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id));
ALTER TABLE app.hr_handler_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY handler_config_read ON app.hr_handler_config FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id));
CREATE POLICY handler_config_write ON app.hr_handler_config FOR ALL USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.allowed('grievances.manage') AND app.allowed('grievances.field.confidential')) WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.allowed('grievances.manage') AND app.allowed('grievances.field.confidential'));
GRANT SELECT,INSERT,UPDATE ON app.hr_handler_config TO hr_runtime;
