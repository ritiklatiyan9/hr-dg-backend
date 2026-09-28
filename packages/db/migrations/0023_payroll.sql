CREATE EXTENSION IF NOT EXISTS btree_gist;
-- Additive payroll foundation. Integer paise strings in validated snapshots; numeric balances are exact.
ALTER TABLE app.employment_records ADD CONSTRAINT employment_org_id_unique UNIQUE(organization_id,id);
CREATE FUNCTION app.payroll_admin(permission text,employee uuid DEFAULT NULL) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT app.has_site(app.site_id()) AND (app.policy_decision(app.actor_id(),app.site_id(),permission,NULL)->>'allowed')::boolean
 AND app.policy_decision(app.actor_id(),app.site_id(),permission,NULL)->>'scope'='site'
 AND (app.policy_decision(app.actor_id(),app.site_id(),'payroll.field.salary',NULL)->>'allowed')::boolean
 AND app.policy_decision(app.actor_id(),app.site_id(),'payroll.field.salary',NULL)->>'scope'='site'
 AND (employee IS NULL OR app.allowed('employees.view',employee)) $$;
CREATE FUNCTION app.payroll_own(employee uuid,permission text) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT app.has_site(app.site_id()) AND app.allowed(permission) AND app.allowed('my_payroll.field.salary')
 AND EXISTS(SELECT 1 FROM app.employees WHERE id=employee AND organization_id=app.org_id() AND user_id=app.actor_id()) $$;
