import { passwordHash } from "../../../apps/api/src/security.js";
import { pool, transaction } from "./index.js";
import { mkdir, writeFile } from "node:fs/promises";
export const ids = {
  superAdmin: "30000000-0000-4000-8000-000000000010",
  siteAdmin: "30000000-0000-4000-8000-000000000011",
  junior: "30000000-0000-4000-8000-000000000012",
  manager: "30000000-0000-4000-8000-000000000013",
  supervisor: "30000000-0000-4000-8000-000000000014",
  org: "10000000-0000-4000-8000-000000000001",
  otherOrg: "10000000-0000-4000-8000-000000000002",
  dg: "20000000-0000-4000-8000-000000000001",
  rg: "20000000-0000-4000-8000-000000000002",
  otherSite: "20000000-0000-4000-8000-000000000003",
  admin: "30000000-0000-4000-8000-000000000001",
  employee: "30000000-0000-4000-8000-000000000002",
  river: "30000000-0000-4000-8000-000000000003",
  outsider: "30000000-0000-4000-8000-000000000004",
  adminEmployee: "40000000-0000-4000-8000-000000000001",
  employeeProfile: "40000000-0000-4000-8000-000000000002",
  riverProfile: "40000000-0000-4000-8000-000000000003",
  outsiderProfile: "40000000-0000-4000-8000-000000000004",
  employer: "50000000-0000-4000-8000-000000000001",
  otherEmployer: "50000000-0000-4000-8000-000000000002",
};
export async function seed(url: string, password: string) {
  if (
    !/^(hr_local|hr_test(?:_[a-z0-9]+)?)$/.test(new URL(url).pathname.slice(1))
  )
    throw new Error("Synthetic seeds are restricted to hr_local or hr_test");
  if (password.length < 12)
    throw new Error("Set a unique SEED_PASSWORD of at least 12 characters");
  const p = pool(url, 1),
    hash = await passwordHash(password);
  try {
    await transaction(p, async (c) => {
      if (
        (
          await c.query("SELECT id FROM app.organizations WHERE id=$1", [
            ids.org,
          ])
        ).rowCount
      )
        return;
      await c.query(
        "INSERT INTO app.organizations(id,name,slug) VALUES($1,'Defence Garden · Synthetic Demo','defence-garden-demo'),($2,'Isolation Test Organization','isolation-test')",
        [ids.org, ids.otherOrg],
      );
      await c.query(
        "INSERT INTO app.sites(id,organization_id,name,timezone) VALUES($1,$2,'Defence Garden','Asia/Kolkata'),($3,$2,'River Green','Asia/Kolkata'),($4,$5,'Other organization site','Asia/Kolkata')",
        [ids.dg, ids.org, ids.rg, ids.otherSite, ids.otherOrg],
      );
      await c.query(
        "INSERT INTO app.legal_employers(id,organization_id,name) VALUES($1,$2,'Garden Services Demo Pvt Ltd'),($3,$4,'Other Demo Employer')",
        [ids.employer, ids.org, ids.otherEmployer, ids.otherOrg],
      );
      const people = [
        {
          user: ids.admin,
          profile: ids.adminEmployee,
          org: ids.org,
          email: "hr@example.test",
          name: "Aditi Sharma",
          code: "DG-001",
          job: "HR Lead",
          dept: "People & Culture",
          sites: [ids.dg, ids.rg],
          role: "hr",
        },
        {
          user: ids.employee,
          profile: ids.employeeProfile,
          org: ids.org,
          email: "employee@example.test",
          name: "Arjun Mehta",
          code: "DG-002",
          job: "Site Engineer",
          dept: "Engineering",
          sites: [ids.dg, ids.rg],
          role: "employee",
        },
        {
          user: ids.river,
          profile: ids.riverProfile,
          org: ids.org,
          email: "river@example.test",
          name: "Meera Kapoor",
          code: "RG-001",
          job: "Landscape Coordinator",
          dept: "Operations",
          sites: [ids.rg],
          role: "employee",
        },
        {
          user: ids.outsider,
          profile: ids.outsiderProfile,
          org: ids.otherOrg,
          email: "outsider@example.test",
          name: "Synthetic Outsider",
          code: "OT-001",
          job: "HR Manager",
          dept: "Testing",
          sites: [ids.otherSite],
          role: "employee",
        },
      ];
      for (const e of people) {
        await c.query(
          "INSERT INTO auth.users(id,organization_id,email,password_hash,requires_mfa) VALUES($1,$2,$3,$4,$5)",
          [e.user, e.org, e.email, hash, e.role === "hr"],
        );
        await c.query(
          "INSERT INTO app.employees(id,organization_id,user_id,employee_code,display_name,work_email,job_title,department) VALUES($1,$2,$3,$4,$5,$6,$7,$8)",
          [e.profile, e.org, e.user, e.code, e.name, e.email, e.job, e.dept],
        );
        await c.query(
          "INSERT INTO app.employment_records(organization_id,employee_id,legal_employer_id,starts_on) VALUES($1,$2,$3,'2024-01-01')",
          [
            e.org,
            e.profile,
            e.org === ids.org ? ids.employer : ids.otherEmployer,
          ],
        );
        for (const site of e.sites) {
          await c.query(
            "INSERT INTO app.site_assignments(organization_id,site_id,employee_id,starts_on) VALUES($1,$2,$3,'2024-01-01')",
            [e.org, site, e.profile],
          );
          await c.query(
            "INSERT INTO app.access_grants(organization_id,user_id,site_id,role) VALUES($1,$2,$3,$4)",
            [e.org, e.user, site, e.role],
          );
        }
      }
    });
    await transaction(p, async (c) => {
      for (const [id, email, role] of [
        [ids.superAdmin, "superadmin@example.test", "super_admin"],
        [ids.siteAdmin, "admin@example.test", "admin"],
        [ids.junior, "junior@example.test", "jr_hr"],
        [ids.manager, "manager@example.test", "manager"],
        [ids.supervisor, "supervisor@example.test", "supervisor"],
      ]) {
        const added = await c.query(
          "INSERT INTO auth.users(id,organization_id,email,password_hash,requires_mfa) VALUES($1,$2,$3,$4,true) ON CONFLICT DO NOTHING RETURNING id",
          [id, ids.org, email, hash],
        );
        if (!added.rowCount) continue;
        for (const site of role === "super_admin"
          ? [ids.dg, ids.rg]
          : [ids.dg]) {
          await c.query(
            "INSERT INTO app.access_grants(organization_id,site_id,user_id,role) VALUES($1,$2,$3,$4)",
            [ids.org, site, id, role],
          );
        }
        if (role === "super_admin")
          await c.query(
            "INSERT INTO app.access_overrides(organization_id,site_id,user_id,key,effect,scope) VALUES($1,$2,$3,'reports.view','allow','organization')",
            [ids.org, ids.dg, id],
          );
        if (role === "admin") {
          await c.query(
            "INSERT INTO app.access_overrides(organization_id,site_id,user_id,key,effect,scope) VALUES($1,$2,$3,'access.view','allow','site'),($1,$2,$3,'access.manage','allow','site')",
            [ids.org, ids.dg, id],
          );
          await c.query(
            "INSERT INTO app.access_delegations(organization_id,site_id,user_id,key,scope) VALUES($1,$2,$3,'employees.view','site'),($1,$2,$3,'employees.edit','site'),($1,$2,$3,'employees.field.contact','site')",
            [ids.org, ids.dg, id],
          );
        }
        if (role === "manager") {
          await c.query(
            "INSERT INTO app.access_overrides(organization_id,site_id,user_id,key,effect,scope) VALUES($1,$2,$3,'employees.view','allow','team'),($1,$2,$3,'employees.field.employment','allow','team')",
            [ids.org, ids.dg, id],
          );
          await c.query(
            "INSERT INTO app.team_assignments(organization_id,site_id,manager_id,employee_id,starts_on) VALUES($1,$2,$3,$4,'2024-01-01')",
            [ids.org, ids.dg, id, ids.employeeProfile],
          );
        }
      }
      for (const site of [ids.dg, ids.rg]) {
        for (const [kind, name, details] of [
          ["department", "Engineering", {}],
          ["department", "People & Culture", {}],
          ["designation", "Site Engineer", {}],
          ["designation", "HR Lead", {}],
          ["shift", "General shift", { startTime: "09:00", endTime: "18:00" }],
          ["holiday", "Republic Day", { date: "2027-01-26" }],
        ])
          await c.query(
            "INSERT INTO app.site_reference_items(organization_id,site_id,kind,name,details) VALUES($1,$2,$3,$4,$5) ON CONFLICT DO NOTHING",
            [ids.org, site, kind, name, JSON.stringify(details)],
          );
      }
      await c.query(
        "INSERT INTO app.employee_sensitive_fields(organization_id,employee_id,field,value) VALUES($1,$2,'salary','42000.00'),($1,$2,'bank','DEMO-ONLY-1234'),($1,$2,'identity','SYNTHETIC-ID') ON CONFLICT DO NOTHING",
        [ids.org, ids.employeeProfile],
      );
    });
  } finally {
    await p.end();
  }
}
if (process.argv[1]?.endsWith("/seed.ts")) {
  if (process.env.NODE_ENV === "production")
    throw new Error("Synthetic seed is disabled in production");
  await seed(
    process.env.MIGRATION_DATABASE_URL ?? "",
    process.env.SEED_PASSWORD ?? "",
  );
  await mkdir(".local", { recursive: true });
  await writeFile(
    ".local/demo-access.json",
    JSON.stringify(
      {
        organizationId: ids.org,
        accounts: [
          "superadmin@example.test",
          "admin@example.test",
          "junior@example.test",
          "manager@example.test",
          "supervisor@example.test",
          "hr@example.test",
          "employee@example.test",
          "river@example.test",
        ],
        passwordSource: "SEED_PASSWORD in .env",
        note: "HR must enroll an authenticator on first sign-in. Synthetic data only.",
      },
      null,
      2,
    ),
    { mode: 0o600 },
  );
  console.log(
    "Synthetic two-site seed ready. Access instructions: .local/demo-access.json",
  );
}
