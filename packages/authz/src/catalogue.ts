/** Canonical product vocabulary. Database catalogue is generated from this file.
 * Availability is independent of authorization: a grant never ships a feature. */
export const actions = [
  "view",
  "create",
  "edit",
  "delete",
  "submit",
  "review",
  "approve",
  "export",
  "manage",
] as const;
export const scopes = ["own", "team", "site", "organization"] as const;
export const roles = [
  "super_admin",
  "admin",
  "hr",
  "jr_hr",
  "employee",
  "manager",
  "supervisor",
] as const;
export type Role = (typeof roles)[number];
export type RecordScope = (typeof scopes)[number];
export type Effect = "inherit" | "allow" | "deny";
export interface ProductModule {
  id: string;
  name: string;
  hindi: string;
  group: string;
  phase: number;
  actions: readonly string[];
  fields: readonly string[];
  dependencies: readonly string[];
}
const module = (
  id: string,
  name: string,
  hindi: string,
  group: string,
  phase: number,
  actions: string[],
  fields: string[] = [],
  dependencies: string[] = [],
): ProductModule => ({
  id,
  name,
  hindi,
  group,
  phase,
  actions,
  fields,
  dependencies,
});
export const catalogue: ProductModule[] = [
  module(
    "my_hr",
    "My HR information",
    "मेरी एचआर जानकारी",
    "Self service",
    2,
    ["view", "submit"],
    ["contact", "employment"],
  ),
  module("my_attendance", "My attendance", "मेरी उपस्थिति", "Self service", 3, [
    "view",
    "create",
    "submit",
  ]),
  module("my_leave", "My leave", "मेरी छुट्टी", "Self service", 3, [
    "view",
    "create",
    "edit",
    "submit",
  ]),
  // create/edit/delete cover the DWR chat messages that feed the report.
  module("my_dwr", "My DWR", "मेरी दैनिक रिपोर्ट", "Self service", 4, [
    "view",
    "create",
    "edit",
    "delete",
    "submit",
  ]),
  module(
    "my_payroll",
    "My payroll",
    "मेरा वेतन",
    "Self service",
    5,
    ["view", "export"],
    ["salary", "bank"],
  ),
  module(
    "my_documents",
    "My documents",
    "मेरे दस्तावेज़",
    "Self service",
    5,
    ["view", "create", "submit", "export"],
    ["identity", "bank"],
  ),
  module(
    "employees",
    "Employee directory",
    "कर्मचारी निर्देशिका",
    "People",
    2,
    ["view", "create", "edit", "review", "approve", "export"],
    ["contact", "employment", "salary", "bank", "identity"],
  ),
  module(
    "organization",
    "Organization settings",
    "संगठन सेटिंग्स",
    "Administration",
    2,
    ["view", "manage"],
  ),
  module(
    "site_settings",
    "Site settings",
    "साइट सेटिंग्स",
    "Administration",
    2,
    ["view", "manage"],
  ),
  module(
    "access",
    "Users & module access",
    "उपयोगकर्ता और अनुमति",
    "Administration",
    2,
    ["view", "manage"],
  ),
  module("audit", "Audit history", "ऑडिट इतिहास", "Administration", 2, [
    "view",
    "export",
  ]),
  module(
    "reports",
    "Organization reporting",
    "संगठन रिपोर्ट",
    "Administration",
    2,
    ["view", "export"],
  ),
  module(
    "attendance",
    "Attendance administration",
    "उपस्थिति प्रबंधन",
    "Operations",
    3,
    ["view", "create", "edit", "review", "approve", "export"],
    [],
    ["employees.view"],
  ),
  module(
    "employee_tracking",
    "Duty location",
    "ड्यूटी स्थान",
    "Operations",
    3,
    ["view", "manage"],
    [],
    ["employees.view", "attendance.view"],
  ),
  module("field_duty", "Field duty", "फील्ड ड्यूटी", "Operations", 3, [
    "view",
    "create",
    "edit",
    "submit",
    "review",
    "approve",
    "export",
  ]),
  module("leave", "Leave administration", "छुट्टी प्रबंधन", "Operations", 3, [
    "view",
    "create",
    "edit",
    "review",
    "approve",
    "export",
  ]),
  module("tasks", "Tasks & teams", "कार्य और टीम", "Operations", 3, [
    "view",
    "create",
    "edit",
    "submit",
    "review",
    "approve",
  ]),
  module(
    "dwr_review",
    "DWR review",
    "दैनिक रिपोर्ट समीक्षा",
    "Operations",
    4,
    ["view", "review", "approve", "export"],
    ["provenance"],
  ),
  // Site oversight of DWR chat groups: view every group, create, edit members
  // and admins, archive groups and moderate messages. Group admins are
  // membership roles inside a group, not catalogue permissions.
  module("dwr_groups", "DWR groups", "डीडब्ल्यूआर समूह", "Operations", 4, [
    "view",
    "create",
    "edit",
    "delete",
  ]),
  module(
    "payroll",
    "Payroll administration",
    "वेतन प्रबंधन",
    "Finance",
    5,
    ["view", "create", "edit", "review", "approve", "export", "manage"],
    ["salary", "bank"],
    ["employees.view"],
  ),
  module(
    "documents",
    "Document administration",
    "दस्तावेज़ प्रबंधन",
    "People",
    5,
    ["view", "create", "edit", "review", "approve", "export", "manage"],
    ["identity", "bank"],
    ["employees.view"],
  ),
  module("announcements", "Announcements", "घोषणाएँ", "Communication", 5, [
    "view",
    "create",
    "edit",
    "submit",
    "approve",
    "manage",
  ]),
  module(
    "inbox",
    "Inbox & approvals",
    "इनबॉक्स और स्वीकृति",
    "Communication",
    5,
    ["view", "review", "approve"],
  ),
  module("expenses", "Expenses", "व्यय", "Finance", 5, [
    "view",
    "create",
    "edit",
    "submit",
    "review",
    "approve",
    "export",
  ]),
  module("assets", "Assets", "संपत्ति", "People", 5, [
    "view",
    "create",
    "edit",
    "submit",
    "review",
    "approve",
    "export",
    "manage",
  ]),
  module(
    "grievances",
    "Grievances",
    "शिकायतें",
    "People",
    5,
    ["view", "create", "submit", "review", "manage"],
    ["confidential"],
  ),
  module("helpdesk", "HR helpdesk", "एचआर सहायता", "People", 5, [
    "view",
    "create",
    "submit",
    "review",
    "manage",
  ]),
  module(
    "analytics",
    "Analytics tools",
    "विश्लेषण उपकरण",
    "Insights",
    6,
    ["view", "export"],
    ["salary"],
    ["reports.view"],
  ),
];
export interface Rule {
  key: string;
  effect: Effect;
  scope: RecordScope;
}
export interface TemplateRule {
  role: Role;
  key: string;
  scope: RecordScope;
}
export const templateRules: TemplateRule[] = [];
const grant = (
  role: Role,
  moduleId: string,
  allowed: readonly string[],
  scope: RecordScope,
) => {
  for (const action of allowed) {
    const existing = templateRules.find(
      (r) => r.role === role && r.key === `${moduleId}.${action}`,
    );
    if (existing) existing.scope = scope;
    else templateRules.push({ role, key: `${moduleId}.${action}`, scope });
  }
};
for (const role of roles) {
  for (const m of catalogue.filter((m) => m.group === "Self service")) {
    grant(role, m.id, m.actions, "own");
    grant(
      role,
      m.id,
      m.fields.map((f) => `field.${f}`),
      "own",
    );
  }
  for (const [id, actions] of [
    ["expenses", ["view", "create", "edit", "submit"]],
    ["assets", ["view", "submit"]],
    ["helpdesk", ["view", "create", "submit"]],
    ["grievances", ["view", "create", "submit"]],
    ["announcements", ["view", "submit"]],
    ["inbox", ["view"]],
  ] as const)
    grant(role, id, actions, "own");
  grant(role, "tasks", ["view", "submit"], "own");
  grant(role, "field_duty", ["view", "create", "submit"], "own");
  if (["super_admin", "admin", "hr"].includes(role)) {
    grant(role, "employee_tracking", ["view", "manage"], "site");
    grant(
      role,
      "tasks",
      ["view", "create", "edit", "review", "approve"],
      "site",
    );
    grant(
      role,
      "field_duty",
      ["view", "create", "edit", "review", "approve"],
      "site",
    );
  }
  // Team authority is explicit, never inferred from a title or manager role.
  if (["employee", "manager", "supervisor"].includes(role)) continue;
  grant(
    role,
    "employees",
    role === "jr_hr"
      ? ["view", "create", "edit"]
      : ["view", "create", "edit", "review", "approve", "export"],
    "site",
  );
  grant(role, "employees", ["field.contact", "field.employment"], "site");
  grant(role, "site_settings", ["view"], "site");
  for (const id of [
    "attendance",
    "leave",
    "dwr_review",
    "dwr_groups",
    "documents",
  ]) {
    const m = catalogue.find((m) => m.id === id)!;
    grant(
      role,
      id,
      m.actions.filter(
        (a) => role !== "jr_hr" || ["view", "create", "edit"].includes(a),
      ),
      "site",
    );
  }
  if (role === "super_admin" || role === "admin") {
    grant(role, "site_settings", ["manage"], "site");
    grant(role, "audit", ["view", "export"], "site");
    grant(
      role,
      "organization",
      ["view", ...(role === "super_admin" ? ["manage"] : [])],
      "site",
    );
  }
  if (role === "super_admin") {
    grant(role, "access", ["view", "manage"], "site");
    grant(
      role,
      "employees",
      ["field.salary", "field.bank", "field.identity"],
      "site",
    );
  }
}
export const permissionKeys = catalogue.flatMap((m) => [
  ...m.actions.map((a) => `${m.id}.${a}`),
  ...m.fields.map((f) => `${m.id}.field.${f}`),
]);
