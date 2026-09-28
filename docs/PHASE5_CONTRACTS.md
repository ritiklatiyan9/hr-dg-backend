# Phase 5 implementation contract

Existing identity, sessions, RLS scope, private files, inbox and outbox remain authoritative.
Payroll is online-only. Currency is INR integer paise strings, never floating-point money.
Line calculations use BigInt rational factors and round half up per line; totals sum rounded lines.
No statutory deductions, absence deductions or company rates are inferred. Accountant-review
acknowledgment, a named policy version and assumptions are required with every calculation.
CSV is a bounded single-result component import with the exact header
`code,label,kind,paise,numerator,denominator`; invalid rows reject the whole command.

Payroll results belong to one employment/legal employer/period and revision; one administrative
site controls the result. Allocations reconcile to net pay and never grant visibility. Historical
results retain their original site. Payroll administration requires selected-site scope plus salary
field access; team grants cannot reveal full compensation. Employees see own published results
with explicit self-service grants and active site membership, even after historical transfer.
Draft → validated → reviewed → approved → published. Creator, reviewer and approver are distinct;
beneficiaries cannot approve. Approved/published snapshots cannot be edited. A subsequent revision
must reference the prior published revision and a reason. Published prior revisions remain visible.

Payments (2026-09-25, `0040`): an append-only ledger records salary payments made outside the
system against approved/published results, with method, reference, date and note. Balances belong
to the employment+period revision chain; the database rejects overpayment, future dates, payment by
the beneficiary and payment of a revision replaced by an approved/published successor, and
serializes each chain. Reversals are linked rows, never edits. `payroll.manage` records payments.
`run` drafts results from one fully covering salary structure per employment (≤100 per call) and
reports every other employment as skipped with a reason; nothing is prorated. Stage transitions and
payments accept up to 100 items atomically. `payroll(siteId, input)` pages with scope-bound keyset
cursors, server filters and an opt-in summary; `/payroll/register/csv` exports current results.

Feature status and actual evidence are recorded in PROGRESS.md; this contract is not a completion claim.

## HR commands and access

`payroll(siteId)` and `payrollCommand(siteId, operation, input)` provide salary
structures and result workflows. `hrRecords(siteId, kind)` and `hrCommand` provide
expense, asset, helpdesk, grievance, document, policy, announcement and lifecycle
records. `approvalQueue(siteId)` merges authorized pending work from these modules,
leave, attendance and DWR. Every command validates a strict schema. Writes carry
clientId and expectedVersion; receipts store only ID/status/version and bind actor,
organization, original site and a digest. Mismatched retries fail. No business
provider call or LLM produces payroll amounts.

Expenses: draft → submitted → approved/rejected → settled. A ready, same-parent
receipt is required before submission. Settlement is a recorded status with a
reason, not bank execution. Assets: draft → available → assigned → acknowledged →
return_requested → returned → cleared, with assigned-employee acknowledgment and
return, administrative assignment/receipt/clearance, unique organization asset tag
and immutable decision history. Cleared assets are terminal in this increment.

Helpdesk and grievances: draft → submitted → in_progress → resolved → employee
closed, with immutable comments/history. Grievances additionally require a named
handler captured from the site's configured handler list, independent site-scope
case permission and confidential-field permission. A reporting relationship never
adds case access. New handler configuration is versioned; changes affect new cases.
Emergency reassignment of cases whose handlers all lose access requires a separately
reviewed recovery policy and is not implemented as a blanket manager bypass.

Documents: draft → submitted → independent approved/rejected; bank and identity
fields are separately gated. Private file intents, scanning/quarantine, metadata
stripping and authenticated downloads reuse the original file service. Document
and policy downloads require export permission in addition to visible metadata.
Configurable expiry reminders default to disabled and deduplicate server inbox
records. Policy/announcement publication requires an independent approver, explicit
user audience and optional acknowledgment; acknowledgments are unique per user.

Lifecycle records capture joining, probation, confirmation, promotion, salary
revision, transfer and exit with effective dates, independent approval and history.
Joining refers to employment created by retained onboarding. Approved promotions
become profile values only on their effective date. Salary revisions reference a
matching immutable salary structure and require payroll authority. Transfers close
the old assignment and append the destination assignment atomically; destination
permission is checked independently. Exit closes employment and assignments only
with all-site authority for affected assignments and cleared assets. Multiple active
employments/future conflicting assignments fail for explicit HR review.

## Snapshots, limits and clients

Snapshots include named calculation policy, engine/rounding version, exact input
lines, effective compensation versions, accessible approved attendance adjustments,
latest verified segment revisions and policy-version IDs. Attendance evidence is
scoped to the result's controlling site; cross-site/manual inputs remain explicitly
recorded assumptions. Missing evidence is not absence. Results cap at 2,000 snapshot
segments and 50 components; CSV input caps at 32 KiB. Lists cap at 100 records and
make this limit visible. Large-scale pagination and batch payroll orchestration are
release-audit follow-ups; this release runs synchronous idempotent result commands,
not a simulated background payroll job.

Flutter and web bind reads/writes to retained immutable scope keys and access versions.
Payroll, bank documents and grievances never enter the offline vault. Native sensitive
screens hide on background and revalidate on return. PDF/print requests fetch freshly
authorized published data; already exported copies cannot be remotely revoked.
Android PDF printing uses printing 5.15.1/pdf 3.13.1, verified against the
[printing API documentation](https://pub.dev/documentation/printing/latest/).
Native PDF generation requests public Noto fonts; font availability is a recoverable
online dependency and must be bundled/validated before an offline-print promise.

The installed graphql 5.2.4 query manager leaves its response listener active after
its stream timeout. A late response can complete twice. Flutter disables that second
request timer and retains Dio's bounded connect/receive deadlines and cancellation;
a deterministic late-response regression test covers the failure boundary.
