-- DWR chat: a personal DWR agent chat for every employee plus WhatsApp-style
-- site groups. Everything an employee writes on a work date (personal or in a
-- group) is the source of that employee's own DWR. The worker's AI agent
-- prepares the draft; submission still needs the employee. Additive only:
-- voice tables remain solely so retained audio keeps being deleted.

-- Catalogue delta, mirroring packages/authz/src/catalogue.ts.
UPDATE app.module_catalogue SET actions=ARRAY['view','create','edit','delete','submit'] WHERE id='my_dwr';
INSERT INTO app.permission_catalogue VALUES('my_dwr.delete','my_dwr','delete');
INSERT INTO app.role_templates(role,key,scope) SELECT r,'my_dwr.delete','own'
 FROM unnest(ARRAY['super_admin','admin','hr','jr_hr','employee','manager','supervisor']) r;
INSERT INTO app.module_catalogue VALUES('dwr_groups','DWR groups','डीडब्ल्यूआर समूह','Operations',4,ARRAY['view','create','edit','delete'],ARRAY[]::text[],ARRAY[]::text[]);
INSERT INTO app.permission_catalogue SELECT 'dwr_groups.'||a,'dwr_groups',a FROM unnest(ARRAY['view','create','edit','delete']) a;
INSERT INTO app.role_templates(role,key,scope) SELECT r,'dwr_groups.'||a,'site'
 FROM unnest(ARRAY['super_admin','admin','hr']) r CROSS JOIN unnest(ARRAY['view','create','edit','delete']) a;
INSERT INTO app.role_templates(role,key,scope) SELECT 'jr_hr','dwr_groups.'||a,'site' FROM unnest(ARRAY['view','create','edit']) a;

-- Group oversight is site administration: team/own/organization scopes are invalid.
DO $$ DECLARE definition text; BEGIN
 SELECT pg_get_functiondef('app.policy_decision(uuid,uuid,text,uuid,jsonb)'::regprocedure) INTO definition;
 IF position($q$m.id IN ('access','organization','site_settings','audit')$q$ in definition)=0 THEN
  RAISE EXCEPTION 'Unexpected policy function; review DWR group scope';END IF;
 EXECUTE replace(definition,$q$m.id IN ('access','organization','site_settings','audit')$q$,
  $q$m.id IN ('access','organization','site_settings','audit','dwr_groups')$q$);
END $$;

