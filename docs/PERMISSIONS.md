# Permission model · Phases 2–5

The canonical catalogue is `packages/authz/src/catalogue.ts`: 26 modules with
meaningful combinations of view, create, edit, submit, review, approve, export
and manage, plus contact, employment, salary, bank, identity and confidential
field permissions. SQL catalogue/template rows originate from this source.
An applied migration is immutable. `scripts/generate-policy.mts <new-output.sql>`
produces the initial catalogue SQL for reference and refuses to overwrite files;
future catalogue changes require a reviewed **delta** migration, not reapplying
that initial CREATE TABLE script.

## Defaults

All roles receive own-record self service. My HR, My Attendance, My Leave,
My DWR, My Payroll and My Documents are separate from their administrative
modules. A payroll self-service grant never grants payroll administration.
Availability is independent of permission: Phase 5 modules are released locally; Phase 6 analytics remains unreleased.

Phase 4 DWR uses my_dwr for own reporting and dwr_review for record-scoped review,
approval and print/export. Manager/Supervisor grants require current assigned-team
relationships. Reviewers cannot approve themselves. Original/corrected transcript
and AI provenance need dwr_review.field.provenance; no role receives it by default.
Provider output is rechecked after external work and never authorizes a mutation.

DWR chat (2026-09-25) adds `my_dwr.delete` (own messages, all roles) and the
site-only `dwr_groups` module (view/create/edit/delete; Super Admin, Admin and HR by
template, Jr. HR without delete). Group admins are membership roles inside a group,
not catalogue grants. Reviewers with `dwr_review.view` read the chat messages behind
reports they may review and see chat-prepared drafts before submission. Admins
manage these per user in Users & module access like every other module; see
DWR_CHAT.md for the full matrix and database-enforced rules.

| Role                 | Template behavior                                                                                                                             |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Super Admin          | Assigned-site employee operations, sensitive employee fields, organization/site settings, access administration and audit oversight           |
| Admin                | Assigned-site employee operations, site settings and audit; access administration and permission delegation require explicit grants           |
| HR                   | Employee operations, contact/employment fields and attendance/leave/DWR/document operations; no payroll or access-administration default      |
| Jr. HR               | Employee view/create/edit for data entry and onboarding drafts; no final approval, sensitive export, salary/bank or permission administration |
| Manager / Supervisor | Self service only; explicit capabilities plus dated team assignments are required to access a team                                            |
| Employee             | Self service only; contact changes use a reviewed request                                                                                     |

No role includes all sites or organization-wide reporting implicitly. The demo
Admin has explicit access.view/access.manage and limited employee delegation;
the demo Manager has explicit team view/employment-field grants. These fixtures
are not additional role defaults. No job title confers permissions.

## Effective decision

Every business request derives organization/actor/session from authentication.
The caller supplies only a site selector and its last observed access version.
On one transaction-local RLS connection the shared SQL policy requires:

1. Active authenticated user, active organization membership and site membership.
2. An enabled module and known catalogue permission.
3. No explicit user/site deny. Deny is deliberately restrictive for that entire
   permission at the site; it is not a partial-record exception.
4. An explicit Allow override, otherwise an inherited template rule or compatible
   explicit Phase 1 grant. Inherit removes the override; absent allows deny.
5. Valid module scope and dependencies: actions/fields require that module's View
   at an equal or wider scope, evaluated against the **same record**. Cross-module
   dependencies also evaluate that record.
6. A matching record scope: own identity, current explicitly assigned team, or
   selected site. Self/team require a currently effective site assignment.
   Site-scoped employee administrators can also inspect historical/future dated
   assignments without rewriting history.
7. Each sensitive field's independent permission. GraphQL returns null/empty
   values for disallowed fields; RLS separately protects sensitive-field rows.

Decisions return `allowed`, `scope` and a rule identifier (template role,
explicit deny/allow, missing dependency, invalid scope or membership). The
control panel previews these before saving and retains an audit explanation.
Contact/employment self-service permissions apply only to the actor's own
profile; they cannot satisfy a team directory or another record's field access.

Self-service scopes must be own. Access, organization, site-settings and audit
scopes must be site; employee creation requires site scope. Organization scope
is accepted only for explicit reports/analytics view/export grants. All Sites
is a separately guarded, bounded, read-only aggregate report, anchored at a real
authorized site. It never means an omitted site filter or an operational write.

