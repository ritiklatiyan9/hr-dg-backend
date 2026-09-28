# Mobile UX redesign — Defence Garden employee app

Started 2026-09-22. Scope: presentation, navigation and interaction of the existing
Flutter app (`apps/employee-mobile`). Backend, authentication, authorization, RLS,
multi-site isolation, offline synchronization and integrations are unchanged.
The React HR panel is untouched.

The visual reference described in the brief (warm off-white surfaces, charcoal type,
confident highlights, outlined rounded controls, compact status pills,
vertical timelines) was not attached to the session as an image file. The tokens
below therefore follow the brief's proposed palette, not sampled values.

## 1. Inventory of the app before the redesign

Captured from `lib/*.dart` (8 021 lines, 16 files) and the Android evidence in
`docs/evidence/phase3..5`. Route table before: `/` (session gate), `/login`, `/home`.
Everything else was pushed with `Navigator.push(MaterialPageRoute)` on the root
navigator, so the bottom bar disappeared on every deeper page.

| # | Screen / state (before) | Purpose | Parent tab | Primary action | Concrete UX problems found | Redesign status |
|---|---|---|---|---|---|---|
| 1 | SessionGate `/` | Restore session | — | none | Bare spinner, no branding | Done: branded loading state |
| 2 | LoginScreen `/login` (+ MFA, recovery) | Sign in | — | Sign in | Green M3 defaults; recovery result shown in the error colour; theme/language icons unlabeled | Done: same fields/labels, new type/tokens, recovery shown as info |
| 3 | HomeScreen `/home` container | Holds site dropdown, tab index, access polling | — | — | Site selector is a full-width dropdown *above every tab*; tabs are plain `setState` (no stacks, no back); 15 s bootstrap poll never pauses | Done: replaced by AppShell + workspace controller |
| 4 | Home tab (ScopedHome tab 0) | Today's status | HOME | none clearly dominant | Headline “A good day starts here.” with no status; four stacked buttons of equal weight (My HR info, Explore my work, View assigned people, Profile update requests); DWR row shows “awaiting review” count only; “Open day & operations” button leads to a 4-segment screen; footer text claims DWR/payroll are unreleased (wrong) | Done: header, yellow status card, DWR block, 3 shortcuts, Needs attention, Recent activity |
| 5 | Work tab (tab 1) | Module list | WORK | none | Mixed list: Team/Access buttons, “My services” tiles keyed on backend module ids (`my_payroll`), unreleased modules listed with “Phase 5 · Unreleased” sheets, duplicated DWR row; “Day & operations” bundles attendance, leave, tasks and sync behind a horizontally scrolling segmented control | Done: Daily work / Requests / Team sections with one canonical row per feature |
| 6 | Inbox tab (tab 2) | Notifications + profile requests | INBOX | none | Four stacked widgets (DWR row, approvals, server notifications, request inbox); notification titles are raw `event.type` strings with push status; tapping pushes a full page and hides the bar; duplicate “Day status” block | Done: single readable list, unread filter, detail page with next action |
| 7 | Me tab (tab 3) | HR information + display prefs | ME | Request profile update | Long label/value dump, salary/bank in the same column as phone; settings appended at the bottom; no payslips/documents entry points (they only lived in Work) | Done: Me hub → Profile, Payslips, Documents, Assets, Settings |
| 8 | OperationsScreen “Day & operations” | Attendance, field duty, leave, tasks, sync, push, inbox in one page | pushed (bar hidden) | Photo check-in | Segmented Duty/Leave/Tasks/Sync; raw `status · gaps` strings; `kind · 12.3 min` segment rows; correction/overtime, task assignment and leave forms are `AlertDialog`s with ISO-timestamp fields; verify/review dialogs use internal words (“Independent evidence review”); push and outbox hidden under “Sync” | Done: split into Attendance, Field Duty, Tasks, Leave, Outbox pages |
| 9 | Attendance history (ExpansionTiles) | Past sessions | pushed | none | No timeline, no hours summary, raw assumption text | Done: IN/OUT vertical timeline, hours summary, exception pills |
| 10 | Correction / overtime dialog | Fix attendance | pushed dialog | Submit | “Start (ISO timestamp)” labels; “Close missed-exit session?” No/Yes dropdown | Done: Fix Attendance form page |
| 11 | Apply for leave dialog | Leave request | pushed dialog | Submit | Balances listed as `type_id` UUIDs; dates typed as YYYY-MM-DD; portion dropdown `full/am/pm` | Done: Leave page with balances, Apply for Leave form |
| 12 | Tasks list (ExpansionTiles) | Assigned tasks | pushed | Status dropdown | Description inside expansion; status dropdown of raw values; comments/attachments in the same tile | Done: Today/Upcoming/Completed filters, detail page, compose panel |
| 13 | Assign task dialog | Manager creates task | pushed dialog | Submit | Dialog form, deadline as ISO text | Done: Assign task form page |
| 14 | Sync segment | Push + outbox | pushed | Sync now | Outbox rows show `kind · state` and “Original site …”; push text is raw status | Done: Outbox page under Me › Settings; push setting in Settings |
| 15 | DwrScreen (list) | Daily reports | pushed | New report | Site title with no context; “Assigned review queue” switch; rows `date · name`, revision numbers; inbox as ExpansionTile with raw timestamps | Done: Daily Report page with today's status, my reports, review queue |
| 16 | DwrEditor | Record/type/review report | pushed | Record report / Review & submit | Long single scroll: date field, provider disclaimer, record button with seconds, five text areas each followed by a “If no items above” dropdown, transcript expansion, attachments, three save buttons, review fields and history; no waveform; stage text only | Done: friendly intro, mic + type, live waveform, staged processing, grouped preview, pinned Send for Review |
| 17 | HrServicesScreen list (payroll/expense/asset/helpdesk/grievance/document/policy/announcement/lifecycle) | Records | pushed | New draft FAB | Generic `title · status · v3` rows; raw status chips; FAB over content; “Online only” footer | Done: kind-specific rows with amount/date/status pills, empty states |
| 18 | HrServicesScreen detail | Record detail | pushed (fake back button swaps state) | raw action buttons (`submit`, `settle`) | Actions rendered as backend verbs; decision history as `event · v2`; back button replaced list ↔ detail inside one widget | Done: real routes `records/:kind/:id`, labeled actions, timeline |
| 19 | Payroll detail | Payslip | pushed | Print / save payslip | Amounts as `INR 30000.00` with `kind · numerator/denominator`; net total not protected; assumptions text dumped | Done: month picker rows, net pay with visibility toggle, earnings/deductions groups, View/Download |
| 20 | HrRecordEditor “Server draft” | Create/edit record | pushed | Save server draft | Field helper “Integer paise: INR 1 = 100 paise”; employee dropdown unlabeled; audience checkboxes inline | Done: kind-aware form page with rupee input, date pickers, pinned Save |
| 21 | Attachment viewer (PdfPreview / image dialog) | Protected preview | pushed / dialog | none | PDF opens a bare Scaffold; images open in a dialog with no error state | Done: in-shell viewer page for image/PDF with error state |
| 22 | TeamScreen | Authorized people | pushed | Search | Detail in bottom sheet; pagination buttons | Done: People page + detail page |
| 23 | MobileAccessScreen / MobileAccessEditor | Access administration | pushed | Preview changes | Three stacked dropdowns per permission; module dropdown + search | Done: same controls restyled, grouped rows |
| 24 | AnalyticsScreen | Management insights | pushed | Explain | Metric ExpansionTiles with raw `state` text | Done: metric rows with pills, explanation panel |
| 25 | ProfileRequestScreen | Contact change request | pushed | Send request to HR | fine, but bar hidden | Done: in-shell form |
| 26 | RequestInbox review dialog | Approve/reject profile request | dialog | Approve | ok | Done: kept as confirmation dialog with note |
| 27 | Unreleased-module sheet | Explain unavailable module | sheet | Got it | Lists unreleased modules in Work | Done: unavailable modules excluded; single footnote |

