# Attendance setup and daily flow

The HR navigation now has **Site geofence**, **Attendance policy**, **Mark IN / OUT**, **Attendance**, and **Attendance approvals**. Permissions still control which records a person can see and who can decide; being an HR job-title holder does not grant access.

1. In **Site geofence**, HR draws three or more boundary corners, or enters `latitude, longitude`, selects **Use as centre**, and sets a radius in metres. The dashed outline is the saved boundary; the green shape is the proposed change. Save with a boundary name and change reason. Version checks prevent overwriting a concurrent change. Coordinates work even when map tiles cannot load.
2. In **Attendance policy**, choose the attendance approver and the evidence/offline rules. Existing values are preserved when reopening the form. Assign the employee's shift in the attendance roster; **Duty location → Tracking settings** controls automatic shift-based location sharing.
3. Employees enable duty location sharing and grant the required OS permissions. Tracking follows HR-assigned shift times, independently of check-in. It stops outside the authorized duty window. A requested OUT no longer prematurely disables shift tracking. See [DUTY_TRACKING.md](DUTY_TRACKING.md) for offline leases and platform limitations.
4. Employees use **Mark IN / OUT** in the web panel, or the app's Home/Attendance screen. A photo and location support an IN/OUT capture. Only server-accepted evidence is confirmed attendance. Poor, missing, stale or boundary-crossing GPS remains uncertain.
5. An OUT outside the fence, with unverified GPS, or against an older session boundary prompts for an employee reason. The API independently classifies the observation with PostGIS and requires a reason for new non-inside OUT captures. Such an OUT remains pending: it does not close the session or receive an effective attendance time until the configured independent approver accepts it.
6. In **Attendance approvals**, the queue groups pending entries by attendance record and shows them in capture order with plain-language check-in, check-out, break and field-work labels. Authorized viewers see a separate evidence section in each request with the employee explanation, location, capture/receipt times and an inline photo preview that opens larger in a dialog without downloading. The page names the assigned approver beside each request; only that person sees Approve and Reject actions. The approver confirms a choice with a decision note; approving an entry also requires a confirmed effective time. Self-approval and duplicate decisions are rejected. Older immutable evidence without the new reason field remains reviewable under its existing approval workflow.
7. **Attendance** shows duty history and evidence. Rejected submissions no longer trap subsequent valid events behind an unusable sequence number. Missing or pending earlier evidence must still be resolved in order.

## Mobile capture and retry behavior

- Location permission is resolved before opening the camera; the GPS fix then runs concurrently with photo capture.
- A recent, accurate, non-mocked duty-stream/OS fix may be reused for at most 15 seconds and never beyond the site's freshness policy. The API validates it again.
- A fresh request is bounded to 8 seconds; an old fix after a long camera interaction is refreshed. A merely imprecise fix is not repeatedly requested in a serial loop.
- Photos are captured at up to 1280 pixels and JPEG quality 80, reducing upload and encrypted outbox size.
- Empty sync queues do not bootstrap/refetch the account. Snapshot loading does not wait for an unrelated queue drain. Web upload reservations no longer trigger full workspace refreshes before uploading.
- Where HR enables offline attendance, encrypted captures return after a maximum three-second foreground sync wait; the existing durable retry continues. This is a queued receipt, never a fabricated successful check-in.
- Pending OUT blocks duplicate submissions and is shown as awaiting confirmation. Unconfirmed attendance is not presented as a confirmed running timer. A failed attempt that never reached the server does not consume a sequence; server-side rejected events do.
- Scope changes cancel capture before submission. Writes and queued records retain their original organization, actor, permission version and site.

## Expired duties and older review requests

- A duty past its own policy's `maxSessionHours` no longer appears as today's active duty in the app or web check-in control. On the next valid IN at the same site, the API changes the old duty to `needs_review` and starts a new duty atomically. It preserves every event and leaves `closed_at` empty; it never invents a checkout or paid time. An authorized correction can close the missed-exit duty after independent review.
- The app uses the site's work date for Today and history, keeps earlier pending evidence visible, and shows the server's reason when a new capture needs verification. Attendance approvals show a count and direct date link for earlier pending evidence. A prior day's request stays pending until the configured independent approver decides it.
- Online photo transfer no longer counts against capture freshness after a timely private file intent. The server binds the intent to the same actor/site, requires it to start within the site's capture freshness window, and allows at most five minutes for the upload and event receipt. GPS accuracy, mock status, observation freshness, geofence, policy versions and clock skew are still checked separately. Offline or longer-delayed evidence remains pending for review.
- The web capture resizes photos over 3 MB to a metadata-free JPEG before reserving the upload; this keeps ordinary camera files below the Vercel request limit. Both clients refresh GPS after a long off-site reason prompt. Time labels use the site's timezone where the site work date is shown.

## Configuration and remaining decision

The local Defence Garden boundary is still synthetic. HR must enter the actual site coordinates/polygon; do not widen the test fence to include a remote test phone. The currently assigned approver is `hr@example.test`; another HR account cannot decide unless an authorized Admin selects it in Attendance policy.

**Automatic paid/confirmed IN on entering the fence is not enabled.** The pending product choice is whether arrival itself creates attendance or starts tracking while the employee confirms IN. The previously agreed HR-shift tracking behavior and photo-confirmed attendance remain in place until that choice is resolved. No hours or payroll are inferred from a GPS arrival.

Migration `0043_attendance_policy_visibility.sql` lets attendance viewers/reviewers read the site's policy and boundary without requiring unrelated settings permissions. Individual event, photo and location access still uses existing record RLS. This update adds no per-position attendance writes and keeps existing indexed tracking storage and retention behavior.

## Evidence

- Backend regression cases: `tests/integration/phase3.test.ts` (reason required, pending until approval, unauthorized/duplicate decision denied, reject/retry recovery, original reason preserved).
- Native regression cases: `apps/employee-mobile/test/attendance_location_test.dart` (freshness/boundary uncertainty, pending display, sequence retries, reason form validation).
- Browser smoke: `tests/browser/attendance-flow.spec.ts` (real local API, visible routes, coordinate drawing, desktop/mobile overflow and runtime errors; no business settings saved).
- Screenshots: [desktop geofence](evidence/attendance-flow/geofence-desktop.png), [mobile geofence](evidence/attendance-flow/geofence-mobile.png), [approvals](evidence/attendance-flow/approvals-desktop.png).
