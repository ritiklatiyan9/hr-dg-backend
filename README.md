# Defence Garden · Employee & HR

Phase 5: a Fastify/Mercurius API, React HR panel, Flutter employee app and worker,
with shared access administration, employee foundation, photo attendance and field
duty, encrypted offline operations, configured leave, tasks, private attachments
and a durable inbox. DWR is a WhatsApp-style chat: each employee's DWR agent chat
and team groups, with the day's messages prepared into the report by an AI agent
(OpenRouter, in the worker), canonical revisions, independent review, print and
configured reminders. Without AI credentials employees send the chat itself. Payroll and HR services now have
connected persisted workflows; Phase 6 release gates and remaining feature limits
are explicit in the feature matrix. See
[six-phase scope](docs/PROJECT_SPEC.md),
[architecture](docs/ARCHITECTURE.md) and [permissions](docs/PERMISSIONS.md).

For site boundary setup, IN/OUT marking and independent off-site OUT approval, see
the [attendance flow guide](docs/ATTENDANCE_FLOW.md).

## Local development

For the requested hosted setup, follow
[Render + existing RDS PostgreSQL](docs/RENDER_RDS_DEPLOYMENT.md), including the
existing-data/file copy and cutover steps. The instructions below are for isolated
development/testing and accessing the existing migration source.

Requirements: Node 24 LTS, npm, Docker Compose, Flutter stable (verified 3.47.5).
Nothing is deployed or provisioned in a paid service.

```sh
npm ci
npm run local:env
docker compose --env-file .env -f infra/compose.yaml up -d --build --wait
npm run db:migrate
npm run db:seed
npm run dev:api
# In separate terminals:
npm run dev:web
npm run dev:worker
```

Open **http://localhost:5180** (use localhost consistently for Origin/cookies).
API: http://localhost:4000/health/ready. Local mail inbox:
http://localhost:58025. Private S3 endpoint: http://localhost:59000.
The private storage service is SeaweedFS single-node S3, with generated credentials.
PostGIS uses the official x86 image under emulation on Apple Silicon. The small
derived image copies the initialization script to avoid macOS bind-mount execute
permission issues. Ports are bound to loopback for infrastructure.

`local:env` generates `.env` and `.env.test` with random local passwords and an
encryption key, mode 0600, and refuses to overwrite them. Never commit these files.
Seed scripts reject production and non-local/non-test database names. Existing
seed accounts are not overwritten on rerun.

Synthetic access (the deployment binds the organization server-side, so login asks
only for Email ID and Password):

- Deployment organization (`LOGIN_ORGANIZATION_ID`): `10000000-0000-4000-8000-000000000001`
- Super Admin: `superadmin@example.test` (access administration and oversight)
- Admin: `admin@example.test` (DG only; explicitly limited delegation)
- HR: `hr@example.test` (MFA enrollment required on first login)
- Jr. HR: `junior@example.test` (onboarding drafts, no final approval)
- Manager: `manager@example.test` (explicit team-view fixture)
- Supervisor: `supervisor@example.test` (self service only)
- Employee: `employee@example.test` (assigned to both example sites)
- River Green employee: `river@example.test` (only River Green)
- Password: your randomly generated `SEED_PASSWORD` in `.env`.

No fixed production password exists. The browser acceptance test enrolls the
synthetic HR account and writes its authenticator URI privately to
`.local/demo-authenticator.txt`. If that test has run, add that URI/key to your
authenticator to use the demo HR account. Never reuse it for a real account.

Open **Administration → Users & module access** as Super Admin, select a person
and a workspace site, then review role/actions/fields, preview and save with a
reason. Changes revoke the target's sessions and increment their access version.
The sample Admin can delegate only its explicitly bounded employee permissions.
Assigning a site membership is separate from an employee's dated work assignment.

The directory supports search, filters, onboarding/drafts, profile drawers,
reporting/shift/site assignments and safe profile-request review. Site & employee
setup manages departments, designations, shifts, holidays and site preferences.
Employee CSV exports require the worker to be running; downloads recheck access.
All Sites is separately authorized read-only reporting.

Flutter exposes Home / Work / Inbox / Me behind one persistent bottom navigation
(every detail page and form stays inside the shell), permitted My HR fields, safe
profile requests, capability-controlled Team/Approvals and the same
access-management workflow. See `docs/MOBILE_UX_REDESIGN.md` for the screen
inventory, route matrix and evidence.
An employee cannot open the HR directory by knowing its URL. Employment/payroll
fields cannot be changed through a self-service profile request; photo, phone and
basic details (date of birth, gender, blood group, addresses, emergency contact)
reach the record only after HR approval. UI language and
theme can be changed without storing HR data locally.

