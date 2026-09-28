# API query audit — 2026-09-29

## Failure and scope

Fastify's 10-second socket inactivity timeout could disconnect a valid handler
while it awaited database results. Removed that cutoff; request receipt and
individual database statement/query limits remain. A real HTTP regression
waits 10.2 seconds and receives a successful response.

Reviewed every route registration and GraphQL resolver in `apps/api/src/app.ts`,
then their domain methods, including authentication, files, notifications,
tracking/offline uploads, payroll, HR, attendance/leave/tasks, DWR/chat,
foundation/access, exports, dashboard and analytics. The main loading problem
was database calls inside record loops. SQL permission checks are still applied
per record, but no longer need a separate network round trip for each check.

## Measured regression budgets

These counts include transaction/context setup and commit, exclude the separate
HTTP session lookup, and measure client-to-database calls, not internal SQL plan
operations. Measurements use disposable local PostGIS databases and synthetic
records. They do not represent production latency.

| API path                          |                                               Database calls in tested case |
| --------------------------------- | --------------------------------------------------------------------------: |
| Bootstrap / site scope            |                                                                       5 / 5 |
| Employee directory                |                   8 per nonempty page (formerly up to 207 for 20 employees) |
| HR records                        |       7 for either 1 or 40 records (formerly 8 additional calls per record) |
| DWR reports                       | 8 for either 1 or 40 reports (formerly up to 5 additional calls per report) |
| Foundation/settings               |                                                                           6 |
| Attendance/leave/tasks snapshot   |                                                                          10 |
| Dashboard                         |                                                                          14 |
| Payroll listing, default input    |                                                                           7 |
| DWR chat home                     |                                                                           8 |
| Tracking monitor                  |                                                                           8 |
| Analytics, one site and all tools |                                                                          21 |
| Bulk duty scheduling              |                                                   13 for either 1 or 7 days |

`tests/integration/api-query-budget.test.ts` enforces budgets, checks page growth,
SQL parameter binding, empty results, tenant isolation and unchanged roster
versions. Existing suites cover larger tracking history, payroll pagination,
field redaction, provenance, exports, private files, revocation and concurrency.

## Changes by route family

- **All domain API calls:** install transaction-local RLS context, then check
  session freshness and site access together on the same connection.
- **Employees:** batch page enrichment, including effective employment,
  assignments, lifecycle, field permissions and actions. Profiles share the
  same implementation. No process-wide identity or permission cache.
- **HR:** history, acknowledgments, actions and files come from one page query;
  independent editor options share one parameterized query. Confidential
  handlers remain omitted. Attachment, audience and handler validation are
  batched; handler inserts are batched.
- **DWR:** batch report history, provenance permissions and employee names;
  preserve transcript redaction. Batch attachment validation, group preparation
  requests and group notification delivery.
- **Operations:** combine independent snapshot sections; retain native timestamp
  decoding for attendance projection. Persist projected segments in one insert.
  Bulk schedules take sorted employee locks, check permissions, calculate site
  timezone windows, simulate chronological overlap decisions, and upsert in one
  batch. Unchanged schedules retain their versions.
- **Payroll:** listing was already paginated and enriched in SQL. Batch allocation
  validation and independent calculation evidence. Bulk stage transitions lock
  rows in sorted order, validate every item, then update/history/audit/notify in
  batches. Failure rolls back the complete batch and retains the item index.
- **Exports:** fetch selected sensitive fields for the entire authorized employee
  set once; retain authorization, expiry, row limits and export auditing.
- **Analytics:** batch source capability checks and avoid separate transactions
  for single-site admission/revalidation. The same transaction rechecks access
  before returning. Multi-site and external-provider rechecks remain explicit.
- **Dashboard, lookup, access/users, role matrix, review queues, profile requests,
  tracking monitor/history and offline uploads:** inspected; reads already use
  bounded/set-based queries. Shared transaction overhead is reduced.
- **Auth, notification registration, photos and file delivery:** no per-record
  query loop found. Keep credential/session rotation, per-file permission checks,
  storage checks and original-scope transaction boundaries.

## Remaining costs and operational verification

Payroll run creation retains bounded per-employment savepoints (up to 100
created results) so an invalid employee can be reported as skipped without
losing valid results. Each result has fewer evidence queries. Payment recording
retains per-item balance enforcement and trigger diagnostics inside one atomic
transaction. These intentional financial write loops are not page-loading
queries and are not claimed to have constant query cost.

The API/database region separation and free-service startup behavior remain
infrastructure costs. No region migration, paid provisioning or schema migration
is included. A lower query count does not prove production SQL execution time;
real authenticated latency must be observed after deployment.

`/health/live` includes Render's public commit revision, when available, to verify
that the new code is actually serving. Public health checks alone do not verify
signed-in module performance. No production employee data was used for tests.

## Attendance and DWR latency repair (2026-09-29)

- AttendanceDay is date- and employee-filtered, paginated in stable groups of 100,
  uses site-timezone day boundaries, retains pending evidence, and skips unrelated
  leave/task/inbox/file reads. Measured 9 DB calls, 8ms in the local synthetic fixture.
- DWR home and personal thread: 8 DB calls each (home previously 13); measured
  11ms and 12ms locally. These are not production latency promises.
- Web DWR chat does not wait for report snapshots; same-scope workspace refreshes
  retain the thread. Polls are single-flight and cancelled when the thread changes.
- Mobile DWR home/thread load concurrently. Attendance reuses scoped capabilities,
  loads employee options once per scope, persists successful uploads across retries,
  joins an active outbox drain, and refreshes after server receipts.
- AI jobs run in bounded parallel batches of three within their 60s DB leases.
  RUN_DWR_AGENT=true enables the AI-only runner beside the API using a separate
  hr_worker connection. No Redis/SMTP consumer or extra server is required for this
  mode. A sleeping Free Render web service also suspends this runner.
- Deployment needs DWR_AI_PROVIDER, the matching provider key/model, and the
  restricted WORKER_DATABASE_URL. Private evidence needs FILE_STORAGE_DISABLED=false
  and private S3 configuration; a queued photo must never bypass evidence checks.
- Verification: 141 existing integration tests passed; 3 added attendance checks
  passed separately (site midnight, employee/pagination/RLS, phone receipt visibility).
  Query budgets, worker concurrency test, and 2 focused browser regressions passed.
  Flutter analyze and 67 tests passed. Groq synthetic DWR returned a validated draft
  in 1.02s; production employee data was not used for tests.
