# Geofenced attendance and duty location

Delivered 2026-09-25. The selected product behavior is **HR-assigned shift times,
including before check-in**. Location sharing does not create an attendance punch,
mark an employee present, calculate payroll, or invent movement between readings.

## Set up

1. Apply additive migrations `0038_duty_tracking.sql` and `0041_tracking_offline.sql` with the migration role and
   restart the API. It has been applied to the local synthetic `hr_local` database.
   The running API uses `hr_runtime`, never migration credentials.
2. In **Site & employee setup → Shifts**, define shift start/end times. In
   **Day & operations → Policy & roster**, configure the actual attendance policy,
   authorized geofence and employee/date shift assignments. An end time earlier
   than the start crosses midnight in the site's timezone; storage is UTC.
3. Open **HR → Duty location → Tracking settings**. Enable sharing, select
   **HR-assigned shift times**, set sampling/staleness intervals, and provide the
   employee disclosure and change reason. Settings are versioned and audited.
   An optional mode requires a verified check-in within the rostered shift.
4. Employees open the correct site in the mobile app, use the location setup strip
   or **Work → Field Duty → Enable automatic duty location**, acknowledge the
   disclosure and grant location/notification permissions once. Sharing then starts
   automatically when an authorized window is active. A changed disclosure requires
   acknowledgement again. The app must be available at shift start.
5. HR sees received coordinates, accuracy, inside/outside/uncertain boundary status,
   observed/received times and fresh/stale/missing/off-duty states. The list and
   latest route samples refresh every 15 seconds. Route history loads 500 points
   at a time using a stable cursor; the roster list pages 50 rows at a time.

The local panel is `http://localhost:5180/#/tracking`. Both tracking migrations
have been applied to the local synthetic database. Defaults remain disabled;
no real company hours, geofence, tracking notice or retention schedule were assumed.
The ordinary debug APK is `apps/employee-mobile/build/app/outputs/flutter-apk/app-debug.apk`.
It targets the emulator's local API (`http://10.0.2.2:4000`), not a production server.

## Enforcement and data behavior

- `employee_tracking.view` controls HR location access. `employee_tracking.manage`
  requires site scope and controls settings. Both depend on employee/attendance
  visibility. Super Admin/Admin/HR templates include these permissions; job titles
  do not. Managers require explicit reviewed grants; employees cannot view others.
- Every request derives identity from its verified session, rechecks permission
  version/site access and uses one transaction with transaction-local RLS context.
  Tracking tables have RLS, non-owner runtime grants, no auth-role business access,
  employee ownership checks and original organization/site/roster identity.
- Current server time and HR roster boundaries govern admission. Samples before
  shift start, after shift end, after disabling sharing, or with stale policy/roster
  versions are rejected. The mobile app checks the schedule every 30 seconds.
  A device-bound offline grant permits collection through the downloaded duty end
  (at most 24 hours of capture). A separate monotonic expiry timer stops the mobile
  stream without waiting for another GPS callback. An online connection is required to download each window; the next roster
  can be prepared up to 24 hours before its start. GPS stays off until that start. The 120-second lease remains the fallback for
  clients without an offline grant.
- Sample UUIDs are idempotent; changed payloads conflict. Samples do not consume
  attendance event sequence numbers. Concurrent devices cannot mix an active route;
  offline grants reserve a roster/policy window to one device until it ends or HR
  revises that authorization. The legacy online-only endpoint permits takeover
  after its prior receiver has been silent for 120 seconds.
- The server rejects reported mock readings, insufficient accuracy, stale readings,
  backward observations, over-frequency updates and readings more than five seconds
  in the future. PostGIS compares the full reported accuracy circle to the boundary;
  an intersecting circle is **unknown**, not inside. This is not hardware attestation
  or proof against a compromised device.
- Legacy `LOCATION` attendance events cannot bypass configured tracking controls.
  Without tracking configuration they require a verified entry. Photo IN/OUT,
  independent review and immutable attendance evidence remain intact.
- Roster updates are serialized per employee, optimistic-version checked and
  protected against cross-site overlaps by a database trigger. Existing schedules
  are not silently rewritten. Scope/account/permission changes cancel sharing and
  discard stale responses; in-flight writes retain their captured original scope.