## Mobile

```sh
npm run contracts
cd apps/employee-mobile
flutter pub get
dart run build_runner build
flutter run --dart-define=API_URL=http://10.0.2.2:4000
```

Use `http://127.0.0.1:4000` for a host simulator, or an HTTPS development API for
a physical device. Android permits local HTTP only in debug. Release builds
require an HTTPS API_URL and real platform signing; release signing is deliberately
unconfigured. Keychain/Keystore stores the session. No employee data is cached
offline in this phase. The local SDK installed during implementation is at
`.local/flutter/bin` and is ignored by source control.

## Verification

```sh
npm run contracts
npm run typecheck
npm run build
npm test
npm run test:integration
npm audit --audit-level=high
node --env-file=.env scripts/verify-storage.mjs
node --env-file=.env scripts/verify-worker.mjs
# With API and web servers running, and installed Chrome:
node --env-file=.env node_modules/@playwright/test/cli.js test
# Mobile:
cd apps/employee-mobile
flutter analyze
flutter test
```

Integration tests require a real PostGIS service and never silently skip. They
create a uniquely named `hr_test_*` database under the dedicated `hr_test` control
database, migrate/seed it and delete only that newly created test database.
They do not use `hr_local` or production records. Browser/mobile live smoke tests
use synthetic `hr_local` data, restore their phone changes, and create audit rows. Mobile requests are cleaned only by the narrowly scoped
synthetic helper below.

For the host Flutter/API smoke test:

```sh
node --import tsx --env-file=.env scripts/mobile-test-env.mjs
cd apps/employee-mobile
flutter test test/live_api.test.dart --dart-define-from-file=../../.local/mobile-test.json
```

For the Android device workflow and screenshot evidence (API/worker running):

```sh
# From the repository root; all fixtures are synthetic and secrets stay local:
node --env-file=.env scripts/clean-mobile-test-requests.mjs
node --import tsx --env-file=.env scripts/mobile-test-env.mjs
cd apps/employee-mobile
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/employee_flow_test.dart -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:4000 --dart-define-from-file=../../.local/mobile-test.json
# Build the ordinary app afterward, without test credentials:
flutter build apk --debug --dart-define=API_URL=http://10.0.2.2:4000
cd ../..
node --env-file=.env scripts/clean-mobile-test-requests.mjs
```

The helper completes normal local Super Admin MFA and creates mode-0600 test
session defines; regenerate them before each device run because refresh tokens
rotate. Never distribute the test binary or credential file. Run browser and
mobile live tests sequentially: the browser permission test intentionally revokes
the synthetic employee's sessions. Screenshots contain only synthetic fixtures
and are indexed in [UI evidence](docs/evidence/phase2/README.md).

CI runs TypeScript builds, real PostGIS isolation tests, dependency audit, Dart
generation, analysis and Flutter tests. Platform distribution, physical-device
QA, backup/restore drills and production deployment remain later-phase work.

## Operator notes

Migration credentials must never be given to the running API. Runtime verifies
its three named roles are non-owner/non-superuser/non-BYPASSRLS. Use reviewed,
additive SQL migrations; no schema-push command is provided. Every applied SQL
file has a recorded SHA-256 checksum. Permission and assignment administration use reviewed bounded services with
shared policy, versions and audit. Never write runtime grants directly.

Production requires an HTTPS reverse proxy, secure cookies, private S3 policy,
SMTP credentials, protected encryption key, separate migration and runtime
secrets, signed mobile packages and the operational decisions listed in the
spec. OpenRouter keys are server-only (DWR agent in the worker, analytics in the
API). The configured DWR model is separate
from the Codex model used to build the application. Tests mock providers unless
explicitly labeled as credentialed real-provider acceptance.

For the prepared AWS RDS PostgreSQL workflow, use
[docs/AWS_RDS_SETUP.md](docs/AWS_RDS_SETUP.md). It uses the official regional CA,
hostname-verifying TLS, a read-only connectivity check, an explicit provisioning
step and separate process environments so the RDS master credential is never
given to the API or worker.

## Phase 3 operational setup

Administration configures versioned attendance limits, an authorized site polygon,
shifts/rosters and explicit leave types/credits in **Day & operations**. Defaults
are intentionally unconfigured. The acceptance suite uses synthetic rules; obtain
actual company policy before production use. See [operational contracts](docs/PHASE3_CONTRACTS.md)
and the local-only `docs/PROGRESS.md` verification log.

