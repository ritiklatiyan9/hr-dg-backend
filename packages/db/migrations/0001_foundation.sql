-- Additive foundation. Run only as the migration owner; never as runtime.
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE SCHEMA app;
CREATE SCHEMA auth;
REVOKE ALL ON SCHEMA public FROM PUBLIC;

CREATE TABLE app.organizations (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name text NOT NULL, slug text UNIQUE NOT NULL
);
CREATE TABLE auth.users (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL REFERENCES app.organizations,
 email text NOT NULL CHECK (email=lower(email)), password_hash text,
 active boolean NOT NULL DEFAULT true, requires_mfa boolean NOT NULL DEFAULT false,
 mfa_secret text, mfa_enabled boolean NOT NULL DEFAULT false, last_totp_step bigint NOT NULL DEFAULT -1,
 permission_version integer NOT NULL DEFAULT 1, created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE (organization_id,id), UNIQUE (organization_id,email)
);
CREATE TABLE app.legal_employers (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL REFERENCES app.organizations,
 name text NOT NULL, UNIQUE (organization_id,id)
);
CREATE TABLE app.sites (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL REFERENCES app.organizations,
 name text NOT NULL, timezone text NOT NULL DEFAULT 'Asia/Kolkata',
 geofence geography(MultiPolygon,4326), UNIQUE (organization_id,id)
);
CREATE TABLE app.employees (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL REFERENCES app.organizations,
 user_id uuid, employee_code text NOT NULL, display_name text NOT NULL,
 work_email text NOT NULL, phone text NOT NULL DEFAULT '', job_title text NOT NULL DEFAULT '',
 department text NOT NULL DEFAULT '', version integer NOT NULL DEFAULT 1,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE (organization_id,id), UNIQUE (organization_id,employee_code), UNIQUE (organization_id,user_id),
 FOREIGN KEY (organization_id,user_id) REFERENCES auth.users(organization_id,id)
);
CREATE TABLE app.employment_records (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL,
 employee_id uuid NOT NULL, legal_employer_id uuid NOT NULL,
 starts_on date NOT NULL, ends_on date CHECK (ends_on IS NULL OR ends_on >= starts_on),
 FOREIGN KEY (organization_id,employee_id) REFERENCES app.employees(organization_id,id),
 FOREIGN KEY (organization_id,legal_employer_id) REFERENCES app.legal_employers(organization_id,id)
);
CREATE TABLE app.site_assignments (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL,
 site_id uuid NOT NULL, employee_id uuid NOT NULL,
 starts_on date NOT NULL, ends_on date CHECK (ends_on IS NULL OR ends_on >= starts_on),
 UNIQUE (organization_id,site_id,employee_id,starts_on),
 FOREIGN KEY (organization_id,site_id) REFERENCES app.sites(organization_id,id),
 FOREIGN KEY (organization_id,employee_id) REFERENCES app.employees(organization_id,id)
);
CREATE INDEX assignments_scope ON app.site_assignments(organization_id,site_id,employee_id);
CREATE TABLE app.role_capabilities (
 role text NOT NULL CHECK (role IN ('super_admin','admin','hr','jr_hr','employee','supervisor','manager')),
 capability text NOT NULL, PRIMARY KEY (role,capability)
);
INSERT INTO app.role_capabilities SELECT r,c FROM
 unnest(ARRAY['super_admin','admin','hr']) r CROSS JOIN
 unnest(ARRAY['employees.read','employees.write','profile.write','hr.access','invitations.send','audit.read']) c;
INSERT INTO app.role_capabilities VALUES
 ('jr_hr','employees.read'),('jr_hr','hr.access'),('jr_hr','profile.write'),
 ('employee','profile.write'),('supervisor','profile.write'),('manager','profile.write');
