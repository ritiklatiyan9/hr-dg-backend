# Phase 3 implementation decisions

User confirmed no company rules, FCM credentials or physical device. No production
policy is inferred. Site settings require explicit, versioned validation; tests
configure synthetic rules only. No policy means capture/leave submission denied
with configuration_required, not fabricated attendance or balances.

Raw duty events, GPS observations, duty sessions, calculated segments and approved
adjustments are distinct. Device capture time and server receipt time are retained.
Delayed/unreliable evidence is pending verification; it never establishes absence
or an automatic wage deduction. Sessions serialize by organization/employee across
sites and devices; a transfer closes the original session before a new site begins.
Client event IDs are immutable idempotency keys with payload hashes. Repeated IDs
with changed bodies conflict. Out-of-order raw evidence remains reviewable.

Attendance policy includes accuracy/freshness/clock windows, offline permission,
maximum session and gap duration, and late/early tolerances. Roster instants use
site-local calendar/time converted by PostgreSQL, including overnight shifts.
Leave types require explicit half-day/weekend/holiday behavior and dated opening
credits; no automatic accrual or company entitlement is invented. Approval locks
the request/balance; the unique ledger debit and decision commit together.

Mobile encrypted files use authenticated AES-GCM with random nonces and an
actor/organization-specific key in OS secure storage. This is application-level
encryption, not a claim that Drift or SQLite encrypts itself. Logout purges keys
and encrypted queue files; a disclosure warns about unsynchronized local records.
No approval or permission update is queued. Automatic duty tracking starts only
from an authorized foreground employee action and stops on end/logout/revocation.
No force-stop or OS-suspension continuity is promised.

Native integration references checked 2026-09-21:

- https://pub.dev/packages/geolocator (Baseflow 14.0.3; native Android/iOS location)
- https://developer.android.com/about/versions/14/changes/fgs-types-required
- https://developer.apple.com/documentation/corelocation/handling-location-updates-in-the-background
- https://developer.apple.com/documentation/corelocation/requesting-authorization-to-use-location-services
- https://pub.dev/packages/cryptography

Geolocator's Android foreground location notification and Apple's location
background mode are used while duty tracking is active. No separate generic
background-service plugin is assumed to provide continuous iOS execution.

FCM references checked:

- https://firebase.google.com/docs/cloud-messaging/flutter/get-started
- https://firebase.google.com/docs/cloud-messaging/send/v1-api

Android dependency compatibility: permission_handler 12.0.3 / Android 13.0.1 is
locked. The newer package requested android-37 while the local toolchain installed
android-37.0, so the compatible release line was used and rebuilt successfully.
Geolocator remains 14.0.3. Firebase currently emits a forward-looking Kotlin plugin
migration warning; the tested debug APK builds. No iOS native build is claimed.

Online-only policies send authorized location samples directly and stop collection
if connectivity fails. They do not require or silently enable offline retention.
Policies permitting offline work use the encrypted outbox and its lease.
