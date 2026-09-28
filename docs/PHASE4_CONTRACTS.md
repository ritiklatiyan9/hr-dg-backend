# Phase 4 DWR contracts

> **Update 2026-09-25:** voice capture, Groq transcription and the voice REST
> endpoints were removed. Reports are now prepared from DWR chat messages by the
> worker's AI agent; see [DWR_CHAT.md](DWR_CHAT.md). The canonical report, review,
> amendment, print, reminder and attachment rules below still apply. Voice sections
> are kept as history; retained audio is still deleted by the worker.

Read with ARCHITECTURE.md, PERMISSIONS.md and the generated GraphQL documents.
Phases 1–3 authentication, assignments, authorization and raw evidence are retained.
Migrations 0017–0022 are additive. Applied checksums must not be edited.

## Canonical workflow

One `dwr_reports` row exists per organization/site/employee/work date. Content
revisions and workflow versions are separate counters. Draft saves advance both;
submission/review advance the version. `dwr_history` retains content, attachment
references, actor, time, event and reason at each version. Its runtime grant is
insert/select only. No accepted report can be duplicated by retries.

`draft → submitted → approved | returned`; a returned report is editable and can
be resubmitted. Submitted content is locked. An approved report can return to a
draft only through `amend`, with a reason and the site's amendments setting enabled.
The same canonical ID and approved revision history remain. Review comments,
return and approval require a reason of 8–1,000 characters and an independent
reviewer; self-approval is prohibited. DWR approval acknowledges review of
employee claims, not verified achievements, payroll approval or payment.

GraphQL `dwr(siteId, workDate?)` returns at most 100 recent visible reports, at
most 100 history entries per report, per-record actions, settings, site time,
voice setup state and 50 inbox updates. An exact date filter reaches older dates;
the current clients show the recent window. This is not a full archive/export.

`dwrCommand(siteId, operation, input)` validates strict operation schemas:

| Operation  | Required input beyond client ID                                                                  | Authorization                    |
| ---------- | ------------------------------------------------------------------------------------------------ | -------------------------------- |
| save       | workDate, expectedVersion, content, attachments, optional voiceId                                | own create/edit                  |
| submit     | id, expectedVersion, confirmed=true                                                              | own submit; separate action      |
| review     | id, expectedVersion, decision=comment/return/approve, reason                                     | record review or approve         |
| amend      | id, expectedVersion, reason                                                                      | own edit + configured amendments |
| fileIntent | id, type, bytes                                                                                  | own editable report              |
| settings   | expectedVersion, deadline, deadlineDayOffset, reminderMinutes, amendments, offlineDrafts, reason | site_settings.manage             |

Settings use optimistic concurrency. Other writes use an actor-bound client UUID,
payload digest and stored response receipt. Reuse with another payload conflicts.
Current authorization precedes receipt replay. Row locks and version checks prevent
lost edits and duplicate acceptance. Fresh session/version checks and RLS run on
one short transaction connection. Operational All Sites writes are rejected.

Organization and actor come from the verified session; employee derives from the
actor. A requested site/date is validated against membership, site timezone,
nonfuture date and effective-dated assignment. Model output cannot set identity,
site, date, review state or permissions.

## Content and provenance

`packages/contracts/dwr.ts` is the canonical runtime schema. It has completed[],
pending[], blockers[], nextDayPlan[], uncertainties[], sourceTranscript and
status="draft". Each array has at most 30 entries of 600 characters; transcript
is at most 12,000 characters. A `stated` map adds not_stated / none / reported for
pending, blockers and nextDayPlan. Empty arrays do not silently mean "none".

Example speech about checking records, registry-data optimization and preparing
payrolls produces only those employee-reported claims; unspecified sections say
Not stated. No quantities, work hours, measured gains, approval or payment release
are inferred. Semantic fidelity remains an AI quality risk: schema/prompt checks
and numeric/injection checks do not prove translation accuracy. The employee
reviews the transcript and all sections before explicit submission.

Original transcript, corrected transcript, generated draft, configured model and
provider, prompt/schema version and subsequent employee edits remain traceable.
The owner can see their provenance; reviewers require the separately delegated
`dwr_review.field.provenance` permission, which has no default grant. Other
reviewers receive sourceTranscript="" and no voice ID/generated provenance,
including in history. Normal DWR report content stays under record authorization.

## Voice transport and admission