CREATE TABLE app.access_grants (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL,
 user_id uuid NOT NULL, site_id uuid NOT NULL, role text,
 capability text, CHECK ((role IS NULL) <> (capability IS NULL)),
 CHECK (role IS NULL OR role IN ('super_admin','admin','hr','jr_hr','employee','supervisor','manager')),
 FOREIGN KEY (organization_id,user_id) REFERENCES auth.users(organization_id,id),
 FOREIGN KEY (organization_id,site_id) REFERENCES app.sites(organization_id,id)
);
CREATE INDEX grants_scope ON app.access_grants(organization_id,user_id,site_id);
CREATE TABLE auth.devices (
 id uuid PRIMARY KEY, organization_id uuid NOT NULL, user_id uuid NOT NULL,
 label text NOT NULL, last_seen_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE (organization_id,user_id,id),
 FOREIGN KEY (organization_id,user_id) REFERENCES auth.users(organization_id,id)
);
CREATE TABLE auth.sessions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, user_id uuid NOT NULL,
 kind text NOT NULL CHECK (kind IN ('web','mobile')), access_hash text UNIQUE NOT NULL, csrf_hash text NOT NULL,
 refresh_hash text UNIQUE, device_id uuid, mfa_verified boolean NOT NULL DEFAULT false,
 expires_at timestamptz NOT NULL, absolute_expires_at timestamptz NOT NULL,
 revoked_at timestamptz, created_at timestamptz NOT NULL DEFAULT now(),
 FOREIGN KEY (organization_id,user_id) REFERENCES auth.users(organization_id,id),
 FOREIGN KEY (organization_id,user_id,device_id) REFERENCES auth.devices(organization_id,user_id,id)
);
CREATE TABLE auth.refresh_history (
 token_hash text PRIMARY KEY, session_id uuid NOT NULL REFERENCES auth.sessions, used_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE auth.action_tokens (
 token_hash text PRIMARY KEY, organization_id uuid NOT NULL, user_id uuid NOT NULL,
 purpose text NOT NULL CHECK (purpose IN ('recovery','invitation')),
 expires_at timestamptz NOT NULL, used_at timestamptz,
 FOREIGN KEY (organization_id,user_id) REFERENCES auth.users(organization_id,id)
);
CREATE TABLE auth.events (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, organization_id uuid, user_id uuid,
 action text NOT NULL, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE auth.mail_outbox (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), encrypted_payload text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), sent_at timestamptz, attempts integer NOT NULL DEFAULT 0
);
CREATE TABLE app.audit_records (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 actor_id uuid NOT NULL, action text NOT NULL, entity_id uuid NOT NULL,
 metadata jsonb NOT NULL DEFAULT '{}', created_at timestamptz NOT NULL DEFAULT now(),
 FOREIGN KEY (organization_id,site_id) REFERENCES app.sites(organization_id,id),
 FOREIGN KEY (organization_id,actor_id) REFERENCES auth.users(organization_id,id)
);
CREATE TABLE app.outbox (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL, site_id uuid NOT NULL,
 event_type text NOT NULL, payload jsonb NOT NULL, created_at timestamptz NOT NULL DEFAULT now(), published_at timestamptz,
 FOREIGN KEY (organization_id,site_id) REFERENCES app.sites(organization_id,id)
);

CREATE FUNCTION app.org_id() RETURNS uuid LANGUAGE sql STABLE AS
 $$ SELECT nullif(current_setting('app.organization_id',true),'')::uuid $$;
CREATE FUNCTION app.actor_id() RETURNS uuid LANGUAGE sql STABLE AS
 $$ SELECT nullif(current_setting('app.actor_id',true),'')::uuid $$;
CREATE FUNCTION app.site_id() RETURNS uuid LANGUAGE sql STABLE AS
 $$ SELECT nullif(current_setting('app.site_id',true),'')::uuid $$;

-- SECURITY DEFINER helpers return booleans, not records. Fixed search_path and
-- explicit tenant predicates prevent recursive policies and cross-tenant access.
CREATE FUNCTION app.has_site(target uuid) RETURNS boolean
 LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT EXISTS (SELECT 1 FROM app.access_grants g WHERE g.organization_id=app.org_id()
   AND g.user_id=app.actor_id() AND g.site_id=target)
 OR EXISTS (SELECT 1 FROM app.site_assignments a JOIN app.employees e
 ON (e.organization_id,e.id)=(a.organization_id,a.employee_id)
 JOIN app.sites s ON (s.organization_id,s.id)=(a.organization_id,a.site_id)
 WHERE a.organization_id=app.org_id() AND e.user_id=app.actor_id() AND a.site_id=target
 AND (now() AT TIME ZONE s.timezone)::date BETWEEN a.starts_on AND COALESCE(a.ends_on,'infinity'::date)) $$;
CREATE FUNCTION app.can(cap text) RETURNS boolean
 LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT EXISTS (SELECT 1 FROM app.access_grants g LEFT JOIN app.role_capabilities rc ON rc.role=g.role
 WHERE g.organization_id=app.org_id() AND g.user_id=app.actor_id() AND g.site_id=app.site_id()
 AND (g.capability=cap OR rc.capability=cap)) $$;
