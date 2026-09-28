-- Salary payment ledger. Records disbursements made outside this system (bank,
-- UPI, cheque, cash); nothing here moves money. Rows are append-only: a mistaken
-- or bounced payment is cancelled by a linked reversal row, never edited or
-- deleted. Balances belong to the pay-period chain (every revision of one
-- employment and period), so a published correction asks only for the difference.
CREATE TABLE app.payroll_payments(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),organization_id uuid NOT NULL,site_id uuid NOT NULL,
 result_id uuid NOT NULL,employment_id uuid NOT NULL,employee_id uuid NOT NULL,period_start date NOT NULL,period_end date NOT NULL,
 kind text NOT NULL CHECK(kind IN ('payment','reversal')),
 amount_paise bigint NOT NULL CHECK(amount_paise BETWEEN 1 AND 99999999999999),
 method text NOT NULL CHECK(method IN ('bank_transfer','upi','cheque','cash')),
 reference text NOT NULL CHECK(reference ~ '^[A-Za-z0-9][A-Za-z0-9 /._-]{0,63}$'),
 paid_on date NOT NULL,reverses_id uuid UNIQUE,reason text NOT NULL CHECK(length(reason) BETWEEN 8 AND 2000),
 created_by uuid NOT NULL,created_at timestamptz NOT NULL DEFAULT now(),
 CHECK((kind='reversal')=(reverses_id IS NOT NULL)),UNIQUE(organization_id,id),
 FOREIGN KEY(organization_id,result_id) REFERENCES app.payroll_results(organization_id,id),
 FOREIGN KEY(organization_id,reverses_id) REFERENCES app.payroll_payments(organization_id,id),
 FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id)
);
CREATE INDEX payroll_payments_chain ON app.payroll_payments(organization_id,employment_id,period_start,period_end);
ALTER TABLE app.payroll_payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY payroll_payment_read ON app.payroll_payments FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.payroll_visible(result_id));
CREATE POLICY payroll_payment_insert ON app.payroll_payments FOR INSERT WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND created_by=app.actor_id() AND app.payroll_admin('payroll.manage',employee_id));
GRANT SELECT,INSERT ON app.payroll_payments TO hr_runtime;
CREATE FUNCTION app.payroll_payment_guard() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE r record;o record;paid bigint;BEGIN
 SELECT * INTO r FROM app.payroll_results WHERE id=NEW.result_id AND organization_id=NEW.organization_id;
 IF r.id IS NULL OR r.site_id<>NEW.site_id OR r.employment_id<>NEW.employment_id OR r.employee_id<>NEW.employee_id OR r.period_start<>NEW.period_start OR r.period_end<>NEW.period_end THEN RAISE EXCEPTION 'CONFLICT';END IF;
 IF r.user_id=NEW.created_by THEN RAISE EXCEPTION 'FORBIDDEN';END IF;
 IF NEW.paid_on>(now() AT TIME ZONE (SELECT timezone FROM app.sites WHERE id=NEW.site_id))::date THEN RAISE EXCEPTION 'BAD_INPUT';END IF;
 -- One writer per pay-period chain; successor rows are share-locked so a
 -- concurrent correction approval cannot slip past the superseded check.
 PERFORM pg_advisory_xact_lock(hashtextextended(NEW.organization_id::text||':pay:'||NEW.employment_id::text||':'||NEW.period_start::text||':'||NEW.period_end::text,0));
 PERFORM 1 FROM app.payroll_results WHERE previous_id=r.id AND organization_id=r.organization_id FOR SHARE;
 SELECT COALESCE(sum(CASE kind WHEN 'payment' THEN amount_paise ELSE -amount_paise END),0) INTO paid FROM app.payroll_payments
  WHERE organization_id=NEW.organization_id AND employment_id=NEW.employment_id AND period_start=NEW.period_start AND period_end=NEW.period_end;
 IF NEW.kind='payment' THEN
  IF r.status NOT IN ('approved','published') OR EXISTS(SELECT 1 FROM app.payroll_results n WHERE n.previous_id=r.id AND n.organization_id=r.organization_id AND n.status IN ('approved','published')) THEN RAISE EXCEPTION 'CONFLICT';END IF;
  IF paid+NEW.amount_paise>(r.snapshot->>'netPaise')::bigint THEN RAISE EXCEPTION 'OVERPAYMENT';END IF;
 ELSE
  SELECT * INTO o FROM app.payroll_payments WHERE id=NEW.reverses_id AND organization_id=NEW.organization_id;
  IF o.id IS NULL OR o.kind<>'payment' OR o.employment_id<>NEW.employment_id OR o.period_start<>NEW.period_start OR o.period_end<>NEW.period_end
   OR o.amount_paise<>NEW.amount_paise OR o.method<>NEW.method OR o.reference<>NEW.reference THEN RAISE EXCEPTION 'CONFLICT';END IF;
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER payroll_payment_guard BEFORE INSERT ON app.payroll_payments FOR EACH ROW EXECUTE FUNCTION app.payroll_payment_guard();
REVOKE ALL ON FUNCTION app.payroll_payment_guard() FROM PUBLIC;
-- Keyset paging (scanned backwards for newest first) and successor lookups.
DROP INDEX app.payroll_scope;
CREATE INDEX payroll_page ON app.payroll_results(organization_id,site_id,period_start,id);
CREATE INDEX payroll_successor ON app.payroll_results(previous_id) WHERE previous_id IS NOT NULL;
-- Read policies: same predicates as 0023, but site-level decisions are scalar
-- subqueries (evaluated once per query as InitPlans) instead of once per row.
-- payroll_admin(p,e) = payroll_admin(p) AND allowed('employees.view',e), and
-- payroll_own(e,p) = e = ANY(payroll_own_ids(p)).
CREATE FUNCTION app.payroll_own_ids(permission text) RETURNS uuid[] LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT CASE WHEN app.has_site(app.site_id()) AND app.allowed(permission) AND app.allowed('my_payroll.field.salary')
 THEN ARRAY(SELECT id FROM app.employees WHERE organization_id=app.org_id() AND user_id=app.actor_id()) ELSE '{}'::uuid[] END $$;
REVOKE ALL ON FUNCTION app.payroll_own_ids(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.payroll_own_ids(text) TO hr_runtime;
DROP POLICY payroll_read ON app.payroll_results;
CREATE POLICY payroll_read ON app.payroll_results FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND (
 ((SELECT app.payroll_admin('payroll.view')) AND app.allowed('employees.view',employee_id))
 OR (status='published' AND employee_id=ANY((SELECT app.payroll_own_ids('my_payroll.view'))::uuid[]))));
DROP POLICY salary_read ON app.salary_structures;
CREATE POLICY salary_read ON app.salary_structures FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id() AND (
 ((SELECT app.payroll_admin('payroll.view')) AND app.allowed('employees.view',employee_id))
 OR employee_id=ANY((SELECT app.payroll_own_ids('my_payroll.view'))::uuid[])));
-- History and payments follow their result's visibility (payroll_read applies inside).
DROP POLICY payroll_history_read ON app.payroll_history;
CREATE POLICY payroll_history_read ON app.payroll_history FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id()
 AND EXISTS(SELECT 1 FROM app.payroll_results r WHERE r.id=result_id));
DROP POLICY payroll_payment_read ON app.payroll_payments;
CREATE POLICY payroll_payment_read ON app.payroll_payments FOR SELECT USING(organization_id=app.org_id() AND site_id=app.site_id()
 AND EXISTS(SELECT 1 FROM app.payroll_results r WHERE r.id=result_id));
