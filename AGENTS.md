# Defence Garden HR

Use Node 24 LTS and npm workspaces. `npm ci`; `npm run typecheck`;
`npm run build`; `npm test`; `npm run test:integration` (isolated PostGIS
database required); `npm run contracts`. See README for local provisioning.
Mobile: `flutter pub get`, `dart run build_runner build`,
`flutter analyze`, `flutter test` in apps/employee-mobile.

Preserve existing work. Implement reviewable increments; update docs/PROGRESS.md
with actual PASS/FAIL/NOT RUN evidence and exact blockers at every handoff.
Never use production data for tests or run destructive migrations, paid
provisioning or production deployment without approval.

Identity and organization come only from verified sessions. Site IDs are
selectors. All business access uses shared authorization and a transaction on
one checked-out connection with transaction-local RLS context. Runtime roles
must not own tables or bypass RLS. Auth control-plane credentials cannot read
business tables. Job titles never confer permissions. Assignments are effective
dated; legal employers are distinct from sites. Store instants in UTC.

Caches include organization, actor, permission version and site. Cancel reads,
discard stale responses and clear values on scope changes. Writes capture their
original scope. Never log credentials, tokens, payroll or sensitive profiles.
Future modules stay explicitly unavailable until backed by tested persistence.
The phase map and remaining product decisions live in docs/PROJECT_SPEC.md.
