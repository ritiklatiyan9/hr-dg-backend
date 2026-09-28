-- Assignment/grant changes invalidate all affected actors' client scope keys.
CREATE OR REPLACE FUNCTION app.grant_changed() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
 BEGIN
 UPDATE auth.users SET permission_version=permission_version+1,
 requires_mfa=requires_mfa OR COALESCE((TG_OP <> 'DELETE' AND id=NEW.user_id AND organization_id=NEW.organization_id AND
 (NEW.role IN ('super_admin','admin','hr','jr_hr') OR NEW.capability IS NOT NULL)),false)
 WHERE (id=NEW.user_id AND organization_id=NEW.organization_id) OR (id=OLD.user_id AND organization_id=OLD.organization_id);
 RETURN COALESCE(NEW,OLD);
 END $$;
CREATE FUNCTION app.assignment_changed() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
 BEGIN
 UPDATE auth.users u SET permission_version=permission_version+1 WHERE EXISTS (
 SELECT 1 FROM app.employees e WHERE (e.organization_id,e.user_id)=(u.organization_id,u.id) AND
 ((e.id=NEW.employee_id AND e.organization_id=NEW.organization_id) OR (e.id=OLD.employee_id AND e.organization_id=OLD.organization_id)));
 RETURN COALESCE(NEW,OLD);
 END $$;
REVOKE ALL ON FUNCTION app.assignment_changed() FROM PUBLIC;
CREATE TRIGGER assignments_changed AFTER INSERT OR UPDATE OR DELETE ON app.site_assignments
 FOR EACH ROW EXECUTE FUNCTION app.assignment_changed();
