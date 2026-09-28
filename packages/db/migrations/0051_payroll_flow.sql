-- Payroll flow requested by the business (2026-09-26): HR prepares salaries and
-- pay runs and sends them for approval; Admin and Super Admin give the final
-- approval, publish payslips and record payments. Maker-checker stays enforced:
-- the approver can never be the creator or the employee being paid.
INSERT INTO app.role_templates(role,key,scope)
SELECT r,k,'site' FROM unnest(ARRAY['super_admin','admin']) r
CROSS JOIN unnest(ARRAY['payroll.view','payroll.create','payroll.edit','payroll.review','payroll.approve','payroll.export','payroll.manage','payroll.field.salary','payroll.field.bank']) k
ON CONFLICT(role,key) DO NOTHING;
INSERT INTO app.role_templates(role,key,scope)
SELECT 'hr',k,'site' FROM unnest(ARRAY['payroll.view','payroll.create','payroll.edit','payroll.export','payroll.field.salary']) k
ON CONFLICT(role,key) DO NOTHING;

-- "Send for approval" is draft -> validated; an approver may now approve it
-- directly. The optional independent review step (validated -> reviewed) stays.
CREATE OR REPLACE FUNCTION app.payroll_guard() RETURNS trigger LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN
 IF NEW.organization_id<>OLD.organization_id OR NEW.site_id<>OLD.site_id OR NEW.employment_id<>OLD.employment_id OR NEW.employee_id<>OLD.employee_id OR NEW.user_id<>OLD.user_id OR NEW.legal_employer_id<>OLD.legal_employer_id OR NEW.period_start<>OLD.period_start OR NEW.period_end<>OLD.period_end OR NEW.revision<>OLD.revision OR NEW.previous_id IS DISTINCT FROM OLD.previous_id OR NEW.created_by<>OLD.created_by OR NEW.version<>OLD.version+1 THEN RAISE EXCEPTION 'CONFLICT'; END IF;
 IF OLD.status='published' OR (OLD.status='approved' AND (NEW.status<>'published' OR (to_jsonb(NEW)-ARRAY['status','version','published_at','updated_at']) IS DISTINCT FROM (to_jsonb(OLD)-ARRAY['status','version','published_at','updated_at']))) THEN RAISE EXCEPTION 'IMMUTABLE_PAYROLL'; END IF;
 IF NEW.status<>OLD.status AND NOT ((OLD.status='draft' AND NEW.status='validated' AND app.payroll_admin('payroll.edit',OLD.employee_id)) OR (OLD.status='validated' AND NEW.status='reviewed' AND app.payroll_admin('payroll.review',OLD.employee_id)) OR (OLD.status IN ('validated','reviewed') AND NEW.status='approved' AND app.payroll_admin('payroll.approve',OLD.employee_id)) OR (OLD.status='approved' AND NEW.status='published' AND app.payroll_admin('payroll.manage',OLD.employee_id)) OR (OLD.status IN ('validated','reviewed') AND NEW.status='draft' AND app.payroll_admin('payroll.edit',OLD.employee_id))) THEN RAISE EXCEPTION 'FORBIDDEN'; END IF;
 IF OLD.status='draft' AND NEW.status='draft' AND NOT app.payroll_admin('payroll.edit',OLD.employee_id) THEN RAISE EXCEPTION 'FORBIDDEN'; END IF;
 RETURN NEW;
END $$;

-- Deciding salary is part of preparing payroll (payroll.edit). A new salary
-- ends the running one the day before it starts; amounts and start dates of a
-- saved salary never change, so paid payslips keep their exact basis.
DROP POLICY salary_create ON app.salary_structures;
CREATE POLICY salary_create ON app.salary_structures FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND created_by=app.actor_id() AND app.payroll_admin('payroll.edit',employee_id));
CREATE POLICY salary_close ON app.salary_structures FOR UPDATE USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.payroll_admin('payroll.edit',employee_id));
GRANT UPDATE(ends_on) ON app.salary_structures TO hr_runtime;
CREATE FUNCTION app.salary_close_guard() RETURNS trigger LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN
 IF NEW.ends_on IS NULL OR NEW.ends_on<OLD.starts_on OR NEW.ends_on>=COALESCE(OLD.ends_on,'infinity'::date)
  OR (to_jsonb(NEW)-'ends_on') IS DISTINCT FROM (to_jsonb(OLD)-'ends_on') THEN RAISE EXCEPTION 'CONFLICT'; END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION app.salary_close_guard() FROM PUBLIC;
CREATE TRIGGER salary_close_guard BEFORE UPDATE ON app.salary_structures FOR EACH ROW EXECUTE FUNCTION app.salary_close_guard();

UPDATE auth.users SET permission_version=permission_version+1;