CREATE TABLE app.dwr_groups (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 name text NOT NULL CHECK(length(btrim(name)) BETWEEN 2 AND 80),
 description text NOT NULL DEFAULT '' CHECK(length(description)<=500),
 created_by uuid NOT NULL, client_id uuid NOT NULL, version integer NOT NULL DEFAULT 1,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), archived_at timestamptz,
 UNIQUE(organization_id,site_id,id), UNIQUE(organization_id,created_by,client_id),
 FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id),
 FOREIGN KEY(organization_id,created_by) REFERENCES auth.users(organization_id,id)
);
CREATE UNIQUE INDEX dwr_group_active_name ON app.dwr_groups(organization_id,site_id,lower(btrim(name))) WHERE archived_at IS NULL;
CREATE TABLE app.dwr_group_members (
 organization_id uuid NOT NULL, site_id uuid NOT NULL, group_id uuid NOT NULL, user_id uuid NOT NULL, employee_id uuid NOT NULL,
 role text NOT NULL DEFAULT 'member' CHECK(role IN ('admin','member')), active boolean NOT NULL DEFAULT true,
 added_by uuid NOT NULL, added_at timestamptz NOT NULL DEFAULT now(), last_read_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(group_id,user_id),
 FOREIGN KEY(organization_id,site_id,group_id) REFERENCES app.dwr_groups(organization_id,site_id,id),
 FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id),
 FOREIGN KEY(organization_id,user_id) REFERENCES auth.users(organization_id,id),
 FOREIGN KEY(organization_id,added_by) REFERENCES auth.users(organization_id,id)
);
CREATE INDEX dwr_member_user ON app.dwr_group_members(organization_id,site_id,user_id) WHERE active;
-- group_id NULL is the author's personal DWR agent chat.
CREATE TABLE app.dwr_messages (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 group_id uuid, user_id uuid NOT NULL, employee_id uuid NOT NULL, work_date date NOT NULL, client_id uuid NOT NULL,
 body text NOT NULL, version integer NOT NULL DEFAULT 1,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
 edited_at timestamptz, deleted_at timestamptz, deleted_by uuid,
 CHECK((deleted_at IS NULL AND length(btrim(body)) BETWEEN 1 AND 2000) OR (deleted_at IS NOT NULL AND body='')),
 UNIQUE(organization_id,user_id,client_id), UNIQUE(organization_id,site_id,id),
 FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id),
 FOREIGN KEY(organization_id,site_id,group_id) REFERENCES app.dwr_groups(organization_id,site_id,id),
 FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id),
 FOREIGN KEY(organization_id,user_id) REFERENCES auth.users(organization_id,id),
 FOREIGN KEY(organization_id,deleted_by) REFERENCES auth.users(organization_id,id)
);
CREATE INDEX dwr_messages_group ON app.dwr_messages(group_id,created_at DESC,id DESC) WHERE group_id IS NOT NULL;
CREATE INDEX dwr_messages_personal ON app.dwr_messages(user_id,created_at DESC,id DESC) WHERE group_id IS NULL;
CREATE INDEX dwr_messages_author_day ON app.dwr_messages(organization_id,site_id,employee_id,work_date);
CREATE INDEX dwr_messages_changes ON app.dwr_messages(organization_id,site_id,updated_at);
-- Previous text of every edited or deleted message: claims are never silently rewritten.
CREATE TABLE app.dwr_message_history (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 message_id uuid NOT NULL, version integer NOT NULL, event text NOT NULL CHECK(event IN ('edit','delete')),
 body text NOT NULL, actor_id uuid NOT NULL, created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(message_id,version),
 FOREIGN KEY(organization_id,site_id,message_id) REFERENCES app.dwr_messages(organization_id,site_id,id),
 FOREIGN KEY(organization_id,actor_id) REFERENCES auth.users(organization_id,id)
);
ALTER TABLE app.dwr_reports ADD COLUMN origin text NOT NULL DEFAULT 'manual' CHECK(origin IN ('manual','voice','chat'));
UPDATE app.dwr_reports SET origin='voice' WHERE voice_id IS NOT NULL;
-- One deployment-wide heartbeat written by the worker; no employee data.
CREATE TABLE app.dwr_agent_state (
 id boolean PRIMARY KEY DEFAULT true CHECK(id), configured boolean NOT NULL, model text NOT NULL DEFAULT '', seen_at timestamptz NOT NULL
);
-- One preparation job per employee work date. Message changes re-queue it after a quiet period.
CREATE TABLE app.dwr_agent_jobs (
 organization_id uuid NOT NULL, site_id uuid NOT NULL, employee_id uuid NOT NULL, user_id uuid NOT NULL, work_date date NOT NULL,
 status text NOT NULL DEFAULT 'queued' CHECK(status IN ('queued','running','done','failed','skipped')),
 explicit boolean NOT NULL DEFAULT false, due_at timestamptz NOT NULL DEFAULT now(), requested_by uuid NOT NULL,
 lease_token uuid, lease_until timestamptz, attempts integer NOT NULL DEFAULT 0, retry_at timestamptz,
 error_code text, source_hash text, provenance jsonb NOT NULL DEFAULT '{}', prepared_at timestamptz,
 updated_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(organization_id,site_id,employee_id,work_date),
 FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id),
 FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id),
 FOREIGN KEY(organization_id,user_id) REFERENCES auth.users(organization_id,id),
 FOREIGN KEY(organization_id,requested_by) REFERENCES auth.users(organization_id,id)
);
CREATE INDEX dwr_agent_due ON app.dwr_agent_jobs(due_at) WHERE status IN ('queued','failed','running');

-- Actor-only helpers. Membership of other users is never answered here.
CREATE FUNCTION app.dwr_member_role(g uuid) RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT m.role FROM app.dwr_group_members m JOIN app.dwr_groups x ON x.id=m.group_id
 WHERE m.group_id=g AND m.user_id=app.actor_id() AND m.active AND x.archived_at IS NULL
 AND x.organization_id=app.org_id() AND x.site_id=app.site_id() $$;
CREATE FUNCTION app.dwr_my_groups() RETURNS uuid[] LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT COALESCE(array_agg(m.group_id),'{}') FROM app.dwr_group_members m JOIN app.dwr_groups x ON x.id=m.group_id
 WHERE m.user_id=app.actor_id() AND m.active AND x.archived_at IS NULL AND x.organization_id=app.org_id() AND x.site_id=app.site_id() $$;

-- Scalar subqueries keep actor-level decisions to one evaluation per statement.
ALTER TABLE app.dwr_groups ENABLE ROW LEVEL SECURITY;
CREATE POLICY dwr_group_read ON app.dwr_groups FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id()
 AND (SELECT app.has_site(app.site_id())) AND ((SELECT app.allowed('dwr_groups.view'))
 OR (archived_at IS NULL AND (SELECT app.allowed('my_dwr.view')) AND id IN (SELECT unnest(app.dwr_my_groups())))));
CREATE POLICY dwr_group_insert ON app.dwr_groups FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id()
 AND created_by=app.actor_id() AND (SELECT app.has_site(app.site_id())) AND (SELECT app.allowed('dwr_groups.create')));
