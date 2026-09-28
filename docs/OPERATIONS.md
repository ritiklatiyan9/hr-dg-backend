# Operations and release runbook

Updated 2026-09-22. Configuration is prepared for review, **not deployed**.
No paid resources were provisioned and no production database was migrated.

## Local / staging / production separation

Local uses Node 24, npm workspaces, Docker PostGIS/Redis/private S3-compatible storage
and Mailpit. Keep `.env`, `.env.test`, `.env.aws`, `.local` and build-time test defines
out of version control/images. `npm run local:env` creates new files only; never run
it to replace an existing database's passwords. README provisioning remains valid.

Staging blueprint: `infra/render.yaml`; API and built HR panel share one HTTPS origin,
worker is separate, Redis is private with no eviction. Applying it creates paid
services and needs owner approval. Copy names, databases, buckets, keys and origins
for production; never point staging at production. Auto-deploy is off. The repository
needs a real Git remote and CI before Render can build it; there is no local Git
metadata at this handoff. No GitHub workflow execution has been claimed.

Suggested co-location: Render Singapore, Neon AWS Singapore and S3 ap-southeast-1.
The user's earlier RDS endpoint is Mumbai; it has not been substituted or connected.
Mumbai↔Singapore latency is unmeasured. Choose and approve Neon versus existing RDS
explicitly before provisioning; no automatic data migration is configured.
[Render regions](https://render.com/docs/regions),
[Neon regions](https://neon.com/docs/introduction/regions).

Neon: run `infra/neon-preflight.sql` with a direct owner connection. Confirm PostGIS,
pgcrypto and btree_gist for the chosen PostgreSQL major version; the official list
supports them. Create `hr_runtime`, `hr_auth`, `hr_worker` with LOGIN NOSUPERUSER
NOCREATEDB NOCREATEROLE NOBYPASSRLS and unique secret passwords, without privileged
role memberships. Do not use the console owner's credential in a runtime service.
Run checksum-verified migrations with the separate owner connection after an approved
backup and maintenance plan. Owner credentials must not be injected into API/worker.
[Neon extensions](https://neon.com/docs/extensions/pg-extensions).

Use Neon pooled connections for runtime transactions; all application scope uses
transaction-local set_config. Direct connections are required for migrations and
pg_dump/restore. Do not introduce session SET, temporary tables or LISTEN on pooled
connections. Test real Neon pool reuse before rollout; only local reuse is verified.
API pools: business 10, auth 5; worker 2 per instance. Keep instance count and shared
database connection budget explicit. Require certificate-verified TLS; never use
`rejectUnauthorized:false`. [Neon pooling](https://neon.com/docs/connect/connection-pooling).

S3: dedicated private bucket, Block Public Access, TLS-only bucket policy, encryption,
least-privilege object Get/Put/Delete and lifecycle/versioning approved for evidence
retention. Supply S3_ENDPOINT, S3_REGION, S3_BUCKET, S3_ACCESS_KEY, S3_SECRET_KEY to
API/worker secret settings. The adapter uses server-mediated downloads, not public
URLs. Configure and test the scanner before allowing quarantined PDFs. Do not add a
bucket lifecycle that deletes intentional attendance evidence earlier than policy.
[S3 encryption](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingServerSideEncryption.html).

API secret settings: runtime/auth URLs, ENCRYPTION_KEY (64 hex), WEB_ORIGIN exact
HTTPS origin, COOKIE_SECURE=true, NODE_ENV=production, SERVE_WEB=true, REDIS_URL.
Worker: worker URL, same encryption key, Redis, S3, SMTP and optional FCM secret file.
Use rediss when a remote Redis endpoint requires TLS. Runtime image is non-root and
contains web assets. Provider keys/configuration stay backend-only; copy optional
analytics/DWR setting names from `.env.example`, never a Codex model selection.

## Cost envelope, checked from official pages

Not a purchased plan or budget approval. Monthly USD list rates at review:
Render API 1 CPU/2 GiB $25 + worker 0.5 CPU/512 MiB $7 + Redis 256 MiB $6 = **$38**.
Neon Launch compute $0.106/CU-hour and storage $0.35/GB-month: an illustrative
always-on 0.25 CU ×730 hours +5 GB is about **$21.10**, before restore history and
other usage. Combined example ~$59.10, excluding a separate staging stack, S3
storage/requests/egress, backups, SMTP, AI, taxes, workspace features and overages.
Scale-to-zero and actual workload change cost; free tier is not a capacity promise.
[Render pricing](https://render.com/pricing), [Neon pricing](https://neon.com/pricing).
Reconfirm current checkout prices before approval. Actual cloud spend created by
this task: none. S3/AI usage costs are unquoted until volume and provider are chosen.

## Release and rollback

1. Freeze a reviewed source revision, close release blockers, obtain deployment approval.
2. Run CI install/contracts/typecheck/build/unit/integration/security/browser/mobile
   gates. Build `docker build -f infra/Dockerfile -t defence-garden-hr:<revision> .`.
3. Back up database and required objects/keys; verify staging restore before changes.
   Apply additive migrations with the direct owner URL. Existing applied SQL checksums
   are immutable. Large index creation needs an approved maintenance window; local
   timings are not a production lock-duration estimate.
4. Deploy staging manually with separate secrets, run role/tenant/download/outbox
   smoke tests, then the same reviewed image to production only after approval.
5. Validate `/health/live`, `/health/ready`, same-origin login/MFA, worker backlog and
   private files. Render HTTP health checks require a prompt successful response;
   workers need separate monitoring. [Health behavior](https://render.com/docs/health-checks).
6. On bad application release, stop affected writes/worker if necessary and redeploy
   the prior compatible image. Do not delete columns, rewrite migration history or
   roll back finalized payroll. New changes are additive; test the chosen previous
   binary on restored data before declaring compatibility. Use a forward repair for
   data issues. Restore is last resort with explicit reconciliation of writes since
   backup. Do not silently replay approvals or payroll publication.

## Monitoring and incident response

Alert setup is a runbook, not a deployed integration: readiness failures >2 minutes;
API 5xx >1%/5 minutes; p95 ordinary reads >250 ms; unpublished outbox age >5 minutes;
failed/exhausted jobs or push attempts; database connection saturation; repeated
permission failures; storage/scanner errors; AI 429/deadline/budget exhaustion.
Assign named on-call owners and test delivery before pilot. Log request ID, status,
latency and error code; never request bodies, session/refresh tokens, salaries,
profiles, transcripts or provider keys. No distributed-tracing backend is deployed.

Redis outage: writes commit durable outbox; publication fails/rolls back within a
bounded timeout. Restore Redis, inspect backlog, let stable job IDs retry; never
flush production queues to clear failures. Current worker business event handlers
are validation/notification foundations, not payroll execution. Future side effects
must use durable idempotency receipts. Inbox persists even without push credentials.
Push leasing is five minutes and attempts are bounded; IDs in deep links reauthorize.

AI outage: deterministic analytics and chat-only DWR submission remain usable. Preserve drafts,
observe Retry-After and budgets, do not silently submit or substitute a provider.
Membership/permission change: retry only after reloading capabilities; don't rebind
queued writes to a newly selected site. Compromised credentials: revoke sessions,
rotate affected service credential through the secret manager, verify least privilege
and audit original scope; encryption-key replacement needs a separate migration.

## Recovery drill

`PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH" node --env-file=.env.test
--import tsx scripts/phase6-restore.ts` (one command; PATH adjustment only on this Mac).
Script accepts only local hr_test control DB, creates isolated databases, pg_dumps to
memory, restores, checks committed marker/counts, role safety and own-record RLS,
then drops only its test databases. `evidence/phase6/restore.json`: 403,495-byte
snapshot in the initial drill; final-schema rerun produced 405,765 bytes, dump ~357 ms,
restore ~629 ms, all checks PASS. No committed pre-snapshot
test marker lost. This is neither production RPO/RTO nor PITR/object/key recovery.

Production runbook: choose approved backup/PITR retention and owner; verify usable
recovery point; restore into a new isolated database with direct connection; restore
matching object versions and encryption secrets; run counts/checksums/migration/RLS
checks and full employee→HR→employee journey; compare last committed business event
to chosen recovery point; record actual data loss/recovery time; switch credentials
only after approval. Preserve old environment for forensic/reconciliation needs.

## Mobile distribution

Android: stable source, Flutter 3.47.5 locked deps, production HTTPS API_URL; remove
all TEST_* defines. Choose signing identity/app ID, protect keystore/passwords, wire
release signing (currently deliberately absent), then `flutter build appbundle
--release --dart-define=API_URL=https://<approved-origin>`. Verify clean install and
upgrade on physical devices, foreground-location disclosure/notification, camera,
microphone, background permission, offline relaunch/logout/account-switch cleanup,
push and printed payslips. Do not upload unsigned/debug/test-driver artifacts.
[Android release](https://docs.flutter.dev/deployment/android).

iOS: install full supported Xcode/CocoaPods, select Xcode toolchain, configure Apple
team/bundle ID/provisioning, APNs and permitted capabilities/background modes. Build
`flutter build ipa --release --dart-define=API_URL=https://<approved-origin>` on a
stable source revision; verify physical device permissions, suspension/gaps,
keychain/data-protection cleanup and accessibility. This Mac currently exposes only
Command Line Tools; iOS build/signing/device checks are NOT RUN.
[iOS release](https://docs.flutter.dev/deployment/ios).

Review Play Data Safety and Apple App Privacy declarations against actual location,
photo/audio, HR, provider and retention behavior. Obtain required employee notices
and approval; implementation is not proof of legal compliance or store acceptance.