CREATE FUNCTION app.visible_employee(target uuid) RETURNS boolean
 LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT app.has_site(app.site_id()) AND EXISTS (
 SELECT 1 FROM app.employees e JOIN app.site_assignments a
 ON (a.organization_id,a.employee_id)=(e.organization_id,e.id)
 JOIN app.sites s ON (s.organization_id,s.id)=(a.organization_id,a.site_id)
 WHERE e.organization_id=app.org_id() AND e.id=target AND a.site_id=app.site_id()
 AND (now() AT TIME ZONE s.timezone)::date BETWEEN a.starts_on AND COALESCE(a.ends_on,'infinity'::date)
 AND (e.user_id=app.actor_id() OR app.can('employees.read'))) $$;
CREATE FUNCTION app.grant_changed() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
 BEGIN
 UPDATE auth.users SET permission_version=permission_version+1,
 requires_mfa=requires_mfa OR (TG_OP <> 'DELETE' AND
 (NEW.role IN ('super_admin','admin','hr','jr_hr') OR NEW.capability IS NOT NULL))
 WHERE id=COALESCE(NEW.user_id,OLD.user_id) AND organization_id=COALESCE(NEW.organization_id,OLD.organization_id);
 RETURN COALESCE(NEW,OLD);
 END $$;
CREATE TRIGGER grants_changed AFTER INSERT OR UPDATE OR DELETE ON app.access_grants
 FOR EACH ROW EXECUTE FUNCTION app.grant_changed();

ALTER TABLE app.organizations ENABLE ROW LEVEL SECURITY;
CREATE POLICY organizations_scope ON app.organizations FOR SELECT USING(id=app.org_id());
ALTER TABLE app.sites ENABLE ROW LEVEL SECURITY;
CREATE POLICY sites_scope ON app.sites FOR SELECT USING(organization_id=app.org_id() AND app.has_site(id));
ALTER TABLE app.employees ENABLE ROW LEVEL SECURITY;
CREATE POLICY employees_read ON app.employees FOR SELECT USING(organization_id=app.org_id() AND app.visible_employee(id));
CREATE POLICY employees_update ON app.employees FOR UPDATE
 USING(organization_id=app.org_id() AND app.visible_employee(id) AND (app.can('employees.write') OR (user_id=app.actor_id() AND app.can('profile.write'))))
 WITH CHECK(organization_id=app.org_id() AND app.visible_employee(id));
ALTER TABLE app.site_assignments ENABLE ROW LEVEL SECURITY;
CREATE POLICY assignments_read ON app.site_assignments FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.visible_employee(employee_id));
ALTER TABLE app.employment_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY employment_read ON app.employment_records FOR SELECT USING(organization_id=app.org_id() AND app.visible_employee(employee_id));
ALTER TABLE app.legal_employers ENABLE ROW LEVEL SECURITY;
CREATE POLICY employers_read ON app.legal_employers FOR SELECT USING(organization_id=app.org_id() AND EXISTS
 (SELECT 1 FROM app.employment_records e WHERE e.legal_employer_id=app.legal_employers.id));
ALTER TABLE app.access_grants ENABLE ROW LEVEL SECURITY;
CREATE POLICY grants_read ON app.access_grants FOR SELECT USING(organization_id=app.org_id() AND user_id=app.actor_id() AND site_id=app.site_id());
ALTER TABLE app.audit_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY audit_read ON app.audit_records FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.can('audit.read'));
CREATE POLICY audit_insert ON app.audit_records FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND actor_id=app.actor_id() AND app.has_site(site_id));
ALTER TABLE app.outbox ENABLE ROW LEVEL SECURITY;
CREATE POLICY outbox_insert ON app.outbox FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id));

-- Roles are provisioned separately, with generated passwords; no production defaults.
GRANT USAGE ON SCHEMA app TO hr_runtime;
GRANT SELECT ON app.organizations,app.sites,app.employees,app.employment_records,app.site_assignments,app.legal_employers,app.access_grants,app.role_capabilities,app.audit_records TO hr_runtime;
GRANT UPDATE(phone,version,updated_at) ON app.employees TO hr_runtime;
GRANT INSERT ON app.audit_records,app.outbox TO hr_runtime;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA app FROM PUBLIC;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA app TO hr_runtime;
REVOKE EXECUTE ON FUNCTION app.grant_changed() FROM hr_runtime;
GRANT USAGE ON SCHEMA auth TO hr_auth;
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA auth TO hr_auth;
REVOKE UPDATE,DELETE ON auth.events FROM hr_auth;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA auth TO hr_auth;
-- Worker intentionally has only queue delivery privileges, no employee access.
GRANT USAGE ON SCHEMA auth,app TO hr_worker;
GRANT SELECT,UPDATE ON auth.mail_outbox,app.outbox TO hr_worker;
CREATE POLICY outbox_worker ON app.outbox TO hr_worker USING(true) WITH CHECK(true);
