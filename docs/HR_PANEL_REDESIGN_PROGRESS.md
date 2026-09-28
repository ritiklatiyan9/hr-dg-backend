# HR panel redesign progress — 22 September 2026

This is a substantial integrated frontend refactor, not a production-readiness
claim. The requested exhaustive product redesign is not declared 100% complete.
Existing schemas, API authorization, auth/MFA and business mutation workflows remain.

## Implemented route coverage

All 25 capability-visible routes received the persistent shell, semantic design
system, navigation, local loading, compact forms/tables and Radix overlays. Automated
navigation/overflow/error checks and screenshots exist at all three requested desktop
sizes. Deep workflows retain original server-backed commands.

| Route | Integrated redesign | Verification / concrete remaining constraint |
| --- | --- | --- |
| dashboard | Real authorized aggregates, four primary metrics, exceptions and recent evidence | Tested navigation; requested attendance trend chart BLOCKED by missing time-series contract. Present/absent are not invented from incomplete evidence. |
| employees | Shared DataTable, cursor pagination, debounced search, column controls | Tested directory/profile; Overview and Employment/history profile tabs are integrated. Cross-module employee tabs are BLOCKED by absent employee-filtered detail contracts; existing assignments/reporting/profile workflows are preserved. |
| attendance | Shared DataTable, raw evidence/corrections/rosters retained | Navigation tested; evidence/decision workflows in existing browser regression. |
| field | Route history, gaps, visits, existing detail and evidence retained | Shared redesign tested; no new map SDK or invented missing routes. |
| tasks | Shared table and task detail Sheet, retained assignment/status/comment/attachment actions | Navigation and persisted workflow tested. |
| dwr | Shared table/filter/voice/review workflow and Radix dialogs | Navigation tested; real provider setup remains external prerequisite. |
| payroll | Shared table, exact grouped amounts, preserved review/publish/print | Navigation tested; >100-result server pagination BLOCKED by bounded response without cursor. |
| leave | Dedicated shared table, existing ledger/approval/forms | Navigation tested; real company configuration remains unconfigured, not guessed. |
| expenses | Shared table and detail Sheet; receipts/decision/settlement retained | Empty state tested; >100 records blocked by existing bounded response. |
| assets | Shared table and detail Sheet; assignment/return/clearance retained | Empty state tested; same cursor limitation. |
| documents | Dedicated table, metadata Sheet, expiry and protected files | Empty state tested; scanner/real-service acceptance remains prior release prerequisite. |
| policies | Dedicated route, publication/acknowledgment retained | Empty state tested. |
| lifecycle | Dedicated route, effective-dated forms/history retained | Empty state tested. |
| helpdesk | Dedicated shared table/Sheet, confidential controls remain distinct | Navigation tested; persisted journey in existing regression. |
| grievances | Separate capability route, case-handler policy retained | Empty state tested; no reporting-manager grant added. |
| announcements | Dedicated route, audience/acknowledgment retained | Empty state tested. |
| inbox | Dedicated unread/all table, mark-read and authorized module links from the durable server inbox | Uses the existing operations inbox containing attendance/task/HR/DWR/payroll notifications; no simulated push delivery. |
| shifts | Direct entry to existing shifts/holidays/reference tabs | Navigation tested; weekly-off policy configuration has no separate new workflow. |
| approvals | Dedicated queue, empty/error/loading, links to existing review workflows | Navigation tested; exact-record deep links remain limited by existing workflow contracts. |
| analytics | Scoped deterministic metrics first, separate optional explanation, lazy chunk | Navigation tested; no employee ranking or authoritative AI amounts. |
| requests | Shared request/form/feedback styles | Navigation tested; existing profile decision workflow preserved. |
| reports | Separate All Sites read-only reporting | Navigation tested; organization grant retained. |
| access | Shared shell, dense permission editor, Radix preview and audit | Navigation tested; delegation, version checks and protected accounts preserved. |
| setup | Site/organization/modules and reference administration | Navigation tested; separate new site provisioning workflow BLOCKED: existing UI/API exposes assigned-site settings, not site creation. |
| audit | Shared readable timeline, bounded record history | Navigation tested; >100 history pagination BLOCKED by existing bounded contract. |

Legacy `#/operations` and `#/hr` remain functional and guarded. Deep links use hash
routing to preserve existing deployment compatibility. No old workflow was deleted.

## Checks

- PASS: TypeScript (root + HR web), production build, 23 unit tests, 86 isolated
  PostGIS integration tests. Build retains >500 kB chunk warning.
- PASS: 25 routes × 3 desktop sizes, shell/header identity, zero JS errors and
  horizontal page overflow, employee Sheet focus/Escape, collapse, site popover,
  tablet Sheet, dark directory.
- PASS: warm employee revisit makes zero employee reads; real site switch removes
  old employee data; narrowed permission response removes records and navigation.
- Initial scope test failed while source changes hot-reloaded the app during the
  run. Paused edits and reran the focused test: PASS.
- PASS: all 11 distinct browser journeys have passing results. The full 10-test
  run passed 9 and failed the task journey because its nested-dialog wait matched
  the still-saving child. The corrected task journey and new legacy/profile
  journey both passed in the focused two-test follow-up. This is not a claim
  that the earlier full command exited successfully.
