# Phase 3 progress and tested handoff

Updated 2026-09-21. Phase 3 backend, React and Flutter operations are implemented and locally verified.
Backend, browser, native offline and full employee/admin device acceptance passed. Authentication and historical schemas remain
intact. Prior completed evidence is retained in PHASE1_HANDOFF.md and PHASE2_HANDOFF.md.
No production data, deployment, paid resources or actual company rules were used.

## Implemented

- Versioned PostGIS site fences/policies, photo IN/OUT, multiple sessions, raw
  capture/receipt evidence, independent verification, shifts/overnight rosters,
  late/early flags, correction/overtime review and preserved adjustment history.
- Separate duty/event/observation/segment/adjustment records. Non-overlapping
  office/field/break/outside/unknown projections retain source IDs and assumptions.
  Unknown GPS never becomes automatic absence or unpaid time.
- Explicit field start/end, assigned photo visits with geodesic radius checks,
  accuracy/stale/gap route view, last seen and known/unknown location summaries.
  Native geolocator integration, foreground disclosure/notification and bounded
  movement/battery-aware collection; no force-stop continuity claim.
- Actor/site-bound AES-GCM offline queue for permitted events and drafts. Original
  scope, client IDs, capture/payload version, bounded retry and distinct local/sync/
  verification/accepted/rejected states. Authorization is rechecked before every
  synchronization. Account changes/logout erase local keys and queue data.
- Configured full/half-day leave and atomic ledger, overlap prevention, independent
  approver decisions, exactly-once debit; tasks, deadlines, priority, status,
  comments, attachments and authorized team views connect to both homes.
- Authenticated private upload intents, strict size/type/image decoding, original
  evidence hashes, stripped derivatives, quarantine and protected downloads.
  Durable server inbox plus transactional outbox and optional real FCM adapter.
  No push configuration is represented as successful delivery.
- Additive migrations 0011–0016 and shared generated GraphQL envelopes with strict
  operation schemas. Phase 4–6 product features remain explicitly unreleased.

## Current evidence

| Check                                                                                  | Result  | Evidence                                                                                                                      |
| -------------------------------------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Node 24 `npm ci`                                                                       | PASS    | 548 packages installed; audit 0 vulnerabilities                                                                               |
| `npm run contracts`                                                                    | PASS    | Shared TypeScript and Flutter documents regenerated                                                                           |
| `npm run typecheck`                                                                    | PASS    | Backend/shared packages and React                                                                                             |
| `npm run build`                                                                        | PASS    | TypeScript and Vite production bundle                                                                                         |
| `npm test`                                                                             | PASS    | 11 unit tests, including unknown observations, overnight/non-overlap, missed exit and event order                             |
| `npm run test:integration`                                                             | PASS    | 49 isolated real PostGIS tests; all prior access/authentication regressions retained                                          |
| Real private S3 workflow                                                               | PASS    | Upload retry after commit, immutable changed upload, stripped derivative, anonymous/forbidden download denial, PDF quarantine |
| Connected Phase 3 Chrome flow                                                          | PASS    | Configuration → photo IN/OUT → task assignment → employee status/comment → HR view; desktop/narrow screenshots                |
| Complete Chrome regression suite                                                       | PASS    | Four tests including Phase 1–2 and connected Phase 3; 12.9 seconds                                                            |
| Flutter pub get / build_runner                                                         | PASS    | Locked dependencies; 45 generated outputs                                                                                     |
| Flutter analyzer / unit/widget suite                                                   | PASS    | No issues / 6 tests; final lifecycle and display edits checked                                                                |
| Native Android encrypted vault                                                         | PASS    | Real OS key storage, ciphertext reopen, account isolation, tamper rejection, key/file removal                                 |
| Android process relaunch / offline synchronization                                     | PASS    | Actual force-stop and separate-process recovery; original-site draft accepted exactly once; final UI teardown passes          |
| Ordinary APK without test credential defines                                           | PASS    | Normal main.dart debug APK built without test defines; adb install succeeded and MainActivity launched                     |
| Physical extended duty session, battery/background                                     | NOT RUN | User has no physical device                                                                                                   |
| iOS build/native encryption/permissions, real push delivery, scanner-positive delivery | NOT RUN | No iOS signing/device, FCM/APNs credentials or live ClamAV instance                                                           |

Regression findings fixed during implementation: publishing module availability
initially copied an older policy function; additive 0016 restores recursive
record-scoped field dependencies and all salary-filter tests pass. PostgreSQL Date
comparisons now preserve milliseconds. New unknown samples invalidate older inside
observations. Visit order/radius checks, dynamic form options, field-review grants, authenticated per-actor throttling
and Flutter screen teardown were tightened after tests exposed gaps.