CREATE POLICY dwr_group_update ON app.dwr_groups FOR UPDATE USING(organization_id=app.org_id() AND site_id=app.site_id()
 AND (SELECT app.has_site(app.site_id())) AND ((SELECT app.allowed('dwr_groups.edit')) OR (SELECT app.allowed('dwr_groups.delete')) OR app.dwr_member_role(id)='admin'));
GRANT SELECT,INSERT ON app.dwr_groups TO hr_runtime;
GRANT UPDATE(name,description,version,updated_at,archived_at) ON app.dwr_groups TO hr_runtime;
ALTER TABLE app.dwr_group_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY dwr_member_read ON app.dwr_group_members FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id()
 AND (SELECT app.has_site(app.site_id())) AND ((SELECT app.allowed('dwr_groups.view'))
 OR ((SELECT app.allowed('my_dwr.view')) AND group_id IN (SELECT unnest(app.dwr_my_groups())))));
CREATE POLICY dwr_member_insert ON app.dwr_group_members FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id()
 AND added_by=app.actor_id() AND (SELECT app.has_site(app.site_id())) AND ((SELECT app.allowed('dwr_groups.create'))
 OR (SELECT app.allowed('dwr_groups.edit')) OR app.dwr_member_role(group_id)='admin'));
CREATE POLICY dwr_member_update ON app.dwr_group_members FOR UPDATE USING(organization_id=app.org_id() AND site_id=app.site_id()
 AND (SELECT app.has_site(app.site_id())) AND ((SELECT app.allowed('dwr_groups.edit')) OR app.dwr_member_role(group_id)='admin' OR user_id=app.actor_id()));
GRANT SELECT,INSERT ON app.dwr_group_members TO hr_runtime;
GRANT UPDATE(role,active,added_by,added_at,last_read_at) ON app.dwr_group_members TO hr_runtime;
ALTER TABLE app.dwr_messages ENABLE ROW LEVEL SECURITY;
-- Reviewers read the sources of reports they may review; that check is per row, so it stays last.
CREATE POLICY dwr_message_read ON app.dwr_messages FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id()
 AND (SELECT app.has_site(app.site_id())) AND (
 (group_id IS NULL AND user_id=app.actor_id() AND (SELECT app.allowed('my_dwr.view')))
 OR (group_id IS NOT NULL AND ((SELECT app.allowed('dwr_groups.view')) OR ((SELECT app.allowed('my_dwr.view')) AND group_id IN (SELECT unnest(app.dwr_my_groups())))))
 OR app.allowed('dwr_review.view',employee_id)));
CREATE POLICY dwr_message_insert ON app.dwr_messages FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id()
 AND user_id=app.actor_id() AND (SELECT app.has_site(app.site_id())) AND app.allowed('my_dwr.create',employee_id)
 AND (group_id IS NULL OR app.dwr_member_role(group_id) IS NOT NULL));
CREATE POLICY dwr_message_update ON app.dwr_messages FOR UPDATE USING(organization_id=app.org_id() AND site_id=app.site_id()
 AND (SELECT app.has_site(app.site_id())) AND (user_id=app.actor_id() OR (group_id IS NOT NULL AND (SELECT app.allowed('dwr_groups.delete')))));
GRANT SELECT,INSERT ON app.dwr_messages TO hr_runtime;
GRANT UPDATE(body,deleted_at) ON app.dwr_messages TO hr_runtime;
ALTER TABLE app.dwr_message_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY dwr_message_history_read ON app.dwr_message_history FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id()
 AND (SELECT app.has_site(app.site_id())) AND (SELECT app.allowed('dwr_groups.view')));
GRANT SELECT ON app.dwr_message_history TO hr_runtime;
ALTER TABLE app.dwr_agent_state ENABLE ROW LEVEL SECURITY;
CREATE POLICY dwr_agent_state_read ON app.dwr_agent_state FOR SELECT USING((SELECT app.has_site(app.site_id())));
GRANT SELECT ON app.dwr_agent_state TO hr_runtime;
ALTER TABLE app.dwr_agent_jobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY dwr_agent_job_read ON app.dwr_agent_jobs FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id()
 AND (SELECT app.has_site(app.site_id())) AND ((user_id=app.actor_id() AND (SELECT app.allowed('my_dwr.view')))
 OR (SELECT app.allowed('dwr_groups.view')) OR app.allowed('dwr_review.view',employee_id)));
GRANT SELECT ON app.dwr_agent_jobs TO hr_runtime;

-- Chat-prepared drafts are derived from messages reviewers can already read,
-- so reviewers see them as "awaiting employee submission". Manual drafts stay private.
DROP POLICY dwr_read ON app.dwr_reports;
CREATE POLICY dwr_read ON app.dwr_reports FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND
 ((user_id=app.actor_id() AND app.allowed('my_dwr.view',employee_id)) OR ((status<>'draft' OR origin='chat') AND app.allowed('dwr_review.view',employee_id))));
