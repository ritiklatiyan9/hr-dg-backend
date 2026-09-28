import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'api.dart';
import 'duty_tracker.dart';
import 'attendance_location.dart';
import 'scope.dart';
import 'operation_vault.dart';
import 'graphql/operations.graphql.dart';

typedef Json = Map<String, dynamic>;

/// Failed local attempts consume no server sequence; pending/server-rejected
/// receipts do. Recompute from durable evidence after cancellation or relaunch.
int nextAttendanceSequence(String dutyId, Map? session, Iterable<Map> queue) {
  var highest = <num>[
    if (session?['last_sequence'] is num) session!['last_sequence'] as num,
    if (session?['max_sequence'] is num) session!['max_sequence'] as num,
  ].fold<int>(0, (a, b) => a > b ? a : b.toInt());
  for (final row in queue) {
    final p = row['payload'];
    if (p is! Map ||
        p['dutyId'] != dutyId ||
        row['state'] == 'rejected' && row['serverId'] == null) {
      continue;
    }
    final sequence = p['sequence'];
    if (sequence is num && sequence > highest) highest = sequence.toInt();
  }
  return highest + 1;
}

class OperationRuntime extends ChangeNotifier {
  OperationRuntime(this.api) : dutyTracker = DutyTracker(api) {
    dutyTracker.addListener(notifyListeners);
    invalidations = api.invalidations.stream.listen((_) => clear());
  }
  StreamSubscription<String>? invalidations;
  Future<void> close() async {
    syncTimer?.cancel();
    await _syncTask;
    await receipts.close();
    await invalidations?.cancel();
    dutyTracker.removeListener(notifyListeners);
    await dutyTracker.close();
    await stopTracking();
  }

  final HrApi api;
  final DutyTracker dutyTracker;
  Future<void> bindTrackingScope(SiteScope? scope) => dutyTracker.bind(scope);
  OperationVault? vault;
  Json? context;
  List<Json> queue = [];
  Timer? syncTimer;
  bool syncing = false;
  Future<void>? _syncTask;
  final receipts = StreamController<SiteScope>.broadcast();
  bool get tracking => dutyTracker.tracking;
  String get trackingStatus => dutyTracker.status;
  String notice = '';
  DateTime? get lastSample => dutyTracker.lastSample;
  Json? get lastLocation => dutyTracker.lastLocation;
  int sequence = 0;
  String? dutyId;
  SiteScope? dutyScope;
  static const uuid = Uuid();
  Future<void> connect(
    SiteScope scope,
    Json snapshot,
    List<String> capabilities,
  ) async {
    if (dutyScope != null && dutyScope!.siteId != scope.siteId) {
      await stopTracking();
      notice =
          'Tracking stopped on workspace change. Queued evidence retains its original site.';
    }
    final actorKey = '${scope.organizationId}:${scope.actorId}';
    if (context?['actorKey'] != actorKey) {
      await stopTracking();
      vault = await OperationVault.open(scope.organizationId, scope.actorId);
      queue = await vault!.entries();
    }
    final rules = (snapshot['policy'] as Map?)?['rules'] as Map?;
    final ownSessions = (snapshot['sessions'] as List)
        .where((e) => e['employee_id'] == snapshot['me'])
        .toList();
    context = {
      'actorKey': actorKey,
      'organizationId': scope.organizationId,
      'actorId': scope.actorId,
      'siteId': scope.siteId,
      'siteName': snapshot['siteName'],
      'permissionVersion': scope.permissionVersion,
      'endpoint': api.dio.options.baseUrl,
      'capabilities': capabilities,
      'serverTime': snapshot['serverTime'],
      'policy': snapshot['policy'],
      'geofence': snapshot['geofence'],
      'me': snapshot['me'],
      'sessions': ownSessions,
      'visits': (snapshot['visits'] as List)
          .where((v) => v['employee_id'] == snapshot['me'])
          .toList(),
      'tasks': (snapshot['tasks'] as List)
          .where((v) => v['employee_id'] == snapshot['me'])
          .toList(),
      'leaseUntil': DateTime.parse(snapshot['serverTime'] as String)
          .add(
            Duration(
              hours: rules?['allowOffline'] == true
                  ? ((rules?['offlineMaxHours'] as num?)?.toInt() ?? 0)
                  : 0,
            ),
          )
          .toUtc()
          .toIso8601String(),
    };
    for (final entry in queue.where(
      (e) => e['state'] == 'pending_verification',
    )) {
      final event = (snapshot['events'] as List)
          .where((e) => e['id'] == entry['serverId'])
          .firstOrNull;
      if (event != null && event['status'] != 'pending_verification') {
        entry['state'] = event['status'];
        entry['reason'] = event['reason'];
        await vault!.write(entry['id'] as String, entry);
      }
    }
    await vault!.write('context', context!);
    await api.storage.write(
      key: 'offline_identity',
      value: jsonEncode({
        'organizationId': scope.organizationId,
        'actorId': scope.actorId,
      }),
    );
    api.beforeClear = clear;
    syncTimer ??= Timer.periodic(const Duration(seconds: 20), (_) => sync());
    unawaited(sync());
  }

