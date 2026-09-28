-- Publish the final catalogue phase without changing recursive scope/dependency rules.
DO $$ DECLARE definition text; BEGIN
 SELECT pg_get_functiondef('app.policy_decision(uuid,uuid,text,uuid,jsonb)'::regprocedure) INTO definition;
 IF position('m.phase<=5' in definition)=0 THEN RAISE EXCEPTION 'Unexpected policy function; review phase publication';END IF;
 EXECUTE replace(definition,'m.phase<=5','m.phase<=6');
END $$;
CREATE TABLE app.analytics_usage (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL,site_id uuid NOT NULL,actor_id uuid NOT NULL,
 started_at timestamptz NOT NULL DEFAULT now(),finished_at timestamptz,retry_after timestamptz,
 FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id),
 FOREIGN KEY(organization_id,actor_id) REFERENCES auth.users(organization_id,id)
);
ALTER TABLE app.analytics_usage ENABLE ROW LEVEL SECURITY;
CREATE POLICY own_usage ON app.analytics_usage USING(organization_id=app.org_id() AND actor_id=app.actor_id() AND site_id=app.site_id() AND app.has_site(site_id) AND app.allowed('analytics.view'));
GRANT SELECT ON app.analytics_usage TO hr_runtime;
GRANT UPDATE(finished_at,retry_after) ON app.analytics_usage TO hr_runtime;
CREATE INDEX analytics_usage_admission ON app.analytics_usage(organization_id,started_at,actor_id);
CREATE FUNCTION app.analytics_reserve(user_limit int,org_limit int,concurrency int) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE result uuid;BEGIN
 IF NOT app.has_site(app.site_id()) OR NOT app.allowed('analytics.view') OR user_limit NOT BETWEEN 1 AND 1000 OR org_limit NOT BETWEEN 1 AND 10000 OR concurrency NOT BETWEEN 1 AND 10 THEN RETURN NULL;END IF;
 PERFORM pg_advisory_xact_lock(726346);
 IF EXISTS(SELECT 1 FROM app.analytics_usage WHERE retry_after>now())
 OR (SELECT count(*) FROM app.analytics_usage WHERE finished_at IS NULL AND started_at>now()-interval '12 seconds')>=concurrency
 OR (SELECT count(*) FROM app.analytics_usage WHERE organization_id=app.org_id() AND started_at>=date_trunc('day',now() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC')>=org_limit
 OR (SELECT count(*) FROM app.analytics_usage WHERE organization_id=app.org_id() AND actor_id=app.actor_id() AND started_at>=date_trunc('day',now() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC')>=user_limit THEN RETURN NULL;END IF;
 INSERT INTO app.analytics_usage(organization_id,site_id,actor_id) VALUES(app.org_id(),app.site_id(),app.actor_id()) RETURNING id INTO result;
 RETURN result;
END $$;
REVOKE ALL ON FUNCTION app.analytics_reserve(int,int,int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.analytics_reserve(int,int,int) TO hr_runtime;
UPDATE auth.users SET permission_version=permission_version+1;