- PASS: URL sorting/Back/history-write regression and synthetic 503 recovery.
- PASS: six additional legacy HR/operations screenshots (both routes at all three
  desktop sizes) and employee Employment/history tab.
- PASS: eight static semantic text-color contrast pairs (minimum 4.59:1), plus
  unit coverage of exact negative/large currency display. The new negative-paise
  test initially failed and was fixed before the final 23-test pass.
- NOT RUN: screen-reader audit, exhaustive rendered WCAG contrast audit, every Hindi string,
  CPU/React DevTools profiling, production network/device measurements.
- No lint script is configured. Prettier and TypeScript are available checks.

## Concrete scope limits and blocked additions

- Cross-module employee detail tabs (attendance/payroll/files/tasks under one profile)
  are BLOCKED by absent employee-filtered detail contracts. The existing authorized
  employment, assignment, manager, shift and contact information is redesigned in
  a two-tab Sheet. Fetching all sensitive module records to filter in the browser
  is not an acceptable substitute.
- Global sorting/cursor pagination beyond the bounded payroll/HR/audit responses,
  bulk mutation workflows, and exact-record approval deep links are BLOCKED by
  absent contracts. Loaded-record sorting/paging is labeled; employee directory
  retains its server cursor. No fake bulk approval/export was added.
- Requested attendance time-series chart and new-site provisioning are BLOCKED by
  aggregate-only analytics and assigned-site-settings contracts respectively.
- The actor contract exposes an ID/version, not a display name/avatar. A named
  sidebar account profile requires an identity contract addition; no name is invented.
- Domain financial/evidence details keep specialized native tables/input groups
  with shared tokens and validation; native selects are keyboard-accessible. The
  redesign does not force unrelated detailed calculations into generic row menus.
- Remaining legacy CSS compatibility rules are technical debt. Full Hindi text
  coverage, screen-reader audit, production CPU/network profiling and the existing
  external-service/device release prerequisites are not claimed complete.

All primary routes have integrated redesign work; the blocked additions above and
unperformed release checks prevent an exhaustive completion/production-ready claim.
No production data or deployment was used.

## Visual review and evidence

Screenshots: `docs/evidence/hr-redesign/` (75 primary-route captures, 6 legacy
captures, profile overview/history, dark directory, tablet navigation and timings).
Actual images opened/reviewed include Dashboard, Employees, Employee Detail,
Attendance, DWR, Leave, Payroll, Documents, Expenses, Approvals, Users & Access,
Tasks, Inbox, dark and tablet views. Fixed low-contrast inherited text, mobile
main-width transition overflow and a table URL-reset rendering loop. The older
phase3 workflow screenshots use full-page capture; fixed overlays can appear at
the capture's scroll offset. Primary redesign evidence uses viewport screenshots.

Build PASS with the existing >500 kB entry warning and non-fatal third-party Zod
annotation warnings. No lint command is configured. `npm run contracts` PASS.
Current entry is 558,132 bytes versus the 646,992-byte baseline; total dependency
transfer is not claimed smaller. Runtime timing and limitations are documented in
`HR_PANEL_PERFORMANCE.md`.

## Requested deliverable index

| Deliverable | Result / reference |
| --- | --- |
| 1. Routes redesigned | 25 primary + 2 preserved legacy routes; matrix above |
| 2. Routes/additions remaining | New-site provisioning and cross-module profile extensions blocked by contracts; exact limits above |
| 3. Shared components | DataTable, FilterBar, Timeline, Money, Heading, feedback, FoundationForm, SiteSwitcher |
| 4. Shadcn/Radix | Slot/CVA Button, Dialog/Sheet, Tabs, Popover/Command, DropdownMenu, Tooltip, Sonner; semantic Tailwind tokens |
| 5. Sidebar | Fixed 248/72 px, grouped capabilities, UI-only persisted collapse, scrollable nav, tablet Sheet |
| 6. Navigation | HashRouter/Link, persistent workspace shell; scope-only content remount |
| 7–8. Flicker cause/fix | Zero freshness/retention, route main key, empty-site intermediate state and eager imports fixed; audit/performance reports |
| 9. Queries/cache | 30 s domain / 120 s foundation freshness; 5 min memory retention; deduped keys, 250 ms search debounce; immediate scope purge |
| 10. Bundle | Lazy route modules; entry 646,992 → 558,132 bytes; total transfer increase disclosed |
| 11. Performance | Measured 75 local transitions, median 104–126 ms; warm directory zero reads; detailed envelope in performance report |
| 12. Responsive | 81 desktop viewport route captures plus tablet Sheet and narrow workflow assertions |
| 13. Accessibility | Keyboard/focus/Escape, labels, semantic controls, 8 contrast pairs; unperformed checks above |
| 14. Tests | 23 unit, 86 integration; all 11 browser journeys have PASS results across full run and corrected reruns |
| 15. Build | PASS with large-entry and third-party annotation warnings |
| 16. Blockers | Explicit contract gaps, localization/accessibility/production profiling and unchanged release prerequisites above |
