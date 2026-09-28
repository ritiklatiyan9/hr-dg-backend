import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { fixture } from "./fixture.js";
import { ids } from "../../packages/db/src/seed.js";
let f: Awaited<ReturnType<typeof fixture>>, hr: string;
before(
  async () => {
    f = await fixture("lifecycle");
    hr = (await f.login("hr@example.test")).token;
  },
  { timeout: 60000 },
);
after(async () => {
  await f?.close();
});
async function gql(token: string, query: string, variables = {}) {
  const r = await f.app.inject({
    method: "POST",
    url: "/graphql",
    headers: { authorization: `Bearer ${token}` },
    payload: { query, variables: { s: ids.dg, ...variables } },
  });
  return r.json();
}
const lifecycle = (token: string, operation: string, input: object) =>
  gql(
    token,
    "mutation($s:ID!,$o:String!,$i:EmployeeLifecycleInput!){employeeLifecycle(siteId:$s,operation:$o,input:$i){id version password}}",
    { o: operation, i: input },
  );
const record = async (id: string) =>
  (
    await gql(
      hr,
      "query($s:ID!,$id:ID!){employee(siteId:$s,id:$id){version status login{status loginId protected}}}",
      { id },
    )
  ).data.employee;
const list = async (status: string) =>
  (
    await gql(
      hr,
      "query($s:ID!,$st:String){employees(siteId:$s,first:50,status:$st){nodes{id}}}",
      { st: status },
    )
  ).data.employees.nodes.map((n: { id: string }) => n.id);
let address = 1;
const signIn = (email: string, password: string) =>
  f.app.inject({
    method: "POST",
    url: "/auth/login",
    remoteAddress: `127.2.0.${address++}`,
    payload: { email, password, kind: "mobile", deviceId: randomUUID() },
  });