  Future<bool> restoreOffline() async {
    final identity = await api.storage.read(key: 'offline_identity');
    if (identity == null) return false;
    final parsed = jsonDecode(identity) as Map;
    vault = await OperationVault.open(
      parsed['organizationId'] as String,
      parsed['actorId'] as String,
    );
    context = await vault!.read('context');
    queue = await vault!.entries();
    api.beforeClear = clear;
    // A fresh online lease is required before automatically resuming.
    await dutyTracker.bind(null);
    notifyListeners();
    return context != null;
  }

  SiteScope scopeFrom(Json c) => SiteScope(
    c['organizationId'] as String,
    c['actorId'] as String,
    c['permissionVersion'] as int,
    c['siteId'] as String,
  );
  bool get canSaveOffline =>
      context != null &&
      (context!['policy']?['rules']?['allowOffline'] == true) &&
      DateTime.now().isAfter(
        DateTime.parse(
          context!['serverTime'] as String,
        ).subtract(const Duration(seconds: 30)),
      ) &&
      DateTime.tryParse('${context!['leaseUntil']}')?.isAfter(DateTime.now()) ==
          true;
  Future<Json> online(SiteScope scope, String operation, Json input) async =>
      Map<String, dynamic>.from(
        (await api.scopedWrite(scope, documentNodeMutationOperate, {
              'operation': operation,
              'input': input,
            }))['operate']
            as Map,
      );
  Future<void> enqueue(
    SiteScope scope,
    String operation,
    Json input, {
    List<int>? photo,
    String? photoType,
  }) async {
    if (vault == null ||
        context?['siteId'] != scope.siteId ||
        context?['actorId'] != scope.actorId ||
        context?['organizationId'] != scope.organizationId) {
      throw StateError('Verify the current account before saving locally');
    }
    if (!['event', 'leave', 'comment'].contains(operation)) {
      throw StateError('This action is online-only');
    }
    if (!canSaveOffline) {
      throw StateError(
        'Offline capture is not enabled or its authorization lease expired',
      );
    }
    if (photo != null && photo.length > 8 * 1024 * 1024) {
      throw StateError('Photo exceeds 8 MB');
    }
    if ((await vault!.entries())
            .where((e) => !['accepted', 'rejected'].contains(e['state']))
            .length >=
        100) {
      throw StateError('Outbox is full; synchronize before capturing more');
    }
    final completed = (await vault!.entries())
        .where((e) => ['accepted', 'rejected'].contains(e['state']))
        .toList();
    // Keep a bounded local receipt list. Durable decisions remain in server history.
    for (final old in completed.take(
      (completed.length - 99).clamp(0, completed.length),
    )) {
      await vault!.remove(old['id'] as String);
    }
    final clientId = (input['clientEventId'] ?? input['clientId']) as String;
    final entry = <String, dynamic>{
      'id': clientId,
      'organizationId': scope.organizationId,
      'actorId': scope.actorId,
      'siteId': scope.siteId,
      'siteName': context?['siteName'],
      'permissionVersion': scope.permissionVersion,
      'endpoint': api.dio.options.baseUrl,
      'clientEventId': clientId,
      'capturedAt':
          input['capturedAt'] ?? DateTime.now().toUtc().toIso8601String(),
      'payloadVersion': 1,
      'operation': operation,
      'payload': input,
      'state': 'saved_locally',
      'attempts': 0,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'nextAttemptAt': DateTime.now().toUtc().toIso8601String(),
      if (photo != null) 'photo': base64Encode(photo),
      'photoType': ?photoType,
    };
    await vault!.write(clientId, entry);
    queue = await vault!.entries();
    notifyListeners();
  }

