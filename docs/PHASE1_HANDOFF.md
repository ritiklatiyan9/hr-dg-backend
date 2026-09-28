# Progress and verification checkpoint

Updated 2026-09-21. Implemented from the attached request in this session.
The starting directory was empty; no source, migrations, instructions, Git
history or user changes were replaced. No external production deployment,
paid provisioning, production migration or external email was performed.

## Phase 1 implementation

Implemented and exercised: Fastify/Mercurius API, shared authorization, real
PostgreSQL/PostGIS isolation, Drizzle profile persistence, secure authentication,
invitation/recovery services and local delivery, TOTP MFA, web cookies/CSRF,
mobile refresh rotation/replay revocation, two-site bootstrap and profiles in
React and Flutter, scope-safe caches/reads/writes, worker/outbox, private local
S3, synthetic seeds, generated contracts, Docker configuration and CI workflow.

The editable profile slice is employee phone/contact data; employee setup and
all later product modules remain on the six-phase roadmap. Future navigation
is clearly unavailable and has no fabricated metrics.

## Changed files

All source files were newly created in this empty repository:

- Root: AGENTS.md, README.md, package.json/package-lock.json, tsconfig.json,
  .nvmrc, .gitignore, .dockerignore, .env.example and playwright.config.ts.
- `apps/api/src`: app.ts, auth.ts, security.ts, domain.ts, index.ts.
- `apps/hr-web`: Vite/TypeScript configuration, index.html, components.json,
  src/main.tsx, api.ts, scope.ts, styles.css and components/ui/button.tsx.
- `apps/employee-mobile`: Flutter manifest/lockfile, build configuration,
  Android/iOS scaffolding, lib/main.dart, api.dart, dio_graphql_link.dart,
  scope.dart, offline.dart/generated Drift model and generated GraphQL models;
  unit/widget and explicitly invoked live API tests.
- `apps/worker/src/index.ts`: transactional event and encrypted mail delivery.
- `packages/db`: migrations, scoped connection helper, Drizzle profile schema,
  migration runner and synthetic seeds. `authz`, `contracts`, `config`: shared
  actor policy, schema/operations/TypeScript generation and validated configuration.
- `infra`: compose.yaml, Dockerfile, Dockerfile.postgres, init-db.sh.
- `tests`: unit/security.test.ts, integration/isolation.test.ts, browser/hr.spec.ts.
- `scripts`: local-env, sync-mobile-contracts, mobile-test-env, verify-storage,
  verify-worker. `.github/workflows/ci.yml`.
- `docs`: PROJECT_SPEC.md, ARCHITECTURE.md, PERMISSIONS.md, DEPENDENCIES.md,
  this PROGRESS.md.

Local generated secrets, SDK, npm cache and demo access information are under
ignored `.env`, `.env.test` and `.local` paths. Their values were not committed
or included in the documentation. Repo was not initialized/committed to Git.

## Migrations

- `0001_foundation.sql`: schemas, organizations, legal employers, PostGIS sites,
  users/employees, employment/assignments, capability mapping/grants,
  sessions/devices/action tokens, authentication audit, encrypted mail outbox,
  operational audit/outbox, composite FKs, RLS policies and restricted grants.
- `0002_permission_invalidation.sql`: privilege changes and assignment changes
  increment affected actors' permission versions; elevated grants require MFA.
- Migration runner uses a transaction, advisory lock and SHA-256 checksums.
  Both migrations applied to synthetic `hr_local` and isolated test databases.
  No production database was connected.

## Commands actually run and results

