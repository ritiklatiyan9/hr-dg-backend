-- Additive Phase 2 policy. Existing authentication and Phase 1 grants remain authoritative.
CREATE TABLE app.organization_memberships (
 organization_id uuid NOT NULL,user_id uuid NOT NULL,active boolean NOT NULL DEFAULT true,
 PRIMARY KEY(organization_id,user_id),FOREIGN KEY(organization_id,user_id) REFERENCES auth.users(organization_id,id));
CREATE TABLE app.site_memberships (
 organization_id uuid NOT NULL,site_id uuid NOT NULL,user_id uuid NOT NULL,active boolean NOT NULL DEFAULT true,
 PRIMARY KEY(organization_id,site_id,user_id),
 FOREIGN KEY(organization_id,user_id) REFERENCES auth.users(organization_id,id),FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id));
INSERT INTO app.organization_memberships SELECT organization_id,id,true FROM auth.users;
INSERT INTO app.site_memberships SELECT DISTINCT organization_id,site_id,user_id,true FROM app.access_grants;
INSERT INTO app.site_memberships SELECT DISTINCT a.organization_id,a.site_id,e.user_id,true FROM app.site_assignments a JOIN app.employees e ON (e.organization_id,e.id)=(a.organization_id,a.employee_id) WHERE e.user_id IS NOT NULL ON CONFLICT DO NOTHING;
CREATE TABLE app.access_overrides (
 organization_id uuid NOT NULL,site_id uuid NOT NULL,user_id uuid NOT NULL,key text NOT NULL REFERENCES app.permission_catalogue(key),
 effect text NOT NULL CHECK(effect IN ('allow','deny')),scope text NOT NULL CHECK(scope IN ('own','team','site','organization')),
 PRIMARY KEY(organization_id,site_id,user_id,key),FOREIGN KEY(organization_id,site_id,user_id) REFERENCES app.site_memberships(organization_id,site_id,user_id));
CREATE TABLE app.access_delegations (
 organization_id uuid NOT NULL,site_id uuid NOT NULL,user_id uuid NOT NULL,key text NOT NULL REFERENCES app.permission_catalogue(key),
 scope text NOT NULL CHECK(scope IN ('own','team','site')),
 PRIMARY KEY(organization_id,site_id,user_id,key),FOREIGN KEY(organization_id,site_id,user_id) REFERENCES app.site_memberships(organization_id,site_id,user_id));
CREATE TABLE app.site_modules (
 organization_id uuid NOT NULL,site_id uuid NOT NULL,module_id text NOT NULL REFERENCES app.module_catalogue(id),enabled boolean NOT NULL DEFAULT true,
 PRIMARY KEY(organization_id,site_id,module_id),FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id));
CREATE TABLE app.team_assignments (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL,site_id uuid NOT NULL,manager_id uuid NOT NULL,employee_id uuid NOT NULL,
 starts_on date NOT NULL,ends_on date CHECK(ends_on>=starts_on),
 FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id),FOREIGN KEY(organization_id,manager_id) REFERENCES auth.users(organization_id,id),FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id));