- Offline telemetry uses the encrypted, durable queue described below. A missing
  GPS fix remains a gap; no coordinates or travel paths are synthesized. Observed
  and received timestamps remain separate, so a delayed upload cannot turn an old
  observation into a fresh location. The Leaflet basemap requests public tiles;
  employee names and raw telemetry are not submitted to the tile provider.
- No tracking rows are automatically deleted under an invented retention policy.
  Company retention/disclosure and production access grants remain deployment setup.

## Native limits

Android uses the existing Geolocator foreground location service with an ongoing
notification and wake lock. iOS uses the existing location background mode and a
visible location indicator. Resuming the app revalidates authorization and restarts
eligible sharing automatically. Permission withdrawal, sign-out, device disable,
lease expiration and schedule end stop sharing when the runtime can execute.

This implementation does **not** start a terminated app, bypass force-stop, obtain
permissions silently, or guarantee an exact background startup when an idle app is
suspended. It only starts a new location stream while the app is foregrounded;
an existing permitted stream can continue in the background. The server rejects
out-of-window persistence independently of mobile timer scheduling. A phone needs
an online connection to download its duty window. Offline HR changes cannot reach
it until reconnection; then the new authorization is enforced and invalid queued
readings are rejected. Physical lock-screen, battery-optimization,
long-duration background and iOS signing/device tests were not run: no device was
connected. These are release gates, not capabilities inferred from unit tests.