States inventoried per screen: loading (`LoadingRows`, `LinearProgressIndicator`,
`CircularProgressIndicator`), error (`RecoverableError`, raw `Text(error)`), empty
(`EmptyMessage`, plain text), offline (`MaterialBanner`), denied (`EmptyMessage` lock),
success (`SnackBar`). Only `RecoverableError` offered retry consistently.

Sources of confusion (before):

- Duplicate destinations: DWR reachable from Home row, Work row and the service tile;
  attendance from Home button, Work “Open day & operations” and the service tile;
  payroll/documents only via Work tiles named after module ids.
- Competing actions: Home showed four equal buttons and no status.
- Unclear labels: “Day & operations”, “Sync”, “Server draft”, `submit`/`settle`
  buttons, `event_type` strings, UUID leave types, ISO timestamps.
- Disappearing navigation: every pushed page hid the bottom bar; deep pages had no
  way to reach another tab except Back.
- Dense forms: dialogs with 5 fields, no date pickers for instants, no inline help.
- Inconsistent components: Chip vs Text for status, ExpansionTile everywhere, FAB
  on one page only.

## 2. Design tokens

See `lib/ui/tokens.dart`. The brief proposed a yellow accent; on the owner's
request (2026-09-22) the focal accent is the company's green instead, applied as
a light-to-dark gradient. Light: canvas `#F7F7F2`, surface `#FFFFFF`, text
`#202421`, secondary `#626860`, accent `#1E6B4B` with gradient `#2F9467 → #124A33`
and white text on it, pale accent `#E3EFE6` (carries charcoal text), outline
`#E3E5DD`, control border `#C9CCC3`; semantic success `#137A44/#D5F0DE`, warning
`#9A5B00/#FDEBCF`, error `#B3261E/#FADAD7`, info `#2D5FA6/#E0E9F8`. Dark is a
separate palette (canvas `#131513`, surface `#1B1E1C`, text `#ECEEE8`, secondary
`#B1B6AD`, pale accent `#16321F`, outline `#33383A`) with the same green family. Type: Manrope (bundled, OFL) with Noto Sans Devanagari fallback
(bundled, OFL); 26/22/19/16/15/13/12 scale. Spacing 4/8 grid, 20 px gutters, 16–24 px
radii.