CREATE INDEX ON app.team_assignments(organization_id,site_id,manager_id,employee_id);
CREATE FUNCTION app.scope_rank(s text) RETURNS int LANGUAGE sql IMMUTABLE AS $$ SELECT CASE s WHEN 'own' THEN 1 WHEN 'team' THEN 2 WHEN 'site' THEN 3 WHEN 'organization' THEN 4 ELSE 0 END $$;
CREATE FUNCTION app.is_super_admin(target uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT EXISTS(SELECT 1 FROM auth.users u JOIN app.organization_memberships m ON (m.organization_id,m.user_id)=(u.organization_id,u.id)
 JOIN app.access_grants g ON (g.organization_id,g.user_id)=(u.organization_id,u.id)
 JOIN app.site_memberships sm ON (sm.organization_id,sm.site_id,sm.user_id)=(g.organization_id,g.site_id,g.user_id)
 WHERE u.id=target AND u.organization_id=app.org_id() AND u.active AND m.active AND sm.active AND g.role='super_admin') $$;
CREATE OR REPLACE FUNCTION app.has_site(target uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT EXISTS(SELECT 1 FROM app.organization_memberships m JOIN auth.users u ON (u.organization_id,u.id)=(m.organization_id,m.user_id)
 JOIN app.site_memberships s ON (s.organization_id,s.user_id)=(m.organization_id,m.user_id)
 WHERE m.organization_id=app.org_id() AND m.user_id=app.actor_id() AND m.active AND u.active AND s.site_id=target AND s.active) $$;
-- Only current actor may check/lock their version; business requests hold this shared lock until commit.
CREATE FUNCTION app.check_access_version(expected int) RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE v int; BEGIN SELECT u.permission_version INTO v FROM auth.users u JOIN app.organization_memberships m ON (m.organization_id,m.user_id)=(u.organization_id,u.id)
 WHERE u.organization_id=app.org_id() AND u.id=app.actor_id() AND u.active AND m.active FOR SHARE OF u;
 RETURN v IS NOT NULL AND v=expected; END $$;
-- Pure decision for current policy or a complete proposed per-site snapshot. Internal only.
CREATE FUNCTION app.policy_rule(target uuid, selected uuid, permission text, proposed jsonb DEFAULT NULL) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE m text; a text; r record; role_name text; override_rule jsonb; is_active boolean;
 BEGIN
 SELECT module_id,action INTO m,a FROM app.permission_catalogue WHERE key=permission;
 IF m IS NULL THEN RETURN jsonb_build_object('allowed',false,'scope','own','rule','unknown_permission'); END IF;
 IF NOT EXISTS(SELECT 1 FROM auth.users u JOIN app.organization_memberships om ON (om.organization_id,om.user_id)=(u.organization_id,u.id) WHERE u.organization_id=app.org_id() AND u.id=target AND u.active AND om.active) THEN
 RETURN jsonb_build_object('allowed',false,'scope','own','rule','inactive_membership'); END IF;
 SELECT active INTO is_active FROM app.site_memberships WHERE organization_id=app.org_id() AND site_id=selected AND user_id=target;
 IF proposed IS NOT NULL THEN is_active := COALESCE((proposed->>'active')::boolean,false); END IF;
 IF NOT COALESCE(is_active,false) THEN RETURN jsonb_build_object('allowed',false,'scope','own','rule','unauthorized_site'); END IF;
 IF EXISTS(SELECT 1 FROM app.site_modules WHERE organization_id=app.org_id() AND site_id=selected AND module_id=m AND NOT enabled) THEN
 RETURN jsonb_build_object('allowed',false,'scope','own','rule','module_disabled'); END IF;
 IF proposed IS NULL THEN SELECT jsonb_build_object('effect',effect,'scope',scope) INTO override_rule FROM app.access_overrides WHERE organization_id=app.org_id() AND site_id=selected AND user_id=target AND key=permission;
 ELSE SELECT value INTO override_rule FROM jsonb_array_elements(proposed->'rules') WHERE value->>'key'=permission; END IF;
 IF override_rule->>'effect'='deny' THEN RETURN jsonb_build_object('allowed',false,'scope',override_rule->>'scope','rule','explicit_deny'); END IF;
 IF override_rule->>'effect'='allow' THEN RETURN jsonb_build_object('allowed',true,'scope',override_rule->>'scope','rule','user_site_allow'); END IF;
 IF proposed IS NOT NULL THEN
 SELECT t.role,t.scope INTO r FROM app.role_templates t WHERE t.role=proposed->>'role' AND t.key=permission;
 ELSE SELECT t.role,t.scope INTO r FROM app.role_templates t JOIN app.access_grants g ON g.role=t.role
 WHERE g.organization_id=app.org_id() AND g.user_id=target AND g.site_id=selected AND t.key=permission ORDER BY app.scope_rank(t.scope) DESC,t.role LIMIT 1;
 END IF;
 IF r.scope IS NOT NULL THEN RETURN jsonb_build_object('allowed',true,'scope',r.scope,'rule','template:'||r.role); END IF;
 -- Explicit Phase 1 grants migrate without acquiring unrelated authority.
 IF proposed IS NULL AND EXISTS(SELECT 1 FROM app.access_grants g WHERE g.organization_id=app.org_id() AND g.user_id=target AND g.site_id=selected AND
 (g.capability=permission OR (g.capability='employees.read' AND permission='employees.view') OR (g.capability='employees.write' AND permission='employees.edit'))) THEN
 RETURN jsonb_build_object('allowed',true,'scope','site','rule','legacy_explicit_grant'); END IF;
 RETURN jsonb_build_object('allowed',false,'scope','own','rule','no_allow');
 END $$;
CREATE FUNCTION app.policy_decision(target uuid,selected uuid,permission text,record_id uuid DEFAULT NULL,proposed jsonb DEFAULT NULL) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 DECLARE d jsonb; dep jsonb; m record; needed text; dt date;
 BEGIN
 d:=app.policy_rule(target,selected,permission,proposed);
 IF NOT (d->>'allowed')::boolean THEN RETURN d; END IF;
 SELECT mc.*,pc.action INTO m FROM app.permission_catalogue pc JOIN app.module_catalogue mc ON mc.id=pc.module_id WHERE pc.key=permission;
 IF m.action<>'view' THEN
 dep:=app.policy_rule(target,selected,m.id||'.view',proposed);
 IF NOT (dep->>'allowed')::boolean OR app.scope_rank(dep->>'scope')<app.scope_rank(d->>'scope') THEN RETURN jsonb_build_object('allowed',false,'scope',d->>'scope','rule','dependency:'||m.id||'.view'); END IF;
 END IF;
 FOREACH needed IN ARRAY m.dependencies LOOP
 dep:=app.policy_rule(target,selected,needed,proposed);
 IF NOT (dep->>'allowed')::boolean THEN RETURN jsonb_build_object('allowed',false,'scope',d->>'scope','rule','dependency:'||needed); END IF;
 END LOOP;
 IF d->>'scope'='organization' AND (m.id NOT IN ('reports','analytics') OR m.action NOT IN ('view','export') OR d->>'rule'<>'user_site_allow') THEN
 RETURN jsonb_build_object('allowed',false,'scope','organization','rule','organization_reporting_only'); END IF;
 IF record_id IS NOT NULL THEN
 SELECT (now() AT TIME ZONE timezone)::date INTO dt FROM app.sites WHERE id=selected AND organization_id=app.org_id();
 IF NOT EXISTS(SELECT 1 FROM app.site_assignments WHERE organization_id=app.org_id() AND site_id=selected AND employee_id=record_id AND starts_on<=dt AND (ends_on IS NULL OR ends_on>=dt)) THEN
 RETURN jsonb_build_object('allowed',false,'scope',d->>'scope','rule','record_outside_site'); END IF;
 IF d->>'scope'='own' AND NOT EXISTS(SELECT 1 FROM app.employees WHERE organization_id=app.org_id() AND id=record_id AND user_id=target) THEN RETURN jsonb_build_object('allowed',false,'scope','own','rule','record_not_own'); END IF;
 IF d->>'scope'='team' AND NOT EXISTS(SELECT 1 FROM app.team_assignments WHERE organization_id=app.org_id() AND site_id=selected AND manager_id=target AND employee_id=record_id AND starts_on<=dt AND (ends_on IS NULL OR ends_on>=dt)) THEN RETURN jsonb_build_object('allowed',false,'scope','team','rule','record_outside_team'); END IF;
 END IF;
 RETURN d || jsonb_build_object('available',m.phase<=2);
 END $$;
CREATE FUNCTION app.decision(permission text,record_id uuid DEFAULT NULL) RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$ SELECT app.policy_decision(app.actor_id(),app.site_id(),permission,record_id) $$;
CREATE FUNCTION app.allowed(permission text,record_id uuid DEFAULT NULL) RETURNS boolean LANGUAGE sql STABLE AS $$ SELECT COALESCE((app.decision(permission,record_id)->>'allowed')::boolean,false) $$;
CREATE OR REPLACE FUNCTION app.can(cap text) RETURNS boolean LANGUAGE sql STABLE AS $$
 SELECT CASE cap WHEN 'employees.read' THEN app.allowed('employees.view') WHEN 'employees.write' THEN app.allowed('employees.edit') WHEN 'profile.write' THEN false WHEN 'hr.access' THEN app.allowed('employees.view') OR app.allowed('access.view') WHEN 'invitations.send' THEN app.allowed('employees.create') WHEN 'audit.read' THEN app.allowed('audit.view') ELSE app.allowed(cap) END $$;
CREATE OR REPLACE FUNCTION app.visible_employee(target uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT app.has_site(app.site_id()) AND (app.allowed('employees.view',target) OR app.allowed('my_hr.view',target)) $$;
-- Membership synchronization only creates missing memberships; never reactivates a disabled membership.
CREATE FUNCTION app.sync_membership() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
 BEGIN
 INSERT INTO app.organization_memberships(organization_id,user_id) VALUES(NEW.organization_id,NEW.user_id) ON CONFLICT DO NOTHING;
 INSERT INTO app.site_memberships(organization_id,site_id,user_id) VALUES(NEW.organization_id,NEW.site_id,NEW.user_id) ON CONFLICT DO NOTHING;
 RETURN NEW; END $$;
CREATE TRIGGER access_membership AFTER INSERT ON app.access_grants FOR EACH ROW EXECUTE FUNCTION app.sync_membership();
CREATE FUNCTION app.new_user_membership() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$ BEGIN INSERT INTO app.organization_memberships(organization_id,user_id) VALUES(NEW.organization_id,NEW.id); RETURN NEW; END $$;
CREATE TRIGGER user_membership AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION app.new_user_membership();
CREATE FUNCTION app.bump_access() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
 BEGIN UPDATE auth.users SET permission_version=permission_version+1 WHERE organization_id=COALESCE(NEW.organization_id,OLD.organization_id) AND id=COALESCE(NEW.user_id,OLD.user_id); RETURN COALESCE(NEW,OLD); END $$;
CREATE TRIGGER membership_version AFTER UPDATE ON app.organization_memberships FOR EACH ROW EXECUTE FUNCTION app.bump_access();
CREATE TRIGGER site_membership_version AFTER UPDATE ON app.site_memberships FOR EACH ROW EXECUTE FUNCTION app.bump_access();
CREATE TRIGGER override_version AFTER INSERT OR UPDATE OR DELETE ON app.access_overrides FOR EACH ROW EXECUTE FUNCTION app.bump_access();
CREATE TRIGGER delegation_version AFTER INSERT OR UPDATE OR DELETE ON app.access_delegations FOR EACH ROW EXECUTE FUNCTION app.bump_access();
CREATE FUNCTION app.team_changed() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$ BEGIN
 UPDATE auth.users SET permission_version=permission_version+1 WHERE organization_id=COALESCE(NEW.organization_id,OLD.organization_id) AND id IN (NEW.manager_id,OLD.manager_id); RETURN COALESCE(NEW,OLD); END $$;
CREATE TRIGGER team_version AFTER INSERT OR UPDATE OR DELETE ON app.team_assignments FOR EACH ROW EXECUTE FUNCTION app.team_changed();
CREATE FUNCTION app.module_changed() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$ BEGIN
 UPDATE auth.users u SET permission_version=permission_version+1 WHERE u.organization_id=COALESCE(NEW.organization_id,OLD.organization_id) AND EXISTS(SELECT 1 FROM app.site_memberships s WHERE (s.organization_id,s.user_id)=(u.organization_id,u.id) AND s.site_id=COALESCE(NEW.site_id,OLD.site_id)); RETURN COALESCE(NEW,OLD); END $$;
CREATE TRIGGER module_version AFTER INSERT OR UPDATE OR DELETE ON app.site_modules FOR EACH ROW EXECUTE FUNCTION app.module_changed();
-- All policy tables are read-only for runtime. Writes go through the bounded administration function.
ALTER TABLE app.organization_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.site_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.access_overrides ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.access_delegations ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.site_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.team_assignments ENABLE ROW LEVEL SECURITY;
CREATE POLICY membership_read ON app.organization_memberships FOR SELECT USING(organization_id=app.org_id() AND user_id=app.actor_id());
CREATE POLICY site_membership_read ON app.site_memberships FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND (user_id=app.actor_id() OR app.allowed('access.view')));
CREATE POLICY overrides_read ON app.access_overrides FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND (user_id=app.actor_id() OR app.allowed('access.view')));
CREATE POLICY delegations_read ON app.access_delegations FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND (user_id=app.actor_id() OR app.allowed('access.view')));
CREATE POLICY modules_read ON app.site_modules FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id));
CREATE POLICY team_read ON app.team_assignments FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.visible_employee(employee_id));
GRANT SELECT ON app.module_catalogue,app.permission_catalogue,app.role_templates,app.organization_memberships,app.site_memberships,app.access_overrides,app.access_delegations,app.site_modules,app.team_assignments TO hr_runtime;
REVOKE ALL ON FUNCTION app.policy_rule(uuid,uuid,text,jsonb),app.policy_decision(uuid,uuid,text,uuid,jsonb),app.is_super_admin(uuid),app.sync_membership(),app.new_user_membership(),app.bump_access(),app.team_changed(),app.module_changed() FROM PUBLIC;
REVOKE ALL ON FUNCTION app.check_access_version(int),app.decision(text,uuid),app.allowed(text,uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.check_access_version(int),app.decision(text,uuid),app.allowed(text,uuid) TO hr_runtime;
