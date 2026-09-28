# Phase 4 progress and Phase 5 handoff

Updated 2026-09-22. Backend, React HR and Flutter DWR workflows are implemented
and tested locally. Manual reporting works without AI credentials. Voice adapters
pass deterministic tests with real local PostgreSQL/private storage. Real-provider
quality, quotas and latency are **NOT RUN**; production voice acceptance remains
open. Prior evidence and AWS setup status are preserved in PHASE1_HANDOFF.md,
PHASE2_HANDOFF.md and PHASE3_HANDOFF.md.

No production data, AWS migrations, paid provisioning or deployment were used.
Existing authentication, authorization and Phase 3 raw evidence remain intact.

## Changed files and delivered flows

- `packages/contracts/dwr.ts`, GraphQL schema/documents and generated TypeScript/
  Flutter contracts: strict manual/AI draft schema and Not stated versus None.
- `packages/db/migrations/0017_dwr.sql` through `0022_dwr_reviewer_notifications.sql`:
  canonical reports, immutable revisions, receipts, settings, private voice jobs,
  usage admission, provenance permissions, reminders and scoped push. All six
  applied locally; earlier migration checksums were retained.
- `apps/api/src/dwr.ts`, `dwr-voice.ts`, `dwr-provider.ts`, `app.ts`, `domain.ts`,
  `files.ts`: save/submit, comments/return/approval/amendment, private attachments,
  print, provider stages/cancellation/budgets and fresh authorization. S3 region
  now follows configuration.
- `apps/worker/src/index.ts`: DWR events/reminders and bounded expired-audio
  deletion outside transactions. Missing push is never simulated as delivery.
- `apps/hr-web/src/dwr-panel.tsx`, workspace/home/API/styles/shared dialog and Vite
  proxy: connected reporting/review/history, WAV upload/manual fallback, print,
  deadlines/reminders and scoped navigation. Fixed narrow overflow, dialog
  centering/labels and the StrictMode save/submit lifecycle.
- `apps/employee-mobile/lib/dwr_screen.dart`, home/API/vault, shared mobile theme, pubspec/lock and native
  microphone declarations: native PCM capture, editable preview, encrypted local
  drafts, independent review, explicit submission and home/inbox connections.
  Reviews/approvals never enter offline draft storage. Hindi/dark/scaling supported.
- `.env.example`, `.env.aws.example`, `scripts/aws-rds.ts`: server-only voice
  settings and S3 cleanup-worker configuration. Missing fields added to ignored
  `.env`/`.env.aws`, preserving existing credentials and mode 0600.
- Unit/integration/browser DWR tests, Flutter widget and native capture/resume/
  review tests, Phase 4 screenshot driver, contracts/design/progress documentation.
  The older unreleased-feature test now targets Phase 5 Documents.

## Commands and evidence

| Check actually run                                                           | Result  | Evidence                                                                                                                                                                   |
| ---------------------------------------------------------------------------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Node 24 `npm ci`                                                             | PASS    | 548 packages installed; audit 0 vulnerabilities                                                                                                                            |
| `npm run contracts`                                                          | PASS    | Shared TypeScript/Flutter documents regenerated                                                                                                                            |
| `npm run typecheck`                                                          | PASS    | API, worker, shared packages, AWS setup and React                                                                                                                          |
| `npm run build`                                                              | PASS    | TypeScript and Vite production bundle                                                                                                                                      |
| `npm test`                                                                   | PASS    | 17 unit tests; provider contracts, example, silence/noise, negation, malformed JSON, injection, 429, timeout and cancellation                                              |
| `npm run test:integration`                                                   | PASS    | 59 isolated real PostGIS tests, including prior role/auth/RLS regressions                                                                                                  |
| DWR private S3/provider-mock workflow                                        | PASS    | Upload retry/truncation, site isolation, cooldown/budget, transcript correction/manual fallback, cancellation and mid-provider revocation; no held business transaction    |
| Canonical/review authorization                                               | PASS    | Double submit/approve, concurrent edits, own/team and expired team assignment, provenance filtering, amendment/history, forbidden print/attachments and revoked membership |
| Worker reminder/deletion                                                     | PASS    | Idempotent durable reminders, bounded object cleanup; updated worker publication and synthetic Mailpit delivery via verify-worker.mjs                                      |
| Connected DWR Chrome journey                                                 | PASS    | Save → explicit submit → independent approval → print; manual setup state, denied URL and 390px overflow assertion                                                         |
| Complete browser suite                                                       | PASS    | All 5 tests; 2.1 minutes with test-fixture pacing based on real rate-limit headers; no production throttle bypass                                                          |
| Flutter pub get / build_runner                                               | PASS    | Locked native integration and regenerated contracts                                                                                                                        |
| Flutter analyze / flutter test                                               | PASS    | No issues; 9 unit/widget tests, including dark-theme contrast                                                                                                              |
| Android encrypted DWR process relaunch                                       | PASS    | Capture, adb force-stop, separate resume; original-site ciphertext reopened, explicit confirmation, one server report, local draft removed after acknowledgment            |
| Android independent review                                                   | PASS    | Fresh MFA session, actual report approval/history and no offline queued approval                                                                                           |
| Android Hindi/dark/140% text scaling                                         | PASS    | Native screenshot and no layout exception                                                                                                                                  |
| Ordinary APK without test defines                                            | PASS    | Final normal main.dart debug APK built without test defines; installed and MainActivity launched                                                                           |
| Real Groq/OpenRouter quality, quotas and p95                                 | NOT RUN | No keys, approved model/provider, actual account limits or reviewed retention settings                                                                                     |
| Physical microphone/extended session/battery/background/assistive technology | NOT RUN | User confirmed no physical test equipment                                                                                                                                  |
| iOS build/native encryption/microphone, real FCM/APNs, positive malware scan | NOT RUN | No signed iOS device/build setup, push credentials or running scanner                                                                                                      |
| Live AWS RDS connection/provisioning                                         | NOT RUN | Master password remains for operator entry; no production test/migration attempted                                                                                         |