## 3. Route-to-screen completion matrix

All routes below live inside one `StatefulShellRoute.indexedStack` (go_router 17.5)
with four branches and their own navigation stacks. Only `/` (session gate) and
`/login` sit outside the shell. Every authenticated page renders `PageScaffold`
(title, back button from its branch navigator, `SiteChip`) and keeps the bottom
navigation visible. "States" lists the states each page implements.

| Route | Screen (file) | Tab | Primary action | States implemented | Status |
|---|---|---|---|---|---|
| `/` | SessionGate (`main.dart`) | — | — | restoring | Done |
| `/login` | LoginScreen (`main.dart`) | — | Sign in / Verify | busy, MFA, enrolment key, recovery notice, error | Done |
| `/home` | HomeTab (`home_tab.dart`) | HOME | Check in/out with photo | loading skeleton, error, not configured, not checked in, checked in (+break/field/pending verification/queued), DWR not started/draft/local draft/sent/approved/needs changes, shortcuts, team summary, needs-attention list + empty, recent activity + empty, choose-site | Done |
| `/home/activity` | ActivityPage (`home_tab.dart`) | HOME | — | list, empty, loading, error | Done |
| `/work` | WorkTab (`work_tab.dart`) | WORK | open a module | loading, error, Daily work / Requests / Team sections, unreleased footnote, no-modules empty, choose-site | Done |
| `/work/attendance` | AttendancePage (`attendance.dart`) | WORK | Check in/out with photo | loading, error, offline banner, not configured, status card with live clock and pills, Today hours summary + timeline, history (7 days/all) + empty, correction requests | Done |
| `/work/attendance/fix` | FixAttendancePage | WORK | Send for review | validation, offline (online-only), busy, error, success snackbar | Done |
| `/work/field-duty` | FieldDutyPage | WORK | Start/End field duty | not checked in, tracking on/off, last update + stale pill, queued samples, notices, visits + empty, consent dialog, tracking errors | Done |
| `/work/daily-report` | DailyReportPage (`dwr_screen.dart`) | WORK | Speak / Type my report | loading, error, offline, reminder due, today card per status, local drafts, my/team lists + empty, restricted | Done |
| `/work/daily-report/edit` | DwrEditorPage → DwrEditor | WORK | Send for review | idle mic, recording (waveform + time), processing steps, preview, recoverable error, saved locally, submitted (confirmed check), returned note, read-only view, reviewer decision, amendment, history, missing-args guard | Done |
| `/work/tasks` | TasksPage (`tasks.dart`) | WORK | open task / Assign | filters Today/Upcoming/Completed/All, loading, error, offline, empty per filter | Done |
| `/work/tasks/:id` | TaskDetailPage | WORK | Send comment | loading, unavailable, status chips (online), comments timeline + attachments, compose panel, attach photo, offline queueing, error | Done |
| `/work/tasks/assign` | AssignTaskPage | WORK | Assign task | validation, busy, error | Done |
| `/work/leave` | LeavePage (`leave.dart`) | WORK | Apply for Leave | loading, error, offline, balances + none, requests + empty, approval timeline | Done |
| `/work/leave/apply` | ApplyLeavePage | WORK | Send for approval | validation, calendar-day hint, offline queue, busy, error | Done |
| `/work/records/:kind` | RecordsPage (`hr_services.dart`) | WORK (expense, helpdesk, grievance) | New claim/request | loading, error, empty, grievance notice, privacy shield | Done |
| `/work/records/:kind/:id` | RecordDetailPage | WORK | labelled workflow action | loading, error, unavailable, pills, details, attachments, actions with reason, decision history timeline | Done |
| `/work/records/:kind/edit` | RecordEditorPage | WORK | Save draft | validation, rupee input, date pickers, audience, attachments after save, error, missing-args guard | Done |
| `/work/team` | PeoplePage (`team.dart`) | WORK (authorized) | search | loading, error, restricted, empty, pagination | Done |
| `/work/team/person` | PersonDetailPage | WORK | — | detail, sensitive show/hide, missing-args guard | Done |
| `/work/team/attendance` | TeamAttendancePage | WORK | — | Today/Recent filter, loading, error, empty, expandable timelines | Done |
| `/work/approvals` | ApprovalsPage (`approvals.dart`) | WORK (authorized) | decide with reason | loading, error, offline (online-only), filters, empty, evidence verification | Done |
| `/work/access` | AccessUsersPage (`access.dart`) | WORK (authorized) | search | loading, error/restricted, empty | Done |
| `/work/access/:userId` | AccessEditorPage | WORK | Preview changes | loading, error, locked, permissions/history, preview sheet, confirm | Done |
| `/work/insights` | AnalyticsScreen (`analytics_screen.dart`) | WORK (authorized) | Explain authorized facts | loading, error, facts, explanation modes, privacy shield | Done |
| `/work/attachment/:id`, `/me/attachment/:id`, `/inbox/attachment/:id` | AttachmentViewerPage | owning tab | — | loading, error + retry, image zoom, PDF preview, not displayable | Done |
| `/inbox` | InboxTab (`inbox.dart`) | INBOX | open message | filters All/Unread/Requests/Announcements, loading, error, empty per filter, unread badge | Done |
| `/inbox/:id` | MessageDetailPage | INBOX | Open module | loading, unavailable, marks read, push note | Done |
| `/me` | MeTab (`me_tab.dart`) | ME | open a personal area | profile card, restricted empty, choose-site | Done |
| `/me/profile` | ProfilePage | ME | Request a phone number change | loading, error, no profile, contact/employment/sensitive (show/hide)/assignments timeline | Done |
| `/me/profile/request` | ProfileRequestPage | ME | Send request to HR | validation, busy, error, success | Done |
| `/me/records/payroll` | RecordsPage (payroll) | ME | open month | loading, error, empty, amounts hidden by default, salary history | Done |
| `/me/records/payroll/:id` | RecordDetailPage (payroll) | ME | View payslip / Download | net pay hidden by default, earnings/deductions, calculation notes, workflow actions | Done |
| `/me/records/document|policy|announcement|asset|lifecycle` (+ `/:id`, `/edit`) | Records pages | ME | per kind | as above with expiry/acknowledged pills | Done |
| `/me/settings` | SettingsPage | ME | — | language, theme, push status, outbox count, about, sign out | Done |
| `/me/outbox` | OutboxPage (`outbox.dart`) | ME | Sync now | notice, syncing, queued rows with original site, empty | Done |