CREATE OR REPLACE FUNCTION app.dwr_visible(report uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT EXISTS(SELECT 1 FROM app.dwr_reports r WHERE r.id=report AND r.organization_id=app.org_id()
 AND r.site_id=app.site_id() AND app.has_site(r.site_id)
 AND ((r.user_id=app.actor_id() AND app.allowed('my_dwr.view',r.employee_id))
 OR ((r.status<>'draft' OR r.origin='chat') AND app.allowed('dwr_review.view',r.employee_id)))) $$;
CREATE OR REPLACE FUNCTION app.dwr_provenance(report uuid) RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT CASE WHEN r.voice_id IS NOT NULL THEN
  (SELECT jsonb_build_object('versions',v.provenance,'generatedDraft',v.draft) FROM app.dwr_voice v
   WHERE (v.organization_id,v.site_id,v.id)=(r.organization_id,r.site_id,r.voice_id))
 ELSE (SELECT jsonb_build_object('agent',j.provenance,'preparedAt',j.prepared_at) FROM app.dwr_agent_jobs j
   WHERE (j.organization_id,j.site_id,j.employee_id,j.work_date)=(r.organization_id,r.site_id,r.employee_id,r.work_date) AND j.prepared_at IS NOT NULL) END
 FROM app.dwr_reports r
 WHERE r.id=report AND r.organization_id=app.org_id() AND r.site_id=app.site_id() AND app.dwr_visible(r.id)
 AND (r.user_id=app.actor_id() OR app.allowed('dwr_review.field.provenance',r.employee_id)) $$;

-- Invariants enforced in the database for every code path.
CREATE FUNCTION app.dwr_group_guard() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
 IF NEW.archived_at IS DISTINCT FROM OLD.archived_at AND NOT app.allowed('dwr_groups.delete') THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001';END IF;
 IF OLD.archived_at IS NOT NULL AND NEW.archived_at IS NOT NULL THEN RAISE EXCEPTION 'CONFLICT' USING ERRCODE='P0001';END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER dwr_group_guard BEFORE UPDATE ON app.dwr_groups FOR EACH ROW EXECUTE FUNCTION app.dwr_group_guard();
-- A member may leave or mark read; promotion and re-admission need a group admin or DWR group editor.
CREATE FUNCTION app.dwr_member_guard() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
 IF (NEW.role IS DISTINCT FROM OLD.role OR (NEW.active AND NOT OLD.active) OR (NOT NEW.active AND OLD.active AND NEW.user_id<>app.actor_id()))
 AND NOT (app.allowed('dwr_groups.edit') OR app.dwr_member_role(NEW.group_id)='admin') THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001';END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER dwr_member_guard BEFORE UPDATE ON app.dwr_group_members FOR EACH ROW EXECUTE FUNCTION app.dwr_member_guard();
-- Authors edit (my_dwr.edit) or delete (my_dwr.delete) their own messages; DWR group
-- moderators may only delete group messages. A submitted/approved DWR locks its sources.
CREATE FUNCTION app.dwr_message_guard() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE deleting boolean:=NEW.deleted_at IS NOT NULL;
BEGIN
 IF OLD.deleted_at IS NOT NULL THEN RAISE EXCEPTION 'CONFLICT' USING ERRCODE='P0001';END IF;
 IF EXISTS(SELECT 1 FROM app.dwr_reports r WHERE (r.organization_id,r.site_id,r.employee_id,r.work_date)=(OLD.organization_id,OLD.site_id,OLD.employee_id,OLD.work_date)
 AND r.status IN ('submitted','approved')) THEN RAISE EXCEPTION 'REPORT_LOCKED' USING ERRCODE='P0001';END IF;
 IF deleting THEN
  IF NOT ((OLD.user_id=app.actor_id() AND app.allowed('my_dwr.delete',OLD.employee_id)) OR (OLD.group_id IS NOT NULL AND app.allowed('dwr_groups.delete'))) THEN
   RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001';END IF;
 ELSIF OLD.user_id<>app.actor_id() OR NOT app.allowed('my_dwr.edit',OLD.employee_id) THEN
  RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001';
 ELSIF NEW.body=OLD.body THEN RAISE EXCEPTION 'BAD_INPUT' USING ERRCODE='P0001';
 END IF;
 INSERT INTO app.dwr_message_history(organization_id,site_id,message_id,version,event,body,actor_id)
 VALUES(OLD.organization_id,OLD.site_id,OLD.id,OLD.version,CASE WHEN deleting THEN 'delete' ELSE 'edit' END,OLD.body,app.actor_id());
 NEW.version:=OLD.version+1; NEW.updated_at:=now();
 IF deleting THEN NEW.body:='';NEW.deleted_at:=now();NEW.deleted_by:=app.actor_id();ELSE NEW.edited_at:=now();END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER dwr_message_guard BEFORE UPDATE ON app.dwr_messages FOR EACH ROW EXECUTE FUNCTION app.dwr_message_guard();
-- ponytail: fixed 10-minute quiet window before automatic preparation; move to dwr_settings if sites need other pacing.
CREATE FUNCTION app.dwr_message_changed() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
 IF EXISTS(SELECT 1 FROM app.dwr_reports r WHERE (r.organization_id,r.site_id,r.employee_id,r.work_date)=(NEW.organization_id,NEW.site_id,NEW.employee_id,NEW.work_date)
 AND r.status IN ('submitted','approved')) THEN RETURN NULL;END IF;
 INSERT INTO app.dwr_agent_jobs AS j(organization_id,site_id,employee_id,user_id,work_date,status,due_at,requested_by,explicit)
 VALUES(NEW.organization_id,NEW.site_id,NEW.employee_id,NEW.user_id,NEW.work_date,'queued',now()+interval '10 minutes',COALESCE(app.actor_id(),NEW.user_id),false)
 ON CONFLICT(organization_id,site_id,employee_id,work_date) DO UPDATE SET status='queued',
  -- A pending explicit request stays immediate; otherwise wait for the author to go quiet.
  due_at=CASE WHEN j.explicit AND j.status IN ('queued','running') THEN now() ELSE now()+interval '10 minutes' END,
  explicit=j.explicit AND j.status IN ('queued','running'),requested_by=excluded.requested_by,
  attempts=0,retry_at=NULL,error_code=NULL,lease_token=NULL,lease_until=NULL,updated_at=now();
 RETURN NULL;
END $$;
CREATE TRIGGER dwr_message_changed AFTER INSERT OR UPDATE ON app.dwr_messages FOR EACH ROW EXECUTE FUNCTION app.dwr_message_changed();

-- Minimal labels of people who may join DWR groups at this site (no contact/HR fields).
CREATE FUNCTION app.dwr_candidates(g uuid,q text,wanted uuid[] DEFAULT NULL) RETURNS TABLE(user_id uuid,employee_id uuid,name text)
 LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
 IF NOT app.has_site(app.site_id()) OR NOT (app.allowed('dwr_groups.create') OR app.allowed('dwr_groups.edit') OR (g IS NOT NULL AND app.dwr_member_role(g)='admin')) THEN
  RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001';END IF;
 RETURN QUERY SELECT e.user_id,e.id,e.display_name FROM app.employees e
  JOIN app.site_memberships sm ON sm.organization_id=e.organization_id AND sm.site_id=app.site_id() AND sm.user_id=e.user_id AND sm.active
  JOIN app.sites s ON s.organization_id=e.organization_id AND s.id=app.site_id()
  WHERE e.organization_id=app.org_id() AND e.user_id IS NOT NULL
  AND EXISTS(SELECT 1 FROM app.site_assignments a WHERE a.organization_id=e.organization_id AND a.site_id=s.id AND a.employee_id=e.id
   AND (now() AT TIME ZONE s.timezone)::date BETWEEN a.starts_on AND COALESCE(a.ends_on,'infinity'::date))
  AND (g IS NULL OR NOT EXISTS(SELECT 1 FROM app.dwr_group_members m WHERE m.group_id=g AND m.user_id=e.user_id AND m.active))
  AND (wanted IS NULL OR e.user_id=ANY(wanted))
  AND e.display_name ILIKE '%'||left(COALESCE(q,''),60)||'%' ESCAPE '\'
  -- Eligibility is decided for the explicitly requested users only; pickers stay cheap.
  AND (wanted IS NULL OR (app.policy_decision(e.user_id,app.site_id(),'my_dwr.view',e.id)->>'allowed')::boolean)
  ORDER BY e.display_name,e.id LIMIT CASE WHEN wanted IS NULL THEN 60 END;
END $$;
-- Display names only for people the actor shares a visible DWR group with, or may review.
CREATE FUNCTION app.dwr_people(users uuid[]) RETURNS TABLE(user_id uuid,name text) LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT e.user_id,e.display_name FROM app.employees e
 WHERE e.organization_id=app.org_id() AND e.user_id=ANY(users[1:300]) AND (SELECT app.has_site(app.site_id()))
 AND (e.user_id=app.actor_id()
  OR EXISTS(SELECT 1 FROM app.dwr_group_members m JOIN app.dwr_groups x ON x.id=m.group_id
   WHERE m.user_id=e.user_id AND x.organization_id=app.org_id() AND x.site_id=app.site_id()
   AND (x.id IN (SELECT unnest(app.dwr_my_groups())) OR (SELECT app.allowed('dwr_groups.view'))))
  OR app.allowed('dwr_review.view',e.id)) $$;
-- Explicit "prepare now" by the author, a DWR group editor or an admin of a shared group.
CREATE FUNCTION app.dwr_agent_request(target uuid,day date) RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE e record;
BEGIN
 IF NOT app.has_site(app.site_id()) THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001';END IF;
 SELECT id,user_id INTO e FROM app.employees WHERE organization_id=app.org_id() AND id=target;
 IF e.user_id IS NULL THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0001';END IF;
 IF NOT ((e.user_id=app.actor_id() AND app.allowed('my_dwr.create',e.id)) OR app.allowed('dwr_groups.edit')
 OR EXISTS(SELECT 1 FROM app.dwr_group_members mine JOIN app.dwr_group_members theirs ON theirs.group_id=mine.group_id AND theirs.user_id=e.user_id AND theirs.active
  JOIN app.dwr_groups x ON x.id=mine.group_id AND x.archived_at IS NULL AND x.organization_id=app.org_id() AND x.site_id=app.site_id()
  WHERE mine.user_id=app.actor_id() AND mine.role='admin' AND mine.active)) THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='P0001';END IF;
 IF NOT EXISTS(SELECT 1 FROM app.dwr_messages WHERE organization_id=app.org_id() AND site_id=app.site_id() AND employee_id=e.id AND work_date=day AND deleted_at IS NULL) THEN RETURN 'NO_MESSAGES';END IF;
 IF EXISTS(SELECT 1 FROM app.dwr_reports WHERE organization_id=app.org_id() AND site_id=app.site_id() AND employee_id=e.id AND work_date=day AND status IN ('submitted','approved')) THEN RETURN 'REPORT_LOCKED';END IF;
 INSERT INTO app.dwr_agent_jobs AS j(organization_id,site_id,employee_id,user_id,work_date,status,due_at,requested_by,explicit)
 VALUES(app.org_id(),app.site_id(),e.id,e.user_id,day,'queued',now(),app.actor_id(),true)
 ON CONFLICT(organization_id,site_id,employee_id,work_date) DO UPDATE SET status='queued',due_at=now(),explicit=true,requested_by=app.actor_id(),
  attempts=0,retry_at=NULL,error_code=NULL,lease_token=NULL,lease_until=NULL,updated_at=now() WHERE j.status<>'running';
 RETURN 'QUEUED';
END $$;
-- Worker: claim due jobs with a lease, rechecking the author's current access and budgets.
CREATE FUNCTION app.dwr_agent_claim(max_jobs int,user_daily int,org_daily int)
 RETURNS TABLE(organization_id uuid,site_id uuid,employee_id uuid,work_date date,lease uuid,source_hash text,messages jsonb,timezone text)
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE j record;token uuid;msgs jsonb;digest text;used int;org_used int;
BEGIN
 IF max_jobs NOT BETWEEN 1 AND 10 OR user_daily NOT BETWEEN 1 AND 500 OR org_daily NOT BETWEEN 1 AND 100000 THEN RAISE EXCEPTION 'BAD_INPUT';END IF;
 FOR j IN SELECT a.* FROM app.dwr_agent_jobs a WHERE a.attempts<5 AND ((a.status IN ('queued','failed') AND a.due_at<=now() AND COALESCE(a.retry_at,now())<=now())
  OR (a.status='running' AND a.lease_until<now())) ORDER BY a.explicit DESC,a.due_at LIMIT max_jobs FOR UPDATE SKIP LOCKED LOOP
  PERFORM set_config('app.organization_id',j.organization_id::text,true),set_config('app.site_id',j.site_id::text,true),set_config('app.actor_id',j.user_id::text,true);
  IF NOT app.has_site(j.site_id) OR NOT app.allowed('my_dwr.create',j.employee_id) THEN
   UPDATE app.dwr_agent_jobs a SET status='skipped',error_code='ACCESS_REVOKED',lease_token=NULL,lease_until=NULL,updated_at=now()
   WHERE (a.organization_id,a.site_id,a.employee_id,a.work_date)=(j.organization_id,j.site_id,j.employee_id,j.work_date);CONTINUE;END IF;
  IF EXISTS(SELECT 1 FROM app.dwr_reports r WHERE (r.organization_id,r.site_id,r.employee_id,r.work_date)=(j.organization_id,j.site_id,j.employee_id,j.work_date) AND r.status IN ('submitted','approved')) THEN
   UPDATE app.dwr_agent_jobs a SET status='skipped',error_code='REPORT_LOCKED',lease_token=NULL,lease_until=NULL,updated_at=now()
   WHERE (a.organization_id,a.site_id,a.employee_id,a.work_date)=(j.organization_id,j.site_id,j.employee_id,j.work_date);CONTINUE;END IF;
  SELECT COALESCE(sum(u.calls),0) INTO org_used FROM app.dwr_usage u WHERE u.organization_id=j.organization_id AND u.day=current_date;
  SELECT COALESCE(sum(u.calls),0) INTO used FROM app.dwr_usage u WHERE u.organization_id=j.organization_id AND u.actor_id=j.user_id AND u.day=current_date;
  IF used>=user_daily OR org_used>=org_daily THEN
   UPDATE app.dwr_agent_jobs a SET status='failed',error_code='LIMIT_REACHED',retry_at=(current_date+1)::timestamptz,lease_token=NULL,lease_until=NULL,updated_at=now()
   WHERE (a.organization_id,a.site_id,a.employee_id,a.work_date)=(j.organization_id,j.site_id,j.employee_id,j.work_date);CONTINUE;END IF;
  -- ponytail: the first 200 messages of a day are the bounded AI input.
  SELECT jsonb_agg(jsonb_build_object('at',m.created_at,'text',m.body) ORDER BY m.created_at,m.id),md5(string_agg(m.id::text||':'||m.version,',' ORDER BY m.created_at,m.id))
  INTO msgs,digest FROM (SELECT x.* FROM app.dwr_messages x WHERE x.organization_id=j.organization_id AND x.site_id=j.site_id AND x.employee_id=j.employee_id
   AND x.work_date=j.work_date AND x.deleted_at IS NULL ORDER BY x.created_at,x.id LIMIT 200) m;
  IF msgs IS NULL THEN
   UPDATE app.dwr_agent_jobs a SET status='skipped',error_code='NO_MESSAGES',lease_token=NULL,lease_until=NULL,updated_at=now()
   WHERE (a.organization_id,a.site_id,a.employee_id,a.work_date)=(j.organization_id,j.site_id,j.employee_id,j.work_date);CONTINUE;END IF;
  token:=gen_random_uuid();
  UPDATE app.dwr_agent_jobs a SET status='running',lease_token=token,lease_until=now()+interval '60 seconds',attempts=a.attempts+1,updated_at=now()
  WHERE (a.organization_id,a.site_id,a.employee_id,a.work_date)=(j.organization_id,j.site_id,j.employee_id,j.work_date);
  INSERT INTO app.dwr_usage VALUES(j.organization_id,j.user_id,current_date,1,0)
  ON CONFLICT ON CONSTRAINT dwr_usage_pkey DO UPDATE SET calls=app.dwr_usage.calls+1;
  RETURN QUERY SELECT j.organization_id,j.site_id,j.employee_id,j.work_date,token,digest,msgs,s.timezone FROM app.sites s WHERE s.id=j.site_id;
 END LOOP;
END $$;
-- Worker: store validated output only if the lease holds, access remains and the sources are unchanged.
CREATE FUNCTION app.dwr_agent_store(org uuid,site uuid,employee uuid,day date,token uuid,source text,p_content jsonb,p_provenance jsonb) RETURNS text
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE j record;r record;digest text;last_event text;
BEGIN
 SELECT * INTO j FROM app.dwr_agent_jobs a WHERE (a.organization_id,a.site_id,a.employee_id,a.work_date)=(org,site,employee,day) FOR UPDATE;
 IF NOT FOUND OR j.status<>'running' OR j.lease_token IS DISTINCT FROM token THEN RETURN 'STALE';END IF;
 IF jsonb_typeof(p_content)<>'object' OR pg_column_size(p_content)>65536 OR jsonb_typeof(p_provenance)<>'object' OR pg_column_size(p_provenance)>4096 THEN RAISE EXCEPTION 'BAD_INPUT';END IF;
 PERFORM set_config('app.organization_id',org::text,true),set_config('app.site_id',site::text,true),set_config('app.actor_id',j.user_id::text,true);
 IF NOT app.has_site(site) OR NOT app.allowed('my_dwr.create',employee) THEN
  UPDATE app.dwr_agent_jobs a SET status='skipped',error_code='ACCESS_REVOKED',lease_token=NULL,lease_until=NULL,updated_at=now()
  WHERE (a.organization_id,a.site_id,a.employee_id,a.work_date)=(org,site,employee,day);RETURN 'ACCESS_REVOKED';END IF;
 SELECT md5(string_agg(m.id::text||':'||m.version,',' ORDER BY m.created_at,m.id)) INTO digest FROM (SELECT x.* FROM app.dwr_messages x
  WHERE x.organization_id=org AND x.site_id=site AND x.employee_id=employee AND x.work_date=day AND x.deleted_at IS NULL ORDER BY x.created_at,x.id LIMIT 200) m;
 IF digest IS DISTINCT FROM source THEN
  UPDATE app.dwr_agent_jobs a SET status='queued',due_at=now(),lease_token=NULL,lease_until=NULL,updated_at=now()
  WHERE (a.organization_id,a.site_id,a.employee_id,a.work_date)=(org,site,employee,day);RETURN 'STALE';END IF;
 SELECT * INTO r FROM app.dwr_reports x WHERE (x.organization_id,x.site_id,x.employee_id,x.work_date)=(org,site,employee,day) FOR UPDATE;
 IF FOUND AND r.status IN ('submitted','approved') THEN
  UPDATE app.dwr_agent_jobs a SET status='skipped',error_code='REPORT_LOCKED',lease_token=NULL,lease_until=NULL,updated_at=now()
  WHERE (a.organization_id,a.site_id,a.employee_id,a.work_date)=(org,site,employee,day);RETURN 'REPORT_LOCKED';END IF;
 IF FOUND AND NOT j.explicit THEN
  SELECT h.event INTO last_event FROM app.dwr_history h WHERE h.report_id=r.id ORDER BY h.version DESC LIMIT 1;
  -- Automatic runs never overwrite the author's own edits; an explicit request does.
  IF last_event IN ('save','amend') THEN
   UPDATE app.dwr_agent_jobs a SET status='skipped',error_code='MANUAL_EDITS',lease_token=NULL,lease_until=NULL,updated_at=now()
   WHERE (a.organization_id,a.site_id,a.employee_id,a.work_date)=(org,site,employee,day);RETURN 'MANUAL_EDITS';END IF;
 END IF;
 IF r.id IS NULL THEN
  INSERT INTO app.dwr_reports(organization_id,site_id,employee_id,user_id,work_date,content,origin)
  VALUES(org,site,employee,j.user_id,day,p_content,'chat') RETURNING * INTO r;
  PERFORM app.operation_notify(j.user_id,'my_dwr',r.id,'dwr.prepared');
 ELSE
  UPDATE app.dwr_reports x SET content=p_content,origin='chat',status='draft',version=x.version+1,revision=x.revision+1,updated_at=now()
  WHERE x.id=r.id RETURNING * INTO r;
 END IF;
 INSERT INTO app.dwr_history(organization_id,site_id,report_id,version,revision,actor_id,event,reason,content,attachments)
 VALUES(org,site,r.id,r.version,r.revision,j.requested_by,'prepare','',r.content,r.attachments);
 UPDATE app.dwr_agent_jobs a SET status='done',explicit=false,prepared_at=now(),source_hash=digest,provenance=p_provenance,error_code=NULL,
  lease_token=NULL,lease_until=NULL,updated_at=now() WHERE (a.organization_id,a.site_id,a.employee_id,a.work_date)=(org,site,employee,day);
 RETURN 'STORED';
END $$;
CREATE FUNCTION app.dwr_agent_fail(org uuid,site uuid,employee uuid,day date,token uuid,code text,retry_seconds int) RETURNS void
 LANGUAGE sql SECURITY DEFINER SET search_path=pg_catalog AS $$
 UPDATE app.dwr_agent_jobs a SET status='failed',error_code=left(code,40),retry_at=now()+make_interval(secs=>LEAST(GREATEST(retry_seconds,1),86400)),
 lease_token=NULL,lease_until=NULL,updated_at=now()
 WHERE (a.organization_id,a.site_id,a.employee_id,a.work_date)=(org,site,employee,day) AND a.status='running' AND a.lease_token=token $$;
CREATE FUNCTION app.dwr_agent_heartbeat(is_configured boolean,model_name text) RETURNS void
 LANGUAGE sql SECURITY DEFINER SET search_path=pg_catalog AS $$
 INSERT INTO app.dwr_agent_state VALUES(true,is_configured,left(COALESCE(model_name,''),120),now())
 ON CONFLICT(id) DO UPDATE SET configured=excluded.configured,model=excluded.model,seen_at=excluded.seen_at $$;

REVOKE ALL ON FUNCTION app.dwr_member_role(uuid),app.dwr_my_groups(),app.dwr_group_guard(),app.dwr_member_guard(),
 app.dwr_message_guard(),app.dwr_message_changed(),app.dwr_candidates(uuid,text,uuid[]),app.dwr_people(uuid[]),app.dwr_agent_request(uuid,date),
 app.dwr_agent_claim(int,int,int),app.dwr_agent_store(uuid,uuid,uuid,date,uuid,text,jsonb,jsonb),
 app.dwr_agent_fail(uuid,uuid,uuid,date,uuid,text,int),app.dwr_agent_heartbeat(boolean,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.dwr_member_role(uuid),app.dwr_my_groups(),app.dwr_candidates(uuid,text,uuid[]),app.dwr_people(uuid[]),
 app.dwr_agent_request(uuid,date) TO hr_runtime;
GRANT EXECUTE ON FUNCTION app.dwr_agent_claim(int,int,int),app.dwr_agent_store(uuid,uuid,uuid,date,uuid,text,jsonb,jsonb),
 app.dwr_agent_fail(uuid,uuid,uuid,date,uuid,text,int),app.dwr_agent_heartbeat(boolean,text) TO hr_worker;
