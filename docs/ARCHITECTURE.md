# Phase 5 extension

`Hr extends Payroll extends Dwr` adds versioned exact-paise payroll and lifecycle/case
workflows through the existing scoped transaction service. Additive migrations
0023–0031 retain prior tables and checksums. See PHASE5_CONTRACTS.md and
PHASE6_RELEASE_AUDIT.md for implemented boundaries and remaining release gates.

# Architecture

Phase 4 adds `Dwr` on the existing Operations/Domain services. DWR chat
(`DwrChat`, 2026-09-25) replaced the voice stages: personal and group chat messages
are the report sources and the worker's AI agent prepares each employee's draft
through leased, budgeted SECURITY DEFINER jobs (see DWR_CHAT.md). Canonical rows,
immutable history and idempotency receipts are PostgreSQL-backed. Provider calls
occur outside business transactions, with fresh authorization before storing output. Flutter uses the existing native-key encrypted vault for
explicitly permitted local drafts. See PHASE4_CONTRACTS.md for exact boundaries.

## Processes and contracts

The retained Phase 1 modular monolith consists of Fastify/Mercurius API, a
React/Vite HR panel, Flutter employee app and a BullMQ worker. PostgreSQL/PostGIS
is authoritative; Redis supports delivery, private S3 stores protected evidence and attachments,
and Mailpit receives synthetic local mail. No authentication replacement,
schema reset, microservices, Kafka or vector database was introduced.

`Domain` handles scoped records; `Foundation` extends it for access management,
onboarding, references, safe profile requests, exports and aggregate reporting.
GraphQL SDL/operations generate TypeScript and Dart contracts. REST remains
narrow: authentication, authorized CSV download and a bounded employee-summary
tool. There is no general query or AI-execution endpoint.

React uses TanStack Query/Table, Tailwind, Lucide icons, local shadcn-style
primitives, accessible native dialogs/drawers and keyboard tabs. Flutter uses
Riverpod, go_router, generated GraphQL, Dio, secure storage and Drift for UI
preferences only. Both use emerald/graphite/warm-neutral tokens, English/Hindi,
light/dark, loading/empty/denied/recoverable states and reduced-motion support.
Mobile navigation is Home / Work / Inbox / Me; Team/admin routes require grants.

## Database trust boundary

Migration credentials alone own schemas/tables/functions. Runtime startup rejects
superuser, BYPASSRLS or table ownership and verifies the three expected roles.
`hr_runtime` can read RLS-protected business rows, update the restricted profile
columns and call bounded business functions. It cannot directly write arbitrary
permissions, memberships or auth tables. `hr_auth` handles credentials, sessions,
action tokens, auth audit and encrypted mail; it cannot read employee/business
tables. `hr_worker` handles outbox/mail, a narrowly granted export-preparation
function and the bounded DWR agent functions (claim/store/fail/heartbeat), which
read only a claimed employee-day's own messages after rechecking that employee's
access; it cannot select employee rows directly. No runtime SET ROLE ownership exists.

Every business root checks out one connection, begins a transaction, sets
organization/actor/site with transaction-local set_config and executes all nested
reads before commit/release. Verified session and current permission version are
rechecked under a user-row lock. Aliased GraphQL roots remain independently
scoped. Missing context fails closed and pooled connections retain no context.

The shared SQL policy evaluates membership, site, module, action, explicit deny,
record scope, dependencies and sensitive fields. Fixed-search-path SECURITY
DEFINER functions are bounded control operations with explicit organization/site
predicates and internal authorization; only the migration owner can replace them.
Composite foreign keys prevent cross-organization relationships. App tables have
RLS, including references, drafts, requests and separately stored sensitive fields.
See PERMISSIONS.md for role defaults, scope semantics and delegation restrictions.

## Persistence and history

Phase 1 identity, employment, legal employers, sites and auth remain intact.
Additive migrations 0003–0010 introduce the shared catalogue, membership/policy,
permission administration, employee foundation, export manifests and subsequent
hardening. Applied migration checksums are immutable. The generator refuses to
overwrite existing output; follow-up changes require a new SQL migration.

Role templates combine with user/site overrides and delegation bounds. Access
saves lock organization and target, check expected access version, preserve the
last recoverable Super Admin, write sanitized before/after audit, increment the
version and revoke target sessions in one transaction. Site/module edits also
use optimistic versions. Permission checks and mutation commits share the lock
boundary with concurrent revocation; a completed earlier transaction is not
retroactively undone.

Employee onboarding creates an employee, a normal employee account with an
unexposed random password hash, legal-employer employment and dated site
assignment. Invitation is a separate authenticated action through the retained
mail/token service. Jr. HR creates drafts; independent approval materializes the
account. Departments/designations/shifts/holidays and site preferences persist.
Reporting relationships and site assignments retain dated history, reject
cycles/overlaps and never infer capabilities from titles. Shift references are reused by the Phase 3 effective-date roster and evidence engine.

Phone/contact changes by employees create versioned review requests. Approval
requires an independent authorized reviewer and an unchanged employee version.
Administrative employee/profile edits also check per-record action/field scope.
Historical/future site records remain visible to site-scoped administrators;
self/team access follows effective dates in the site's timezone. Instants are UTC.

## Authentication retained

Passwords use salted scrypt (N=32768/r=8/p=1), bounded inputs, constant-time
comparison and dummy hashing for unknown users. Opaque tokens are persisted only
as SHA-256 hashes; MFA secrets and mail payloads use AES-256-GCM.

Web sessions are Secure HttpOnly SameSite=Strict cookies with an eight-hour
absolute lifetime. Local HTTP uses explicit development COOKIE_SECURE=false;
production rejects that configuration. Cookie writes require exact Origin and
session-bound CSRF. JSON-only transport, bounded requests and disabled GraphQL
GET/batching constrain the API.

