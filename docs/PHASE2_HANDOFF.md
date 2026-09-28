# Phase 2 progress and tested handoff

Updated 2026-09-21. **The requested Phase 2 increment is implemented and locally
verified across the backend, React panel and Flutter app.** Phase 1 authentication,
identity and schema were retained; changes use additive migrations. The original
Phase 1 checkpoint is preserved in [PHASE1_HANDOFF.md](PHASE1_HANDOFF.md).
No production data, destructive production migration, paid provisioning, AI call,
external email or production deployment was used. This directory still has no
Git history; no repository was initialized and no user work was replaced.

## Delivered behavior

- Shared 25-module catalogue with distinct self/admin services, meaningful actions,
  field grants, conservative role templates and Inherit/Allow/Deny overrides.
  One SQL decision path checks active membership, site, module, action, record,
  same-record dependencies and sensitive fields, and returns the deciding rule.
- Web Administration → Users & module access and Flutter Work → Users & module
  access: user/module search, assigned sites, templates, action/field scopes,
  delegation limits, preview, required reason, history and optimistic versions.
  Self-escalation/protected accounts/last recoverable Super Admin are guarded.
- Access updates invalidate versions and revoke target sessions. Both clients
  cancel/clear scoped reads, reject late responses, preserve original write scope,
  refresh on foreground and poll access every 15 seconds. Web tabs have independent
  site selection and a BroadcastChannel for access invalidation.
- Employee directory/search/filter/paging, masked profile drawers, onboarding and
  Jr. HR drafts, independent approval, departments/designations/shifts/holidays,
  site settings, reporting hierarchy and preserved dated site assignments.
  Flutter My HR shows only permitted fields and submits safe contact requests;
  Inbox shows real request status; Team is capability-controlled.
- Bounded employee CSV queue/download with authorization at enqueue, preparation
  and download, independent field filtering, no retained PII export bytes and
  formula-safe cells. Explicit read-only All Sites aggregate reporting and its
  REST tool reuse the authorization path.
- Original emerald/graphite/warm-neutral UI: tables, filters, drawers/dialogs,
  tabs, badges, timelines, validation, keyboard focus, English/Hindi, light/dark,
  text scaling, reduced motion, loading/empty/offline/denied/recovery states.
  Unreleased modules are distinguished from denied access and do not pretend to
  provide attendance, payroll, DWR or full document persistence.

## Changed files and migration record

Main implementation files (plus generated contract outputs):

| Area          | Changed / added files                                                                                                                                                                                                       |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Shared policy | `packages/authz/src/catalogue.ts`, `scripts/generate-policy.mts`                                                                                                                                                            |
| Database      | Additive SQL below; `packages/db/src/seed.ts`                                                                                                                                                                               |
| API           | `apps/api/src/domain.ts`, `foundation.ts`, `app.ts`; existing `auth.ts` retained                                                                                                                                            |
| Worker        | `apps/worker/src/index.ts` recognizes access/foundation events and prepares guarded export manifests                                                                                                                        |
| Contracts     | `packages/contracts/schema.graphql`, `operations.graphql`, generated TS; synced SDL/operations and generated Dart                                                                                                           |
| Web           | `src/access-panel.tsx`, `foundation-panel.tsx`, `workspace.tsx`, `workspace-context.tsx`, `ui.tsx`, `labels.ts`, `auth-labels.ts`; updated `main.tsx`, `api.ts`, `styles.css`, Vite proxy                                   |
| Flutter       | `lib/access.dart`, `home.dart`, `providers.dart`, `mobile_ui.dart`; updated `main.dart`, `api.dart`, pubspec/lock; generated GraphQL                                                                                        |
| Verification  | `tests/integration/phase2.test.ts`, browser access/hr suites, mobile live API/reduced-motion tests, `integration_test/employee_flow_test.dart`, `test_driver/integration_test.dart`, private-fixture helper/cleanup scripts |
| Handoff       | README, architecture, permissions, specification, dependencies, this checkpoint and [UI evidence](evidence/phase2/README.md)                                                                                                |

Applied to synthetic `hr_local` and isolated `hr_test_*` databases:

| Migration                     | Purpose                                                                                                        |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------- |
| 0003_access_catalogue         | Canonical modules, permissions and role templates                                                              |
| 0004_access_policy            | Membership, overrides, delegation, team assignments, shared decisions/RLS and invalidation                     |
| 0005_access_administration    | Bounded users/snapshot/preview/save workflow, audit, safeguards and sessions                                   |
| 0006_employee_foundation      | References, site settings, sensitive rows, onboarding drafts, profile requests and assignment services         |
| 0007_exports_reporting        | Export manifests, worker authorization and read-only aggregate reports                                         |
| 0008_employee_request_fix     | Correct request-function variable shadowing without modifying applied SQL                                      |
| 0009_scope_and_session_guards | Contextual scopes, fresh session checks, self/protected guards, module versions and historical employee access |
| 0010_record_dependency_scope  | Evaluate action/field dependencies against the same employee record                                            |

0001–0002 remain unchanged. The final migration runner verified recorded checksums
for all ten migrations. Future changes start with **0011**; do not edit applied
SQL or rerun the initial catalogue CREATE script as a new migration.

## Commands actually run

| Check                                                                                                                                                                                                                                   | Result  | Evidence / limits                                                                                                                              |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `npm ci` under Node 24.16.0                                                                                                                                                                                                             | PASS    | Clean lockfile installation; 543 packages installed                                                                                            |
| `npm audit --audit-level=high`                                                                                                                                                                                                          | PASS    | 0 vulnerabilities; transitive deprecation notices only                                                                                         |
| `npm run db:migrate`, `npm run db:seed`                                                                                                                                                                                                 | PASS    | Synthetic data only; final migration checksum verification also passed                                                                         |
| `npm run contracts`                                                                                                                                                                                                                     | PASS    | Shared TypeScript output plus SDL/operations synced to Flutter                                                                                 |
| `npm run typecheck`                                                                                                                                                                                                                     | PASS    | Backend/shared packages and React; final run after responsive UI refinement                                                                    |
| `npm run build`                                                                                                                                                                                                                         | PASS    | TypeScript emit and Vite production bundle                                                                                                     |
| `npm test`                                                                                                                                                                                                                              | PASS    | 7 unit tests, including scope keys, cancellation and late-response rejection                                                                   |
| `npm run test:integration`                                                                                                                                                                                                              | PASS    | **36 real PostGIS tests**, no skips, uniquely created/dropped isolated databases                                                               |
| `npm run test:browser`                                                                                                                                                                                                                  | PASS    | **3 Chrome acceptance tests**, final run 9.4 seconds; real MFA and live API/worker                                                             |
| `flutter pub get`                                                                                                                                                                                                                       | PASS    | SDK localization/integration test dependencies resolved and locked                                                                             |
| `dart run build_runner build`                                                                                                                                                                                                           | PASS    | Final shared GraphQL/Drift generation completed, 29 outputs                                                                                    |
| `flutter analyze --no-pub`                                                                                                                                                                                                              | PASS    | Final run: no issues                                                                                                                           |
| `flutter test --no-pub`                                                                                                                                                                                                                 | PASS    | **4 unit/widget tests**, including reduced-motion route behavior                                                                               |
| Explicit `flutter test --no-pub test/live_api.test.dart --dart-define-from-file=../../.local/mobile-test.json`                                                                                                                          | PASS    | Real API: self direct edit denied, sensitive fields absent, safe request persisted, both sites, refresh/logout; only OS storage mocked on host |
| `flutter drive --no-pub --driver=test_driver/integration_test.dart --target=integration_test/employee_flow_test.dart -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:4000 --dart-define-from-file=../../.local/mobile-test.json` | PASS    | Real Pixel 8 Android 37 emulator, real secure-storage plugin and API; employee flow plus MFA-verified Super Admin preview/Team; 9 screenshots  |
| `flutter build apk --debug --dart-define=API_URL=http://10.0.2.2:4000`                                                                                                                                                                  | PASS    | Ordinary APK rebuilt **without test credential defines**, then installed over test APK on emulator                                             |
| `node --env-file=.env scripts/clean-mobile-test-requests.mjs`                                                                                                                                                                           | PASS    | Removed only exact synthetic verification requests after the runs                                                                              |
| Visual inspection                                                                                                                                                                                                                       | PASS    | Desktop, 390px web, dark/Hindi, Android employee/admin and 140% text-size examples; [evidence index](evidence/phase2/README.md)                |
| iOS build/device, physical Android, tablet, TalkBack/VoiceOver                                                                                                                                                                          | NOT RUN | No iOS signing/device or physical-device execution in this session                                                                             |
| Real OS reduced-motion visual check and real network-loss device interaction                                                                                                                                                            | NOT RUN | Reduced-motion widget test and guarded recovery implementations exist; no claim of full device accessibility/offline QA                        |
| Production Docker image, remote CI, load/restore tests, deployment                                                                                                                                                                      | NOT RUN | No remote repository/deployment configured; these remain production hardening                                                                  |

