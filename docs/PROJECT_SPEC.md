# Defence Garden Employee & HR Management System

Source: the request attached to this session, read on 2026-09-21. No earlier
conversation documents were available or assumed. Repository was empty and
was not a Git repository. This is a modular monolith with a worker process,
one React HR panel and one Flutter employee app.

## Six-phase delivery map

1. **Foundation (delivered Phase 1):** organizations, legal employers, sites,
   users, employees, employment records, effective-dated assignments, roles,
   capabilities, sessions, devices, audit, authentication and MFA; shared
   authorization/RLS; client bootstrap/site selection; employee profile slice;
   generated contracts, local services, synthetic seeds and isolation tests.
2. **Permissions, UI and employee setup (delivered Phase 2):** shared complete
   module/action/field catalogue, reviewed per-user/site access administration,
   role templates and delegation, employee onboarding/drafts, profiles and safe
   contact requests, dated site/reporting assignments, references/site settings,
   authorized exports/reporting foundation, consistent web/mobile design. Bulk
   import and full document metadata/retention remain deferred to full HR; neither
   is exposed as a completed module.
3. **Attendance, field duty, leave and tasks:** photo evidence, PostGIS
   geofences, multiple IN/OUT events, work dates/hours, device batches and
   idempotency, field duty, regularization, leave balances, assigned tasks,
   supervisor/manager approvals and operational dashboards. Approve exact
   offline attendance policy before implementing a local event queue.
4. **Voice DWR:** private audio capture/upload, server-only Groq
   whisper-large-v3 transcription, configurable OpenRouter structured draft
   generation, schema validation, employee review, approval and traceability.
   AI cannot approve or submit records without explicit user action.

   Phase 4 implementation now includes manual reports, canonical revisions,
   independent review, configured deadlines/reminders, private attachments,
   printable reports and opt-in encrypted mobile drafts. Provider adapters have
   deterministic tests; production AI quality, quotas and p95 are separate gates.
   See PHASE4_CONTRACTS.md, PHASE4_DESIGN.md and PROGRESS.md.

   2026-09-25: per the owner's request, voice capture/transcription was replaced by
   WhatsApp-style DWR chat (personal DWR agent chat, site groups with group admins,
   native-keyboard dictation). The worker's OpenRouter agent prepares each
   employee's draft from their own messages; employees still submit explicitly and
   reviewers decide. See DWR_CHAT.md.

5. **Payroll and full HR:** payroll calculations and periods, reviewed rules,
   payslips, legal-employer segregation, documents, inbox, announcements,
   expenses, assets, grievances, manager approvals and audit history UI.
   See PHASE5_CONTRACTS.md, the feature matrix in PROGRESS.md and
   PHASE6_RELEASE_AUDIT.md for implemented workflows and explicit remaining limits.
6. **Analytics, testing and deployment:** authorized AI analytics with bounded
   queries, dashboards, permission/security regression, mobile device QA,
   load/recovery testing, observability, backup restores and approved deployment.

## Product invariants

- HR-panel roles: Super Admin, Admin, HR, Jr. HR. Mobile roles/capabilities:
  Employee, Supervisor, Manager and explicitly assigned administrative access.
  A designation such as "HR Manager" grants nothing.
- Every operational query/mutation supplies a selected authorized site.
  Organization and user identity come exclusively from a verified session.
- Defence Garden and River Green are sites, not legal employers. One employee
  identity can have multiple effective-dated site assignments. Employee contact
  details are organization-owned; assignment and operational history stay with
  their original site.
- Instants are UTC `timestamptz`. Site timezone derives calendar work dates.
  Example timezone is configurable `Asia/Kolkata`; date intervals are inclusive.
- No fabricated production data, payroll totals or attendance metrics. Seeds
  are explicitly synthetic and restricted to local/test databases.
- Passwords, tokens, HR records and audio never enter logs or public storage.
  Future features remain clearly unavailable until their services are implemented.

## Contract decisions

Business operations use GraphQL; REST is reserved for authentication, guarded
CSV downloads, a bounded reporting tool and future media/audio/device transport. Both routes use the same Domain authorization.
GraphQL pagination is UUID keyset pagination, 1–50 rows, scope-bound opaque cursor.
UTC instants use ISO-8601 strings; calendar dates use YYYY-MM-DD; money uses exact
decimal strings. Error codes include UNAUTHENTICATED, MFA_REQUIRED, FORBIDDEN,
SCOPE_CHANGED, NOT_FOUND, BAD_INPUT, BAD_CURSOR, CONFLICT and INVALID_TOKEN.
Profiles/settings use optimistic integer versions; permission edits use the
target access version. Employee requests update phone, basic details (contact
field class) and profile photo (512 px re-encoded JPEG) only after independent
approval; administrative onboarding, profile edits, assignments and references
persist through bounded services. Salary/bank values are independently filtered,
with no employee payroll editing. Phase 5 adds explicit reviewed exact-paise calculations;
new HR lists are bounded at 100 records (full pagination remains a release gate); payroll
results use keyset pagination since 2026-09-25.