Legacy locations: `/home` remains the post-login location; the old pushed screens
(`OperationsScreen`, `DwrScreen`, `HrServicesScreen`, `TeamScreen`,
`MobileAccessScreen`) were replaced by the routes above. Inbox notification
targets are mapped by `routeForNotification` to the owning tab.

Shell behaviour implemented in `app_router.dart`:

- One persistent `NavigationBar` with icons and labels for all four tabs, green
  stadium indicator, unread badge on Inbox, safe-area padding, 72 px height.
- Keyboard insets are handled once in the shell: the body shrinks and the bar is
  lifted above the keyboard; pages see no inset. Forms use `FormPageBody`, which
  pins actions above the bar and lets them scroll when the height is constrained.
- Reselecting a tab returns to its root only after an unsaved-work check; tab
  switches during a microphone recording prompt Keep / Stop and keep / Discard.
- Platform Back pops the branch stack, then returns non-Home tabs to Home once.
- Site switch: unsaved-work guard, cancel reads (`switchSite` epoch), stop
  tracking, invalidate scoped providers, select site, current branch to root,
  other branches lazily reset on their next selection. Pages are keyed by the
  immutable `SiteScope`, so old-site values are discarded, not relabelled.
- Field-duty tracking shows a persistent strip above the bar on every page.
- The green gradient is reserved for focal areas: the Home attendance status
  card, the payslip net-pay card, the brand mark and the Daily Report record
  button. Buttons, the selected navigation indicator and pills stay solid so
  their pressed/disabled states remain predictable.
