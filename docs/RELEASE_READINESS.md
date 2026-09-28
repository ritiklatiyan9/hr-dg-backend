# Release readiness — Phase 6 checkpoint

2026-09-22. **No-Go for a real-employee two-site pilot.** A synthetic local demo is
usable. Analytics and release-hardening increments are implemented, but the product
is not certified complete. No production deployment, paid provisioning, AWS database
connection, real push delivery or store approval is claimed.

Prior phase evidence is preserved in PHASE1_HANDOFF.md through PHASE5_HANDOFF.md.
Read [PROGRESS.md](PROGRESS.md) for the latest command results and exact checkpoint;
[SECURITY_REVIEW.md](SECURITY_REVIEW.md), [PERFORMANCE.md](PERFORMANCE.md) and
[OPERATIONS.md](OPERATIONS.md) contain the release review and recovery procedures.

## Current evidence

- Node 24 contracts/typecheck/build and 22 unit tests passed. Full real PostGIS
  integration suite: **86 PASS**, including all prior phase regressions plus analytics,
  request-local loaders, static-file isolation, Redis recovery and push fairness.
- Analytics Chrome journey passed with desktop/narrow screenshots and no horizontal
  overflow or page errors. Full browser rerun status is recorded in PROGRESS.
- Synthetic 500-employee/two-site/year workload: zero final errors, dashboard sample
  p95 769 ms. Attendance read 313 ms and 100-record HR list 521 ms miss the 250 ms
  ordinary-read target. Small sample sizes are disclosed; no production SLA claim.
- Logical restore drill passed data marker/counts, runtime role safety and own-record
  RLS. Final local measured dump ~357 ms / restore ~629 ms; cloud PITR and complete recovery
  are untested.
- Docker image built locally; non-root production-mode DB/Redis/readiness/web smoke
  passed without migration credentials. Blueprint is review-only; cloud validation
  and actual provider connections remain NOT RUN.
- npm audit reported zero known vulnerabilities; credential-pattern check passed.
  Local tracked-file check NOT RUN because there is no Git metadata.
- Samsung SM-G781B Android 13/API 33: initial vault case passed inside an otherwise
  failed profile run, but standalone reruns did not complete. Final native storage
  and UI profiling acceptance is incomplete. A simultaneous Flutter redesign also
  breaks current analyzer/widget checks. The phone was restored to the prior ordinary
  app, not a claimed Phase 6 release. Check PROGRESS for exact command results.

## Requirement matrix

“Integrated/tested” is bounded local evidence, not approval of business policy or
every device path. No row labeled incomplete is hidden behind a success screen.