Android evidence: Pixel_8 AVD, emulator-5554, Android 17/API 37, arm64-v8a,
1080×2400, Flutter 3.47.5. This is emulator evidence, not hardware attestation.
The secure-storage plugin logs a legacy EncryptedSharedPreferences migration
fallback on test reinstalls; native key persistence/AES-GCM reopen/process recovery
pass. Firebase's Kotlin plugin warns about future compatibility; the current build
passes. Vite emits a bundle-size advisory (~600 kB before gzip), not a build failure.

Visual checks: desktop editor/review, centered dialogs, 390px layout, print HTML,
native local recovery/read-only review and Hindi/dark/140% scaling. Screenshots
are in `docs/evidence/phase4`. Physical print, actual speech/AI preview states,
screen-reader interaction, iOS and physical battery/background behavior were not
checked. Longer print content flows to additional pages without clipping.

## Exact next checkpoint and rollout gates

Read PHASE4_CONTRACTS.md and PHASE4_DESIGN.md before Phase 5. The latter specifies
the real-provider quality/latency envelope. Eight-second p95 and a 30-second normal
journey remain targets, not measured achievements.

To activate voice, fill server-side GROQ_API_KEY, OPENROUTER_API_KEY,
OPENROUTER_DWR_MODEL, OPENROUTER_DWR_PROVIDER, policy/quota review dates, per-user/org
call and audio-second budgets, provider RPM/concurrency and 1–168 hour audio TTL.
Never put keys in client assets or screenshots. Verify actual Groq account quotas
and selected provider JSON Schema support/retention first. Configure approved site
deadlines/reminders/amendments/offline drafts through the panel. Local acceptance
settings are explicitly synthetic, not company rules.

Remaining rollout gates: real multilingual fidelity/p95, provider quota/retention
review, physical microphone/accessibility and iOS execution. Transcript/revision
retention needs a policy separate from temporary-audio TTL. Read models expose
bounded recent reports/history, not a full archive. Mobile attachments upload and
display images; PDF access uses HR web and stays quarantined without a scanner.

Phase 5 must preserve canonical IDs, history, receipts and RLS. DWR employee claims
must never become payroll approvals, measured hours or payment release. Do not
rewrite Phase 3 raw attendance or interpret unknown GPS as absence. Payroll/full-HR
and analytics modules remain unreleased.

Native reproduction: `flutter drive --keep-app-running --driver=test_driver/phase4.dart
--target=integration_test/dwr_flow_test.dart -d emulator-5554
--dart-define-from-file=../../.local/mobile-test.json --dart-define=DWR_STAGE=capture`,
then adb force-stop and a separate `DWR_STAGE=resume` run. The fixture helper
`scripts/mobile-test-env.mjs` prepares protected credentials and normal MFA.
Regenerate before `integration_test/dwr_review_test.dart`; refresh tokens rotate.
Never ship these test defines in an ordinary APK.

Local review services: API http://localhost:4000, HR web http://localhost:5180 and
the updated worker. This workspace has no Git repository/remote; no PR was created.

Resolved verification failures: strict-mode editor state prevented submit after save; narrow grid tracks overflowed the viewport; reminder times wrapped across midnight; old browser assertions still called DWR unreleased. Follow-up fixes and regressions pass. Accelerated browser journeys now honor rate-limit reset headers between shared synthetic accounts. Manual fallback explicitly detaches failed voice jobs while retaining text; its encrypted-draft widget regression passes.

Final visual correction: explicit on-surface body/label colors keep Hindi dark-theme text readable. The contrast regression passes; native visual-only recapture uses an already approved report and stable theme rendering. The earlier native mutation test independently proved review/approval and no offline approval persistence.