test("HR issues an app login, disables it, exit revokes it and rehire restores it", async () => {
  const created = await gql(
    hr,
    'mutation($s:ID!,$i:FoundationInput!){saveFoundation(siteId:$s,operation:"create_employee",input:$i){id status}}',
    {
      i: {
        employeeCode: "LIFE-001",
        displayName: "Lifecycle Person",
        workEmail: "Lifecycle@Example.test",
        department: "Engineering",
        designation: "Site Engineer",
        legalEmployerId: ids.employer,
        startsOn: "2026-01-01",
      },
    },
  );
  const id = created.data.saveFoundation.id as string;
  let e = await record(id);
  assert.equal(e.status, "active");
  assert.deepEqual(e.login, {
    status: "pending",
    loginId: "lifecycle@example.test",
    protected: false,
  });
  assert.ok((await list("current")).includes(id));

  const issued = await lifecycle(hr, "set_password", {
    employeeId: id,
    expectedVersion: e.version,
  });
  const password = issued.data.employeeLifecycle.password as string;
  assert.match(password, /^[a-z2-9]{4}-[a-z2-9]{4}-[a-z2-9]{4}$/);
  const first = await signIn("lifecycle@example.test", password);
  assert.equal(first.statusCode, 200, first.body);
  const session = first.json().accessToken as string;
  assert.equal((await record(id)).login.status, "active");
  // The password never reaches the audit trail.
  const audit = (
    await f.owner.query(
      "SELECT metadata FROM app.audit_records WHERE entity_id=$1 AND action='employee.set_password'",
      [id],
    )
  ).rows[0].metadata;
  assert.ok(!JSON.stringify(audit).includes(password));
  assert.ok(!JSON.stringify(audit).includes("passwordHash"));

  // Stale versions and Jr HR (no approve) are refused.
  assert.equal(
    (
      await lifecycle(hr, "disable_login", {
        employeeId: id,
        expectedVersion: 1,
      })
    ).errors[0].extensions.code,
    "CONFLICT",
  );
  const junior = (await f.login("junior@example.test")).token;
  e = await record(id);
  assert.equal(
    (
      await lifecycle(junior, "disable_login", {
        employeeId: id,
        expectedVersion: e.version,
      })
    ).errors[0].extensions.code,
    "FORBIDDEN",
  );
  const disabled = await lifecycle(hr, "disable_login", {
    employeeId: id,
    expectedVersion: e.version,
  });
  assert.ok(disabled.data, JSON.stringify(disabled.errors));
  assert.equal(
    (await signIn("lifecycle@example.test", password)).statusCode,
    401,
  );
  const revoked = await f.app.inject({
    method: "GET",
    url: "/auth/session",
    headers: { authorization: `Bearer ${session}` },
  });
  assert.equal(revoked.statusCode, 401);
  e = await record(id);
  assert.equal(e.login.status, "disabled");
  await lifecycle(hr, "enable_login", {
    employeeId: id,
    expectedVersion: e.version,
  });
  assert.equal(
    (await signIn("lifecycle@example.test", password)).statusCode,
    200,
  );

  // An exit that has taken effect ends the login and moves the record to former.
  await f.owner.query(
    "UPDATE app.employment_records SET ends_on=current_date-1 WHERE employee_id=$1",
    [id],
  );
  await f.owner.query(
    "UPDATE app.site_assignments SET ends_on=current_date-1 WHERE employee_id=$1",
    [id],
  );
  e = await record(id);
  assert.equal(e.status, "former");
  assert.equal(e.login.status, "disabled");
  assert.equal(
    (await signIn("lifecycle@example.test", password)).statusCode,
    401,
  );
  assert.ok(!(await list("current")).includes(id));
  assert.ok((await list("former")).includes(id));
  assert.equal(
    (
      await lifecycle(hr, "enable_login", {
        employeeId: id,
        expectedVersion: e.version,
      })
    ).errors[0].extensions.code,
    "EMPLOYEE_EXITED",
  );

  const rehired = await lifecycle(hr, "rehire", {
    employeeId: id,
    expectedVersion: e.version,
    legalEmployerId: ids.employer,
    startsOn: new Date().toISOString().slice(0, 10),
  });
  assert.ok(rehired.data, JSON.stringify(rehired.errors));
  e = await record(id);
  assert.equal(e.status, "active");
  assert.equal(e.login.status, "active");
  assert.equal(
    (await signIn("lifecycle@example.test", password)).statusCode,
    200,
  );
});
test("privileged accounts, self and employees cannot use directory login controls", async () => {
  const created = await gql(
    hr,
    'mutation($s:ID!,$i:FoundationInput!){saveFoundation(siteId:$s,operation:"create_employee",input:$i){id}}',
    {
      i: {
        employeeCode: "LIFE-002",
        displayName: "Promoted Person",
        workEmail: "promoted@example.test",
        department: "Engineering",
        designation: "Site Engineer",
        legalEmployerId: ids.employer,
        startsOn: "2026-01-01",
      },
    },
  );
  const id = created.data.saveFoundation.id as string;
  await f.owner.query(
    "INSERT INTO app.access_grants(organization_id,site_id,user_id,role) SELECT organization_id,$2,user_id,'jr_hr' FROM app.employees WHERE id=$1",
    [id, ids.dg],
  );
  const e = await record(id);
  assert.equal(e.login.protected, true);
  assert.equal(
    (
      await lifecycle(hr, "set_password", {
        employeeId: id,
        expectedVersion: e.version,
      })
    ).errors[0].extensions.code,
    "PROTECTED_ACCOUNT",
  );
  const self = await record(ids.adminEmployee);
  assert.equal(
    (
      await lifecycle(hr, "disable_login", {
        employeeId: ids.adminEmployee,
        expectedVersion: self.version,
      })
    ).errors[0].extensions.code,
    "SELF_ESCALATION",
  );
  const employee = (await f.login("employee@example.test")).token;
  const own = await gql(
    employee,
    "query($s:ID!){myProfile(siteId:$s){status login{status}}}",
  );
  assert.equal(own.data.myProfile.login, null);
  // Runtime credentials cannot reach the account helper directly.
  await assert.rejects(() =>
    f.runtime.query("SELECT app.login_protected($1)", [ids.admin]),
  );
});
test("HR can type the app password; short ones are refused", async () => {
  const created = await gql(
    hr,
    'mutation($s:ID!,$i:FoundationInput!){saveFoundation(siteId:$s,operation:"create_employee",input:$i){id}}',
    {
      i: {
        employeeCode: "LIFE-003",
        displayName: "Typed Password",
        workEmail: "typed@example.test",
        department: "Engineering",
        designation: "Site Engineer",
        legalEmployerId: ids.employer,
        startsOn: "2026-01-01",
      },
    },
  );
  const id = created.data.saveFoundation.id as string;
  const short = await lifecycle(hr, "set_password", {
    employeeId: id,
    expectedVersion: 1,
    password: "short",
  });
  assert.equal(short.errors[0].extensions.code, "BAD_INPUT");
  const set = await lifecycle(hr, "set_password", {
    employeeId: id,
    expectedVersion: 1,
    password: "Garden@2026",
  });
  assert.equal(set.data.employeeLifecycle.password, "Garden@2026");
  assert.equal(
    (await signIn("typed@example.test", "Garden@2026")).statusCode,
    200,
  );
});
