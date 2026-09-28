# HR panel audit — 22 September 2026

## Baseline before edits

Node 24.16.0; React 19, Vite 7, Tailwind 4, TanStack Query/Table already installed.
Only Button was implemented as a shadcn-style primitive (Radix Slot/CVA).
No React Router, Radix dialogs/popovers/tabs, RHF or shared table existed.
GraphQL uses typed documents and fetch with cancellation; no Apollo client.
QueryClient is correctly created once at module scope. Providers are not recreated
by normal navigation. Hash links do not cause browser reloads.

### Confirmed flicker causes

- `gcTime: 0` removes records when a route unmounts; `staleTime: 0` refetches every revisit.
- `<main key={scope + page}>` recreates all route content and provider instances.
- Site switching sets the site to an empty string between selections, rendering the
  workspace picker before the next scope resolves.
- Permission reload clears selected site, forcing another selection.
- Visibility change deliberately removes sensitive data; this security boundary must
  stay, but its loading state belongs inside the retained shell.
- Employee landing bundles approvals, DWR and operation summaries with directory
  queries. All module code is eagerly imported. Baseline JS: 646,992 bytes; CSS: 40,870.

## Route inventory

All existing routes share global CSS, Button, Badge, Heading, Skeleton, Empty,
ErrorState, native Dialog and basic Tabs. Narrow layouts use horizontal tables and
an inadequate sidebar collapse. Most modules blank their content on initial fetch.
Shared redesign requires semantic tokens, compact headers, Radix overlays, local
skeletons, bounded tables, and persistent scoped routing. Status begins AUDITED.

| Existing route / embedded workflow | Module / permission | Current problems and required redesign | Performance/loading/responsive findings | Status |
| --- | --- | --- | --- | --- |
| employees | employees.view | Directory mixed with home summaries; extract dashboard, reuse table and profile Sheet | Cursor pagination exists; search fires each keystroke; multiple unrelated queries | AUDITED |
| employee Sheet | employees.view + field grants | Preserve restricted fields, history and editing; consistent sections | Details fetched on opening; native overlay; narrow overflow needs check | AUDITED |
| operations/overview | own/admin attendance, inbox | Separate working-day overview and inbox entry | One bounded operations snapshot, polls 15s; initial skeleton replaces heading | AUDITED |
| operations/attendance | attendance.view / my_attendance.view | Evidence, corrections and rosters need focused navigation | Shared snapshot; long evidence lists | AUDITED |
| operations/field | field_duty.view | Route evidence and gap warnings need clear detail hierarchy | Shared snapshot; no invented maps or evidence | AUDITED |
| operations/leave | leave.view / my_leave.view | Applications/decisions need consistent request pattern | Shared snapshot and dialogs | AUDITED |
| operations/tasks | tasks.view | Assignments/comments/attachments need focused route | Shared snapshot and dialogs | AUDITED |
| operations/config | site_settings.manage | Policy/approver configuration needs grouped forms | People/setup loaded before needed | AUDITED |
| dwr | my_dwr.view / dwr_review.view | Reporting/review, voice and policy controls must survive | 15s polling, table and native dialogs; no route chunks | AUDITED |
| payroll | payroll.view / my_payroll.view + salary fields | Preserve exact amounts, reviewer separation, history and publication | Native tables, bounded response, no cursor on runs | AUDITED |
| hr/expense | expenses.view | Receipts/decisions/settlement need dedicated route | Shared record list, 100-record backend bound | AUDITED |
| hr/asset | assets.view | Assignment/return/clearance need dedicated route | Same shared list and native dialogs | AUDITED |
| hr/helpdesk | helpdesk.view | Cases need dedicated route and detail Sheet | Same shared list | AUDITED |
| hr/grievance | grievances.view + case policy | Preserve confidential handler controls separately | Same shared list; sensitive cache requires purge | AUDITED |
| hr/document | documents.view / my_documents.view | Dedicated documents navigation; retain expiry/download grants | Same bounded list | AUDITED |
| hr/policy | documents.view / my_documents.view | Policy publication and acknowledgment retained | Same bounded list | AUDITED |
| hr/announcement | announcements.view | Audience/acknowledgment preserved, dedicated route | Same bounded list | AUDITED |
| hr/lifecycle | my_hr.view / employee module grants | Joining/transfer/exit forms retained | Same bounded list | AUDITED |
| requests | employees.review | Profile request review, reasons/history | List and native dialog; no cursor | AUDITED |
| embedded approval queue | source review grants | Dedicated entry, honest empty/loading/error states | Queue request already bounded | AUDITED |
| analytics | analytics.view + source grants | Deterministic evidence above optional AI explanation | Heavy panel eager; date filters; real aggregates | AUDITED |
| access | access.view/manage + delegation | Dense user/rule editor, preserve preview/concurrency | Large matrix, narrow overflow; native preview dialog | AUDITED |
| setup: departments/designations/shifts/holidays/drafts | site_settings.view/manage | Reference tabs need consistent page and focused navigation | Stable reference data unnecessarily refetched | AUDITED |
| setup: organization/modules | organization.manage | Preserve enabled modules and versioning | Same reference query | AUDITED |
| audit | audit.view | Timeline and readable labels | Bounded history, no cursor | AUDITED |
| reports | reports.view with organization scope | Keep All Sites visibly read-only | Separately authorized aggregate, no missing site filter | AUDITED |

No backend/schema changes are planned. Server pagination beyond existing cursor
contracts must be explicitly documented rather than simulating server paging.

## Implementation outcome

The pre-change findings above were recorded before edits. Current route status,
implemented shared components, test evidence and concrete blocked additions are in
`HR_PANEL_REDESIGN_PROGRESS.md`; performance evidence is in
`HR_PANEL_PERFORMANCE.md`. Every inventory row received the shared shell/tokens,
loading/error treatment and capability-preserving navigation. Primary employee,
attendance, leave, task, DWR, payroll, HR-record and inbox lists use one DataTable.
No initial AUDITED status above should be read as a final unimplemented omission.
