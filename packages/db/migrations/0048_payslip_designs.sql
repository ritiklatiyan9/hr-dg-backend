-- Per-site payslip presentation (branding, layout, visible sections). Holds no
-- pay data: amounts always render from the immutable published snapshot.
-- Everyone at the site may read it (it styles their own payslip); only site
-- payroll managers may change it, with an optimistic version.
CREATE TABLE app.payslip_designs (
 organization_id uuid NOT NULL, site_id uuid NOT NULL,
 version integer NOT NULL DEFAULT 1 CHECK(version>0),
 design jsonb NOT NULL CHECK(jsonb_typeof(design)='object' AND octet_length(design::text)<=90000),
 updated_by uuid NOT NULL, updated_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(organization_id,site_id),
 FOREIGN KEY(organization_id,site_id) REFERENCES app.sites(organization_id,id),
 FOREIGN KEY(organization_id,updated_by) REFERENCES auth.users(organization_id,id)
);
ALTER TABLE app.payslip_designs ENABLE ROW LEVEL SECURITY;
CREATE POLICY scoped_read ON app.payslip_designs FOR SELECT
 USING(organization_id=app.org_id() AND site_id=app.site_id() AND app.has_site(site_id));
CREATE POLICY scoped_insert ON app.payslip_designs FOR INSERT
 WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND updated_by=app.actor_id() AND (SELECT app.payroll_admin('payroll.manage')));
CREATE POLICY scoped_update ON app.payslip_designs FOR UPDATE
 USING(organization_id=app.org_id() AND site_id=app.site_id() AND (SELECT app.payroll_admin('payroll.manage')))
 WITH CHECK(organization_id=app.org_id() AND site_id=app.site_id() AND updated_by=app.actor_id() AND (SELECT app.payroll_admin('payroll.manage')));
GRANT SELECT,INSERT,UPDATE ON app.payslip_designs TO hr_runtime;