## Configuration and Phase 4 boundary

Visual checks: desktop and 390px React operations plus native duty/tasks/sync
screens were inspected. Physical/assistive-technology checks are not inferred from
these captures. The Phase 2 device regression also exercises Hindi/dark/140% text.

The user explicitly confirmed no company policies, FCM credentials or physical
test equipment. Production policy/leave setup remains unconfigured. Browser tests
create explicitly named synthetic local fixtures only. No payroll calculation,
absence deduction, accrual, overtime rounding or legal policy is invented.

See PHASE3_CONTRACTS.md for schemas/limits and PHASE3_DESIGN.md for native references.
Read models expose bounded recent history (100 sessions/requests/tasks and 3,000
associated raw events), not a full archive. The map is a coordinate schematic with
accuracy and gaps; no outside map provider receives location data. PDFs remain
quarantined without a scanner. Evidence retention and orphan-upload cleanup need
an approved company retention policy before production. iOS execution and physical
battery/background performance must be verified separately, not inferred from the
Android emulator. FCM is implemented but actual delivery is NOT RUN.

Phase 4 should consume reviewed attendance/leave evidence and existing scoped
capabilities, preserve all applied migration checksums, and add DWR/AI workflows
without changing raw attendance or treating unknown intervals as payroll decisions.

Native encryption evidence is Android-emulator evidence, not hardware attestation.
The secure-storage plugin logged a legacy EncryptedSharedPreferences migration
fallback on test APK reinstalls; the actual encrypted vault, native key persistence,
relaunch/decryption, tamper rejection and logout deletion tests passed. iOS uses a
device-only key accessible after first unlock for authorized background writes;
its actual native execution remains NOT RUN.

Reproduction of native offline acceptance uses
`flutter drive --keep-app-running --driver=test_driver/phase3.dart
--target=integration_test/offline_flow_test.dart -d emulator-5554
--dart-define=OUTBOX_STAGE=capture` with protected local test defines, followed by
`adb shell am force-stop com.defencegarden.defence_garden_employee` and a separate
run with `OUTBOX_STAGE=resume`. The test asserts one server comment at the original
site, retries sync without duplication, and captures real duty/tasks/sync views.
The capture screenshot is explicitly a harness; resume screens are product UI.
Use `scripts/mobile-test-env.mjs` before the older employee/admin device regression,
since its protected refresh token is single-use and cannot be reused from Phase 2.

Worker verification: `scripts/verify-worker.mjs` passed transactional event publication
and synthetic recovery-mail delivery with the updated Phase 3 worker running.

Final main-app Android regression: PASS. Employee Home/Work/Inbox/Me, safe profile
request, sensitive-field filtering, Hindi/dark at 140% text, logout, then a freshly
MFA-verified Super Admin's access preview and Team view all passed on the emulator
(28 seconds). Earlier reruns correctly rejected an expired fixture refresh token
and a leftover duplicate profile request; refreshing/cleaning only those synthetic
fixtures resolved them. Screenshots in `evidence/phase2` were refreshed by this run.
The exact synthetic verification profile requests were removed afterward.

Final review environment: HR web is running at http://localhost:5180, API at
http://localhost:4000 and the updated worker is running. The ordinary Android APK
was installed successfully and launched after all device tests. No production
deployment or Git remote/PR was created.

## AWS RDS preparation (2026-09-21)

The operator supplied an AWS RDS PostgreSQL endpoint in `ap-south-1` and will add
the master credential locally. The ignored mode-`0600` `.env.aws` file now exists
with generated, distinct runtime/auth/worker passwords and an encryption key. The
official Mumbai RDS CA bundle was downloaded over HTTPS to an ignored mode-`0600`
path. Setup commands provide a secret-safe read-only check, explicit dedicated
database/role provisioning, additive migrations, runtime-role verification and
role-separated generated process environments. No seed or destructive database
operation is part of this flow.

| Check | Result | Evidence |
| --- | --- | --- |
| AWS environment template/init and file permissions | PASS | `.env.aws` and regional CA are both mode `0600`; secrets are ignored |
| Official `ap-south-1` RDS CA download | PASS | AWS bundle validated as PEM with three certificates |
| AWS setup TypeScript | PASS | Included in root `npm run typecheck` |
| Live RDS read-only connection | NOT RUN | `AWS_RDS_ADMIN_PASSWORD` intentionally remains for the operator to enter locally |
| RDS provisioning/migrations/runtime role validation | NOT RUN | Depends on a successful credentialed read-only check and explicit operator execution |