REVOKE ALL ON FUNCTION app.payroll_admin(text,uuid),app.payroll_own(uuid,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.payroll_admin(text,uuid),app.payroll_own(uuid,text) TO hr_runtime;
CREATE TABLE app.salary_structures(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL,site_id uuid NOT NULL,
 employment_id uuid NOT NULL,employee_id uuid NOT NULL,starts_on date NOT NULL,ends_on date,
 version int NOT NULL DEFAULT 1,components jsonb NOT NULL,reason text NOT NULL,created_by uuid NOT NULL,created_at timestamptz NOT NULL DEFAULT now(),
 CHECK(ends_on IS NULL OR ends_on>=starts_on), UNIQUE(organization_id,id),
 FOREIGN KEY(organization_id,employment_id) REFERENCES app.employment_records(organization_id,id),
 FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id),
 FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id),
 EXCLUDE USING gist(employment_id WITH =,daterange(starts_on,ends_on,'[]') WITH &&)
);
CREATE TABLE app.payroll_results(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL,site_id uuid NOT NULL,
 employment_id uuid NOT NULL,employee_id uuid NOT NULL,user_id uuid NOT NULL,legal_employer_id uuid NOT NULL,
 period_start date NOT NULL,period_end date NOT NULL,revision int NOT NULL DEFAULT 1,previous_id uuid REFERENCES app.payroll_results(id),
 status text NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','validated','reviewed','approved','published')),
 version int NOT NULL DEFAULT 1,input jsonb NOT NULL,snapshot jsonb NOT NULL,allocations jsonb NOT NULL,
 reason text NOT NULL,created_by uuid NOT NULL,reviewed_by uuid,approved_by uuid,published_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now(),
 CHECK(period_end>=period_start AND period_end-period_start<=62),CHECK(revision>0),
 CHECK(reviewed_by IS NULL OR reviewed_by<>created_by),CHECK(approved_by IS NULL OR (approved_by<>created_by AND approved_by<>reviewed_by AND approved_by<>user_id)),
 UNIQUE(organization_id,id),UNIQUE(organization_id,employment_id,period_start,period_end,revision),
 FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id),
 FOREIGN KEY(organization_id,employment_id) REFERENCES app.employment_records(organization_id,id),
 FOREIGN KEY(organization_id,employee_id) REFERENCES app.employees(organization_id,id),
 FOREIGN KEY(organization_id,legal_employer_id) REFERENCES app.legal_employers(organization_id,id),
 FOREIGN KEY(organization_id,user_id) REFERENCES auth.users(organization_id,id)
);
CREATE INDEX payroll_scope ON app.payroll_results(organization_id,site_id,period_start DESC);
CREATE FUNCTION app.payroll_visible(result uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT EXISTS(SELECT 1 FROM app.payroll_results r WHERE r.id=result AND r.organization_id=app.org_id() AND r.site_id=app.site_id()
 AND (app.payroll_admin('payroll.view',r.employee_id) OR (r.status='published' AND app.payroll_own(r.employee_id,'my_payroll.view')))) $$;
REVOKE ALL ON FUNCTION app.payroll_visible(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.payroll_visible(uuid) TO hr_runtime;
ALTER TABLE app.salary_structures ENABLE ROW LEVEL SECURITY;
CREATE POLICY salary_read ON app.salary_structures FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND (app.payroll_admin('payroll.view',employee_id) OR app.payroll_own(employee_id,'my_payroll.view')));
CREATE POLICY salary_create ON app.salary_structures FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND created_by=app.actor_id() AND app.payroll_admin('payroll.manage',employee_id));
-- Effective-dated structures are immutable. Revisions use non-overlapping explicit dates.
GRANT SELECT,INSERT ON app.salary_structures TO hr_runtime;
ALTER TABLE app.payroll_results ENABLE ROW LEVEL SECURITY;
CREATE POLICY payroll_read ON app.payroll_results FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND (app.payroll_admin('payroll.view',employee_id) OR (status='published' AND app.payroll_own(employee_id,'my_payroll.view'))));
CREATE POLICY payroll_insert ON app.payroll_results FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND created_by=app.actor_id() AND status='draft' AND app.payroll_admin('payroll.create',employee_id));
CREATE POLICY payroll_update ON app.payroll_results FOR UPDATE USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.payroll_admin('payroll.view',employee_id)) WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND app.payroll_admin('payroll.view',employee_id));
GRANT SELECT,INSERT,UPDATE ON app.payroll_results TO hr_runtime;
CREATE FUNCTION app.payroll_guard() RETURNS trigger LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN
 IF NEW.organization_id<>OLD.organization_id OR NEW.site_id<>OLD.site_id OR NEW.employment_id<>OLD.employment_id OR NEW.employee_id<>OLD.employee_id OR NEW.user_id<>OLD.user_id OR NEW.legal_employer_id<>OLD.legal_employer_id OR NEW.period_start<>OLD.period_start OR NEW.period_end<>OLD.period_end OR NEW.revision<>OLD.revision OR NEW.previous_id IS DISTINCT FROM OLD.previous_id OR NEW.created_by<>OLD.created_by OR NEW.version<>OLD.version+1 THEN RAISE EXCEPTION 'CONFLICT'; END IF;
 IF OLD.status='published' OR (OLD.status='approved' AND (NEW.status<>'published' OR (to_jsonb(NEW)-ARRAY['status','version','published_at','updated_at']) IS DISTINCT FROM (to_jsonb(OLD)-ARRAY['status','version','published_at','updated_at']))) THEN RAISE EXCEPTION 'IMMUTABLE_PAYROLL'; END IF;
 IF NEW.status<>OLD.status AND NOT ((OLD.status='draft' AND NEW.status='validated' AND app.payroll_admin('payroll.edit',OLD.employee_id)) OR (OLD.status='validated' AND NEW.status='reviewed' AND app.payroll_admin('payroll.review',OLD.employee_id)) OR (OLD.status='reviewed' AND NEW.status='approved' AND app.payroll_admin('payroll.approve',OLD.employee_id)) OR (OLD.status='approved' AND NEW.status='published' AND app.payroll_admin('payroll.manage',OLD.employee_id)) OR (OLD.status IN ('validated','reviewed') AND NEW.status='draft' AND app.payroll_admin('payroll.edit',OLD.employee_id))) THEN RAISE EXCEPTION 'FORBIDDEN'; END IF;
 IF OLD.status='draft' AND NEW.status='draft' AND NOT app.payroll_admin('payroll.edit',OLD.employee_id) THEN RAISE EXCEPTION 'FORBIDDEN'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER payroll_guard BEFORE UPDATE ON app.payroll_results FOR EACH ROW EXECUTE FUNCTION app.payroll_guard();
