import 'ui/icons.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'api.dart';
import 'attendance_location.dart';
import 'mobile_ui.dart';
import 'operation_runtime.dart';
import 'providers.dart';
import 'scope.dart';
import 'ui/components.dart';
import 'workspace.dart';
import 'graphql/operations.graphql.dart';

export 'operation_runtime.dart' show Json;

enum CaptureResult { cancelled, recorded, queued, pendingVerification, failed }

/// Snapshot of the operations query for one site scope plus UI flags.
class OperationsState {
  const OperationsState({
    this.snapshot,
    this.error,
    this.busy = false,
    this.captureStage = '',
    this.offline = false,
    this.assignable = const [],
  });
  final Json? snapshot;
  final Object? error;
  final bool busy, offline;
  final String captureStage;
  final List<dynamic> assignable;
  OperationsState copyWith({
    Json? snapshot,
    Object? error,
    bool? busy,
    String? captureStage,
    bool? offline,
    List<dynamic>? assignable,
    bool clearError = false,
    bool clearSnapshot = false,
  }) => OperationsState(
    snapshot: clearSnapshot ? null : (snapshot ?? this.snapshot),
    error: clearError ? null : (error ?? this.error),
    busy: busy ?? this.busy,
    captureStage: captureStage ?? this.captureStage,
    offline: offline ?? this.offline,
    assignable: assignable ?? this.assignable,
  );
  bool get loaded => snapshot != null;
  String? get me => snapshot?['me'] as String?;
  List<Json> _list(String key) => ((snapshot?[key] ?? const []) as List)
      .map((e) => Json.from(e as Map))
      .toList();
  List<Json> get sessions => _list('sessions');
  List<Json> get ownSessions =>
      sessions.where((s) => s['employee_id'] == me).toList();
  List<Json> get events => _list('events');
  List<Json> get tasks => _list('tasks');
  List<Json> get ownTasks =>
      tasks.where((t) => t['employee_id'] == me).toList();
  List<Json> get visits =>
      _list('visits').where((v) => v['employee_id'] == me).toList();
  List<Json> get leaveRequests => _list('leaveRequests');
  List<Json> get ownLeave =>
      leaveRequests.where((l) => l['employee_id'] == me).toList();
  List<Json> get leaveTypes => _list('leaveTypes');
  List<Json> get balances =>
      _list('balances').where((b) => b['employee_id'] == me).toList();
  List<Json> get adjustments => _list('adjustments');
  List<Json> get comments => _list('comments');
  List<Json> get inbox => _list('inbox');
  List<Json> get files => _list('files');
  bool get configured =>
      snapshot?['policy'] != null && snapshot?['geofence'] != null;
  int get unreadInbox => inbox.where((n) => n['read_at'] == null).length;
  String? get approverId =>
      snapshot?['policy']?['rules']?['attendanceApproverId'] as String?;
  String? get siteName => snapshot?['siteName'] as String?;
}

/// One controller per site scope. Home, Attendance, Tasks, Leave, Field duty
/// and Inbox share it, so a tab switch never refetches on its own.
class OperationsController extends Notifier<OperationsState> {
  OperationsController(this.scope);
  final SiteScope scope;
  bool _loading = false;
  OperationRuntime get runtime => ref.read(operationRuntimeProvider);
  @override
  OperationsState build() {
    Future.microtask(load);
    return const OperationsState();
  }

  Json? _offlineSnapshot() {
    final c = runtime.context;
    if (c == null ||
        c['siteId'] != scope.siteId ||
        c['actorId'] != scope.actorId) {
      return null;
    }
    return Json.from(c);
  }

  Future<void> load({bool silent = false}) async {
    if (_loading) return;
    _loading = true;
    try {
      final api = ref.read(apiProvider);
      final result = await api.scopedRead(scope, documentNodeQueryOperations);
      final caps = (await api.capabilities(scope)).scope.capabilities;
      var assignable = state.assignable;
      if (caps.contains('tasks.create') && caps.contains('employees.view')) {
        assignable = (await api.team(scope)).employees.nodes;
      }
      if (!ref.mounted) return;
      final snapshot = Json.from(result['operations'] as Map);
      await runtime.connect(scope, snapshot, caps);
      if (!ref.mounted) return;
      state = state.copyWith(
        snapshot: snapshot,
        clearError: true,
        offline: false,
        assignable: assignable,
      );
    } catch (e) {
      final networkFailure =
          e is ApiFailure && (e.code == 'OFFLINE' || e.code == 'NETWORK_ERROR');
      if (!networkFailure) {
        await runtime.stopTracking();
        runtime.context = null;
      } else if (runtime.context == null) {
        await runtime.restoreOffline();
      }
      if (!ref.mounted) return;
      state = networkFailure
          ? state.copyWith(
              snapshot: state.snapshot ?? _offlineSnapshot(),
              error: e,
              offline: true,
            )
          : state.copyWith(clearSnapshot: true, error: e, offline: false);
    } finally {
      _loading = false;
    }
  }