## Administration and concurrency

Administration → Users & module access selects a user and current workspace site.
It exposes assigned sites, role template, active membership, module search,
Inherit/Allow/Deny, scopes, sensitive fields, delegation bounds, effective rules,
preview, mandatory change reason and audit history. Flutter exposes the same
policy workflow through capability-controlled Work navigation.

Admin must possess access.manage and may grant only permissions they themselves
hold **and** are explicitly authorized to delegate, within both scope bounds.
Raw proposed allows are checked even for disabled modules, preventing latent
escalation. Admin cannot change delegation limits, their own account or a
protected Super Admin (including an inactive protected account). Super Admin
also cannot increase their own effective access.

All saves serialize on the organization and target user, require the expected
access version, and atomically persist grants/overrides/delegations, audit and
outbox. Conflicting editors receive CONFLICT and must reload. At least one
recoverable Super Admin must remain: an active user and organization membership,
a nonempty password hash, a Super Admin role and effective access.manage at an
active site. This is an account-access invariant, not an MFA-loss recovery bypass;
production administrator-assisted MFA recovery remains an operational decision.

Permission saves increment the target access version and revoke existing target
sessions. Membership, assignment and module changes also invalidate affected
versions. Every scoped request rechecks the session and current version under a
user-row lock; old versions fail SCOPE_CHANGED. Authenticated downloads and
queued exports recheck current session, version, module, action and field access.

## Enforcement surfaces and remaining boundaries

REST, GraphQL roots/fields, Domain/Foundation services, RLS, CSV downloads,
export preparation and the bounded analytics reporting tool use the same policy.
Export jobs contain only scope/column manifests, expire after 15 minutes and
never retain employee CSV bytes; download regenerates authorized data. Sensitive
columns require independent field grants. CSV formula prefixes are neutralized.
No general SQL/AI tool, public employee-file URL or unsigned HR download exists.
Audit and report export keys are reserved catalogue permissions; the current
export workflow is the employee CSV. Full documents, payroll and AI analytics
remain unreleased and must reuse these guards when implemented.

The auth database role cannot read business tables. Runtime roles do not own
tables or bypass RLS. Bounded SECURITY DEFINER functions perform only explicitly
validated administration operations; no runtime role can write arbitrary grants.
Audit/outbox omit profile and payroll values, tokens and credentials.

## Phase 3 enforcement

Duty, observation, segment, visit, roster, ledger, task, comment, file and inbox
records are site-scoped with RLS. Own attendance/leave stays separate from review
and approval. Managers gain no implicit team powers from their title. Task/field
self-service defaults are own; site operational grants follow the shared role
catalogue. Every queued synchronization and file download rechecks current access.
Approvals require the configured reviewer and forbid self-approval. Site transfers
cannot move open duties, pending uploads or encrypted queue entries.

The configuration approver selector returns minimal eligible user labels only when
site_settings.manage is allowed; selecting an approver does not grant that person
powers or expose permission administration. All Sites is still read-only reporting
and cannot be passed as an operational site. Route coordinates require field-duty
view on the same employee. Preserving recursive dependency checks in migration
0016 prevents a field grant from borrowing a broader self-service profile view.

## Phase 5 field and case boundaries

Recording or reversing a salary payment requires `payroll.manage` for the employee and
is refused to the payment's beneficiary, in the API and in the database guard.
Payroll administration requires site-scope action and salary-field permissions plus
historical employee visibility. Team grants and allocation rows cannot reveal total
salary. Published self-service records use own identity plus current site membership,
retaining original payslip scope after transfers. Grievances require explicit captured
case-handler membership and confidential grants; reporting-manager access is insufficient.
Documents add bank-field grants separately from identity fields; sensitive downloads
recheck their parent and export access. Own expense/helpdesk/grievance/asset receipt
and announcement reading/acknowledgment grants do not grant administration.

Analytics is now phase 6. `analytics.view` never grants the source module or its
sensitive fields. Aggregate cohorts intersect both source and analytics record
scopes. Additional selected sites require organization-scoped analytics and reports
at the anchor and active membership/current analytics at each site. Salary totals
require site payroll administration, salary-field grants, a complete past calendar
month and at least ten authorized employees; no employee/date differencing filter
is accepted. External AI receives no salary/identity and excludes small cohorts.
Every tool uses the same fresh session scope as GraphQL. See PHASE6_CONTRACTS.md.
