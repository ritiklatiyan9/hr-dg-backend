# Phase 6 release audit input

This is a release checklist, not production approval. Preserve the local synthetic
fixtures and prior handoffs. No production data, AWS migration, payment integration,
statutory filing, paid provisioning or deployment was performed in Phase 5.

## Required gates

- Accountant approves actual salary components, attendance inputs, paid-unit rules,
  deductions, overtime rates, proration and rounding. Current fixtures are explicitly
  synthetic; no company/statutory rules are inferred. Manual review remains required.
- Verify AWS runtime/auth/worker/migration credentials, TLS, PostGIS/btree_gist support,
  private S3, scanner, SMTP, Redis and backup/restore against approved infrastructure.
  `.env.aws` is still ignored, mode 0600, with credentials supplied locally by owner.
- Configure confidential case handlers, their narrowly scoped grants, recovery when
  all handlers are unavailable, record/file retention and deletion policies.
- Native iOS build/signing, PDF print/font rendering, physical Android/iOS shared-device,
  accessibility/screen-reader and background/battery tests remain separate gates.
- Real FCM/APNs delivery and scanner-positive PDF acceptance require credentials/services.
- Re-run all role/field/tenant/site/history tests after changing business policies.
  Test restore/replay and revoked downloads against an approved staging environment.
- Add operational pagination beyond the explicit 100-record window, sustained payroll
  throughput, notification/reminder load/backlog testing and budgeted load envelopes.
- Review every new SECURITY DEFINER helper, RLS policy, immutable trigger and privilege
  grant. Runtime is non-owner/non-BYPASSRLS. Auth credentials cannot read business data.
- Native administrative salary creation/import remains a web-admin workflow; Flutter
  supports employee payroll/history/print and capability-controlled review stages.
- Complete remaining Hindi translations of administrative action/status labels and
  validate Hindi fonts in exported PDFs. Current Hindi theme/text-scale screenshots
  are evidence of tested screens, not exhaustive accessibility or localization certification.
- Large multi-employee CSV imports, asynchronous batch payroll jobs, structured case
  escalation/SLA policies and bulk cross-site payroll reporting are not implemented.
  Current component CSV imports and single-result workflow are real and transactional.

## Environment commands

Node 24: `npm ci`, `npm run contracts`, `npm run typecheck`, `npm run build`,
`npm test`, `npm run test:integration` (disposable PostGIS), `npm run test:browser`.
For synthetic browser fixtures only:
`node --env-file=.env node_modules/tsx/dist/cli.mjs scripts/phase5-local-fixtures.ts`.
The script rejects any host/database other than localhost/127.0.0.1 `hr_local`.
It installs explicit fixture grants; they are not product role defaults.

Flutter: `flutter pub get`, `dart run build_runner build`, `flutter analyze`,
`flutter test`; native Phase 5 driver is `test_driver/phase5.dart` with
`integration_test/phase5_test.dart`. Test credentials must stay in ignored mode-0600
`.local/mobile-test.json`. Build/install normal `lib/main.dart` without test defines
when finished; do not distribute credential-bearing integration APKs.