Private S3 configuration is reused. Optional `CLAMAV_HOST`/`CLAMAV_PORT` enables
real scanning; without it PDFs stay quarantined and decoded images report scanner
unavailable. Original photo evidence remains private; regular downloads serve the
metadata-stripped derivative. Define an approved retention policy before production;
orphaned uploads and raw originals must not be deleted on an invented schedule.

For real push, provide `FCM_SERVICE_ACCOUNT_FILE` to the worker and corresponding
public Firebase client configuration through Flutter dart-defines:
`FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_SENDER_ID`, `FIREBASE_PROJECT_ID`.
Never ship the service-account key. Enable push in the app's Sync view; missing
configuration is shown honestly. iOS additionally needs signed Push Notifications
capability/APNs configuration. No credentials or paid project were provisioned here.
Native references and platform test limits are recorded in `docs/PHASE3_DESIGN.md`.

## DWR chat setup

Run the additive migrations (through 0039), then open **Daily work reports** in HR
web or **Daily Report** from Flutter Home/Work. Employees chat with their DWR agent
(and in groups) using the phone keyboard, whose mic key dictates Hindi, English or
Hinglish. HR/Admin create groups and appoint group admins in the Groups tab and grant
or deny `my_dwr.*`/`dwr_groups.*` per user in Users & module access. To enable AI
preparation, give the **worker** `OPENROUTER_API_KEY` and `OPENROUTER_DWR_MODEL`
(optional `OPENROUTER_DWR_PROVIDER`, `DWR_AGENT_*_DAILY_CALLS`) and restart it; the
panel shows the agent online once its heartbeat arrives. See [DWR chat](docs/DWR_CHAT.md).
An authorized administrator configures deadlines, reminders, amendments and
permitted offline drafts per site.

Real-provider quality, latency and budgets are not claimed; tests use mocked
providers. Keys are server-only and never reach the web build or Flutter.

## Phase 5 payroll and HR setup

Read [the implementation contract](docs/PHASE5_CONTRACTS.md),
the local-only `docs/PROGRESS.md` feature matrix and tests, and
[Phase 6 release audit](docs/PHASE6_RELEASE_AUDIT.md). Apply additive migrations
through 0031 with the migration role, then restart API/worker. Payroll grants, salary
fields, bank/identity fields and confidential case handlers are explicit capabilities.
The local fixture helper installs synthetic grants only into loopback `hr_local`.

Open **Payroll** or **HR services** in the web workspace. Accountant-confirmed
components, policy version, assumptions and attendance inputs are mandatory. CSV is
a per-result component import with header `code,label,kind,paise,numerator,denominator`.
The editor previews exact amounts before saving. Separate actors review and approve;
published slips appear in Flutter **My Payroll**. No bank payment is initiated.

Configure confidential handlers and optional document-expiry reminder days in HR
services. Approvals and sensitive HR drafts stay online. The normal Flutter APK is
built without `.local/mobile-test.json` defines; those credentials are test-only.

## Phase 6 analytics and release audit

Open **Management insights** with an explicit `analytics.view` grant and the
underlying module permissions. Synthetic local grants/migrations:
`node --env-file=.env --import tsx scripts/phase6-local-fixtures.ts` (localhost
`hr_local` only). Deterministic dashboards work without AI credentials. Configure
the separate analytics model/provider and reviewed budgets in `.env.example` only
after approval; provider keys never belong in Flutter or the HR web build.

Read [release readiness](docs/RELEASE_READINESS.md),
[security review](docs/SECURITY_REVIEW.md), [performance](docs/PERFORMANCE.md),
[operations](docs/OPERATIONS.md) and the local-only `docs/PROGRESS.md` checkpoint.
The real-employee pilot recommendation is **No-Go** until the documented business,
mobile and infrastructure gates are closed. `infra/render.yaml` is review-only;
applying it creates paid services and requires separate approval.

## Automatic duty location

The new **HR → Duty location** module shows received employee location during
HR-assigned shift times, including before check-in. It has separate location
permissions, geofence/accuracy validation, signal freshness and a Leaflet map.
The employee app adapts sampling to movement/battery, encrypts offline readings in
SQLite, and automatically uploads bounded, duplicate-safe batches after reconnecting.
Current or next-day duty windows must first be downloaded while online; see the
linked guide for queue limits, the seven-day sync deadline and device restrictions.
HR must configure dated rosters and enable the site's tracking policy; employees
acknowledge the disclosure and device permissions once. See
[setup, verification and native background limits](docs/DUTY_TRACKING.md).
