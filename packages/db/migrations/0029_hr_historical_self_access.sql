-- Own assets and documents retain their original authorized site after dated transfers.
-- Published policy audience uses independent My Documents export access.
-- Map administrative draft submission to existing edit capabilities. Self-service submit remains separate.
CREATE OR REPLACE FUNCTION app.hr_row_access(kind text,employee uuid,owner_id uuid,creator uuid,state text,handlers uuid[],audience uuid[],payload jsonb,action text DEFAULT 'view') RETURNS boolean LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE mod text; d jsonb; BEGIN
 IF NOT app.has_site(app.site_id()) THEN RETURN false;END IF;
 mod:=app.hr_module(kind);
 IF kind='asset' AND owner_id=app.actor_id() AND action IN ('view','submit') THEN RETURN app.allowed('assets.'||action);END IF;
 IF kind='grievance' THEN
 IF owner_id=app.actor_id() THEN RETURN app.allowed('grievances.'||CASE WHEN action='edit' THEN 'submit' ELSE action END,employee) AND action IN ('view','create','edit','submit');END IF;
 RETURN state<>'draft' AND app.actor_id()=ANY(handlers) AND app.allowed('grievances.field.confidential') AND app.allowed('grievances.'||action) AND app.decision('grievances.'||action)->>'scope'='site';
 END IF;
 IF kind IN ('policy','announcement') AND state='published' AND app.actor_id()=ANY(audience) AND action IN ('view','submit','export') THEN RETURN app.allowed(CASE WHEN kind='policy' THEN 'my_documents.'||action ELSE 'announcements.'||action END);END IF;
 IF action='submit' AND (kind IN ('lifecycle','policy') OR (kind='document' AND owner_id<>app.actor_id())) THEN action:='edit';END IF;
 IF kind='document' THEN
 mod:=CASE WHEN owner_id=app.actor_id() THEN 'my_documents' ELSE 'documents' END;
 IF payload->>'category' IN ('bank','identity') AND NOT app.allowed(mod||'.field.'||(payload->>'category'),CASE WHEN owner_id=app.actor_id() THEN NULL ELSE employee END) THEN RETURN false;END IF;
 IF owner_id=app.actor_id() AND action='edit' THEN action:='submit';END IF;
 IF owner_id=app.actor_id() THEN RETURN app.allowed(mod||'.'||action);END IF;
 END IF;
 IF kind='lifecycle' AND owner_id=app.actor_id() AND action='view' THEN RETURN state='approved' AND app.allowed('my_hr.view',employee) AND app.allowed('my_hr.field.employment',employee);END IF;
 IF owner_id<>app.actor_id() AND state='draft' AND creator<>app.actor_id() THEN RETURN false;END IF;
 d:=app.decision(mod||'.'||action,CASE WHEN kind IN ('policy','announcement') THEN NULL ELSE employee END);
 IF kind IN ('policy','announcement') OR (kind='asset' AND action<>'submit' AND action<>'view') THEN RETURN (d->>'allowed')::boolean AND d->>'scope'='site';END IF;
 RETURN (d->>'allowed')::boolean;
END $$;
