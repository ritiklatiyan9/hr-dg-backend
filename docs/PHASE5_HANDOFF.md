# Phase 5 progress and Phase 6 handoff

Updated 2026-09-22. Payroll and HR workflows now persist through the existing
backend, React panel and Flutter app. Local acceptance passes; production release
acceptance remains incomplete at the gates listed below. No production data,
AWS migrations, paid provisioning, payment execution or statutory filing was used.
Prior handoffs are preserved in PHASE1_HANDOFF.md through PHASE4_HANDOFF.md.

## Implemented increment

- Exact INR paise payroll components, rational proration, explicit per-line half-up
  rounding, validated manual/component CSV entry and effective-dated compensation.
  No guessed statutory deductions, company rates or LLM-generated amounts.
- Employment/legal-employer/pay-period/revision uniqueness; reconciled site allocations;
  immutable approved snapshots with policy, compensation, attendance evidence,
  calculation inputs and approval history. Missing GPS evidence is not absence.
- Draft → Validate → Review → Approve → Publish, independent actors, prohibited
  self-approval, optimistic versions, idempotent receipts and traceable revisions.
  Historical payslips keep their original site. Allocation visibility grants no
  salary visibility. Own published slips use fresh identity/site/field/export checks.
- Effective-dated lifecycle records, expenses/receipts/settlement status, assets and
  clearance, private documents and expiry reminders, policies/announcements/audiences,
  confidential handler-scoped grievances, helpdesk, inbox and approval queues.
- All sensitive screens remain online-only; salary, bank and grievance records do
  not enter the offline vault. Already downloaded copies cannot be remotely revoked.

## Feature matrix

“Integrated/tested” means the stated local flow has real persistence and tests;
UI coverage differs by row. It does not mean production policies or native hardware
acceptance are complete. “Incomplete” and “Blocked” are explicit remaining work.

| Requested workflow                                                 | Status and concrete evidence/boundary                                                                                                                                                                                                                                     |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Salary structures and salary revision/history                      | Integrated/tested: immutable dated structures, overlap rejection, employment linkage, approved lifecycle revision; web creation, Flutter own history                                                                                                                      |
| Earnings, deductions, overtime, bonus, reimbursements, adjustments | Integrated/tested: BigInt paise fixtures for full/partial month, half-paise rounding and all component kinds; accountant-reviewed manual inputs, no inferred legal/attendance rules                                                                                       |
| Manual/CSV import and pay periods                                  | Integrated/tested: strict per-result component CSV, invalid import atomic rejection, bounded size, canonical employment/period/revision; multi-employee batch CSV is incomplete                                                                                           |
| Payroll review, approval, publication and corrections              | Integrated/tested: independent creator/reviewer/approver, conflicting edits, repeated commands after commit, duplicate approval, immutable final result and linked revision; complete browser journey                                                                     |
| Transfers, multiple assignments and site allocations               | Integrated/tested: historical assignments, allocation reconciliation and unauthorized allocation rejection; site/team grants cannot reveal aggregate pay; bulk cross-site payroll reports incomplete                                                                      |
| My Payroll, breakdown, payslip history and export                  | Integrated/tested: web and Android read published slip; protected printable HTML/CSV/JSON, native PDF adapter, wrong-person/field-deny/download revocation tests. Actual native PDF/print rendering NOT RUN                                                               |
| Promotion, transfer, probation/confirmation, joining, exit         | Integrated/tested: dated independent approvals, profile projection, destination checks, preserved assignment history and asset-clearance gate; joining uses retained onboarding/employment foundation                                                                     |
| My HR Information                                                  | Integrated/tested retained foundation with effective promotion values; safe profile-update requests and field filtering preserved                                                                                                                                         |
| Restricted documents/bank documents                                | Integrated/tested: private intent → real object upload/retry → metadata-stripped download; independent decisions, bank/identity permissions, Jr. HR denial and revoked export; PDF scanner-positive path blocked by missing scanner                                       |
| Expiry reminders and policies                                      | Integrated/tested: versioned reminder configuration, deduplicated server inbox, independent policy publication, selected audience and one acknowledgment per user                                                                                                         |
| Expenses/reimbursements                                            | Integrated/tested: own draft/ready receipt → independent approval/rejection → settlement status/history; Flutter/web forms and shared attachment path; settlement does not execute a payment                                                                              |
| Assets                                                             | Integrated/tested: register → assign → employee acknowledgment → return request → received → cleared; duplicate tags and unauthorized actions rejected; cleared items are terminal in this increment                                                                      |
| Helpdesk                                                           | Integrated/tested: employee → independent HR start/resolve → employee close; persisted Android journey and web submission evidence                                                                                                                                        |
| Confidential grievances                                            | Integrated/tested: explicit captured case handlers plus confidential/site grants; reporting managers/unrelated admins denied; configuration versions and unauthorized handler selection tested. Emergency handler reassignment/recovery is incomplete pending case policy |
| Announcements, audiences, acknowledgments                          | Integrated/tested: explicit audience, independent publication, idempotent acknowledgment and scoped server inbox                                                                                                                                                          |
| HR inbox and consolidated queues                                   | Integrated/tested: React/Flutter data and links use current authorization; HR/payroll/leave/attendance/DWR queues; queued push rechecks inbox and parent grants; real FCM/APNs delivery blocked by credentials                                                            |
| Shift, holiday, leave administration                               | Integrated/tested retained Phases 2–3 configuration/roster/ledger/decision flows; regressions include overnight shifts, dated assignments and double leave approval; production company policies remain unconfigured                                                      |
| Capability-controlled team tools                                   | Integrated/tested retained team scopes and new HR review actions; no title-based powers, Jr. HR salary/bank/confidential restrictions, no implicit grievance manager access                                                                                               |
| Flutter administrative payroll preparation                         | Incomplete: salary-structure creation and CSV preparation are web-admin workflows; Flutter implements employee reading/printing and permitted workflow review stages                                                                                                      |
| Hindi/accessibility and large datasets                             | Incomplete: core labels and dark/140% text-scale evidence exist; some admin action/status labels remain English; screen-reader/physical-device checks NOT RUN; lists currently show a visible 100-record cap                                                              |
| Payroll background batches                                         | Incomplete: current synchronous commands are idempotent; no simulated payroll job. Multi-result orchestration, sustained-load/replay tests and large-list pagination remain Phase 6 work                                                                                  |