  Future<void> sync({bool force = false}) {
    final running = _syncTask;
    if (running != null) {
      // A capture may have arrived after the running drain took its snapshot.
      return force ? running.then((_) => sync(force: true)) : running;
    }
    final task = _drain(force: force);
    _syncTask = task;
    unawaited(
      task
          .whenComplete(() {
            if (identical(_syncTask, task)) _syncTask = null;
          })
          .catchError((Object _) {}),
    );
    return task;
  }

  Future<void> _drain({required bool force}) async {
    if (vault == null || context == null) return;
    if (!queue.any(
      (entry) =>
          ['saved_locally', 'pending_sync'].contains(entry['state']) &&
          (force ||
              !DateTime.parse(
                entry['nextAttemptAt'] as String,
              ).isAfter(DateTime.now())),
    )) {
      return;
    }
    syncing = true;
    notifyListeners();
    try {
      final bootstrap = (await api.bootstrap()).bootstrap;
      if (bootstrap.actor.id != context!['actorId'] ||
          bootstrap.organization.id != context!['organizationId']) {
        await clear();
        return;
      }
      final verifiedSites = <String>{};
      for (final entry in await vault!.entries()) {
        if ([
          'accepted',
          'rejected',
          'pending_verification',
        ].contains(entry['state'])) {
          continue;
        }
        if (!force &&
            DateTime.parse(
              entry['nextAttemptAt'] as String,
            ).isAfter(DateTime.now())) {
          continue;
        }
        if (entry['endpoint'] != api.dio.options.baseUrl) {
          throw StateError('Outbox belongs to another server');
        }
        final scope = SiteScope(
          entry['organizationId'] as String,
          entry['actorId'] as String,
          bootstrap.actor.permissionVersion,
          entry['siteId'] as String,
        );
        try {
          // Fresh capabilities at the original site; the selected workspace is irrelevant.
          if (verifiedSites.add(scope.siteId)) await api.capabilities(scope);
          entry['state'] = 'pending_sync';
          await vault!.write(entry['id'] as String, entry);
          notifyListeners();
          final payload = Map<String, dynamic>.from(entry['payload'] as Map);
          if (entry['photo'] != null) {
            final bytes = base64Decode(entry['photo'] as String);
            final intent = await online(scope, 'fileIntent', {
              'clientId': entry['id'],
              'purpose': payload['kind'].toString().startsWith('VISIT_')
                  ? 'visit'
                  : 'attendance',
              'type': entry['photoType'] ?? 'image/jpeg',
              'bytes': bytes.length,
            });
            final response = await api.dio.post<Json>(
              '/files/intents/${intent['id']}/content',
              queryParameters: {'siteId': scope.siteId},
              data: Stream.value(bytes),
              options: Options(
                headers: {
                  'authorization': 'Bearer ${api.access}',
                  'content-type': 'application/octet-stream',
                  'content-length': bytes.length,
                },
              ),
            );
            if (response.data?['status'] != 'ready') {
              throw const ApiFailure(
                'FILE_NOT_READY',
                'Photo is quarantined or rejected',
              );
            }
            payload['photoId'] = intent['id'];
            // Persist the ready upload before sending the event. A retry after
            // an event timeout reuses the evidence instead of uploading again.
            entry['payload'] = payload;
            entry.remove('photo');
            await vault!.write(entry['id'] as String, entry);
          }
          final result = await online(
            scope,
            entry['operation'] as String,
            payload,
          );
          entry['payload'] = payload;
          entry['state'] = result['status'] == 'pending_verification'
              ? 'pending_verification'
              : 'accepted';
          entry['reason'] = result['reason'] ?? 'Server accepted';
          entry['serverId'] = result['id'];
          entry.remove('photo');
          receipts.add(scope);
        } catch (e) {
          final code = e is ApiFailure
              ? e.code
              : e is DioException && e.response?.data is Map
              ? '${(e.response!.data as Map)['code']}'
              : 'OFFLINE';
          final terminal = [
            'FORBIDDEN',
            'UNAUTHENTICATED',
            'BAD_INPUT',
            'CONFLICT',
            'PHOTO_REQUIRED',
            'OFFSITE_REASON_REQUIRED',
            'FILE_NOT_READY',
            'INSUFFICIENT_BALANCE',
            'NOT_FOUND',
          ].contains(code);
          entry['state'] = terminal ? 'rejected' : 'pending_sync';
          entry['reason'] = e.toString();
          entry['attempts'] = (entry['attempts'] as int) + 1;
          final seconds = (5 * (1 << ((entry['attempts'] as int).clamp(0, 8))))
              .clamp(5, 900);
          entry['nextAttemptAt'] = DateTime.now()
              .add(Duration(seconds: seconds))
              .toUtc()
              .toIso8601String();
          if (code == 'FORBIDDEN' || code == 'UNAUTHENTICATED') {
            await stopTracking();
          }
        }
        await vault!.write(entry['id'] as String, entry);
      }
    } catch (e) {
      notice = 'Pending sync: ${e.toString()}';
    } finally {
      syncing = false;
      if (vault != null) queue = await vault!.entries();
      notifyListeners();
    }
  }

