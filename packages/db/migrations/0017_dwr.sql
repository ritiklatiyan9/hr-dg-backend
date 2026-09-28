-- Phase 4: canonical DWR, immutable revisions, voice receipts and bounded usage.
CREATE TABLE app.dwr_reports (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 employee_id uuid NOT NULL, user_id uuid NOT NULL, work_date date NOT NULL,
 status text NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','submitted','approved','returned')),
 version integer NOT NULL DEFAULT 1, revision integer NOT NULL DEFAULT 1,
 content jsonb NOT NULL, attachments uuid[] NOT NULL DEFAULT '{}', voice_id uuid,
 submitted_at timestamptz, approved_revision integer, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(organization_id,site_id,employee_id,work_date), UNIQUE(organization_id,site_id,id),
 FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id),
 FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id),
 FOREIGN KEY(organization_id,user_id) REFERENCES auth.users(organization_id,id)
);
CREATE INDEX dwr_report_scope ON app.dwr_reports(organization_id,site_id,work_date DESC,id);
CREATE TABLE app.dwr_history (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 report_id uuid NOT NULL, version integer NOT NULL, revision integer NOT NULL, actor_id uuid NOT NULL,
 event text NOT NULL, reason text NOT NULL DEFAULT '', content jsonb NOT NULL, attachments uuid[] NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(report_id,version),
 FOREIGN KEY(organization_id,site_id,report_id) REFERENCES app.dwr_reports(organization_id,site_id,id),
 FOREIGN KEY(organization_id,actor_id) REFERENCES auth.users(organization_id,id)
);
CREATE TABLE app.dwr_receipts (
 organization_id uuid NOT NULL, site_id uuid NOT NULL, actor_id uuid NOT NULL, client_id uuid NOT NULL,
 digest text NOT NULL, result jsonb NOT NULL, created_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(organization_id,actor_id,client_id),
 FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id),
 FOREIGN KEY(organization_id,actor_id) REFERENCES auth.users(organization_id,id)
);
CREATE TABLE app.dwr_settings (
 organization_id uuid NOT NULL, site_id uuid NOT NULL, version integer NOT NULL DEFAULT 1,
 deadline time NOT NULL, deadline_day_offset integer NOT NULL CHECK(deadline_day_offset BETWEEN 0 AND 1),
 reminder_minutes integer NOT NULL CHECK(reminder_minutes BETWEEN 0 AND 1440),
 amendments boolean NOT NULL, offline_drafts boolean NOT NULL DEFAULT false, reason text NOT NULL,
 PRIMARY KEY(organization_id,site_id), FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id)
);
CREATE TABLE app.dwr_voice (
 id uuid PRIMARY KEY, organization_id uuid NOT NULL, site_id uuid NOT NULL, employee_id uuid NOT NULL, user_id uuid NOT NULL,
 work_date date NOT NULL, content_hash text NOT NULL, object_key text NOT NULL, seconds numeric NOT NULL,
 status text NOT NULL DEFAULT 'uploaded', transcript text, draft jsonb, error_code text,
 transcribe_ms integer, structure_ms integer, created_at timestamptz NOT NULL DEFAULT now(),
 expires_at timestamptz NOT NULL, lease_until timestamptz, lease_token uuid, retry_at timestamptz,
 attempts integer NOT NULL DEFAULT 0, provenance jsonb NOT NULL DEFAULT '{}', deleted_at timestamptz,
 UNIQUE(organization_id,site_id,id),
 FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id),
 FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id),
 FOREIGN KEY(organization_id,user_id) REFERENCES auth.users(organization_id,id)
);
CREATE INDEX dwr_voice_cleanup ON app.dwr_voice(expires_at) WHERE deleted_at IS NULL;
CREATE TABLE app.dwr_usage (
 organization_id uuid NOT NULL, actor_id uuid NOT NULL, day date NOT NULL, calls integer NOT NULL DEFAULT 0,
 seconds integer NOT NULL DEFAULT 0, PRIMARY KEY(organization_id,actor_id,day)
);
CREATE TABLE app.dwr_reminders (
 organization_id uuid NOT NULL, site_id uuid NOT NULL, user_id uuid NOT NULL, work_date date NOT NULL,
 PRIMARY KEY(organization_id,site_id,user_id,work_date)
);
CREATE FUNCTION app.dwr_visible(report uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT EXISTS(SELECT 1 FROM app.dwr_reports r WHERE r.id=report AND r.organization_id=app.org_id()
 AND r.site_id=app.site_id() AND app.has_site(r.site_id)
 AND ((r.user_id=app.actor_id() AND app.allowed('my_dwr.view',r.employee_id))
 OR (r.status<>'draft' AND app.allowed('dwr_review.view',r.employee_id)))) $$;
REVOKE ALL ON FUNCTION app.dwr_visible(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.dwr_visible(uuid) TO hr_runtime;
ALTER TABLE app.dwr_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY dwr_read ON app.dwr_reports FOR SELECT USING(app.dwr_visible(id));
CREATE POLICY dwr_insert ON app.dwr_reports FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND user_id=app.actor_id() AND app.allowed('my_dwr.create',employee_id));
CREATE POLICY dwr_update ON app.dwr_reports FOR UPDATE USING(app.dwr_visible(id) AND
 ((user_id=app.actor_id() AND (app.allowed('my_dwr.edit',employee_id) OR app.allowed('my_dwr.submit',employee_id)))
 OR (user_id<>app.actor_id() AND (app.allowed('dwr_review.review',employee_id) OR app.allowed('dwr_review.approve',employee_id)))));
GRANT SELECT,INSERT,UPDATE ON app.dwr_reports TO hr_runtime;
ALTER TABLE app.dwr_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY dwr_read ON app.dwr_history FOR SELECT USING(app.dwr_visible(report_id));
CREATE POLICY dwr_insert ON app.dwr_history FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND actor_id=app.actor_id() AND app.dwr_visible(report_id));
GRANT SELECT,INSERT ON app.dwr_history TO hr_runtime;
ALTER TABLE app.dwr_receipts ENABLE ROW LEVEL SECURITY;
CREATE POLICY dwr_receipt ON app.dwr_receipts USING(organization_id=app.org_id() AND site_id=app.site_id() AND actor_id=app.actor_id() AND app.has_site(site_id));
GRANT SELECT,INSERT ON app.dwr_receipts TO hr_runtime;
ALTER TABLE app.dwr_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY dwr_settings_read ON app.dwr_settings FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id));
CREATE POLICY dwr_settings_write ON app.dwr_settings FOR ALL USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.allowed('site_settings.manage')) WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.allowed('site_settings.manage'));
GRANT SELECT,INSERT,UPDATE ON app.dwr_settings TO hr_runtime;
ALTER TABLE app.dwr_voice ENABLE ROW LEVEL SECURITY;
CREATE POLICY dwr_voice_owner ON app.dwr_voice USING(organization_id=app.org_id() AND site_id=app.site_id() AND user_id=app.actor_id() AND app.allowed('my_dwr.view',employee_id));
GRANT SELECT,INSERT,UPDATE ON app.dwr_voice TO hr_runtime;
ALTER TABLE app.dwr_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.dwr_reminders ENABLE ROW LEVEL SECURITY;
-- Bounded admission holds a global lock only for its short transaction, never during AI calls.
CREATE FUNCTION app.dwr_reserve(seconds_used int,user_calls int,org_calls int,user_seconds int,org_seconds int,concurrency int,rpm int) RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE mine record; total record; BEGIN
 IF NOT app.has_site(app.site_id()) OR NOT app.allowed('my_dwr.create') OR seconds_used NOT BETWEEN 0 AND 120
 OR LEAST(user_calls,org_calls,user_seconds,org_seconds,concurrency,rpm)<1 THEN RETURN false; END IF;
 PERFORM pg_advisory_xact_lock(726344);
 SELECT COALESCE(sum(calls),0) calls,COALESCE(sum(seconds),0) seconds INTO total FROM app.dwr_usage WHERE organization_id=app.org_id() AND day=current_date;
 SELECT * INTO mine FROM app.dwr_usage WHERE organization_id=app.org_id() AND actor_id=app.actor_id() AND day=current_date;
 IF total.calls>=org_calls OR total.seconds+seconds_used>org_seconds OR COALESCE(mine.calls,0)>=user_calls OR COALESCE(mine.seconds,0)+seconds_used>user_seconds
 OR (SELECT count(*) FROM app.dwr_voice WHERE lease_until>now())>=concurrency
 OR (SELECT count(*) FROM app.dwr_voice WHERE created_at>now()-interval '1 minute')>=rpm THEN RETURN false; END IF;
 INSERT INTO app.dwr_usage VALUES(app.org_id(),app.actor_id(),current_date,1,seconds_used)
 ON CONFLICT(organization_id,actor_id,day) DO UPDATE SET calls=app.dwr_usage.calls+1,seconds=app.dwr_usage.seconds+excluded.seconds;
 RETURN true;
 END $$;
REVOKE ALL ON FUNCTION app.dwr_reserve(int,int,int,int,int,int,int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.dwr_reserve(int,int,int,int,int,int,int) TO hr_runtime;
ALTER TABLE app.private_files DROP CONSTRAINT private_files_purpose_check;
ALTER TABLE app.private_files ADD CHECK(purpose IN ('attendance','task','visit','dwr'));
DROP POLICY scoped_read ON app.private_files;
CREATE POLICY scoped_read ON app.private_files FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id) AND
 (CASE WHEN purpose='dwr' THEN app.dwr_visible(parent_id)
 ELSE owner_id=app.actor_id() OR app.allowed('attendance.view',employee_id) OR app.allowed('tasks.view',employee_id) END));
-- No implicit provenance grant; employees see their own source and reviewers need a specific field grant.
INSERT INTO app.permission_catalogue(key,module_id,action) VALUES('dwr_review.field.provenance','dwr_review','field.provenance');