## Changed implementation

- `packages/contracts/payroll.ts`, `hr.ts`, GraphQL SDL/operations and generated
  TypeScript/Dart contracts; `packages/authz/src/catalogue.ts` has 26 modules.
- Additive migrations **0023–0031**: payroll, HR records/history/acknowledgments,
  RLS, receipts, lifecycle application, notifications/reminders, historical own
  access and bounded handler validation. All applied to synthetic `hr_local`;
  existing migration checksums remain intact.
- `apps/api/src/payroll.ts`, `hr.ts`, `app.ts`, `files.ts`, `domain.ts`;
  worker event vocabulary, expiry tick and fresh queued-push authorization.
- React `payroll-panel.tsx`, `hr-panel.tsx`, workspace, styles and protected route
  proxy; Flutter `hr_services.dart`, home/API, printing dependencies and generated
  operations. Native query timeout fix retains bounded Dio deadlines/cancellation
  and prevents a late GraphQL listener completing twice.
- New payroll unit, Phase 5 PostGIS/browser/Android tests and protected local
  fixture script. Contracts and release audit live in PHASE5_CONTRACTS.md and
  PHASE6_RELEASE_AUDIT.md.

## Commands and actual results

| Check actually run                                                                           | Result  | Evidence                                                                                                                                                                 |
| -------------------------------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Node 24.16.0 `npm ci`                                                                        | PASS    | 548 packages; audit reported 0 vulnerabilities at install                                                                                                                |
| `npm run contracts`                                                                          | PASS    | Shared TypeScript and Flutter source documents regenerated                                                                                                               |
| `npm run typecheck` / `npm run build`                                                        | PASS    | API, worker, contracts and React; final run includes handler fix                                                                                                         |
| `npm test`                                                                                   | PASS    | 20 tests, including exact payroll arithmetic/import/formula-injection protection                                                                                         |
| `npm run test:integration`                                                                   | PASS    | **74 tests**, including 15 Phase 5 tests on disposable real PostGIS databases; prior auth/permissions/attendance/DWR regressions retained                                |
| Private object storage                                                                       | PASS    | Real loopback S3-compatible upload/retry/stripped derivative and export revocation; synthetic objects cleaned up                                                         |
| `npm run test:browser`                                                                       | PASS    | **6 tests**, 3.2 minutes; real rate-limit pacing, payroll independent actors → publication → employee payslip, HR helpdesk and prior journeys                            |
| Worker verification                                                                          | PASS    | `node --env-file=.env scripts/verify-worker.mjs`: transactional publication and synthetic Mailpit delivery; reminder/push permission logic separately integration-tested |
| Flutter pub get / build_runner                                                               | PASS    | Locked dependencies and generated contracts                                                                                                                              |
| Flutter analyze / flutter test                                                               | PASS    | No issues; **10 unit/widget tests** including late transport response, scopes and encrypted DWR regression                                                               |
| Android Phase 5 integration driver                                                           | PASS    | Published payroll plus employee → HR → employee helpdesk closure persisted; final driver response result=true with no failures                                           |
| Android ordinary APK                                                                         | PASS    | `flutter build apk --debug --target=lib/main.dart`, installed on emulator-5554 and launched without test credential defines                                              |
| Live AWS connection/migration                                                                | NOT RUN | `.env.aws` ignored and mode 0600; `AWS_RDS_ADMIN_PASSWORD` remains blank for owner input; no production DB tests performed                                               |
| Accountant/company/statutory acceptance                                                      | BLOCKED | User supplied no company rules; all acceptance calculations/policies clearly synthetic                                                                                   |
| Real FCM/APNs and scanner-positive PDF                                                       | NOT RUN | Credentials and running scanner unavailable; missing delivery never erases inbox; unscanned PDF stays quarantined                                                        |
| Native PDF rendering/printing, iOS, screen reader, physical shared-device/battery/background | NOT RUN | No physical equipment/signed iOS setup; emulator screenshots are not these checks                                                                                        |
| Real AI provider quality/quotas/latency from Phase 4                                         | NOT RUN | Keys, approved runtime model/provider and reviewed account/retention settings still required                                                                             |