| Original requirement group                                     | State / evidence / remaining boundary                                                                                                                                                   |
| -------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Existing architecture, Node/workspaces, contracts              | Integrated/tested; shared services and generated TS/Dart retained; additive migrations only                                                                                             |
| Login/session/MFA/recovery/CSRF                                | Integrated/tested; direct and nested authorization, refresh replay, revocation; company MFA-loss recovery policy blocked                                                                |
| Shared module/action catalogue, self vs administration         | Integrated/tested; 26 modules, phase availability and separate self/admin actions; analytics phase now published                                                                        |
| Role templates, inherit/allow/deny, record/field scope         | Integrated/tested; role/team/own/site, salary filtering, Jr. HR restrictions and explicit deny                                                                                          |
| User/site access control panel                                 | Integrated/tested; preview/reason/audit/concurrency/delegation/protected Super Admin/last-admin safeguards                                                                              |
| All Sites / organization reporting                             | Integrated/tested explicit read-only analytics/reporting grant, each site rechecked; no implicit all-site writes                                                                        |
| Employee directory/profiles/departments/designations/reporting | Integrated/tested retained foundation and keyset directory; mobile safe profile requests                                                                                                |
| Sites/assignments/shifts/holidays/settings                     | Integrated/tested dated history; actual company configuration blocked                                                                                                                   |
| Photo/geofence attendance, IN/OUT/history/status/rosters       | Integrated/tested server validation, real private uploads and raw-evidence preservation                                                                                                 |
| Segments/overnight/missed events/corrections/overtime          | Integrated/tested adversarial ordering/retries/overnight/latest revisions; unknown time separate; real policy sign-off blocked                                                          |
| Field duty/visits/route accuracy/staleness                     | Integrated/tested persisted protocol/UI; no fabricated gaps; extended physical background/battery acceptance incomplete                                                                 |
| Durable encrypted offline operations/drafts                    | Integrated/tested outbox/idempotency/scope/account isolation; physical vault reruns incomplete; final redesigned offline UI/relaunch replay not certified                               |
| Leave/half-days/ledger/regularization/approvers                | Integrated/tested overlapping requests and double approval race; actual entitlement/rules blocked                                                                                       |
| Tasks/team views/comments/attachments                          | Integrated/tested scoped assignments/transitions/private files and inbox                                                                                                                |
| Private files/quarantine/scanning                              | Integrated/tested local S3 image path and revoked downloads; deployed scanner-positive PDF flow blocked                                                                                 |
| Inbox/outbox/FCM/deep links                                    | Durable records and fresh permission/lease/retry behavior tested; FCM/APNs delivery blocked by credentials                                                                              |
| Manual DWR/drafts/revisions/review/return/print                | Integrated/tested canonical employee/site/date and independent decisions; prior one-page HTML overflow treatment retained                                                               |
| DWR chat + AI agent (Hindi/Hinglish/English)                   | Integrated/tested chat, groups/admins, locks, moderation, leased agent jobs with mocked provider; voice removed; real model quality/budgets NOT RUN                                     |
| Salary structures/components/proration/rounding                | Integrated/tested exact paise/rational arithmetic; accountant/statutory input blocked; no guessed legal deductions                                                                      |
| Payroll validate/review/approve/publish/history                | Integrated/tested separation/idempotency/versions/immutable snapshots/transfers/canonical allocations; atomic bulk stages; merged decision/payment timeline with actor names            |
| My Payroll/private payslips/exports                            | Integrated/tested web/Android published records, wrong-person denial and CSV protection; payslips show recorded payments; native PDF/font/print acceptance incomplete                   |
| Payroll imports/batches/large history                          | Per-result CSV and structure-based payroll run (≤100/call, explicit skips) tested; keyset pagination, filters, register CSV tested; multi-employee CSV import and async jobs incomplete |
| Salary payment ledger                                          | Integrated/tested append-only payments/reversals, chain balances, overpayment/self/future/race rejection; no bank payout integration (recording only)                                   |
| Promotions/transfers/salary/probation/joining/exits            | Integrated/tested dated lifecycle/history/clearance; organization policies still required                                                                                               |
| Documents/bank docs/expiry/policies                            | Integrated/tested independent publication/acknowledgments/field restrictions; real retention/scanner setup blocked                                                                      |
| Expenses/reimbursements                                        | Integrated/tested receipts → decisions → settlement state; no bank payment execution                                                                                                    |
| Assets/assignment/acknowledgment/return/exit clearance         | Integrated/tested lifecycle and uniqueness; settled assets terminal                                                                                                                     |
| Helpdesk                                                       | Integrated/tested persisted employee → HR → employee closure                                                                                                                            |
| Confidential grievances                                        | Integrated/tested captured handlers and confidential permission; no automatic manager access; emergency handler recovery incomplete                                                     |
| Announcements/audiences/acknowledgments                        | Integrated/tested; durable inbox remains independent of push                                                                                                                            |
| Consolidated HR/attendance/leave/DWR/payroll queues            | Integrated/tested individual authorized queues; analytics summary excludes confidential grievances and keeps payroll queue separate                                                     |
| Web/mobile design, Hindi/English, themes, text scaling         | Existing evidence plus analytics responsive check; concurrent redesign, full Hindi labels, screen-reader and exhaustive accessibility acceptance incomplete                             |
| Deterministic analytics / definitions / gaps                   | Integrated/tested workforce, attendance/hours, DWR, tasks, approvals, leave, docs, expenses, protected payroll; metric contract documents caveats                                       |
| AI explanation and scoped read-only tools                      | Integrated/tested with mocked providers, schema validation, small-cohort exclusion, budgets/deadline/Retry-After/revocation; real provider setup blocked                                |
| Analytics evidence navigation                                  | Authorized source IDs and module links implemented; exact-record preselected deep links incomplete; mobile currently selected-site only                                                 |
| Performance optimization                                       | Measured queries/indexes/narrow aggregates/loaders/cost bounds done; two read targets, sustained-load and full mobile profiles incomplete                                               |
| Security/reliability                                           | 86 integration tests + unit checks; no independent penetration test; deployed logs/traces/alerts and retention/deletion policies incomplete                                             |
| CI/Docker/Render/Neon/S3/Redis                                 | CI/config prepared, Docker/local smoke passed, current official docs checked; no hosted CI run, paid service creation or staging deployment                                             |
| Backups/recovery/rollback                                      | Local logical restore measured; production RPO/RTO, object/key recovery and previous-image compatibility drill incomplete                                                               |
| Android release/iOS/store submission                           | Instructions prepared; Android signing absent; iOS full Xcode/device absent; no release signing/store approval                                                                          |

## Prioritized pilot gates

1. Approve company/accountant policies, real sites/geofences/legal employers,
   approvers, case handlers, privacy/tracking notices, retention and recovery owners.
2. Freeze the mobile redesign; run final analyzer/unit/widget/integration tests,
   release/profile build, shared-device/offline crash recovery, actual frame/startup/
   memory and extended authorized field session. Complete Hindi/accessibility gaps.
3. Finish large-list pagination and any payroll batch workflow included in the pilot;
   otherwise explicitly approve a smaller pilot scope with visible limitations.
4. Supply staging credentials and approve provisioning/deployment separately. Verify
   Neon/RDS roles/TLS/pool isolation, S3 policies/scanner, SMTP/push and secret handling.
5. Approve the DWR agent model/provider and budgets and measure preparation quality
   on real chats, or run chat-only reports (no AI) explicitly.
6. Run complete staging employee→manager→HR→employee journeys, alert drill, backup/
   object/key recovery, rollback and fresh wrong-person/revocation tests. Obtain
   business owner sign-off before any real employee onboarding.

The original completion rule allows an exact checkpoint when another session is
needed. This is such a checkpoint: **Phase 6 is not declared fully complete.**
