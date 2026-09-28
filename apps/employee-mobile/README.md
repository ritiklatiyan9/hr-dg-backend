# Defence Garden Employee

Flutter app with Riverpod, go_router, one cancellable GraphQL client, generated
models, Dio authentication and protected token storage. Supports sign-in, MFA,
authorized site selection, attendance, field duty, daily reports, tasks, leave,
HR records, payslips, inbox and approvals, all scoped to the selected site.

See the [root setup guide](../../README.md) for synthetic accounts, API startup,
Android emulator URL, tests and production constraints. Run `flutter pub get`,
`dart run build_runner build`, `flutter analyze`, and `flutter test` here.

## Structure (2026-09 redesign)

- `lib/ui/tokens.dart` — design tokens (`AppTokens`), theme, spacing, radii.
- `lib/ui/components.dart` — shared widgets: page scaffold, site chip, rows,
  pills, timeline, forms, states, sheets/dialogs, formatting helpers.
- `lib/app_router.dart` — go_router `StatefulShellRoute` with four branches
  (Home, Work, Inbox, Me), `AppShell`, persistent `BottomNav`, `ScopedRoute`.
- `lib/workspace.dart` — site selection, unsaved-work and recording registries.
- Feature pages: `home_tab.dart`, `work_tab.dart`, `inbox.dart`, `me_tab.dart`,
  `attendance.dart` (shared operations controller, attendance, fix form, field
  duty, team attendance), `tasks.dart`, `leave.dart`, `dwr_screen.dart`,
  `hr_services.dart` (records, payslips, editor, attachment viewer),
  `approvals.dart`, `team.dart`, `access.dart`, `analytics_screen.dart`,
  `outbox.dart`.
- Fonts are bundled (`assets/fonts`, SIL OFL): Manrope with a Noto Sans
  Devanagari fallback. No runtime font download for the UI.

Tests: `flutter test` (unit, widget, shell navigation and goldens under
`test/goldens`; regenerate with `--update-goldens` and inspect the PNGs).
Device screenshot tour: `flutter drive --driver=test_driver/redesign.dart
--target=integration_test/redesign_tour_test.dart -d <device>
--dart-define=API_URL=http://10.0.2.2:4000
--dart-define-from-file=../../.local/mobile-test.json`. Frame timing:
`test_driver/perf.dart` with `integration_test/perf_test.dart` in `--profile`.
See `docs/MOBILE_UX_REDESIGN.md` for the inventory and route matrix.

Offline HR data is intentionally disabled until approved policies exist.
Android/iOS scaffolds are included; release signing is not configured.