Android evidence: Pixel_8 AVD, emulator-5554, Android 17/API 37, arm64-v8a,
1080×2400, Flutter 3.47.5. Vite warns about the 638 kB minified bundle; build passes.
Firebase's Kotlin plugin warns about future compatibility. Secure-storage plugin
logs its legacy migration fallback on test reinstalls; Phase 5 does not claim a
new physical-device encryption verification.

Visual checks actually inspected: desktop payroll entry and decision history,
printable payslip HTML, helpdesk dialog, 390px web layout, Android payroll and closed
helpdesk history, Hindi/dark/140% text scaling. See `docs/evidence/phase5/README.md`.
Hindi administrative labels and native PDF font rendering need further work.

Resolved failures: immutable date comparison used parsed timestamps instead of SQL
calendar strings; administrative submission/export mappings were incomplete; native
GraphQL timeout could complete a late response twice; repeated browser helpdesk
fixtures selected an older submitted record; generic attendance/leave approver lookup
could not validate grievance handlers. Dedicated scoped handler validation now passes
positive/negative/version tests. Sandbox socket/cache restrictions required approved
local test execution. No tests were pointed at AWS to work around local restrictions.

## Exact Phase 6 checkpoint

Read PHASE5_CONTRACTS.md, PHASE6_RELEASE_AUDIT.md and this matrix before extending.
Keep authentication, RLS, raw evidence, receipt identities and immutable histories.
Complete the explicit incomplete items and obtain company/accountant configuration;
then run staging recovery/load/security/device acceptance before requesting production
rollout. Do not treat a successful local build as release approval.

Review locally at http://localhost:5180 (API http://localhost:4000). Explicit synthetic
payroll/case grants are installed by `scripts/phase5-local-fixtures.ts` only for loopback
`hr_local`; they are not role defaults. Keep API and worker running after migrations.
Normal Android APK: `apps/employee-mobile/build/app/outputs/flutter-apk/app-debug.apk`.
This workspace has no Git repository/remote, so no commit or PR was created.