  Future<Json> command(String operation, Json input) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      return await runtime.online(scope, operation, input);
    } catch (e) {
      if (ref.mounted) state = state.copyWith(error: e);
      rethrow;
    } finally {
      if (ref.mounted) state = state.copyWith(busy: false);
      unawaited(load());
    }
  }

  Future<void> markRead(String id) async {
    try {
      await runtime.online(scope, 'readInbox', {'id': id});
      await load();
    } catch (_) {
      /* Read receipts are best effort. */
    }
  }

  /// Photo/GPS evidence capture. Returns what actually happened; a queued
  /// capture is not confirmed attendance until the server accepts it.
  Future<CaptureResult> capture(
    String kind, {
    String? visitId,
    Future<String?> Function()? requestOffsiteReason,
  }) async {
    if (state.busy) return CaptureResult.cancelled;
    if (!state.configured || runtime.context == null) {
      state = state.copyWith(
        error: StateError(
          tr(
            'Attendance is not configured at this site yet.',
            'इस साइट पर उपस्थिति अभी सेट नहीं है।',
          ),
        ),
      );
      return CaptureResult.failed;
    }
    state = state.copyWith(busy: true, clearError: true);
    XFile? capturedFile;
    final api = ref.read(apiProvider);
    final epoch = api.scopeEpoch.capture();
    void checkScope() {
      if (!ref.mounted ||
          !api.scopeEpoch.isCurrent(epoch) ||
          runtime.context?['siteId'] != scope.siteId ||
          runtime.context?['actorId'] != scope.actorId ||
          runtime.context?['organizationId'] != scope.organizationId ||
          runtime.context?['permissionVersion'] != scope.permissionVersion) {
        throw StateError(
          'Workspace changed. Capture was cancelled; try again in the selected site.',
        );
      }
    }

    void stage(String text) {
      if (ref.mounted) state = state.copyWith(captureStage: text);
    }

    try {
      checkScope();
      final open = runtime.localOpenDuty;
      if (open != null &&
          sessionEvents(
            state,
            runtime,
            scope,
            open['id'] as String?,
          ).any((e) => e['kind'] == 'OUT' && e['status'] != 'rejected')) {
        throw StateError(
          tr(
            'Your OUT is already submitted. Wait for sync or attendance approval.',
            'आपका OUT भेजा जा चुका है। सिंक या अनुमोदन की प्रतीक्षा करें।',
          ),
        );
      }
      if (runtime.dutyId != open?['id'] || kind == 'IN') {
        runtime.dutyId = open?['id'] ?? const Uuid().v4();
        // Continue after every submitted event, including pending ones, so a
        // restarted app never reuses a sequence number.
        runtime.sequence = [
          open?['last_sequence'],
          open?['max_sequence'],
        ].whereType<num>().fold(0, (a, b) => a > b ? a : b.toInt());
        runtime.dutyScope = scope;
      }
      final needsPhoto = [
        'IN',
        'OUT',
        'VISIT_START',
        'VISIT_END',
      ].contains(kind);
      final duty = runtime.dutyId;
      final policyVersion =
          open?['policy_version'] ?? runtime.context!['policy']['version'];
      final geofenceVersion =
          open?['geofence_version'] ?? runtime.context!['geofence']['version'];
      // Resolve the first location permission before opening the camera so
      // Android/iOS never have competing permission sheets. The fix itself
      // runs while the employee takes their photo.
      stage(tr('Checking location access…', 'स्थान अनुमति जाँच रहे हैं…'));
      final locationAllowed = await runtime.ensureLocationAccess();
      checkScope();
      final position = locationAllowed
          ? runtime.position(permissionReady: true)
          : Future<Json?>.value(null);
      stage(tr('Opening camera…', 'कैमरा खुल रहा है…'));
      List<int>? bytes;
      if (needsPhoto) {
        XFile? file;
        try {
          file = await ImagePicker().pickImage(
            source: ImageSource.camera,
            maxWidth: 1280,
            maxHeight: 1280,
            imageQuality: 80,
          );
        } on PlatformException catch (e) {
          throw StateError(
            e.code.contains('denied')
                ? tr(
                    'Camera access is needed to record attendance evidence. Allow it in system settings and try again.',
                    'उपस्थिति साक्ष्य के लिए कैमरा अनुमति चाहिए। सिस्टम सेटिंग में अनुमति दें और फिर कोशिश करें।',
                  )
                : tr(
                    'The camera is unavailable right now. Try again.',
                    'कैमरा अभी उपलब्ध नहीं है। फिर कोशिश करें।',
                  ),
          );
        }
        if (file == null) return CaptureResult.cancelled;
        capturedFile = file;
        bytes = await file.readAsBytes();
      }
      stage(tr('Checking site location…', 'साइट स्थान जाँच रहे हैं…'));
      var location = await position;
      checkScope();
      final rules = runtime.context?['policy']?['rules'] as Map?;
      if (location != null && !attendanceFixRecent(location, rules)) {
        location = await runtime.position();
      }
      checkScope();
      final capturedAt = DateTime.now().toUtc().toIso8601String();
      String? offsiteReason;
      if (kind == 'OUT' &&
          (geofenceVersion != runtime.context?['geofence']?['version'] ||
              !attendanceInside(
                runtime.context?['geofence']?['geojson'] as Map?,
                location,
                rules,
              ))) {
        stage(tr('Reason needed for this OUT', 'इस OUT का कारण चाहिए'));
        offsiteReason = await requestOffsiteReason?.call();
        if (offsiteReason == null) return CaptureResult.cancelled;
        if (offsiteReason.trim().length < 8) {
          throw StateError('Enter a reason of at least 8 characters.');
        }
      }
      checkScope();
      runtime.sequence = nextAttendanceSequence(
        duty!,
        runtime.localOpenDuty,
        runtime.queue,
      );
      final payload = <String, dynamic>{
        'clientEventId': const Uuid().v4(),
        'dutyId': duty,
        'sequence': runtime.sequence,
        'kind': kind,
        'capturedAt': capturedAt,
        'payloadVersion': 1,
        'policyVersion': policyVersion,
        'geofenceVersion': geofenceVersion,
        'location': ?location,
        'visitId': ?visitId,
        'offsiteReason': ?offsiteReason,
      };
      stage(tr('Saving attendance…', 'उपस्थिति सहेज रहे हैं…'));
      var result = CaptureResult.recorded;
      if (runtime.canSaveOffline) {
        await runtime.enqueue(
          scope,
          'event',
          payload,
          photo: bytes,
          photoType: 'image/jpeg',
        );
        result = CaptureResult.queued;
      } else {
        if (state.offline) {
          throw StateError(
            tr(
              'You are offline and offline capture is not enabled for this site.',
              'आप ऑफ़लाइन हैं और इस साइट पर ऑफ़लाइन कैप्चर सक्षम नहीं है।',
            ),
          );
        }
        if (bytes != null) {
          final intent = await runtime.online(scope, 'fileIntent', {
            'clientId': payload['clientEventId'],
            'purpose': kind.startsWith('VISIT_') ? 'visit' : 'attendance',
            'type': 'image/jpeg',
            'bytes': bytes.length,
          });
          await ref
              .read(apiProvider)
              .uploadOperationPhoto(scope, intent['id'] as String, bytes);
          payload['photoId'] = intent['id'];
        }
        final receipt = await runtime.online(scope, 'event', payload);
        if (receipt['status'] == 'pending_verification') {
          result = CaptureResult.pendingVerification;
        }
      }
      // Shift-based tracking continues until the HR-authorized duty window ends.
      // An OUT request must not silently switch off scheduled tracking.
      if (result == CaptureResult.queued) {
        stage(tr('Saved · syncing receipt…', 'सहेजा · रसीद सिंक हो रही है…'));
        await runtime
            .sync(force: true)
            .timeout(const Duration(seconds: 3), onTimeout: () {});
      }
      if (result == CaptureResult.queued) {
        final entry = runtime.queue
            .where((e) => e['id'] == payload['clientEventId'])
            .firstOrNull;
        switch (entry?['state']) {
          case 'accepted':
            result = CaptureResult.recorded;
          case 'pending_verification':
            result = CaptureResult.pendingVerification;
          case 'rejected':
            throw StateError(
              '${entry?['reason'] ?? tr('The server rejected this capture.', 'सर्वर ने इसे अस्वीकार किया।')}',
            );
        }
      }
      return result;
    } catch (e) {
      if (ref.mounted) state = state.copyWith(error: e);
      return CaptureResult.failed;
    } finally {
      if (capturedFile != null) {
        final cached = File(capturedFile.path);
        if (await cached.exists()) await cached.delete();
      }
      if (ref.mounted) {
        state = state.copyWith(busy: false, captureStage: '');
        unawaited(load());
      }
    }
  }

  Future<void> startTracking() async {
    await runtime.dutyTracker.bind(scope);
    await runtime.dutyTracker.enable();
  }

  Future<void> stopTracking() => runtime.dutyTracker.disable();
}

final operationsProvider = NotifierProvider.autoDispose
    .family<OperationsController, OperationsState, SiteScope>(
      OperationsController.new,
    );

class AttendanceStatus {
  const AttendanceStatus({
    this.open,
    this.since,
    this.lastKind,
    this.verification,
    this.queued = 0,
    this.events = const [],
  });
  final Json? open;
  final DateTime? since;
  final String? lastKind, verification;
  final int queued;
  final List<Json> events;
  bool get checkedIn =>
      open != null &&
      (events.isEmpty ||
          events.any((e) => e['kind'] == 'IN' && e['status'] != 'rejected'));
  bool get confirmedIn =>
      events.any((e) => e['kind'] == 'IN' && e['status'] == 'accepted');
  bool get awaitingOut =>
      open != null &&
      events.any((e) => e['kind'] == 'OUT' && e['status'] != 'rejected');
  bool get onBreak => lastKind == 'BREAK_START';
  bool get onField => lastKind == 'FIELD_START';
}

bool runtimeMatches(OperationRuntime runtime, SiteScope scope) =>
    runtime.context?['siteId'] == scope.siteId &&
    runtime.context?['actorId'] == scope.actorId;