Flutter uses `record` 7.1.1 native PCM streaming, 16-bit mono 16 kHz, then wraps
samples as WAV in memory. Recording is foreground only and stops on leaving or
pausing the screen; it does not imply continuous/background recording. The web
accepts a WAV upload or manual entry. Both clients show setup-required/manual mode
unless server provider configuration is complete. Neither client contains keys.

Authenticated REST endpoints, with concrete site scope:

- POST `/dwr/voice/:clientId/audio?siteId=...&workDate=...`, binary body.
- GET `/dwr/voice/:id?siteId=...`, owner status and editable draft.
- POST `/dwr/voice/:id/transcribe`, `/structure`, `/cancel`; JSON siteId,
  plus optional corrected transcript for structuring.
- GET `/dwr/:id/print?siteId=...`, freshly authorized HTML. Reviewer printing
  additionally requires dwr_review.export. Attachments remain separately guarded.

Server checks actual WAV headers, sample format, size (4 MiB), duration (1–120 s),
truncation and silence. Upload IDs/hash/date are stable across retries. Private S3
upload happens outside transactions; incomplete uploads remain retryable.
Groq uses `/openai/v1/audio/transcriptions`, `whisper-large-v3`, verbose_json,
automatic language recognition, never the translation endpoint. No-speech and
confidence diagnostics can request rerecording. Structuring calls the explicitly
configured OpenRouter model and single provider, disables fallback, requires
supported parameters and JSON Schema, and validates output again server-side.
Transcript text is untrusted data. There are no model tools or business side effects.

Each provider call has a six-second network deadline; a stage has a twelve-second
outer deadline and a twenty-second database lease. Calls never retain a business
transaction. One request per stage attempt, at most six total job attempts;
Retry-After persists as a cooldown, including HTTP dates. Cooldowns beyond the
maximum audio lifetime expire the job rather than permitting early retry.
Responses are bounded to 100,000 bytes while streaming. Cancellation aborts this
process's call and invalidates the durable lease; another process's result cannot
commit after cancellation. The other process still has its short provider deadline.

A global admission lock enforces configured concurrent leases and calls/minute.
Daily per-user and organization call/audio-second budgets are reserved before
provider calls; failed attempts consume usage. Current access is rechecked before
storing provider output, saving a report and submitting. Revocation during a call
discards its output. Voice processing alone creates no accepted report.

## Files, retention, reminders and offline drafts

Attachments reuse private upload intents, strict image/PDF limits (8 MiB, ten
attachments), image sanitation, scanner quarantine and protected downloads. PDFs
without a scanner remain quarantined. A file must belong to that editable report,
site and employee and be ready before being attached. Mobile uploads gallery
images and displays authorized images; PDF viewing uses the HR web flow.

Explicit temporary-audio retention is 1–168 hours. The worker deletes at most 20
expired S3 objects per tick, outside a transaction, then acknowledges deletion.
Cancellation also deletes audio. Transcript/provenance and report revision history
are retained as business records; production retention for those records requires
an approved policy. Provider retention is separate: no zero-retention claim is made.

Site deadlines use site-local HH:mm and same/next-day offset; reminder lead time
is 0–1,440 minutes. Calendar timestamp comparisons handle midnight crossings.
Effective assignments/current permissions and missing submissions determine
reminders. A unique employee/site/date reminder record plus inbox/outbox transaction
prevents duplicate reminders. Reviews notify owners; submissions notify authorized
reviewers under the distinct dwr_review module. Queued push rechecks report access.
Missing FCM never removes the durable inbox record.

Opt-in mobile local drafts use the existing native-key AES-256-GCM vault. Text,
audio, original org/actor/site/date, payload version and pending request UUID are
inside ciphertext. DWR drafts are excluded from automatic attendance synchronization.
An offline draft needs explicit reopening, current access and employee confirmation
before submission. Failed transcription preserves approved local audio/draft;
failed structuring exposes the transcript for typing or correction. Logout warns
about unsaved DWR work and deletes the actor's local files and key. Account
namespaces are isolated. The vault has a 128 MiB aggregate limit.

## Phase 5 boundary

Do not consume DWR claims as payroll evidence or approvals. Keep canonical IDs,
immutable history, request receipts and all RLS checks. Remaining rollout gates:
approved company deadlines/retention; selected provider/model and measured account
quotas; real multilingual quality/p95 run; physical microphone and accessibility
checks; iOS signing/build/native vault validation. See PROGRESS.md for actual results.