Mobile uses one atomic OS-protected session, 15-minute access tokens, 30-day
absolute refresh families and single-flight rotation. Refresh replay revokes the
family. Pending MFA has no business access and a ten-minute access limit.
Privileged grants require MFA, including grants added after login. TOTP steps
cannot replay. Password reset revokes sessions and retains MFA requirements.
Recovery/invitation links are opaque, single-use, 30-minute tokens delivered via
encrypted outbox; response text does not reveal account existence.

## Client invalidation

Web selected site is independent per-tab memory. Query keys include organization,
actor, permission version and site; filters/cursors additionally bind their query.
Switching sites aborts reads, clears values and editors, and rejects late responses
using an epoch guard. Writes capture their original scope and never auto-retry or
migrate to the next site. Destinations for new assignments are explicitly chosen
and separately authorized from the source employee site.

Both clients refresh capabilities after changes, poll bootstrap every 15 seconds,
and clear/revalidate on foreground transitions or authorization errors. Web
BroadcastChannel signals relevant access changes to other tabs without changing
their selected sites. Revoked sessions sign out; old versions cannot fetch data.
This is bounded polling, not a claim of instant server-push revocation of pixels
already displayed. Server request/download authorization remains authoritative.
There are no active business subscriptions; future listeners must cancel/rebind
on the same boundary.

Flutter uses immutable Riverpod scope keys, a transport epoch guard and noCache
GraphQL operations. OS secure storage holds sessions; Drift stores only language
and theme. Payroll/profile records stay online. Explicit Phase 3 policy permits
minimal own-duty/task context and operations in the separate encrypted vault.
Network errors hide online-only work and expose recovery/authorized-outbox controls.

## Exports, reporting and delivery

Employee CSV work queues only an actor/session/version/site/column manifest.
The worker's bounded function reauthorizes it before marking ready. Download
checks ownership, current session/version, action and fields again, reads through
RLS and generates fresh CSV (maximum 1,000 records, 15-minute job lifetime,
no-store response, formula-safe cells). No export bytes are retained in Redis,
S3 or the job table. Revoked queued jobs/downloads fail closed.

All Sites is a separate explicit organization-report capability. Its bounded
aggregate counts use organization predicates and never enable operational writes.
The analytics-tool REST route invokes that same deterministic service. Future
AI tools and document downloads must reuse it; neither is represented as complete.

Audit, outbox and business mutations commit together. Worker SKIP LOCKED batches,
stable BullMQ IDs and PII-free events support at-least-once delivery. Mail uses
stable Message-ID, erases delivered ciphertext and stops after five failed
attempts. SMTP can duplicate across a send/commit crash; operational retry tooling
and a shared horizontal rate limiter remain deployment hardening.

Pool sizes are bounded (business 10, auth 5, worker 2); isolation tests also use
one connection. Statement timeout is 8 seconds, request timeout 15 seconds, body
64 KiB, directory pages at most 50 and nested collections at most 100. Logs omit
request bodies, credentials, tokens and sensitive profiles. Audit stores changed
field names and permission rules, not phone/payroll values. Private S3 has no
unguarded HR media route; future object keys/URLs must bind authorized scope.

## Phase 3 operations

`Operations extends Foundation` for duty evidence, projection, roster, visits,
leave ledger, tasks, files and inbox. Additive migrations 0011–0016 retain all prior
identities and business tables. 0016 preserves the recursive record dependency
check introduced in 0010 while publishing Phase 3 availability. Regression tests
cover this explicitly; do not copy an older policy function for future releases.
The separate engine in `packages/attendance` has no payroll/absence decision.

Flutter's actor/organization vault encrypts every queued payload, photo and scope
with authenticated AES-GCM. Its key lives in native secure storage; Drift remains
preferences-only. A bounded signed-in policy snapshot supports offline work with
an expiry and clock-rollback guard. Queue capacity is 100 unresolved operations,
128 MiB ciphertext, and 100 recent terminal receipts. Logout/account changes erase
keys and files; UI warns before discarding unsynchronized work. An unavailable/lost
key destroys unreadable ciphertext instead of attempting to reassign it.

Native geolocator supplies Android foreground location notification and Apple
background-location mode. Capture starts from employee consent in the foreground,
uses movement/battery-aware sample retention and native battery-aware settings,
and ends at duty limits, site changes, logout, revoked access or user stop. Relaunch
never silently resumes tracking. Pauses, permission withdrawal and force-stop are
route gaps. Camera activity no longer invalidates navigation solely because the app
became inactive; access is rechecked on resume and every request.

See PHASE3_CONTRACTS.md and PHASE3_DESIGN.md for command boundaries, sources and
unconfigured-policy behavior. Phase 4 DWR/AI and Phase 5 payroll/documents are now implemented locally; the Phase 3 server inbox is an event foundation, not a claim that all
future communication features are complete.

Phase 6 adds typed deterministic analytics and a separate constrained OpenRouter
explanation adapter; see PHASE6_CONTRACTS.md. Aggregates intersect analytics and
source permissions, and narrow fixed SQL helpers return only authorized totals.
There is no arbitrary SQL tool, persistent analytics cache or employee ranking.
The API can serve the built HR panel on the same origin; production rate limiting
uses shared Redis. Request-scoped GraphQL profile loaders and expanded-fragment
cost bounds prevent repeated aliases escaping the work budget. Push claims now use
a five-minute retry lease; external push requests run outside DB transactions and
recheck current recipient access. Runtime role checks reject privileged memberships.