/// Combines the server snapshot with queued local events. Server status wins:
/// a queued IN is "waiting to sync", a pending IN is "pending verification".
AttendanceStatus attendanceStatus(
  OperationsState s,
  OperationRuntime runtime,
  SiteScope scope,
) {
  final local = runtimeMatches(runtime, scope);
  final open = local
      ? runtime.localOpenDuty
      : s.ownSessions.where((x) => x['status'] == 'open').firstOrNull;
  if (open == null) {
    return AttendanceStatus(queued: local ? queuedCount(runtime, scope) : 0);
  }
  final all = sessionEvents(s, runtime, scope, open['id'] as String?);
  final visible = all.where((e) => e['kind'] != 'LOCATION').toList();
  String? verification;
  if (visible.any((e) => e['status'] == 'pending_verification')) {
    verification = 'pending_verification';
  }
  return AttendanceStatus(
    open: open,
    since: parseInstant(open['opened_at']),
    lastKind: visible.lastOrNull?['kind'] as String?,
    verification:
        verification ??
        visible.where((e) => e['kind'] == 'IN').firstOrNull?['status']
            as String?,
    queued: local ? queuedCount(runtime, scope) : 0,
    events: visible,
  );
}

int queuedCount(OperationRuntime runtime, SiteScope scope) => runtime.queue
    .where(
      (e) =>
          e['siteId'] == scope.siteId &&
          ['saved_locally', 'pending_sync'].contains(e['state']),
    )
    .length;

/// Server events for a duty plus queued local ones, ordered by sequence.
List<Json> sessionEvents(
  OperationsState s,
  OperationRuntime runtime,
  SiteScope scope,
  String? dutyId,
) {
  if (dutyId == null) return const [];
  final rows = s.events.where((e) => e['duty_id'] == dutyId).toList();
  if (runtimeMatches(runtime, scope)) {
    for (final q in runtime.queue) {
      final p = q['payload'];
      if (q['operation'] == 'event' &&
          p is Map &&
          p['dutyId'] == dutyId &&
          ['saved_locally', 'pending_sync'].contains(q['state'])) {
        rows.add({
          'kind': p['kind'],
          'sequence': p['sequence'],
          'captured_at': p['capturedAt'],
          'status': 'queued',
          'visit_id': p['visitId'],
        });
      }
    }
  }
  rows.sort(
    (a, b) =>
        ((a['sequence'] as num?) ?? 0).compareTo((b['sequence'] as num?) ?? 0),
  );
  return rows;
}

/// Minutes per segment kind for a projected session.
Map<String, int> sessionTotals(Json session) {
  final totals = <String, int>{};
  for (final seg in (session['segments'] as List? ?? const [])) {
    final start = DateTime.tryParse('${seg['startsAt']}'),
        end = DateTime.tryParse('${seg['endsAt']}');
    if (start == null || end == null) continue;
    final kind = '${seg['kind']}';
    totals[kind] = (totals[kind] ?? 0) + end.difference(start).inMinutes;
  }
  return totals;
}

String segmentLabel(String kind) => tr(
  const {
        'office': 'At site',
        'field': 'Field',
        'break': 'Break',
        'outside': 'Outside site',
        'unknown': 'Unknown',
        'overtime': 'Overtime',
      }[kind] ??
      kind,
  const {
        'office': 'साइट पर',
        'field': 'फील्ड',
        'break': 'ब्रेक',
        'outside': 'साइट के बाहर',
        'unknown': 'अज्ञात',
        'overtime': 'ओवरटाइम',
      }[kind] ??
      kind,
);

TimelineKind timelineKind(String kind) => switch (kind) {
  'IN' => TimelineKind.start,
  'OUT' => TimelineKind.end,
  'BREAK_START' || 'BREAK_END' => TimelineKind.breakTime,
  'FIELD_START' || 'FIELD_END' => TimelineKind.field,
  'VISIT_START' || 'VISIT_END' => TimelineKind.visit,
  _ => TimelineKind.neutral,
};

