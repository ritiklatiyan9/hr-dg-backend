CREATE TABLE app.dwr_provider_calls(id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,started_at timestamptz NOT NULL DEFAULT now());
CREATE INDEX ON app.dwr_provider_calls(started_at);
ALTER TABLE app.dwr_provider_calls ENABLE ROW LEVEL SECURITY;
CREATE OR REPLACE FUNCTION app.dwr_reserve(seconds_used int,user_calls int,org_calls int,user_seconds int,org_seconds int,concurrency int,rpm int) RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE mine record; total record; BEGIN
 IF NOT app.has_site(app.site_id()) OR NOT app.allowed('my_dwr.create') OR seconds_used NOT BETWEEN 0 AND 120
 OR LEAST(user_calls,org_calls,user_seconds,org_seconds,concurrency,rpm)<1 THEN RETURN false; END IF;
 PERFORM pg_advisory_xact_lock(726344);
 SELECT COALESCE(sum(calls),0) calls,COALESCE(sum(seconds),0) seconds INTO total FROM app.dwr_usage WHERE organization_id=app.org_id() AND day=current_date;
 SELECT * INTO mine FROM app.dwr_usage WHERE organization_id=app.org_id() AND actor_id=app.actor_id() AND day=current_date;
 IF total.calls>=org_calls OR total.seconds+seconds_used>org_seconds OR COALESCE(mine.calls,0)>=user_calls OR COALESCE(mine.seconds,0)+seconds_used>user_seconds
 OR (SELECT count(*) FROM app.dwr_voice WHERE lease_until>now())>=concurrency
 OR (SELECT count(*) FROM app.dwr_provider_calls WHERE started_at>now()-interval '1 minute')>=rpm THEN RETURN false; END IF;
 INSERT INTO app.dwr_usage VALUES(app.org_id(),app.actor_id(),current_date,1,seconds_used)
 ON CONFLICT(organization_id,actor_id,day) DO UPDATE SET calls=app.dwr_usage.calls+1,seconds=app.dwr_usage.seconds+excluded.seconds;
 INSERT INTO app.dwr_provider_calls DEFAULT VALUES;
 DELETE FROM app.dwr_provider_calls WHERE started_at<now()-interval '1 day';
 RETURN true;
 END $$;
REVOKE ALL ON FUNCTION app.dwr_reserve(int,int,int,int,int,int,int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.dwr_reserve(int,int,int,int,int,int,int) TO hr_runtime;

CREATE FUNCTION app.dwr_provenance(report uuid) RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT jsonb_build_object('versions',v.provenance,'generatedDraft',v.draft)
 FROM app.dwr_reports r JOIN app.dwr_voice v ON (v.organization_id,v.site_id,v.id)=(r.organization_id,r.site_id,r.voice_id)
 WHERE r.id=report AND r.organization_id=app.org_id() AND r.site_id=app.site_id() AND app.dwr_visible(r.id)
 AND (r.user_id=app.actor_id() OR app.allowed('dwr_review.field.provenance',r.employee_id)) $$;
REVOKE ALL ON FUNCTION app.dwr_provenance(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.dwr_provenance(uuid) TO hr_runtime;