Platform references checked during implementation:
[Android foreground service launch restrictions](https://developer.android.com/develop/background-work/services/fgs/launch)
and [location foreground-service requirements](https://developer.android.com/about/versions/14/changes/fgs-types-required).

## Leaflet map and interaction

The HR module now includes a site overview, keyboard-accessible employee markers,
search/status filters, received-point route history, current geofence, latest
accuracy radius, fit-to-locations and follow-latest camera controls. Marker layers
update in place. Fresh employee pins and the route's highlighted latest pin glide
between received fixes, with a direction arrow when displacement exceeds GPS
uncertainty. Recorded dots, accuracy circles, attendance and database coordinates
retain the original readings. Dragging pauses follow.
A failed basemap has a retry control while observation layers remain usable.

`DutyMotion` uses bounded quintic easing (roughly 0.9–2.5 seconds), monotonic frame
time, shortest-turn heading rotation and retargeting from the position currently on
screen. It never extrapolates past the newest received fix or snaps observations to
roads. Animation is a visual transition, not proof of the route taken. The UI explains
this distinction. Small uncertainty-sized displacements update without an invented
direction. Stale/off-duty signals, receipt delays above 30 seconds, observation gaps
above 90 seconds, accuracy worse than 100 m, jumps above 2 km or implied speed above
75 m/s are not animated. These are display gates, not server evidence validation.

One `requestAnimationFrame` scheduler serves all moving pins on a map, and stops
when they arrive. No additional GPS samples, API polling or database writes are
introduced; HR sampling and 15-second dashboard refresh still determine update
frequency. Hidden tabs and reduced-motion changes settle to the received endpoint
and cancel frames. Removing markers, switching scope and closing a route dispose
pending work. Static history layers are not redrawn every animation frame. Camera
follow uses an 80 px safe area to avoid panning for every small location change.
The implementation uses the public [Leaflet marker API](https://leafletjs.com/reference.html#marker-setlatlng)
and [browser animation frames](https://developer.mozilla.org/en-US/docs/Web/API/Window/requestAnimationFrame).

Leaflet is lazy-loaded with its CSS. Rendering is capped at the latest 2,000 loaded
samples, the route table initially renders 100 rows, and server history pages stay
at 500 rows. SVG layers avoid the canvas teardown redraw race found during tests. Leaflet's
CSS zoom animation is disabled because its completion timer can outlive a closed
dialog; follow/fit camera pans retain cancellable smooth animation.
Map/resize/listener cleanup runs on unmount and scope changes. Dashboard freshness
continues to age during a network outage; metric cards use the same derived status
as employee rows. Counts are explicitly per page.

No paid mapping service or API key is required. The default basemap uses
[OpenStreetMap standard tiles](https://operations.osmfoundation.org/policies/tiles/)
with attribution, an HTTPS URL, Referer, browser caching, no offline tile download
and no bulk prefetch. That public service is best-effort, not an unlimited-capacity
SLA. Tile requests disclose the viewed geographic area to the provider. For a
large deployment, select a tile service whose usage terms cover the expected load;
the tile layer is isolated in `apps/hr-web/src/duty-map.tsx`.

## Movement and battery algorithm

`DutySampling` changes cadence, never evidence coordinates. It rejects stale,
mocked, inaccurate, duplicate, future and isolated impossible-jump fixes before
queueing. Accuracy-aware displacement uses a fixed anchor and both uncertainty
radii, so GPS jitter does not repeatedly mark a stationary phone as moving. Three
valid fixes over at least 90 seconds establish stillness. Two displaced fixes, or
credible speed with known uncertainty, resume moving cadence. Long observation
gaps reset movement evidence. This is a heuristic, not employee activity proof.

Moving cadence starts at HR's interval. Stationary cadence is up to three times
that interval; low battery (20% or less, restored at 25%) permits up to twice the
interval. Both are capped at half HR's stale threshold. Battery reads occur at most
every five minutes. Upload timing and retry limits use monotonic elapsed time.

Android keeps precise fused location and changes its native interval only while
foregrounded, with a 60-second restart cooldown. In the background, the existing
subscription remains at its last configured interval, while uploads still adapt.
iOS has no Geolocator interval setting, so adaptive uploads reduce radio traffic
without claiming to control iOS GPS cadence. A wake lock/visible notification is
retained for the authorized Android window. No battery percentage improvement is
claimed without physical-device profiling. See [Android's battery guidance](https://developer.android.com/develop/sensors-and-location/location/battery)
and [the Geolocator platform behavior](https://pub.dev/packages/geolocator).

## Offline queue and recovery

- An authenticated phone obtains an immutable grant for its current roster,
  policy, device and original geofence/attendance rules. Grants are reused, not
  inserted every poll. Another device cannot obtain a simultaneous offline grant
  for the same employee's roster/policy window. The next roster can be prepared
  up to 24 hours in advance; capture stays off until its start. Downloading additional
  shifts requires internet.
- The app encrypts each accepted GPS payload with AES-256-GCM before upload. SQLite
  runs on a background isolate, uses WAL and full durability, and indexes pending
  sequence/scope. Keys use device secure storage. Account, site, grant and location
  payloads are encrypted; database identifiers and queue state are opaque metadata.
- Write-before-send plus stable sample UUIDs handles process restart, lost
  acknowledgements and duplicate retries. Only explicit per-item acceptance deletes
  a pending record. Rejected readings stay encrypted and have a visible count.
- Reconnection drains batches of 100, up to five batches per cycle, using each
  record's original account/site/grant. Current verified permissions are checked
  for every request. A 30-second schedule check detects reconnection; retries use
  capped exponential backoff and jitter. Authentication failures do not clear data.
- Collection ends at the downloaded window boundary, even without callbacks.
  Offline restart requires a matching cached account/permission scope and a clock
  that has not moved backward since its snapshot. It cannot cold-start a killed app.
- Uploads are accepted for seven days after the grant's capture end, provided the
  roster/tracking policy remains authorized. HR disabling/revising the policy or
  roster can reject queued records, including records not uploaded before a change.
  Rejected readings are never presented as received attendance or live locations.
- Storage is capped at 20,000 records / 16 MiB of encrypted payloads. At capacity,
  capture stops with a visible message; existing records are not silently dropped.
  Signing out removes this account's encrypted queue and encryption key. This
  behavior is disclosed in the employee flow.

## Database load controls

`0041_tracking_offline.sql` adds RLS-protected grants, a grant foreign key, an
append-friendly received-time BRIN index and telemetry-specific analyze/vacuum
settings. Existing scoped latest-position and UUID-uniqueness B-tree indexes remain.
Batch ingestion performs set-based validation/classification/insertion on one
checked-out connection and one transaction, with per-employee advisory serialization.
It validates neighboring sample spacing, timestamps, original geofence, device,
policy/roster, authorization and the upload deadline. Each item has an acknowledgement;
one invalid item cannot poison other valid items. Request bodies remain capped at
64 KiB and batch size at 100; reads use keyset pagination instead of deep OFFSET.

Local synthetic testing: the final full-suite run's 100-row offline insert took
132 ms; scoped 500-point reads over 50,000 historical rows measured 159 ms median /
196 ms p95 in that run, using `tracking_latest`. These are local evidence, not a production
capacity guarantee. Raw server history is retained: indexes/backpressure do not cap
long-term disk growth. A company-approved retention/archive policy and production
load measurements are still required before promising a fixed storage ceiling.
No production deletion, archive upload or paid infrastructure was provisioned.

## Verification

Evidence is in `docs/evidence/tracking/`. The full backend suite passed 104 tests;
subsequent focused coverage passed 13 tests, including actual GraphQL session
checks, strict forged-identity rejection and 504-point cursor completeness. All
35 Flutter tests passed, including five automatic tracking lifecycle tests. Web
contract/UI and actual local API browser checks are recorded separately; mocked
browser fixtures are not evidence of real device location capture.

The Leaflet/adaptive/offline increment evidence is in `docs/evidence/tracking-map/`; see its README and the newest `docs/PROGRESS.md` entry for final PASS/FAIL evidence. The earlier 35-test/online-only delivery below is historical.

## Phone presence: Live, Idle, Location off, Signal lost — 2026-09-26

Root cause of "Signal lost" for a connected, sharing phone (verified on the
SM-G781B with `dumpsys` of Google's fused location provider): indoors the GPS
chip produced 0 fixes and the provider marked the phone `device stationary`
(`throttling @10m`). It delivered 3 locations in 42 minutes, and each reached the
server about 1 s later. The app only contacted HR when a new fix arrived, so
HR saw the last reading age past the stale threshold.

- The phone now sends a lightweight `trackingCommand(operation: "heartbeat")`
  with its grant and state (`tracking` or `location_off`) on its schedule poll,
  only when no accepted upload happened recently. It adds no extra radio wake-up
  and no new rows: migration `0050_tracking_presence.sql` adds
  `last_seen_at`/`device_state` to the device's grant row, updated in place (HOT,
  fillfactor 80, 10 s server throttle, column-level UPDATE grant plus an
  owner-only RLS policy).
- The poll period and heartbeat age follow HR's stale threshold
  (`pollSeconds = clamp((stale-25)/2, 10, 30)`, heartbeat after
  `stale-25-poll` seconds without contact). The worst gap between contacts is
  therefore `stale - 25` s, which leaves room for the 15 s HR refresh. The
  defaults (30 s sampling, 120 s stale) keep the 30 s poll.
- Status (`packages/attendance/src/tracking.ts`, shared by API and web):
  **Live** = fix within the stale threshold; **Idle** = no new fix, but the phone
  was seen (upload or heartbeat) within it; **Location off** = the latest
  contact was a heartbeat reporting device location/GPS unavailable;
  **Signal lost** = no contact at all. Idle pins keep their colour but never
  glide or show a direction. This is contact evidence, not proof of activity.
- The phone keeps the encrypted offline context on disk until the window, grant
  or permission scope changes. It no longer re-encrypts and rewrites it on every
  30 s poll.
- The HR list shows one row per employee: the running duty window, else the
  nearest one. Previously today's and tomorrow's windows appeared as two rows.
  `?employee=<id>` (from the employee profile's "Track live") limits the
  monitor to that person.

## One way to assign shifts

The same "Assign shift & duty time" dialog (`apps/hr-web/src/duty-schedule.tsx`)
is used from Live tracking ("Set duty time"), Attendance ("Assign shift"),
Day & operations → Policy & roster, Shifts ("Assign to employees" on a shift),
and an employee profile ("Shift"). The profile version schedules that person's
duty windows (default: 4 weeks, Mon–Sat) and records their default shift. It
replaces the raw "Existing roster version (0 for new)" form. `rosterRange` leaves
active site holidays free and reports them. The attendance snapshot loads the
listed sessions' rosters plus the coming week, soonest first. Previously the
newest 100 by date could hide today's rosters behind bulk schedules.