/// Vertical IN/OUT timeline for one session.
class SessionTimeline extends StatelessWidget {
  const SessionTimeline({super.key, required this.events});
  final List<Json> events;
  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          tr(
            'No events recorded for this session.',
            'इस सत्र के लिए कोई घटना दर्ज नहीं।',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Column(
      children: [
        for (final (i, e) in events.indexed)
          TimelineRow(
            time: formatTime(context, e['effective_at'] ?? e['captured_at']),
            title: kindLabel('${e['kind']}'),
            subtitle: e['status'] == 'pending_verification'
                ? '${e['reason'] ?? ''}'.trim().isEmpty
                      ? null
                      : reasonLabel('${e['reason']}')
                : e['classification'] != null
                ? '${e['classification']}'.replaceAll('_', ' ')
                : null,
            kind: e['status'] == 'pending_verification'
                ? TimelineKind.pending
                : timelineKind('${e['kind']}'),
            first: i == 0,
            last: i == events.length - 1,
            trailing: switch (e['status']) {
              'pending_verification' => StatusPill(
                tr('Pending verification', 'सत्यापन लंबित'),
                tone: StatusTone.warning,
              ),
              'queued' => StatusPill(
                tr('Waiting to sync', 'सिंक बाकी'),
                tone: StatusTone.info,
                icon: AppIcons.cloudUpload,
              ),
              'rejected' => StatusPill(
                tr('Rejected', 'अस्वीकृत'),
                tone: StatusTone.error,
              ),
              _ => null,
            },
          ),
      ],
    );
  }
}

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key, required this.scope});
  final SiteScope scope;
  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  late final poller = VisiblePoller(
    const Duration(seconds: 20),
    () =>
        ref.read(operationsProvider(widget.scope).notifier).load(silent: true),
  );
  String range = 'week';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    poller.start(context);
  }

  @override
  void dispose() {
    poller.stop();
    super.dispose();
  }

  Future<void> act(String kind) async {
    final controller = ref.read(operationsProvider(widget.scope).notifier);
    final result = await controller.capture(
      kind,
      requestOffsiteReason: () => requestAttendanceOutReason(context),
    );
    if (!mounted) return;
    switch (result) {
      case CaptureResult.recorded:
        HapticFeedback.lightImpact();
        showConfirmation(
          context,
          '${kindLabel(kind)} · ${tr('recorded', 'दर्ज हुआ')}',
        );
      case CaptureResult.queued:
        showConfirmation(
          context,
          tr(
            'Saved on this device. It will sync when online.',
            'इस डिवाइस पर सहेजा। ऑनलाइन होने पर सिंक होगा।',
          ),
        );
      case CaptureResult.pendingVerification:
        showConfirmation(
          context,
          tr('Recorded. Waiting for verification.', 'दर्ज हुआ। सत्यापन लंबित।'),
        );
      case CaptureResult.cancelled:
      case CaptureResult.failed:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    final ops = ref.watch(operationsProvider(scope));
    final controller = ref.read(operationsProvider(scope).notifier);
    final runtime = ref.watch(operationRuntimeProvider);
    final text = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    return PageScaffold(
      title: tr('Attendance', 'उपस्थिति'),
      actions: [
        IconButton(
          tooltip: tr('Refresh', 'रिफ्रेश'),
          onPressed: ops.busy ? null : () => controller.load(),
          icon: const AppIcon(AppIcons.rotateCw),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () => controller.load(),
        child: !ops.loaded
            ? ListView(
                padding: Space.page,
                children: [
                  if (ops.error != null)
                    InlineError(ops.error!, retry: controller.load)
                  else
                    const LoadingState(rows: 3, rowHeight: 90),
                ],
              )
            : ListenableBuilder(
                listenable: runtime,
                builder: (context, _) {
                  final status = attendanceStatus(ops, runtime, scope);
                  final own = ops.ownSessions
                    ..sort(
                      (a, b) =>
                          '${b['opened_at']}'.compareTo('${a['opened_at']}'),
                    );
                  final now = DateTime.now();
                  final weekAgo = now.subtract(const Duration(days: 7));
                  final history = own.where((s) {
                    if (s['id'] == status.open?['id']) return false;
                    final opened = parseInstant(s['opened_at']);
                    return range == 'all' ||
                        (opened != null && opened.isAfter(weekAgo));
                  }).toList();
                  final today =
                      status.open ??
                      own.where((s) {
                        final opened = parseInstant(s['opened_at']);
                        return opened != null &&
                            opened.year == now.year &&
                            opened.month == now.month &&
                            opened.day == now.day;
                      }).firstOrNull;
                  final myAdjustments = ops.adjustments
                      .where((a) => a['requester_id'] == scope.actorId)
                      .toList();
                  return ListView(
                    padding: Space.page,
                    children: [
                      if (ops.offline)
                        NoticeBanner(
                          tr(
                            'Offline · captures stay with this site and sync later. Approvals are online-only.',
                            'ऑफ़लाइन · कैप्चर इसी साइट पर रहेंगे और बाद में सिंक होंगे। स्वीकृति केवल ऑनलाइन।',
                          ),
                          tone: StatusTone.warning,
                          icon: AppIcons.cloudOff,
                          action: TextButton(
                            onPressed: () => runtime.sync(force: true),
                            child: Text(tr('Sync', 'सिंक')),
                          ),
                        ),
                      if (ops.error != null && !ops.offline)
                        InlineError(
                          ops.error!,
                          retry: controller.load,
                          compact: true,
                        ),
                      SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    status.awaitingOut
                                        ? tr('OUT submitted', 'OUT भेजा गया')
                                        : status.verification ==
                                              'pending_verification'
                                        ? tr(
                                            'Attendance awaiting approval',
                                            'उपस्थिति अनुमोदन लंबित',
                                          )
                                        : status.checkedIn
                                        ? tr('Checked in', 'चेक-इन हो गया')
                                        : tr(
                                            'Not checked in',
                                            'चेक-इन नहीं हुआ',
                                          ),
                                    style: text.titleLarge,
                                  ),
                                ),
                                if (status.verification ==
                                    'pending_verification')
                                  StatusPill(
                                    tr('Pending verification', 'सत्यापन लंबित'),
                                    tone: StatusTone.warning,
                                    icon: AppIcons.hourglass,
                                  )
                                else if (status.onBreak)
                                  StatusPill(
                                    tr('On break', 'ब्रेक पर'),
                                    tone: StatusTone.warning,
                                    icon: AppIcons.coffee,
                                  )
                                else if (status.onField)
                                  StatusPill(
                                    tr('On field duty', 'फील्ड ड्यूटी पर'),
                                    tone: StatusTone.info,
                                    icon: AppIcons.compass,
                                  )
                                else if (status.checkedIn)
                                  StatusPill(
                                    tr('IN recorded', 'IN दर्ज हुआ'),
                                    tone: StatusTone.success,
                                    icon: AppIcons.check,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (status.confirmedIn &&
                                !status.awaitingOut &&
                                status.since != null)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  ElapsedSince(
                                    status.since!,
                                    style: text.headlineMedium?.copyWith(
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      '${tr('since', 'से')} ${formatTime(context, status.since!.toIso8601String())}',
                                      style: text.bodySmall,
                                    ),
                                  ),
                                ],
                              )
                            else if (status.awaitingOut)
                              Text(
                                tr(
                                  'Your OUT is waiting for sync or attendance approval.',
                                  'आपका OUT सिंक या अनुमोदन की प्रतीक्षा में है।',
                                ),
                              )
                            else if (!ops.configured)
                              Text(
                                tr(
                                  'HR must configure the attendance policy and site boundary first.',
                                  'पहले एचआर उपस्थिति नीति और साइट सीमा निर्धारित करे।',
                                ),
                                style: text.bodyMedium,
                              )
                            else
                              Text(
                                tr(
                                  'Take a photo to check in at ${ops.siteName ?? tr('this site', 'इस साइट')}.',
                                  '${ops.siteName ?? 'इस साइट'} पर चेक-इन के लिए फोटो लें।',
                                ),
                                style: text.bodyMedium,
                              ),
                            if (status.queued > 0) ...[
                              const SizedBox(height: 6),
                              Text(
                                tr(
                                  '${status.queued} capture(s) waiting to sync from this device.',
                                  '${status.queued} कैप्चर इस डिवाइस से सिंक की प्रतीक्षा में।',
                                ),
                                style: text.bodySmall,
                              ),
                            ],
                            const SizedBox(height: 14),
                            if (ops.busy && ops.captureStage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  ops.captureStage,
                                  semanticsLabel: ops.captureStage,
                                ),
                              ),
                            ActionButton(
                              status.awaitingOut
                                  ? tr(
                                      'OUT awaiting confirmation',
                                      'OUT पुष्टि लंबित',
                                    )
                                  : status.checkedIn
                                  ? tr(
                                      'Check out with photo',
                                      'फोटो से चेक-आउट',
                                    )
                                  : tr('Check in with photo', 'फोटो से चेक-इन'),
                              icon: AppIcons.camera,
                              busy: ops.busy,
                              onPressed:
                                  !ops.configured ||
                                      ops.busy ||
                                      status.awaitingOut
                                  ? null
                                  : () => act(status.checkedIn ? 'OUT' : 'IN'),
                            ),
                            if (status.checkedIn && !status.awaitingOut) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ActionButton(
                                      status.onBreak
                                          ? tr('End break', 'ब्रेक समाप्त')
                                          : tr('Start break', 'ब्रेक शुरू'),
                                      icon: AppIcons.coffee,
                                      variant: ButtonVariant.secondary,
                                      onPressed: ops.busy
                                          ? null
                                          : () => act(
                                              status.onBreak
                                                  ? 'BREAK_END'
                                                  : 'BREAK_START',
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ActionButton(
                                      tr('Field duty', 'फील्ड ड्यूटी'),
                                      icon: AppIcons.compass,
                                      variant: ButtonVariant.secondary,
                                      onPressed: () =>
                                          context.go('/work/field-duty'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (today != null) ...[
                        SectionHeader(
                          tr('Today', 'आज'),
                          subtitle: formatDay(
                            context,
                            '${parseInstant(today['opened_at'])?.toIso8601String().substring(0, 10)}',
                          ),
                        ),
                        _HoursSummary(session: today),
                        const SizedBox(height: 8),
                        SessionTimeline(
                          events: sessionEvents(
                            ops,
                            runtime,
                            scope,
                            today['id'] as String?,
                          ),
                        ),
                        if (!ops.offline)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ActionButton(
                              tr(
                                'Fix attendance for today',
                                'आज की उपस्थिति सुधारें',
                              ),
                              icon: AppIcons.calendarCog,
                              variant: ButtonVariant.text,
                              expanded: false,
                              onPressed: () => context.go(
                                '/work/attendance/fix?duty=${today['id']}',
                              ),
                            ),
                          ),
                      ],
                      SectionHeader(
                        tr('History', 'इतिहास'),
                        trailing: SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                              value: 'week',
                              label: Text(tr('7 days', '7 दिन')),
                            ),
                            ButtonSegment(
                              value: 'all',
                              label: Text(tr('All', 'सभी')),
                            ),
                          ],
                          selected: {range},
                          onSelectionChanged: (v) =>
                              setState(() => range = v.first),
                        ),
                      ),
                      if (history.isEmpty)
                        EmptyState(
                          title: tr(
                            'No earlier sessions',
                            'कोई पिछला सत्र नहीं',
                          ),
                          message: tr(
                            'Your check-ins and check-outs will build a timeline here.',
                            'आपके चेक-इन/चेक-आउट यहाँ समयरेखा बनाएँगे।',
                          ),
                          illustration: TinyKind.clock,
                        ),
                      for (final s in history)
                        _SessionCard(
                          session: s,
                          events: sessionEvents(
                            ops,
                            runtime,
                            scope,
                            s['id'] as String?,
                          ),
                          canFix: !ops.offline,
                          onFix: () => context.go(
                            '/work/attendance/fix?duty=${s['id']}',
                          ),
                        ),
                      if (myAdjustments.isNotEmpty) ...[
                        SectionHeader(
                          tr('Your correction requests', 'आपके सुधार अनुरोध'),
                        ),
                        for (final (i, a) in myAdjustments.indexed)
                          ActionRow(
                            icon: AppIcons.calendarCog,
                            title:
                                '${segmentLabel('${a['kind']}')} · ${formatDay(context, '${parseInstant(a['starts_at'])?.toIso8601String().substring(0, 10)}')}',
                            subtitle:
                                '${formatTime(context, a['starts_at'])} – ${formatTime(context, a['ends_at'])}\n${a['reason']}${a['decision_note'] == null ? '' : '\n${tr('Decision', 'निर्णय')}: ${a['decision_note']}'}',
                            trailing: StatusPill.status('${a['status']}'),
                            divider: i < myAdjustments.length - 1,
                          ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        tr(
                          'Unknown GPS time is not absence or unpaid time. A photo or GPS sample is evidence, not biometric proof.',
                          'अज्ञात जीपीएस समय अनुपस्थिति या अवैतनिक समय नहीं है। फोटो/जीपीएस साक्ष्य है, बायोमेट्रिक प्रमाण नहीं।',
                        ),
                        style: text.bodySmall?.copyWith(color: t.textSecondary),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _HoursSummary extends StatelessWidget {
  const _HoursSummary({required this.session});
  final Json session;
  @override
  Widget build(BuildContext context) {
    final totals = sessionTotals(session);
    final text = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final overtime = (session['overtimeMinutes'] as num?)?.toInt() ?? 0;
    final worked = (totals['office'] ?? 0) + (totals['field'] ?? 0) + overtime;
    final chips = <Widget>[
      if (session['late'] == true)
        StatusPill(
          tr('Late', 'देर'),
          tone: StatusTone.warning,
          icon: AppIcons.clock3,
        ),
      if (session['early'] == true)
        StatusPill(
          tr('Left early', 'जल्दी गए'),
          tone: StatusTone.warning,
          icon: AppIcons.clock3,
        ),
      if ((session['gaps'] as List? ?? []).isNotEmpty)
        StatusPill(
          tr('Unknown time', 'अज्ञात समय'),
          tone: StatusTone.neutral,
          icon: AppIcons.circleHelp,
        ),
      if (session['status'] == 'open')
        StatusPill(tr('Open', 'खुला'), tone: StatusTone.info),
    ];
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(tr('Worked', 'काम किया'), style: text.labelMedium),
              ),
              Text(
                formatDuration(Duration(minutes: worked)),
                style: text.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final e in totals.entries)
                Text(
                  '${segmentLabel(e.key)} ${formatDuration(Duration(minutes: e.value))}',
                  style: text.bodySmall?.copyWith(color: t.text),
                ),
              if (overtime > 0)
                Text(
                  '${tr('Overtime', 'ओवरटाइम')} ${formatDuration(Duration(minutes: overtime))}',
                  style: text.bodySmall?.copyWith(color: t.text),
                ),
            ],
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: chips),
          ],
          if ((session['gaps'] as List? ?? []).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              tr(
                'Unknown time means no evidence was recorded, not absence.',
                'अज्ञात समय का अर्थ है साक्ष्य दर्ज नहीं हुआ, अनुपस्थिति नहीं।',
              ),
              style: text.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionCard extends StatefulWidget {
  const _SessionCard({
    required this.session,
    required this.events,
    required this.canFix,
    required this.onFix,
  });
  final Json session;
  final List<Json> events;
  final bool canFix;
  final VoidCallback onFix;
  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool open = false;
  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final text = Theme.of(context).textTheme;
    final totals = sessionTotals(s);
    final worked =
        (totals['office'] ?? 0) +
        (totals['field'] ?? 0) +
        ((s['overtimeMinutes'] as num?)?.toInt() ?? 0);
    final opened = parseInstant(s['opened_at']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        padding: const EdgeInsets.all(14),
        onTap: () => setState(() => open = !open),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opened == null
                            ? '—'
                            : MaterialLocalizations.of(
                                context,
                              ).formatMediumDate(opened),
                        style: text.titleMedium,
                      ),
                      Text(
                        '${formatTime(context, s['opened_at'])} – ${s['closed_at'] == null ? tr('open', 'खुला') : formatTime(context, s['closed_at'])} · ${formatDuration(Duration(minutes: worked))}',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                if ((s['gaps'] as List? ?? []).isNotEmpty)
                  StatusPill(
                    tr('Unknown time', 'अज्ञात समय'),
                    icon: AppIcons.circleHelp,
                  ),
                const SizedBox(width: 6),
                AppIcon(
                  open ? AppIcons.chevronUp : AppIcons.chevronDown,
                  color: AppTokens.of(context).textSecondary,
                ),
              ],
            ),
            AnimatedSize(
              duration: Motion.medium,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !open
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        SessionTimeline(events: widget.events),
                        if (widget.canFix)
                          ActionButton(
                            tr('Fix this session', 'यह सत्र सुधारें'),
                            icon: AppIcons.calendarCog,
                            variant: ButtonVariant.text,
                            expanded: false,
                            onPressed: widget.onFix,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class FixAttendancePage extends ConsumerStatefulWidget {
  const FixAttendancePage({super.key, required this.scope, this.dutyId});
  final SiteScope scope;
  final String? dutyId;
  @override
  ConsumerState<FixAttendancePage> createState() => _FixAttendancePageState();
}

class _FixAttendancePageState extends ConsumerState<FixAttendancePage> {
  late final UnsavedWork unsaved;
  final form = GlobalKey<FormState>();
  final reason = TextEditingController();
  String? duty, startsAt, endsAt;
  String kind = 'office';
  bool closeSession = false, busy = false;
  Object? error;
  @override
  void initState() {
    super.initState();
    unsaved = ref.read(unsavedWorkProvider);
    duty = widget.dutyId;
  }

  void dirty() => ref
      .read(unsavedWorkProvider)
      .mark(
        'fix-attendance',
        tr('Fix Attendance', 'उपस्थिति सुधार'),
        reason.text.isNotEmpty || startsAt != null || endsAt != null,
      );
  @override
  void dispose() {
    unsaved.mark('fix-attendance', '', false);
    reason.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate() || duty == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(operationsProvider(widget.scope).notifier)
          .command('adjustment', {
            'dutyId': duty,
            'startsAt': startsAt,
            'endsAt': endsAt,
            'kind': kind,
            'reason': reason.text.trim(),
            'closeSession': closeSession,
          });
      unsaved.mark('fix-attendance', '', false);
      if (mounted) {
        showConfirmation(
          context,
          tr('Correction request sent', 'सुधार अनुरोध भेजा गया'),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ops = ref.watch(operationsProvider(widget.scope));
    final sessions = ops.ownSessions
      ..sort((a, b) => '${b['opened_at']}'.compareTo('${a['opened_at']}'));
    final text = Theme.of(context).textTheme;
    return PageScaffold(
      title: tr('Fix Attendance', 'उपस्थिति सुधारें'),
      body: Form(
        key: form,
        onChanged: dirty,
        child: FormPageBody(
          fields: [
            Text(
              tr(
                'Request a correction or overtime',
                'सुधार या ओवरटाइम का अनुरोध',
              ),
              style: text.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              tr(
                'Your approver reviews the request. Approved corrections are added to your session as evidence.',
                'आपका अनुमोदक अनुरोध की समीक्षा करता है। स्वीकृत सुधार साक्ष्य के रूप में सत्र में जुड़ते हैं।',
              ),
              style: text.bodyMedium?.copyWith(
                color: AppTokens.of(context).textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            if (ops.offline)
              NoticeBanner(
                tr('Corrections are online-only.', 'सुधार केवल ऑनलाइन।'),
                tone: StatusTone.warning,
              ),
            AppDropdown<String>(
              label: tr('Session', 'सत्र'),
              value: duty,
              hint: tr('Choose a day', 'दिन चुनें'),
              items: [
                for (final s in sessions.take(30))
                  (
                    s['id'] as String,
                    '${formatDay(context, parseInstant(s['opened_at'])?.toIso8601String().substring(0, 10))} · ${formatTime(context, s['opened_at'])}${s['status'] == 'open' ? ' · ${tr('open', 'खुला')}' : ''}',
                  ),
              ],
              validator: (v) =>
                  v == null ? tr('Choose a session', 'सत्र चुनें') : null,
              onChanged: (v) => setState(() => duty = v),
            ),
            DateField(
              label: tr('From', 'से'),
              value: startsAt,
              withTime: true,
              validator: (v) => v == null ? tr('Required', 'आवश्यक') : null,
              onChanged: (v) => setState(() {
                startsAt = v;
                dirty();
              }),
            ),
            DateField(
              label: tr('To', 'तक'),
              value: endsAt,
              withTime: true,
              validator: (v) => v == null
                  ? tr('Required', 'आवश्यक')
                  : startsAt != null &&
                        DateTime.tryParse(
                              v,
                            )?.isAfter(DateTime.parse(startsAt!)) !=
                            true
                  ? tr('End must be after start', 'समाप्ति आरंभ के बाद हो')
                  : null,
              onChanged: (v) => setState(() {
                endsAt = v;
                dirty();
              }),
            ),
            ChoiceChips<String>(
              label: tr('What was this time?', 'यह समय क्या था?'),
              value: kind,
              items: [
                for (final k in [
                  'office',
                  'field',
                  'break',
                  'outside',
                  'unknown',
                  'overtime',
                ])
                  (k, segmentLabel(k)),
              ],
              onChanged: (v) => setState(() => kind = v),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                tr(
                  'I never checked out that day',
                  'उस दिन मैंने चेक-आउट नहीं किया',
                ),
              ),
              subtitle: Text(
                tr(
                  'Close the session with this correction',
                  'इस सुधार से सत्र बंद करें',
                ),
              ),
              value: closeSession,
              onChanged: (v) => setState(() => closeSession = v),
            ),
            const SizedBox(height: 8),
            AppTextField(
              label: tr('Reason', 'कारण'),
              controller: reason,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              help: tr('At least 8 characters', 'कम से कम 8 अक्षर'),
              validator: (v) => (v?.trim().length ?? 0) < 8
                  ? tr('Use at least 8 characters', 'कम से कम 8 अक्षर लिखें')
                  : null,
            ),
            if (error != null) InlineError(error!),
          ],
          actions: [
            ActionButton(
              tr('Send for review', 'समीक्षा के लिए भेजें'),
              icon: AppIcons.sendHorizontal,
              busy: busy,
              onPressed: busy || ops.offline ? null : submit,
            ),
          ],
        ),
      ),
    );
  }
}

class FieldDutyPage extends ConsumerStatefulWidget {
  const FieldDutyPage({super.key, required this.scope});
  final SiteScope scope;
  @override
  ConsumerState<FieldDutyPage> createState() => _FieldDutyPageState();
}

class _FieldDutyPageState extends ConsumerState<FieldDutyPage> {
  late final poller = VisiblePoller(
    const Duration(seconds: 20),
    () =>
        ref.read(operationsProvider(widget.scope).notifier).load(silent: true),
  );
  Object? trackingError;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    poller.start(context);
  }

  @override
  void dispose() {
    poller.stop();
    super.dispose();
  }

  Future<void> toggleTracking() async {
    final controller = ref.read(operationsProvider(widget.scope).notifier);
    final runtime = ref.read(operationRuntimeProvider);
    if (runtime.dutyTracker.enabledOnDevice) {
      await controller.stopTracking();
      return;
    }
    final agreed = await confirmDialog(
      context,
      title: tr('Duty location sharing', 'ड्यूटी स्थान साझाकरण'),
      message: tr(
        '${runtime.dutyTracker.disclosure} Location sharing starts automatically during HR-authorized shifts, including before check-in if HR selects that mode, and stops outside that window. HR can see received coordinates, accuracy and last-seen time. A visible notification or location indicator stays on. When offline, readings are encrypted on this device until connectivity returns, within the downloaded shift only. HR changes arrive after reconnection. Upload within 7 days; signing out deletes unsynced readings. Force-stop, permissions and OS restrictions can create gaps. Open the app at shift start. Location sharing does not mark attendance.',
        '${runtime.dutyTracker.disclosure} एचआर की निर्धारित शिफ्ट में स्थान अपने आप साझा होगा, चेक-इन से पहले भी यदि एचआर ने यह चुना हो। ड्यूटी समाप्त होने पर साझाकरण रुकता है। अधिकृत एचआर को प्राप्त स्थान, सटीकता और अंतिम समय दिखते हैं। सूचना या स्थान संकेत चालू रहता है। नेटवर्क, अनुमति या सिस्टम रोकने पर अंतराल हो सकते हैं। शिफ्ट शुरू होने पर ऐप खोलें। स्थान साझा करने से उपस्थिति नहीं लगती।',
      ),
      confirmLabel: tr('Enable during duty', 'ड्यूटी में सक्षम करें'),
    );
    if (!agreed) return;
    try {
      await controller.startTracking();
      if (mounted) setState(() => trackingError = null);
    } catch (e) {
      if (mounted) setState(() => trackingError = e);
    }
  }

  Future<void> act(String kind, {String? visitId}) async {
    final result = await ref
        .read(operationsProvider(widget.scope).notifier)
        .capture(kind, visitId: visitId);
    if (!mounted) return;
    if (result == CaptureResult.recorded ||
        result == CaptureResult.pendingVerification) {
      showConfirmation(context, kindLabel(kind));
    } else if (result == CaptureResult.queued) {
      showConfirmation(
        context,
        tr(
          'Saved on this device. It will sync when online.',
          'इस डिवाइस पर सहेजा। ऑनलाइन होने पर सिंक होगा।',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    final ops = ref.watch(operationsProvider(scope));
    final runtime = ref.watch(operationRuntimeProvider);
    final text = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    return PageScaffold(
      title: tr('Field Duty', 'फील्ड ड्यूटी'),
      body: !ops.loaded
          ? ListView(
              padding: Space.page,
              children: [
                if (ops.error != null)
                  InlineError(
                    ops.error!,
                    retry: () =>
                        ref.read(operationsProvider(scope).notifier).load(),
                  )
                else
                  const LoadingState(rows: 3),
              ],
            )
          : ListenableBuilder(
              listenable: runtime,
              builder: (context, _) {
                final status = attendanceStatus(ops, runtime, scope);
                final last = runtime.lastSample;
                final stale =
                    last != null &&
                    DateTime.now().difference(last) >
                        Duration(
                          seconds:
                              (runtime
                                          .dutyTracker
                                          .authorization?['policy']?['stale_seconds']
                                      as num?)
                                  ?.toInt() ??
                              120,
                        );
                final queuedSamples = runtime.queue
                    .where(
                      (e) =>
                          e['siteId'] == scope.siteId &&
                          e['payload']?['kind'] == 'LOCATION' &&
                          [
                            'saved_locally',
                            'pending_sync',
                          ].contains(e['state']),
                    )
                    .length;
                final loc = runtime.lastLocation;
                return ListView(
                  padding: Space.page,
                  children: [
                    if (ops.offline)
                      NoticeBanner(
                        tr(
                          'Offline · permitted duty locations are encrypted on this device and sync when connected. HR sees the last received sample.',
                          'ऑफ़लाइन · अनुमत ड्यूटी स्थान डिवाइस पर एन्क्रिप्ट होकर सहेजे जाते हैं और इंटरनेट आने पर सिंक होते हैं।',
                        ),
                        tone: StatusTone.warning,
                        icon: AppIcons.cloudOff,
                      ),
                    if (ops.error != null && !ops.offline)
                      InlineError(ops.error!, compact: true),
                    if (trackingError != null) InlineError(trackingError!),
                    SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  status.onField
                                      ? tr('On field duty', 'फील्ड ड्यूटी पर')
                                      : status.checkedIn
                                      ? tr('At site', 'साइट पर')
                                      : tr('Not checked in', 'चेक-इन नहीं हुआ'),
                                  style: text.titleLarge,
                                ),
                              ),
                              if (runtime.tracking)
                                StatusPill(
                                  tr('Tracking', 'ट्रैकिंग'),
                                  tone: StatusTone.success,
                                  icon: AppIcons.circleDot,
                                )
                              else
                                StatusPill(
                                  tr('Not tracking', 'ट्रैकिंग बंद'),
                                  tone: StatusTone.neutral,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          KeyValueRow(
                            tr('Current site', 'वर्तमान साइट'),
                            ops.siteName ?? '—',
                            selectable: false,
                          ),
                          KeyValueRow(
                            tr('Last location update', 'अंतिम स्थान अपडेट'),
                            last == null
                                ? tr(
                                    'No location recorded yet',
                                    'अभी कोई स्थान दर्ज नहीं',
                                  )
                                : '${relativeTime(context, last.toIso8601String())}${loc?['accuracyM'] != null ? ' · ±${(loc!['accuracyM'] as num).round()} m' : ''}${loc?['mocked'] == true ? ' · ${tr('mock location', 'नकली स्थान')}' : ''}',
                            selectable: false,
                            trailing: stale
                                ? StatusPill(
                                    tr('Stale', 'पुराना'),
                                    tone: StatusTone.warning,
                                    icon: AppIcons.history,
                                  )
                                : null,
                          ),
                          if (queuedSamples > 0)
                            KeyValueRow(
                              tr('Waiting to sync', 'सिंक बाकी'),
                              tr(
                                '$queuedSamples samples on this device',
                                '$queuedSamples नमूने इस डिवाइस पर',
                              ),
                              selectable: false,
                            ),
                          if (runtime.notice.isNotEmpty)
                            Text(
                              runtime.notice,
                              style: text.bodySmall?.copyWith(color: t.warning),
                            ),
                          AnimatedSwitcher(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 220),
                            child: Align(
                              key: ValueKey(runtime.trackingStatus),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                runtime.trackingStatus,
                                style: text.bodySmall,
                              ),
                            ),
                          ),
                          if (runtime.tracking &&
                              runtime
                                  .dutyTracker
                                  .samplingStatus
                                  .isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                AppIcon(
                                  AppIcons.batteryLow,
                                  size: 16,
                                  color: t.success,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    runtime.dutyTracker.samplingStatus,
                                    style: text.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          KeyValueRow(
                            'Secure location queue',
                            '${runtime.dutyTracker.queuedCount} waiting · ${runtime.dutyTracker.rejectedCount} need review',
                            selectable: false,
                          ),
                          if (runtime.dutyTracker.queuedCount > 0)
                            ActionButton(
                              'Sync saved locations',
                              icon: AppIcons.refreshCw,
                              busy: runtime.dutyTracker.syncingQueue,
                              onPressed: runtime.dutyTracker.syncingQueue
                                  ? null
                                  : () => runtime.dutyTracker.syncQueue(
                                      force: true,
                                    ),
                            ),
                          if (runtime.dutyTracker.rejectedCount > 0)
                            Text(
                              'Some readings were rejected by the server. They remain encrypted on this device; they are not shown as received by HR.',
                              style: text.bodySmall?.copyWith(color: t.warning),
                            ),
                          Text(
                            'Offline capture ends with the downloaded shift. Reconnect to receive HR schedule changes. Saved readings have a 7-day upload deadline.',
                            style: text.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          if (runtime.dutyTracker.needsLocation) ...[
                            ActionButton(
                              tr('Turn on location', 'स्थान चालू करें'),
                              icon: AppIcons.mapPin,
                              onPressed: runtime.dutyTracker.fixLocation,
                            ),
                            const SizedBox(height: 8),
                          ],
                          ActionButton(
                            runtime.dutyTracker.enabledOnDevice
                                ? 'Disable automatic duty location'
                                : 'Enable automatic duty location',
                            icon: AppIcons.mapPin,
                            onPressed: toggleTracking,
                          ),
                          const SizedBox(height: 12),
                          if (!status.checkedIn)
                            Text(
                              tr(
                                'Check in at the site first, then start field duty.',
                                'पहले साइट पर चेक-इन करें, फिर फील्ड ड्यूटी शुरू करें।',
                              ),
                              style: text.bodyMedium,
                            )
                          else ...[
                            ActionButton(
                              status.onField
                                  ? tr('End field duty', 'फील्ड ड्यूटी समाप्त')
                                  : tr('Start field duty', 'फील्ड ड्यूटी शुरू'),
                              icon: status.onField
                                  ? AppIcons.circleStop
                                  : AppIcons.compass,
                              busy: ops.busy,
                              onPressed: ops.busy
                                  ? null
                                  : () => act(
                                      status.onField
                                          ? 'FIELD_END'
                                          : 'FIELD_START',
                                    ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                    SectionHeader(tr('Assigned visits', 'निर्धारित दौरे')),
                    if (ops.visits.isEmpty)
                      EmptyState(
                        title: tr(
                          'No visits scheduled',
                          'कोई दौरा निर्धारित नहीं',
                        ),
                        message: tr(
                          'Visits assigned to you appear here with arrive and leave actions.',
                          'आपको सौंपे दौरे यहाँ पहुँचने/छोड़ने की क्रिया के साथ दिखेंगे।',
                        ),
                        illustration: TinyKind.site,
                      ),
                    for (final v in ops.visits)
                      SurfaceCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${v['title']}', style: text.titleMedium),
                            Text(
                              formatInstant(context, v['scheduled_at']),
                              style: text.bodySmall,
                            ),
                            if ('${v['notes'] ?? ''}'.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${v['notes']}',
                                  style: text.bodyMedium,
                                ),
                              ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ActionButton(
                                    tr('Arrive (photo)', 'पहुँचे (फोटो)'),
                                    icon: AppIcons.camera,
                                    variant: ButtonVariant.secondary,
                                    onPressed: !status.checkedIn || ops.busy
                                        ? null
                                        : () => act(
                                            'VISIT_START',
                                            visitId: v['id'] as String,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ActionButton(
                                    tr('Leave (photo)', 'छोड़ा (फोटो)'),
                                    icon: AppIcons.logOut,
                                    variant: ButtonVariant.secondary,
                                    onPressed: !status.checkedIn || ops.busy
                                        ? null
                                        : () => act(
                                            'VISIT_END',
                                            visitId: v['id'] as String,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      tr(
                        'This build shows recorded location facts only; there is no map preview. Gaps in tracking are kept as gaps.',
                        'यह संस्करण केवल दर्ज स्थान तथ्य दिखाता है; मानचित्र पूर्वावलोकन नहीं है। ट्रैकिंग में अंतराल अंतराल ही रहते हैं।',
                      ),
                      style: text.bodySmall,
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class TeamAttendancePage extends ConsumerStatefulWidget {
  const TeamAttendancePage({super.key, required this.scope});
  final SiteScope scope;
  @override
  ConsumerState<TeamAttendancePage> createState() => _TeamAttendancePageState();
}

class _TeamAttendancePageState extends ConsumerState<TeamAttendancePage> {
  String filter = 'today';
  @override
  Widget build(BuildContext context) {
    final ops = ref.watch(operationsProvider(widget.scope));
    final runtime = ref.watch(operationRuntimeProvider);
    final now = DateTime.now();
    final rows = ops.sessions.where((s) {
      if (s['employee_id'] == ops.me) return false;
      if (filter == 'all') return true;
      final opened = parseInstant(s['opened_at']);
      return opened != null &&
          opened.year == now.year &&
          opened.month == now.month &&
          opened.day == now.day;
    }).toList();
    return PageScaffold(
      title: tr('Team attendance', 'टीम उपस्थिति'),
      body: !ops.loaded
          ? ListView(
              padding: Space.page,
              children: [
                if (ops.error != null)
                  InlineError(
                    ops.error!,
                    retry: () => ref
                        .read(operationsProvider(widget.scope).notifier)
                        .load(),
                  )
                else
                  const LoadingState(rows: 4),
              ],
            )
          : ListView(
              padding: Space.page,
              children: [
                FilterBar<String>(
                  value: filter,
                  items: [
                    ('today', tr('Today', 'आज')),
                    ('all', tr('Recent', 'हाल के')),
                  ],
                  onChanged: (v) => setState(() => filter = v),
                ),
                const SizedBox(height: 8),
                if (rows.isEmpty)
                  EmptyState(
                    title: tr('No team sessions', 'कोई टीम सत्र नहीं'),
                    message: tr(
                      'Sessions of people you are authorized to see appear here.',
                      'जिन लोगों को देखने की अनुमति है उनके सत्र यहाँ दिखेंगे।',
                    ),
                    illustration: TinyKind.people,
                  ),
                for (final s in rows)
                  _TeamSessionCard(
                    session: s,
                    events: sessionEvents(
                      ops,
                      runtime,
                      widget.scope,
                      s['id'] as String?,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _TeamSessionCard extends StatefulWidget {
  const _TeamSessionCard({required this.session, required this.events});
  final Json session;
  final List<Json> events;
  @override
  State<_TeamSessionCard> createState() => _TeamSessionCardState();
}

class _TeamSessionCardState extends State<_TeamSessionCard> {
  bool open = false;
  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final text = Theme.of(context).textTheme;
    final totals = sessionTotals(s);
    final worked = (totals['office'] ?? 0) + (totals['field'] ?? 0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        padding: const EdgeInsets.all(14),
        onTap: () => setState(() => open = !open),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar('${s['display_name'] ?? '?'}', size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s['display_name'] ?? tr('Employee', 'कर्मचारी')}',
                        style: text.titleMedium,
                      ),
                      Text(
                        '${formatInstant(context, s['opened_at'])} · ${formatDuration(Duration(minutes: worked))}',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                StatusPill.status('${s['status']}'),
              ],
            ),
            AnimatedSize(
              duration: Motion.medium,
              alignment: Alignment.topCenter,
              child: !open
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: SessionTimeline(events: widget.events),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Independent evidence review for a pending attendance event.
Future<bool> verifyEventFlow(
  BuildContext context,
  WidgetRef ref,
  SiteScope scope,
  Json event,
) async {
  String? effectiveAt = event['captured_at']?.toString();
  final result = await askDecision(
    context,
    title: tr('Review attendance evidence', 'उपस्थिति साक्ष्य समीक्षा'),
    message:
        '${kindLabel('${event['kind']}')} · ${formatInstant(context, event['captured_at'])}\n${event['reason'] ?? ''}\n${event['offsite_reason'] == null ? '' : 'Employee reason: ${event['offsite_reason']}'}',
    approveLabel: tr('Accept', 'स्वीकार करें'),
    rejectLabel: tr('Reject', 'अस्वीकार करें'),
    extra: StatefulBuilder(
      builder: (ctx, set) => DateField(
        label: tr('Effective time', 'प्रभावी समय'),
        value: effectiveAt,
        withTime: true,
        onChanged: (v) => set(() => effectiveAt = v),
      ),
    ),
  );
  if (result == null) return false;
  try {
    await ref.read(operationsProvider(scope).notifier).command('verifyEvent', {
      'id': event['id'],
      'expectedStatus': 'pending_verification',
      'approve': result.approve,
      if (result.approve) 'effectiveAt': effectiveAt,
      'reason': result.note,
    });
    if (context.mounted) {
      showConfirmation(
        context,
        result.approve
            ? tr('Evidence accepted', 'साक्ष्य स्वीकृत')
            : tr('Evidence rejected', 'साक्ष्य अस्वीकृत'),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
    return false;
  }
}

Future<bool> reviewAdjustmentFlow(
  BuildContext context,
  WidgetRef ref,
  SiteScope scope,
  Json a,
) async {
  final result = await askDecision(
    context,
    title: tr('Review correction request', 'सुधार अनुरोध समीक्षा'),
    message:
        '${segmentLabel('${a['kind']}')} · ${formatInstant(context, a['starts_at'])} – ${formatTime(context, a['ends_at'])}\n${a['reason']}',
  );
  if (result == null) return false;
  try {
    await ref
        .read(operationsProvider(scope).notifier)
        .command('reviewAdjustment', {
          'id': a['id'],
          'expectedVersion': a['version'],
          'approve': result.approve,
          'reason': result.note,
        });
    if (context.mounted) {
      showConfirmation(
        context,
        result.approve
            ? tr('Correction approved', 'सुधार स्वीकृत')
            : tr('Correction rejected', 'सुधार अस्वीकृत'),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
    return false;
  }
}

Future<String?> requestAttendanceOutReason(BuildContext context) async {
  if (!context.mounted) return null;
  var reason = '';
  final form = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      scrollable: true,
      title: Text(tr('OUT needs approval', 'OUT के लिए अनुमोदन चाहिए')),
      content: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr(
                'You are outside the site, or GPS could not confirm you are inside. Explain the reason. This OUT counts only after your attendance approver accepts it.',
                'आप साइट के बाहर हैं या GPS अंदर होने की पुष्टि नहीं कर सका। कारण बताएँ। अनुमोदक की स्वीकृति के बाद ही यह OUT मान्य होगा।',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              onChanged: (value) => reason = value,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: tr('Reason for OUT', 'OUT का कारण'),
              ),
              validator: (v) => (v?.trim().length ?? 0) < 8
                  ? tr('Enter at least 8 characters', 'कम से कम 8 अक्षर लिखें')
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(tr('Cancel', 'रद्द करें')),
        ),
        FilledButton(
          onPressed: () {
            if (form.currentState!.validate()) {
              Navigator.pop(dialogContext, reason.trim());
            }
          },
          child: Text(tr('Submit for approval', 'अनुमोदन हेतु भेजें')),
        ),
      ],
    ),
  );
}