CREATE TABLE app.payroll_history(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL,site_id uuid NOT NULL,result_id uuid NOT NULL,version int NOT NULL,
 actor_id uuid NOT NULL,event text NOT NULL,reason text NOT NULL,snapshot jsonb NOT NULL,created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(result_id,version),FOREIGN KEY(organization_id,result_id) REFERENCES app.payroll_results(organization_id,id)
);
ALTER TABLE app.payroll_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY payroll_history_read ON app.payroll_history FOR SELECT USING(app.payroll_visible(result_id));
CREATE POLICY payroll_history_insert ON app.payroll_history FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND actor_id=app.actor_id() AND app.payroll_visible(result_id));
GRANT SELECT,INSERT ON app.payroll_history TO hr_runtime;
CREATE TABLE app.hr_receipts(organization_id uuid NOT NULL,site_id uuid NOT NULL,actor_id uuid NOT NULL,client_id uuid NOT NULL,digest text NOT NULL,result jsonb NOT NULL,PRIMARY KEY(organization_id,actor_id,client_id));
ALTER TABLE app.hr_receipts ENABLE ROW LEVEL SECURITY;
CREATE POLICY receipt_scope ON app.hr_receipts USING(organization_id=app.org_id() AND site_id=app.site_id() AND actor_id=app.actor_id() AND app.has_site(site_id));
GRANT SELECT,INSERT ON app.hr_receipts TO hr_runtime;
CREATE FUNCTION app.payroll_insert_guard() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE e record;p record;BEGIN
 PERFORM pg_advisory_xact_lock(hashtextextended(NEW.employment_id::text,735));
 SELECT er.*,u.user_id INTO e FROM app.employment_records er JOIN app.employees u ON u.id=er.employee_id AND u.organization_id=er.organization_id WHERE er.id=NEW.employment_id AND er.organization_id=NEW.organization_id;
 IF e.employee_id IS DISTINCT FROM NEW.employee_id OR e.legal_employer_id IS DISTINCT FROM NEW.legal_employer_id OR e.user_id IS DISTINCT FROM NEW.user_id OR NEW.period_end<e.starts_on OR NEW.period_start>COALESCE(e.ends_on,'infinity'::date) THEN RAISE EXCEPTION 'INVALID_EMPLOYMENT'; END IF;
 IF EXISTS(SELECT 1 FROM app.payroll_results r WHERE r.organization_id=NEW.organization_id AND r.employment_id=NEW.employment_id AND daterange(r.period_start,r.period_end,'[]') && daterange(NEW.period_start,NEW.period_end,'[]') AND (r.period_start<>NEW.period_start OR r.period_end<>NEW.period_end OR r.site_id<>NEW.site_id)) THEN RAISE EXCEPTION 'PAY_PERIOD_OVERLAP';END IF;
 IF NEW.revision=1 THEN IF NEW.previous_id IS NOT NULL THEN RAISE EXCEPTION 'CONFLICT';END IF;
 ELSE SELECT * INTO p FROM app.payroll_results WHERE id=NEW.previous_id AND organization_id=NEW.organization_id AND employment_id=NEW.employment_id AND site_id=NEW.site_id AND period_start=NEW.period_start AND period_end=NEW.period_end AND revision=NEW.revision-1 AND status='published';IF p.id IS NULL THEN RAISE EXCEPTION 'CONFLICT';END IF; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER payroll_insert_guard BEFORE INSERT ON app.payroll_results FOR EACH ROW EXECUTE FUNCTION app.payroll_insert_guard();
REVOKE ALL ON FUNCTION app.payroll_guard(),app.payroll_insert_guard() FROM PUBLIC;
CREATE FUNCTION app.payroll_allocation(selected uuid,employee uuid,start_date date,end_date date) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT app.payroll_admin('payroll.view',employee) AND app.has_site(selected) AND EXISTS(SELECT 1 FROM app.site_assignments WHERE organization_id=app.org_id() AND site_id=selected AND employee_id=employee AND starts_on<=end_date AND COALESCE(ends_on,'infinity')>=start_date) $$;
REVOKE ALL ON FUNCTION app.payroll_allocation(uuid,uuid,date,date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.payroll_allocation(uuid,uuid,date,date) TO hr_runtime;
