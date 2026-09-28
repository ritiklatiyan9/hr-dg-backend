# Phase 3 operational contracts

The retained session is the only source of organization, actor and device identity.
`siteId` is a concrete selector. `operations(siteId)` and
`operate(siteId, operation, input)` run through `Domain.site` on one connection,
with current-session/version checks and RLS. Generated TypeScript and Dart share
the SDL and documents. The JSON envelope is deliberate: each operation is strictly
validated by its named Zod schema in `apps/api/src/operations.ts`; unknown properties,
operation names, invalid instants and malformed UUIDs are rejected.

## Read model

`operations` returns serverTime, me, policy, geofence, authorized approver choices,
sessions, events, adjustments, rosters, visits, leaveTypes, leaveRequests, balances,
ledger, tasks, comments, inbox and safe file metadata. No object keys, authentication
secrets, bank or salary fields are returned. Location coordinates for route events
require field-duty access for that employee. Lists are bounded (100 sessions,
3,000 associated events, 100 tasks/requests, 200 comments); this is a recent-work
read model, not an unlimited archive/export. Session projections expose engine
version, sources, assumptions, gaps, late/early flags, approved overtime and
separate known/unknown time-at-location summaries.

## Commands

| Operation        | Input / concurrency                                                                                                                                                     |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| policy           | rules, expectedVersion, reason; rules explicitly include offline window, accuracy, freshness, clock skew, gap/max duty duration, late/early grace, attendanceApproverId |
| geofence         | closed longitude/latitude polygon, label, expectedVersion, reason; versioned PostGIS geography                                                                          |
| event            | clientEventId, dutyId, sequence, kind, capturedAt, payloadVersion=1, policyVersion, geofenceVersion; optional location, photoId, visitId                                |
| roster           | employeeId, shiftId, workDate, expectedVersion (0 to create); site-local shift becomes UTC instants                                                                     |
| adjustment       | dutyId, startsAt, endsAt, kind, closeSession, reason                                                                                                                    |
| reviewAdjustment | id, expectedVersion, approve, reason; independent configured approver                                                                                                   |
| verifyEvent      | id, expectedStatus=pending_verification, approve, effectiveAt when accepting, reason                                                                                    |
| visit            | employeeId, title, scheduledAt, latitude, longitude, radiusM, notes                                                                                                     |
| leaveType        | code, label, halfDays, includeWeekends, includeHolidays, approverId                                                                                                     |
| leaveCredit      | employeeId, typeId, units, effectiveOn, reason; explicit configuration, never automatic accrual                                                                         |
| leave            | clientId, typeId, startsOn, endsOn, half=full/am/pm, reason                                                                                                             |
| reviewLeave      | id, expectedVersion, approve, reason; request and ledger debit commit together                                                                                          |
| task             | clientId, employeeId, title, description, deadline, priority                                                                                                            |
| taskStatus       | id, expectedVersion, status=todo/in_progress/blocked/done                                                                                                               |
| comment          | clientId, taskId, body, optional protected attachmentId                                                                                                                 |
| fileIntent       | clientId, purpose=attendance/visit/task, parentId for task, type, exact bytes (maximum 8 MiB)                                                                           |
| readInbox        | id; only the recipient's record at the selected site                                                                                                                    |

Event kinds are IN, OUT, FIELD_START, FIELD_END, BREAK_START, BREAK_END, LOCATION,
VISIT_START and VISIT_END. One open duty per organization/employee spans all devices
and sites. Transfers must finish/correct the original duty. Accepted order is
serialized; raw out-of-order/clock-anomalous/delayed evidence awaits independent
verification. IN/OUT and visits require completed photo upload. Captured and received
instants remain separate. Unknown observations immediately stop previous location
inference. No segment produces an automatic absence or payroll deduction.

Event, leave, task, comment and upload-intent retries use stable client IDs;
changed payloads conflict. Approval/version conflicts are online-only. Clients must
retain original scope and reconcile pending-verification receipts after review.
The offline queue batches a bounded drain periodically, uploads photos before events,
rechecks each original site and uses capped exponential retry delays. Terminal errors
are shown as Rejected rather than retried forever.

## Private files and notifications

`POST /files/intents/:id/content?siteId=` accepts authenticated octet-stream bytes;
web requests need retained Origin/CSRF protection. Exact size/type, owner and fresh
parent-record authorization are checked. Images are decoded under a pixel limit;
an immutable private original and metadata-stripped derivative have separate hashes.
Without ClamAV, decoded images explicitly report scanner unavailable; PDFs remain
quarantined. `GET /files/attachments/:id?siteId=` rechecks current access and returns
private no-store content. No reusable public URL is issued.

An inbox item and transactional outbox event commit with business updates. Missing
FCM configuration/delivery never removes the inbox item. `POST /notifications/register`
accepts a real device token and platform at an authorized site; tokens are encrypted.
The worker uses Google OAuth and FCM HTTP v1 only when configured. Push data contains
IDs, and the mobile handler reloads capabilities and the matching server inbox record
before following it. It never trusts notification IDs as authorization.