Phase 6 checkpoint (2026-09-22): deterministic analytics and constrained AI explanation
are integrated with backend/React/Flutter contracts. Query, Redis and deployment
hardening, synthetic workload and local restore evidence are recorded in
PHASE6_CONTRACTS.md, RELEASE_READINESS.md, SECURITY_REVIEW.md, PERFORMANCE.md and
OPERATIONS.md. This does not close outstanding product/device/company-policy gates;
the two-site real-employee pilot recommendation remains No-Go.

## Decisions still requiring business input

- Actual organization/legal employer registrations, site geofences, onboarding
  identifiers, payroll jurisdiction and statutory rules.
- Statutory deductions (PF/ESI/PT/TDS), bank payout or bank bulk-upload formats,
  whether salary payment recording needs a finance role separate from
  `payroll.manage`, and proration for joiners/leavers/mid-period salary changes.
  Payments are recorded after the fact; the system never moves money.
- Actual supervisor/manager rosters, approval substitutes and payroll delegation.
  The implemented default requires explicit team capabilities and dated reporting
  relationships. Jr. HR can read employees and create onboarding drafts; final
  approvals, sensitive fields/exports and permission administration require
  separate grants and are absent by default.
- Overnight shifts, breaks, rounding, grace periods, field travel rules,
  multi-site workday ownership, leave calendars and regularization limits.
- Photo/audio/document retention, permitted offline datasets, device integrity
  policy, consent notices and disaster recovery objectives.
- MFA loss recovery: no insecure fallback or email bypass is provided. A reviewed
  administrator-assisted recovery procedure must precede production onboarding.
- Production domain, email transport, S3 provider, secrets manager, infrastructure
  and deployment approval; AI provider/model selection and cost limits.
- DWR chat: approved OpenRouter model/provider and daily budgets, the automatic
  preparation quiet period (10 minutes), chat message and deleted-text retention,
  and whether late reporting after midnight should post to the previous work date.

Continue the existing architecture and update this file and PROGRESS.md in every
phase. Do not redesign or claim later phases complete based on UI placeholders.

## Phase 3 entry checkpoint

Read PROGRESS.md, ARCHITECTURE.md and PERMISSIONS.md; keep authentication and
0001–0010 checksums intact. Reuse the catalogue, app.policy_decision, Domain.site,
transaction-local RLS, effective dates and client scope/version guards. Additive
attendance/leave/task tables must retain originating org/site/user scope.

Before implementing offline event capture, settle acceptance/rejection rules for
late/offline punches, device time versus server time, maximum offline duration,
photo/geofence evidence and duplicate batches. Also settle overnight shifts,
breaks/rounding/grace periods, multi-site work dates, leave balances/accruals and
regularization/approval ownership. Current shift/holiday setup is reference data,
not an attendance engine. Do not mark Phase 3–6 modules available until their
persistence and authorization have passed real integration tests.

## Phase 3 delivered increment and configuration boundary

See PROGRESS.md for current verification. Attendance, field duty, leave and tasks
now have persisted backend/web/mobile flows. Duty calculations are evidence-based;
unknown intervals are explicit and never converted to absence, unpaid time or
fabricated routes. Leave configuration and dated credits are explicit.

The user confirmed no company attendance/leave rules, push credentials or physical
test device. Production policies remain unconfigured. Local browser acceptance
creates clearly named synthetic policies/boundaries/tasks only. Physical battery,
background survivability, iOS signing and real push delivery require later evidence;
they must not be inferred from an emulator or adapter implementation. Phase 4 must
consume these reviewed evidence/ledger contracts without rewriting raw events.

## Duty location increment — 2026-09-25

The user selected automatic sharing during **HR-assigned shift times, including
before employee check-in**. `Duty location` is a dedicated permission-controlled HR
module backed by separate RLS telemetry storage and versioned site settings. It
requires explicit dated shift rosters, configured attendance/geofence settings and
employee device permissions/disclosure acknowledgement. Automatic sharing never
creates attendance, payroll or absence records. The optional checked-in mode is
bounded by both the HR shift and verified attendance duty.

New samples are accepted online during the current server-authorized window only.
The mobile app automatically starts eligible sharing while available, renews a
short lease and stops on expiry/end/scope changes. Cold launch from a terminated
app, exact startup while OS-suspended, physical-device background survivability,
battery use, retention and production disclosure remain explicit release gates.
See [DUTY_TRACKING.md](DUTY_TRACKING.md) for setup, contracts and limits.

### Duty tracking refinements — 2026-09-25

The user explicitly selected Leaflet/free maps, premium UI and smooth interactions,
confirmed that battery/performance optimization must be included, and subsequently
requested offline movement capture followed by automatic upload. This supersedes
the earlier online-only telemetry decision. Current implementation uses device-bound
current-shift offline grants (24-hour maximum capture window, seven-day upload
window), encrypted bounded SQLite queue, duplicate-safe 100-point uploads, movement
hysteresis/adaptive cadence and received-time-aware HR map history. See
[DUTY_TRACKING.md](DUTY_TRACKING.md) for exact authorization, native limits and local
scale evidence. Production raw-history retention/archive policy remains undecided;
no automatic server deletion is enabled.