- Dialogs use the root navigator (scrim covers the bar); routine pickers use
  body-contained sheets on the branch navigator.

## 4. Components

`lib/ui/tokens.dart`: `AppTokens` (ThemeExtension), `Space`, `Radii`, `Motion`,
`buildEmployeeTheme`, `ReducedMotionTransitions`. `lib/ui/components.dart`:
`SectionHeader`, `StatusPill`, `ActionButton`, `ActionRow`, `CountBadge`,
`KeyValueRow`, `Avatar`, `TimelineRow`, `ActionPanel`, `FormPageBody`,
`LabeledField`, `AppTextField`, `AppDropdown`, `DateField`, `ChoiceChips`,
`FilterBar`, `LoadingState`, `InlineError`, `NoticeBanner`, `EmptyState`,
`TinyIllustration`, `ConfirmedCheck`, `ElapsedSince`, `RecordingWaveform`,
`SiteChip` + `showSitePicker`, `PageScaffold`, `showAppSheet`, `confirmDialog`,
`askDecision`, `VisiblePoller`, formatting helpers (`formatInr` with Indian
grouping, dates, `statusLabel`, `friendlyError` in `workspace.dart`).
`lib/app_router.dart`: `AppShell`, `BottomNav`, `ScopedRoute`, `ChooseSitePage`,
`TabRoot`. `lib/workspace.dart`: site selection, `UnsavedWork`,
`RecordingSession`, `WorkspaceActions`.

## 5. Tests and evidence

Commands actually run from `apps/employee-mobile` with the repository SDK
(`.local/flutter/bin`, Flutter 3.47.5, Dart 3.13.4):

| Command | Result | Notes |
|---|---|---|
| `flutter pub get` | PASS | adds `flutter_driver` (dev) and bundled font assets |
| `dart format lib test integration_test test_driver` | PASS | |
| `flutter analyze` | PASS | no issues (lib, test, integration_test, test_driver) |
| `flutter test` | PASS | 30 tests, see below |
| `flutter test --update-goldens test/shell_test.dart` | PASS | goldens regenerated deliberately after each visual change and inspected |
| `flutter drive … redesign_tour_test.dart -d emulator-5554` | see §6 | screenshot tour on the synthetic backend |
| `flutter drive … employee_flow_test.dart -d emulator-5554` | see §6 | navigation regression on the synthetic backend |
| `flutter drive … phase5_test.dart -d emulator-5554` | see §6 | payslip + helpdesk journeys on the synthetic backend |
| `flutter drive --profile … perf_test.dart` | see §6 | frame timing |

Unit and widget tests (`test/`):

- `shell_test.dart` (fake API and runtime, real bundled fonts, fixed clock):
  bottom navigation visible on tab roots, detail pages and forms with the
  owning tab selected; site chip on every page; Back pops the branch stack and
  then returns to Home; keyboard inset lifts the bar and the form action scrolls
  into view above it; site switch discards old-site values and resets other
  branches; a restricted role cannot reach `/work/access` through a shortcut;
  manager Team section without losing daily actions; profile request form
  submits, confirms and pops; goldens for Home light,
  Home checked-in dark, Work, Home at 320 px, Work in Hindi at 200 %, Home in
  landscape and the Daily Report editor.
- `components_test.dart`: Indian rupee grouping, status labels/tones, friendly
  error mapping, real PCM level computation.
- Retained: `dwr_test.dart` (encrypted local draft, theme contrast),
  `widget_test.dart` (login), `scope_test.dart`, `reduced_motion_test.dart`,
  `hr_transport_test.dart`, `operation_vault_test.dart`.

Required-test coverage from the brief:

| Requirement | Where |
|---|---|
| Bottom navigation visible on every ordinary authenticated route | `shell_test` roots/details/forms; tour screenshots |
| No content, CTA or keyboard overlaps the bar | `shell_test` keyboard test; `FormPageBody` pinned/scrolling actions; tour form screenshots |
| Tab stacks, Back, deep links | `shell_test` back test and route/tab assertions; `routeForNotification` |
| Site switching cannot display old-site data or relabel a pending write | `shell_test` site switch; `SiteScope`-keyed pages; outbox entries keep `siteId` (`scope_test`, `operation_vault_test`) |
| DWR recording, draft editing and submission retain data and explicit consent | `dwr_test` (encrypted local draft, no auto-submit), `dwr_flow_test`/`dwr_review_test` (device, staged) |
| Attendance, leave, task, inbox, payslip and approval journeys | device tests in §6 |
| Restricted roles cannot reach hidden data through shortcuts | `shell_test` restricted role; server authorization unchanged |
| Narrow screens, large text, Hindi, dark mode, keyboard | goldens (320 px, 200 % Hindi, dark, landscape) and tour screenshots |

## 6. Device runs

Environment: Android emulator `emulator-5554` (`sdk_gphone16k_arm64`, Android 17 /
API 37, 1080×2400), local API on :4000 reached as `http://10.0.2.2:4000`,
synthetic `hr_local` fixtures, debug builds with the protected test defines.
The physical Samsung SM-G781B used by the concurrent session was not attached
during this increment.

| Run | Result | Evidence / notes |
|---|---|---|
| `redesign_tour_test.dart` (30 routes, dark, Hindi 160 %) | PASS | `docs/evidence/redesign/01…43-*.png`, 30 screenshots; bottom bar asserted on every route, no layout exceptions; final run after the inspection fixes |
| `employee_flow_test.dart` (navigation regression: sign-in, site choice, Home, Work, Attendance detail with bar, Me, Hindi/dark/140 %, profile request → Inbox Requests, tab-stack restore, sign-out, then injected Super Admin session → access editor/preview → People) | PASS | `flutter-*.png`. Diagnosing this run found a real defect in the redesign, now fixed: after signing out and restoring a different account in the same process, the non-autoDispose scope provider kept the previous bootstrap alive and the restore path never invalidated it, so the new user's requests carried the old permission version (SCOPE_CHANGED loop). `SessionGate` now resets the workspace and invalidates bootstrap, and the scope provider is autoDispose. Earlier attempts also failed on test finders (keyboard-covered tap, below-the-fold rows, single-use admin refresh token) and were corrected |
| `phase5_test.dart` (payslip hidden/shown, Hindi/dark payslip, helpdesk submit → HR start/resolve → employee close) | PASS | `flutter-payroll*.png`, `flutter-helpdesk-*.png`; first attempt failed only on an expired admin token |
| `perf_test.dart` in `--profile` (frame timing while scrolling Home/Attendance and switching tabs) | NOT RUN | Profile builds reject cleartext HTTP on Android (by design, see README) and the local API is HTTP-only, so the app cannot sign in; no physical device was attached. The test and `test_driver/perf.dart` (writes `docs/evidence/redesign/perf/summary.json`) are ready for an HTTPS development API. No frame numbers are claimed. |
| Usability observation with employees | NOT RUN | No representative employees available in this session |

Visual inspection of the device captures led to these fixes before the final
tour: timeline trailing pills no longer stretch to the row height; Tasks lands
on the first non-empty filter (Today → Upcoming → All); the Payslips title no
longer truncates behind two toolbar actions and period ranges drop the weekday;
the outbox shows a quiet "Everything is synced" state; historic dates include
the year; known server verification reasons are shown in Hindi; the greeting
header no longer truncates the name.

## 7. Remaining blockers and follow-ups

- Physical mid-range device profiling (Samsung SM-G781B or similar) and 60 fps
  evidence: NOT RUN (device absent; profile builds need an HTTPS API).
- Usability observation with representative employees: NOT RUN.
- Voice reporting on the synthetic site is not configured (`voice.configured`
  false), so the editor shows the honest "Voice is not set up" state; the
  recording/processing UI is covered by the widget golden and the unchanged
  `dwr_flow_test` (device, staged) which was not re-run in this increment.
- Field duty has no map preview by design in this build; the page states this.
- Leave types are not configured on the synthetic site, so Apply for Leave is
  disabled there with an explanation.
- The login screen's green hero was added by a concurrent session and kept as
  is; it uses the shared components and keys.