| Check                                                                           | Result  | Evidence / scope                                                                                                     |
| ------------------------------------------------------------------------------- | ------- | -------------------------------------------------------------------------------------------------------------------- |
| Official documentation and registry version checks                              | PASS    | Sources and resolved versions recorded in DEPENDENCIES.md                                                            |
| `npm install`, patched Nodemailer install, final `npm audit --audit-level=high` | PASS    | Final audit: 0 vulnerabilities                                                                                       |
| `npm run local:env`                                                             | PASS    | Random local credentials; existing files protected                                                                   |
| Docker Compose `up -d --build --wait`                                           | PASS    | PostgreSQL/PostGIS, Redis, SeaweedFS, Mailpit running                                                                |
| `npm run db:migrate`, `npm run db:seed`                                         | PASS    | Additive migrations; synthetic two-site organization plus isolation tenant                                           |
| `npm run contracts`                                                             | PASS    | Generated TypeScript; synced common SDL and operations to Flutter                                                    |
| `npm run typecheck`                                                             | PASS    | Backend/shared packages and HR web                                                                                   |
| `npm run build`                                                                 | PASS    | TypeScript emit and Vite production bundle                                                                           |
| `npm test`                                                                      | PASS    | 7 unit tests: password/crypto, MFA gate, dates, cache keys, late responses                                           |
| `npm run test:integration`                                                      | PASS    | 19 real PostGIS tests; no skips; pool size 1 also exercised                                                          |
| `npm run test:browser`                                                          | PASS    | Real Chrome: MFA, two independent tabs, site changes, persisted profile and logout                                   |
| Flutter stable SDK installation/version                                         | PASS    | Local Flutter 3.47.5 / Dart 3.13.4                                                                                   |
| `flutter create --platforms=android,ios ... --no-pub`                           | PASS    | Native projects generated, existing app code preserved                                                               |
| `flutter pub get`, `dart run build_runner build`                                | PASS    | GraphQL and Drift models generated, pubspec.lock saved                                                               |
| `flutter analyze --no-pub`                                                      | PASS    | No issues                                                                                                            |
| `flutter test --no-pub`                                                         | PASS    | 3 unit/widget tests                                                                                                  |
| Explicit Flutter `test/live_api.test.dart` with protected local defines         | PASS    | Real HTTP API/PostGIS profile persistence, both sites, refresh and logout; only secure-storage plugin mocked on host |
| `node --env-file=.env scripts/verify-storage.mjs`                               | PASS    | Private object round trip; anonymous GET denied with 403; test object removed                                        |
| `node --env-file=.env scripts/verify-worker.mjs`                                | PASS    | Events published and synthetic recovery email delivered to local Mailpit                                             |
| `flutter build apk --debug --dart-define=API_URL=http://10.0.2.2:4000`          | PASS    | Built `apps/employee-mobile/build/app/outputs/flutter-apk/app-debug.apk`                                             |
| iOS package/device execution                                                    | NOT RUN | Requires Xcode/signing/device verification                                                                           |
| API production Docker image build                                               | NOT RUN | Dockerfile provided; local dependency services built/verified                                                        |
| Remote GitHub Actions run                                                       | NOT RUN | Workflow written; no remote repository configured                                                                    |
| Production deployment, AI calls                                                 | NOT RUN | Outside Phase 1 and no production approval/credentials                                                               |

## Failures found and resolved during verification

- Initial npm network/IPC restrictions required sandbox-approved install/test runs.
- Initial mail library had a high advisory; replaced with patched 10.0.10 and
  reran audit (zero remaining findings).
- Docker Desktop was stopped, its helper was outside PATH, and the PostGIS tag
  lacked arm64. Started Desktop, used its CLI/helper and x86 image emulation.
- MinIO image was unavailable; official source is archived. Replaced local S3
  with verified SeaweedFS 4.47. No paid service was used.
- macOS script bind-mount execution failed during first database initialization.
  Provisioned only the missing local roles, and changed the image to COPY a
  non-executable sourced initialization script. Final Compose build passed.
- CSRF was rejected with GraphQL HTTP 200; formatter now preserves HTTP 403.
- Administrative grant elevation could reuse a non-MFA login flag; ordinary
  sessions now remain explicitly unverified and a regression test proves gating.
- Browser interaction revealed unstable table data references and a sign-out
  control below a short viewport. Memoized data and scrollable sidebar fixed both;
  complete browser test passed afterward.
- Flutter client API mismatch, lints and host test HTTP interception were fixed.
  Real HTTP is enabled only in the explicitly invoked live integration test.
- Database restart exposed an unhandled idle-pool error in the worker. Added a
  redacted pool error handler and verified worker delivery after restart.

## Remaining work and boundaries

- Phase 2: real onboarding/account creation, assignment management and reviewed
  permission-administration UI. Invitation flow currently targets provisioned users.
- Phase 3–6: full scope remains in PROJECT_SPEC.md; no attendance, payroll,
  DWR, approval engine or AI analytics is represented as complete.
- Deployment decisions: real legal employers, site geofences and policies,
  production HTTPS domain, SMTP credentials, S3 provider, secret rotation,
  MFA-loss recovery, retention/backup policy, mobile signing and app IDs.
- Physical-device Keychain/Keystore, offline policy, platform distribution,
  restore/load testing and horizontal rate-limit storage need later verification.
- Current API and worker plus web dev server use generated local configuration.
  Web: http://localhost:5180. API readiness: http://localhost:4000/health/ready.
  Local services are intentionally left running for review; no production state.

## Exact continuation

Read this file and PROJECT_SPEC.md first. Preserve the existing monorepo.
Use README startup commands, then typecheck/build/unit/PostGIS tests. Do not
replace auth/RLS or bypass MFA to make tests pass. Use `.local/demo-access.json`
and `.env` for local demo access; after browser tests the synthetic HR authenticator
URI is in private `.local/demo-authenticator.txt`. Do not print those secrets.
Resume the next phase only after resolving its listed business decisions.
