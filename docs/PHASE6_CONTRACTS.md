# Phase 6 analytics contracts

Updated 2026-09-22. Additive to Phases 1–5. No new identity, employee, file,
permission or notification foundation replaces the existing services.

## Authorized facts

`analytics(siteId: ID!, input: JSON!): JSON!` and REST
`POST /analytics/tools/:tool` accept strictly validated `from`, `to`, `siteIds`.
Dates are inclusive site-local dates, at most 366 days, never future dates.
Site IDs select existing memberships. Organization, actor and permission version
come from the session and are checked again by Domain.site. Multiple sites require
explicit organization-scoped analytics **and** reports access at the anchor, plus
current access at every selected site. Maximum five sites; no organization write.

The seven fixed tools are getWorkforceSummary, getAttendanceSummary,
getDwrCompliance, getApprovalBacklog, getTaskBacklog, getHrSummary and
getPayrollSummary. Unknown tools/arguments, SQL, employee filters and model-supplied
organization scope are rejected. Tools have no business-write capability; reads
append an audit entry. SQL values are parameterized, table names are static.

Every site result includes timezone, from/to, asOf, metric definitions and up to
five recent authorized record references per supported source. Metric fields:
id, label, value (decimal/integer string or null), unit, denominator, eligibility,
source, limitation, state. `no_records` is distinct from `not_configured`,
`not_authorized` and `suppressed`. Unknown GPS is never absence or unpaid time.

| Metric                | Definition / interpretation                                                                                                                                |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Workforce             | Distinct permitted employees assigned during the window; site counts cannot be summed as unique organization people                                        |
| Attendance/late/early | Rostered employee-days and recorded session boundaries against versioned grace; overnight duty belongs to start date                                       |
| Evidence hours        | Latest complete revision per duty; non-overlapping segments clipped to window; office/field/break/outside/unknown seconds kept separate                    |
| Unverified            | Pending event verifications received in window, not presumed absence                                                                                       |
| DWR overdue           | Roster days past configured deadline without a currently submitted/approved canonical report; no invented expected days                                    |
| Approvals             | Currently actionable independent requests created in window; confidential grievances excluded; payroll workflow remains in its own queue                   |
| Tasks                 | Current unfinished/overdue tasks with deadlines in window; not historical status reconstruction                                                            |
| Leave                 | Current status of requests overlapping window, not deducted units/days                                                                                     |
| Documents             | Authorized expiry count by window end; restricted document RLS still applies                                                                               |
| Expenses              | Current pending/settled record counts dated in window; settlement is not payment execution                                                                 |
| Payroll               | Latest published canonical full-calendar-month results at controlling site, exact paise, at least ten employees; source and sensitive-field gates required |

Large attendance/DWR/task aggregates use three narrow SECURITY DEFINER routines.
They return aggregate JSON only, derive scope from the checked-out transaction,
validate dates, and intersect analytics/source permissions once per employee.
All relations explicitly constrain organization/site and eligible employees.
Runtime roles still do not own tables or bypass RLS. Record links and other reads
continue through RLS. These functions are a security review boundary, not arbitrary
SQL endpoints. No daily materialized rollup or persistent analytics cache exists.

## Explanation

`explainAnalytics` first recomputes authorized facts. Cohorts with fewer than ten
authorized workforce members are not sent to AI. No salary, document content,
employee identifiers, names, transcript, free-text question or actual site name is
sent. OpenRouter receives synthetic fact IDs and non-sensitive computed aggregates.
The model selects fact IDs and one of four reading codes using strict JSON Schema.
The server rejects unknown IDs, extra fields, duplicate IDs and incompatible readings,
then renders all numbers/claims itself. This is a constrained factual explanation,
not a conversational analyst, productivity score or employment recommendation.

Required server-only settings: OPENROUTER_API_KEY, OPENROUTER_ANALYTICS_MODEL,
OPENROUTER_ANALYTICS_PROVIDER, ANALYTICS_PROVIDER_REVIEWED_AT,
ANALYTICS_USER_DAILY_CALLS, ANALYTICS_ORG_DAILY_CALLS, ANALYTICS_CONCURRENCY.
Daily budget uses UTC; admission is durable/serialized, provider concurrency is
bounded, calls time out after eight seconds, output is capped at 700 tokens/32 KiB,
and Retry-After blocks immediate retries. No automatic retries or database transaction
is held during the provider request. Model/provider is separate from voice DWR and
the coding model. Provider fallback is disabled; supported parameters are required.
Provider retention is not asserted to be zero. Missing setup leaves deterministic
facts usable. Modes: available/setup_required/explained/insufficient_evidence/
budget_exhausted/recoverable_error. Permissions are rechecked after provider work.

Web reads use actor/org/version/site query keys, cancellation and stale-response
discard. Mobile uses fresh capability checks, lifecycle clearing and generation
checks. Both refresh after 60 seconds and do not persist analytics offline.
Provider work has a fixed deadline; client disconnect cancellation is not yet
propagated into the provider call and remains a documented limitation.