  Future<bool> ensureLocationAccess() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever;
    } catch (_) {
      return false;
    }
  }

  Future<Json?> position({bool permissionReady = false}) async {
    if (!permissionReady && !await ensureLocationAccess()) return null;
    final rules = context?['policy']?['rules'] as Map?;
    if (attendanceFixFresh(lastLocation, rules)) {
      return Map<String, dynamic>.from(lastLocation!);
    }
    try {
      final cached = await Geolocator.getLastKnownPosition();
      if (cached != null && attendanceFixFresh(locationJson(cached), rules)) {
        return locationJson(cached);
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return locationJson(p);
    } catch (_) {
      // Missing GPS remains unverified evidence; it is never accepted as inside.
      return null;
    }
  }

  Json locationJson(Position p) => {
    'latitude': p.latitude,
    'longitude': p.longitude,
    'accuracyM': p.accuracy,
    'observedAt': p.timestamp.toUtc().toIso8601String(),
    'mocked': p.isMocked,
  };
  Future<void> startTracking(
    SiteScope scope,
    String duty,
    int lastSequence,
  ) async {
    await dutyTracker.bind(scope);
    await dutyTracker.enable();
  }

  bool get withinDutyWindow => dutyTracker.authorized;

  Json? get localOpenDuty {
    final sessions = (context?['sessions'] ?? []) as List;
    Json? open;
    for (final s in sessions) {
      if (s['status'] == 'open') {
        open = Json.from(s as Map);
        break;
      }
    }
    for (final row in queue.where(
      (e) =>
          e['siteId'] == context?['siteId'] &&
          e['operation'] == 'event' &&
          ['saved_locally', 'pending_sync'].contains(e['state']),
    )) {
      final p = row['payload'] as Map;
      if (p['kind'] == 'IN') {
        open = {
          'id': p['dutyId'],
          'employee_id': context?['me'],
          'status': 'open',
          'last_sequence': p['sequence'],
          'opened_at': p['capturedAt'],
          'policy_version': p['policyVersion'],
          'geofence_version': p['geofenceVersion'],
        };
      }
      if (open?['id'] == p['dutyId']) {
        open!['last_sequence'] = p['sequence'];
        // A queued OUT has not closed the server duty. Keep it visible until receipt/refresh.
      }
    }
    return open;
  }

  Json eventPayload(String kind, {Json? location, String? visitId}) {
    final c = context!;
    final open = (c['sessions'] as List)
        .where((s) => s['id'] == dutyId)
        .firstOrNull;
    return {
      'clientEventId': uuid.v4(),
      'dutyId': dutyId,
      'sequence': ++sequence,
      'kind': kind,
      'capturedAt': DateTime.now().toUtc().toIso8601String(),
      'payloadVersion': 1,
      'policyVersion': open?['policy_version'] ?? c['policy']['version'],
      'geofenceVersion': open?['geofence_version'] ?? c['geofence']['version'],
      'location': ?location,
      'visitId': ?visitId,
    };
  }

  Future<void> stopTracking() => dutyTracker.stop();

  Future<void> clear() async {
    await dutyTracker.bind(null);
    syncTimer?.cancel();
    syncTimer = null;
    await vault?.destroy();
    vault = null;
    context = null;
    queue = [];
    dutyId = null;
    dutyScope = null;
    await api.storage.delete(key: 'offline_identity');
    notifyListeners();
  }
}