The 36 database tests include all seven roles, own versus explicit teams, salary
filtering and same-record dependencies, direct forbidden GraphQL/REST/downloads,
forged/cross-org sites, last Super Admin, self/delegated escalation, actual
concurrent permission edits, downgrade/revoked export jobs, stale versions and
membership, MFA/session/CSRF/refresh behavior, connection reuse, safe requests,
independent draft approval, assignment history, cycles/overlaps and settings
versions. Browser checks prove hidden administration routes perform no forbidden
administration fetch, unreleased versus denied states differ, two tabs retain
independent sites, and an actual downloaded CSV excludes unauthorized fields.

## Failures found and resolved

- Profile-request PL/pgSQL variable shadowing caused a persistence failure;
  additive 0008 fixes it. The approved-request and real mobile flows now pass.
- Scope-only dependency checks could borrow My HR visibility for a team field;
  0010 applies dependencies to the same record, with a regression test. The team
  directory also explicitly filters employees.view for each returned row.
- Historical assignment access, raw disabled-module grants, self-escalation and
  fresh session checks were tightened before the final policy suite passed.
- Repeated synthetic MFA tests encountered replay/rate limits. Fixtures now use
  isolated test client addresses or normal fresh-step MFA; production checks were
  not weakened. Real mobile admin fixture preparation completes normal MFA.
- Narrow web grid overflow and shortened scope labels were corrected and recaptured.
  Native-dialog focus containment and zero page overflow pass browser assertions.
- Flutter analyzer found formatting/import issues; fixed. The admin device test
  initially tried to find a lazily rendered reason field without scrolling;
  corrected the test helper and reran the full device workflow successfully.
- Local emulator/web server stopped during the session interruption. Restarted
  existing local services. One automatic approval review timed out; its allowed
  retry succeeded. There is no remaining approval blocker.

## Remaining boundaries and exact Phase 3 continuation

No known blocker remains for the requested Phase 2 increment. This is a local
verified handoff, not a production release. Full payroll/documents/attendance/DWR,
bulk import, generic approvals and AI analytics remain unreleased. Audit/report
export catalogue keys are reserved; employee CSV is the implemented export.
Mobile supports My HR, requests, Team and access administration; broad site setup
and onboarding forms live in the HR panel.

Before Phase 3 attendance/offline work, settle offline-punch acceptance windows,
server/device time authority, duplicate batches, photos/geofences, overnight
shifts, breaks/rounding/grace, multi-site workday ownership, leave accruals and
regularization/approval delegation. Actual legal employers/geofences, retention,
MFA-loss recovery, signing, HTTPS/SMTP/storage/secrets, restore/load testing and
horizontal rate limits remain business/production decisions. See PROJECT_SPEC.md.

Read AGENTS.md and current docs, then use README startup/check commands. Reuse
`app.policy_decision`, `Domain.site`, transaction-local RLS and record/field scope;
never replace authentication or grant permissions from titles. Future subscriptions
must dispose on the same scope boundary. Keep later modules unavailable until
persistence and authorization are integration-tested.

Review locally at **http://localhost:5180**; API readiness is
http://localhost:4000/health/ready. API, worker, web and local dependency services
were left running; the existing Android emulator has the normal debug APK.
Use `.local/demo-access.json` and protected `.env` locally. Browser tests retain
synthetic HR TOTP setup in `.local/demo-authenticator.txt`; never print these.
Regenerate `.local/mobile-test.json` before device tests because refresh tokens
rotate. Live browser/mobile tests must run sequentially: permission saves revoke
the synthetic employee's sessions. Private `.local` and environment files stay
ignored; no credentials are in the screenshots or ordinary APK defines.
