# Security review

2026-09-22. Repository review and local adversarial tests; not an independent
penetration test or a claim of legal compliance. Release remains No-Go for real
employee data until the release gates are closed.

## Preserved boundaries and tested behavior

- Session-derived identity/org, active organization/site membership, effective
  assignments, action/record/field permissions and explicit deny. No role from job
  title. Both direct REST and nested GraphQL use the same checked-out transaction.
- RLS context is transaction-local. Runtime/auth/worker roles are separate, non-owner,
  non-superuser and non-BYPASSRLS. Startup now rejects membership in a privileged or
  business-table-owning role too. Migration credentials are rejected in production
  API runtime configuration; no migration runs at API boot.
- Permission updates retain optimistic versions, audit/reason, delegation limits,
  protected Super Admin and last-admin safeguards. Read/download/job authorization
  is fresh. Session downgrade, stale capabilities, tenant/site forgery, own/team
  boundaries and salary/grievance filtering remain regression-tested.
- Web cookies, MFA, CSRF, refresh replay detection, password recovery and rate limits
  are retained. Production rate limiting uses shared Redis and fails closed on outage.
  GraphQL batches/subscriptions are not exposed. Query depth is eight; cost now counts
  aliases and expanded fragments with early saturation. Request-local profile loaders
  deduplicate aliases without cross-request or cross-scope caching.
- Sensitive responses remain no-store; web/mobile caches include scope/version and
  discard late responses. Sensitive payroll/bank/grievance offline replication is
  prohibited. Existing downloaded copies are outside remote revocation control.
- Private upload intents validate scope/size/type. Quarantine/scanner requirements,
  protected downloads, metadata handling, CSV formula-injection escaping and immutable
  approved payroll snapshots remain enforced. No bank payments/statutory filing added.
- Deterministic analytics intersects source permissions. New fixed aggregate functions
  accept dates only, validate bounds, constrain all relations by session org/site, and
  return aggregates only. Tests cover direct unscoped calls, team intersection,
  cross-site reporting, unknown GPS, latest revisions and overnight clipping.
- AI gets no credentials, SQL, employee text, identities, payroll or document content.
  Small cohorts are excluded. Strict schema permits only existing fact IDs/reading
  codes; every number is rendered from authorized computed facts. Budgets, deadline,
  Retry-After and post-provider permission recheck are tested with mocked providers.
- Immutable audit triggers and existing idempotency receipts remain. Redis publication
  now has a three-second command deadline; failures roll back database publication.
  Synthetic tests cover Redis-unavailable rollback and retry after a queue commit.
  Push leases avoid head-of-line starvation and provider calls no longer hold a DB
  transaction. Recipient/inbox/parent permission is rechecked immediately before send.
  Delivery is at-least-once; push contains IDs only and deep links reauthorize.

Evidence: `tests/integration/{isolation,phase2,phase3,phase4,phase5,phase6,reliability}.test.ts`
(actual suite names are listed by `rg --files tests/integration`), unit scope/payroll/
provider/query-cost tests, `docs/evidence/phase6/integration.log`, browser evidence,
and `restore.json`. `npm-audit.json` reports zero known vulnerabilities at the audit
time. Credential-pattern scan passed; Git-tracked-file checking was NOT RUN locally
because this directory has no Git metadata. CI performs that additional check.

## Open risks / controls required before pilot

| Priority | Risk / unverified item                                       | Required closure                                                                                                                                        |
| -------- | ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| P0       | Company payroll/leave/attendance/statutory rules unspecified | Named company/accountant approval, configured approvers and synthetic-fixture removal from deployment                                                   |
| P0       | Infrastructure credentials/policies and retention unapproved | Staging DB roles/TLS, S3 denial tests, scanner, SMTP, reviewed AI/data/tracking disclosures, retention schedule                                         |
| P0       | Stable current mobile build / device acceptance              | Finish concurrent mobile redesign, rerun profile, offline replay, shared-device and background tests; preserve current work                             |
| P1       | Sensitive analytics inference                                | Fixed salary month/cohort thresholds reduce leakage, not differential privacy; review repeated/cohort-overlap reporting before organization-wide grants |
| P1       | Business recovery policy                                     | Approve MFA-loss and confidential-handler recovery; no insecure support bypass is implemented                                                           |
| P1       | Worker/notification operations                               | Real FCM/APNs and expired/invalid-token scenarios NOT RUN; monitor failed/exhausted jobs, never treat server inbox as delivered push                    |
| P1       | Provider privacy/quotas                                      | Verify approved actual provider settings, retention, residency and measured account quotas; no zero-retention assumption                                |
| P1       | Backup coverage                                              | Logical database restore passed; remote PITR, S3 versions, secret/key recovery and full environment recovery NOT RUN                                    |
| P1       | Large data/UI completeness                                   | HR/payroll 100-row caps, batch imports/jobs, Hindi/accessibility and exact-record analytics deep links remain incomplete                                |
| P2       | Observability                                                | Structured redacted logs/request IDs exist; no deployed tracing collector, alert receiver or tested on-call paging                                      |

Operational secrets belong in the host secret store, never clients, repository,
images, browser storage or logs. Recovery must preserve the encryption key matching
encrypted DB payloads; losing it can make MFA/mail/push data unrecoverable. Do not
rotate it by replacing a value without a reviewed re-encryption plan. Limit S3 IAM
to the dedicated bucket/prefix. Review proxy trust before enabling multi-hop client-IP
rate-limit attribution. Production user data must not be copied into developer tests.

Retention is not silently invented: previously retained voice audio follows its
configured retention (voice capture is removed); DWR chat messages and their
edit/delete history are business records awaiting an approved schedule; audit, attendance/photo, HR documents and analytics usage require the
company's reviewed schedule. Automatic broad business-record deletion is not added.
Provider disconnect cancellation is deadline-bounded, not immediate. Email outbox
delivery still uses bounded synchronous SMTP inside its transaction; test operational
load before scaling. No operational business subscriptions are enabled; denial is
the supported behavior, not untested real-time subscription support.
