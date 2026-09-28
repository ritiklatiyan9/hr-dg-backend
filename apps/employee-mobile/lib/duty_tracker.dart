import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'tracking_store.dart';
import 'package:battery_plus/battery_plus.dart';
import 'duty_sampling.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;
import 'package:uuid/uuid.dart';
import 'api.dart';
import 'scope.dart';
import 'graphql/operations.graphql.dart';

typedef TrackingJson = Map<String, dynamic>;

/// A device-bound offline grant caps capture at the downloaded HR duty end.
/// Monotonic timers prevent an active session's clock changes extending capture. No location is captured until the disclosure and
/// OS permissions have been accepted; ordinary later shifts start automatically.
class DutyTracker extends ChangeNotifier with WidgetsBindingObserver {
  DutyTracker(
    this.api, {
    this.locationAvailable,
    this.positionStream,
    this.batteryLevel,
    this.openStore,
  }) {
    WidgetsBinding.instance.addObserver(this);
  }
  final HrApi api;
  final Future<TrackingStore> Function(SiteScope)? openStore;
  TrackingStore? queue;
  TrackingJson? offlineGrant, cachedContext;
  bool offline = false, syncingQueue = false;
  int queuedCount = 0, rejectedCount = 0, syncFailures = 0;
  Duration nextSync = Duration.zero;
  DateTime? lastUploaded;

  /// Monotonic time of the last accepted upload or heartbeat (HR "last seen").
  Duration? lastContact;
  bool heartbeating = false;
  int pollSeconds = 30;
  String? savedContextKey;
  Future<TrackingStore> _openStore(SiteScope s) =>
      openStore?.call(s) ?? TrackingStore.open(s.organizationId, s.actorId);
  Future<void> updateQueueCounts() async {
    final store = queue;
    if (store == null) return;
    final counts = await store.counts();
    if (store != queue) return;
    queuedCount = counts.pending;
    rejectedCount = counts.rejected;
    notifyListeners();
  }

  final Future<int> Function()? batteryLevel;
  final Stopwatch samplingClock = Stopwatch()..start();
  DutySampling? sampler;
  DateTime? serverAnchor;
  Duration serverAnchorElapsed = Duration.zero;
  Duration? lastBatteryRead, lastNativeChange;
  int? nativeSeconds;
  bool adjusting = false, starting = false;
  int streamGeneration = 0;
  String get samplingStatus => sampler == null
      ? ''
      : '${sampler!.label} · up to ${sampler!.intervalSeconds}s between uploads';
  final Future<bool> Function()? locationAvailable;
  final Stream<Position> Function(LocationSettings)? positionStream;
  SiteScope? scope;
  TrackingJson? authorization;
  Timer? poller, expiry;
  StreamSubscription<Position>? positions;
  final Stopwatch leaseClock = Stopwatch();
  Duration leaseDuration = Duration.zero;
  bool refreshing = false, sending = false, tracking = false, foreground = true;
  bool enabledOnDevice = false;
  int generation = 0;
  String status = 'Duty location is not configured';

  /// Duty time is running but device location or its permission is off.
  bool needsLocation = false;
  DateTime? lastSample;
  TrackingJson? lastLocation;
  String? activeWindow;
  bool get authorized =>
      authorization?['window'] != null &&
      leaseClock.isRunning &&
      leaseClock.elapsed < leaseDuration &&
      serverAnchor != null &&
      !serverAnchor!
          .add(samplingClock.elapsed - serverAnchorElapsed)
          .isBefore(
            DateTime.parse(authorization!['window']['starts_at'] as String),
          );
  String get disclosure => authorization?['policy']?['notice'] as String? ?? '';
  String get consentKey =>
      'duty_tracking:${scope?.organizationId}:${scope?.actorId}:${scope?.siteId}';

  Future<void> bind(SiteScope? next) async {
    if (scope == next) return;
    final ticket = ++generation;
    poller?.cancel();
    await stop();
    if (ticket != generation) return;
    final previousStore = queue;
    queue = null;
    await previousStore?.close();
    if (ticket != generation) return;
    scope = next;
    offlineGrant = null;
    cachedContext = null;
    queuedCount = 0;
    rejectedCount = 0;
    lastUploaded = null;
    lastContact = null;
    savedContextKey = null;
    authorization = null;
    enabledOnDevice = false;
    lastLocation = null;
    lastSample = null;
    sampler = null;
    activeWindow = null;
    lastBatteryRead = null;
    status = 'Checking HR duty schedule';
    notifyListeners();
    if (next == null) return;
    final saved = await api.storage.read(key: 'tracking_identity');
    if (ticket != generation) return;
    if (saved != null) {
      final identity = jsonDecode(saved) as Map;
      if (identity['organizationId'] == next.organizationId &&
          identity['actorId'] == next.actorId) {
        final restored = await _openStore(next);
        if (ticket != generation) {
          await restored.close();
          return;
        }
        queue = restored;
        cachedContext = await restored.context(next);
        await updateQueueCounts();
      }
    }
    if (ticket != generation) return;
    schedulePoll(30);
    await refresh();
  }

  /// One periodic schedule check; its period follows HR's stale threshold.
  void schedulePoll(int seconds) {
    if (poller?.isActive == true && seconds == pollSeconds) return;
    poller?.cancel();
    pollSeconds = seconds;
    poller = Timer.periodic(Duration(seconds: seconds), (_) => refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (foreground) unawaited(refresh());
  }

  Future<void> refresh() async {
    final capturedScope = scope;
    if (capturedScope == null || refreshing) return;
    refreshing = true;
    final ticket = generation;
    final requestClock = Stopwatch()..start();
    try {
      final result = await api.scopedRead(
        capturedScope,
        documentNodeQueryTrackingContext,
      );
      if (ticket != generation) return;
      final data = TrackingJson.from(result['trackingContext'] as Map);
      data['window'] ??= data['upcomingWindow'];
      if (offline) nextSync = Duration.zero;
      offline = false;
      await applyAuthorization(
        data,
        ticket,
        capturedScope,
        requestClock.elapsed,
        online: true,
      );
    } catch (e) {
      if (ticket != generation) return;
      final denied =
          e is ApiFailure &&
          [
            'FORBIDDEN',
            'UNAUTHENTICATED',
            'SCOPE_CHANGED',
            'NOT_FOUND',
            'CONFLICT',
          ].contains(e.code);
      if (denied) {
        await stop();
        authorization = null;
        offlineGrant = null;
        cachedContext = null;
        savedContextKey = null;
        if (queue != null) await queue!.saveContext(capturedScope, {});
      } else {
        offline = true;
        if (!authorized &&
            cachedContext?['authorization'] != null &&
            cachedContext?['grant'] != null) {
          final savedAt = DateTime.parse(cachedContext!['savedAt'] as String);
          final elapsed = DateTime.now().difference(savedAt);
          final cached = TrackingJson.from(
            cachedContext!['authorization'] as Map,
          );
          // A backward clock or a different permission version requires online revalidation.
          if (elapsed >= Duration.zero &&
              cachedContext!['permissionVersion'] ==
                  capturedScope.permissionVersion) {
            cached['serverTime'] = DateTime.parse(
              cached['serverTime'] as String,
            ).add(elapsed).toIso8601String();
            offlineGrant = TrackingJson.from(cachedContext!['grant'] as Map);
            await applyAuthorization(
              cached,
              ticket,
              capturedScope,
              Duration.zero,
              online: false,
            );
          }
        }
      }
      if (authorized && !tracking && foreground && !denied) {
        await start(ticket, capturedScope);
      }
      if (!authorized) await stop();
      status = tracking && offlineGrant != null
          ? 'Offline · recording securely until the downloaded duty window ends'
          : 'Duty location unavailable. Reconnect to download the HR duty window.';
    } finally {
      refreshing = false;
      if (ticket == generation) {
        // Heartbeat after the drain, in the same radio wake-up as the poll.
        unawaited(syncQueue().whenComplete(heartbeat));
        notifyListeners();
      }
    }
  }

  Future<void> applyAuthorization(
    TrackingJson data,
    int ticket,
    SiteScope capturedScope,
    Duration requestElapsed, {
    required bool online,
  }) async {
    final policy = data['policy'] as Map?;
    final window = data['window'] as Map?;
    final consent = await api.storage.read(key: consentKey);
    if (ticket != generation) return;
    enabledOnDevice = consent != null && consent == policy?['notice'];
    authorization = data;
    serverAnchor = DateTime.parse(
      data['serverTime'] as String,
    ).add(requestElapsed);
    serverAnchorElapsed = samplingClock.elapsed;
    expiry?.cancel();
    leaseClock.stop();
    leaseClock.reset();
    if (window == null || policy?['enabled'] != true || !enabledOnDevice) {
      await stop();
      offlineGrant = null;
      cachedContext = null;
      schedulePoll(30);
      if (queue != null && savedContextKey != '') {
        savedContextKey = '';
        await queue!.saveContext(capturedScope, {});
      }
      status = policy?['enabled'] != true
          ? 'Duty location is disabled by HR'
          : !enabledOnDevice
          ? 'Enable automatic duty location on this device'
          : data['configured'] != true
          ? 'Attendance policy and geofence are required'
          : 'Waiting for an HR-authorized duty window';
      notifyListeners();
      return;
    }
    final identity =
        '${window['id']}:${window['version']}:${policy?['version']}:${data['locationRules']}';
    if (activeWindow != identity) {
      if (activeWindow != null && online) offlineGrant = null;
      await stop(cancelLease: false);
      activeWindow = identity;
      final rules = data['locationRules'] as Map?;
      sampler = DutySampling(
        baseSeconds: (policy!['sample_seconds'] as num).toInt(),
        staleSeconds: (policy['stale_seconds'] as num?)?.toInt() ?? 120,
        maxAccuracyM: (rules?['maxAccuracyM'] as num?)?.toDouble() ?? 50,
        freshnessSeconds: (rules?['freshnessSeconds'] as num?)?.toInt() ?? 60,
      );
      lastLocation = null;
      lastSample = null;
      schedulePoll(sampler!.pollSeconds);
    }
    if (offlineGrant?['roster_id'] != window['id'] ||
        offlineGrant?['roster_version'] != window['version'] ||
        offlineGrant?['policy_version'] != policy?['version'] ||
        DateTime.tryParse(
              '${offlineGrant?['ends_at']}',
            )?.isAfter(serverAnchor!) !=
            true) {
      offlineGrant = null;
    }
    if (online && offlineGrant == null) {
      final permit = await api.scopedWrite(
        capturedScope,
        documentNodeMutationTrackingCommand,
        {
          'operation': 'offlinePermit',
          'input': {
            'rosterId': window['id'],
            'rosterVersion': window['version'],
            'policyVersion': policy!['version'],
          },
        },
      );
      if (ticket != generation) return;
      final grant = permit['trackingCommand'];
      if (grant is Map && grant['id'] != null) {
        offlineGrant = TrackingJson.from(grant);
      }
    }
    if (offlineGrant != null && online) {
      if (queue == null) {
        final opened = await _openStore(capturedScope);
        if (ticket != generation) {
          await opened.close();
          return;
        }
        queue = opened;
        await api.storage.write(
          key: 'tracking_identity',
          value: jsonEncode({
            'organizationId': capturedScope.organizationId,
            'actorId': capturedScope.actorId,
          }),
        );
      }
      // Only a changed window, grant or permission scope is re-encrypted to
      // disk; savedAt and serverTime stay a consistent pair for offline restore.
      final contextKey =
          '$activeWindow:${offlineGrant!['id']}:${capturedScope.permissionVersion}';
      if (contextKey != savedContextKey) {
        cachedContext = {
          'authorization': data,
          'grant': offlineGrant,
          'savedAt': DateTime.now().toUtc().toIso8601String(),
          'permissionVersion': capturedScope.permissionVersion,
        };
        await queue!.saveContext(capturedScope, cachedContext!);
        if (ticket != generation) return;
        savedContextKey = contextKey;
      }
    }
    if (ticket != generation) return;
    final end = offlineGrant?['ends_at'] ?? data['leaseUntil'];
    leaseDuration =
        DateTime.parse(end as String).difference(serverAnchor!) -
        (samplingClock.elapsed - serverAnchorElapsed);
    if (leaseDuration <= Duration.zero || (!online && offlineGrant == null)) {
      await stop();
      return;
    }
    leaseClock.start();
    expiry = Timer(leaseDuration, () async {
      await stop();
      status = 'Downloaded duty window ended';
      notifyListeners();
    });
    if (sampler != null &&
        (lastBatteryRead == null ||
            samplingClock.elapsed - lastBatteryRead! >=
                const Duration(minutes: 5))) {
      lastBatteryRead = samplingClock.elapsed;
      try {
        final level = await (batteryLevel?.call() ?? Battery().batteryLevel)
            .timeout(const Duration(seconds: 2));
        if (ticket != generation) return;
        // Hysteresis avoids flapping around 20%.
        if (level >= 0 && level <= 20) sampler?.lowBattery = true;
        if (level >= 25) sampler?.lowBattery = false;
      } catch (_) {
        /* Unsupported battery API keeps the normal cadence. */
      }
    }
    if (!authorized) status = 'Waiting for the downloaded HR shift to start';
    if (!tracking && foreground && authorized) {
      await start(ticket, capturedScope);
    }
    if (tracking) await adjustCadence(ticket, capturedScope);
    if (!tracking && !foreground) {
      status = 'Open the app to start this duty window';
    }
  }

  Future<void> enable() async {
    final ticket = generation;
    if (scope == null || disclosure.isEmpty) {
      throw StateError('HR must configure duty location first');
    }
    final key = consentKey, notice = disclosure;
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      throw StateError('Turn on device location, then enable again');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Allow precise location in device settings');
    }
    if (Platform.isAndroid &&
        !await permissions.Permission.notification.request().isGranted) {
      throw StateError('Allow the visible duty location notification');
    }
    if (ticket != generation) return;
    await api.storage.write(key: key, value: notice);
    if (ticket != generation) return;
    enabledOnDevice = true;
    await refresh();
  }

  Future<void> disable() async {
    final key = consentKey;
    generation++;
    await stop();
    enabledOnDevice = false;
    await api.storage.delete(key: key);
    status = 'Automatic duty location disabled on this device';
    notifyListeners();
  }

  /// Opens the one setting that blocks sharing; resuming the app rechecks.
  Future<void> fixLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
    } else if (await Geolocator.requestPermission() ==
        LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
    await refresh();
  }

  Future<bool> _locationAvailable() async {
    final permission = await Geolocator.checkPermission();
    return await Geolocator.isLocationServiceEnabled() &&
        [
          LocationPermission.always,
          LocationPermission.whileInUse,
        ].contains(permission);
  }

  Future<void> start(int ticket, SiteScope capturedScope) async {
    if (!authorized || !enabledOnDevice || starting || tracking) return;
    starting = true;
    final startTicket = streamGeneration;
    try {
      final available = locationAvailable != null
          ? await locationAvailable!()
          : await _locationAvailable();
      if (ticket != generation ||
          startTicket != streamGeneration ||
          !authorized ||
          !foreground) {
        return;
      }
      needsLocation = !available;
      if (!available) {
        status = 'Duty time has started. Turn on location to share it with HR';
        return;
      }
      final seconds = sampler!.intervalSeconds;
      nativeSeconds = seconds;
      lastNativeChange = samplingClock.elapsed;
      final streamTicket = ++streamGeneration;
      final LocationSettings settings = Platform.isAndroid
          ? AndroidSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
              intervalDuration: Duration(seconds: seconds),
              foregroundNotificationConfig: const ForegroundNotificationConfig(
                notificationTitle: 'Defence Garden duty location',
                notificationText:
                    'Sharing location during your HR-assigned duty. Open the app for controls.',
                enableWakeLock: true,
              ),
            )
          : AppleSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
              showBackgroundLocationIndicator: true,
              pauseLocationUpdatesAutomatically: false,
              allowBackgroundLocationUpdates: true,
            );
      tracking = true;
      status = 'Automatic duty location active';
      positions =
          (positionStream?.call(settings) ??
                  Geolocator.getPositionStream(locationSettings: settings))
              .listen(
                (p) {
                  if (streamTicket == streamGeneration) {
                    unawaited(send(p, ticket, capturedScope));
                  }
                },
                onError: (Object e) async {
                  if (ticket != generation ||
                      streamTicket != streamGeneration) {
                    return;
                  }
                  await stop(cancelLease: false);
                  // Reported to HR as "location off" until sharing restarts.
                  needsLocation = true;
                  status =
                      'GPS unavailable. No route is inferred; retrying while the app is open.';
                  notifyListeners();
                },
              );
      notifyListeners();
    } finally {
      starting = false;
    }
  }

  Future<void> send(Position p, int ticket, SiteScope capturedScope) async {
    if (ticket != generation || !tracking || !authorized || sending) return;
    final cadence = sampler;
    if (cadence == null || serverAnchor == null) return;
    final elapsed = samplingClock.elapsed;
    final captureStart = DateTime.parse(
      (offlineGrant?['starts_at'] ?? authorization!['window']['starts_at'])
          as String,
    );
    final captureEnd = DateTime.parse(
      (offlineGrant?['ends_at'] ?? authorization!['window']['ends_at'])
          as String,
    );
    if (p.timestamp.isBefore(captureStart) ||
        !p.timestamp.isBefore(captureEnd)) {
      return;
    }
    final valid = cadence.observe(
      p,
      elapsed,
      serverAnchor!.add(elapsed - serverAnchorElapsed),
    );
    if (!valid) {
      if (cadence.rejectedReason != null && status != cadence.rejectedReason) {
        status = cadence.rejectedReason!;
        notifyListeners();
      }
      return;
    }
    unawaited(adjustCadence(ticket, capturedScope));
    if (!cadence.due(elapsed)) return;
    // Captured immutable authorization prevents a response being assigned to a
    // different site, shift or policy after any await.
    final window = Map<String, dynamic>.from(authorization!['window'] as Map);
    final policyVersion = authorization!['policy']['version'];
    final windowKey = activeWindow;
    sending = true;
    cadence.attempted(elapsed);
    final payload = {
      'clientId': const Uuid().v4(),
      'rosterId': window['id'],
      'rosterVersion': window['version'],
      'policyVersion': policyVersion,
      'latitude': p.latitude,
      'longitude': p.longitude,
      'accuracyM': p.accuracy,
      'observedAt': p.timestamp.toUtc().toIso8601String(),
      'mocked': p.isMocked,
    };
    try {
      if (offlineGrant != null && queue != null) {
        final store = queue!;
        await store.enqueue(capturedScope, {
          'sample': payload,
          'grantId': offlineGrant!['id'],
          'organizationId': capturedScope.organizationId,
          'actorId': capturedScope.actorId,
          'siteId': capturedScope.siteId,
          'permissionVersion': capturedScope.permissionVersion,
        });
        if (ticket != generation ||
            windowKey != activeWindow ||
            store != queue) {
          return;
        }
        lastSample = p.timestamp;
        lastLocation = {
          'latitude': p.latitude,
          'longitude': p.longitude,
          'accuracyM': p.accuracy,
          'observedAt': p.timestamp.toUtc().toIso8601String(),
        };
        status = offline
            ? 'Offline · location saved securely on this device'
            : 'Duty location saved · synchronizing';
        await updateQueueCounts();
        unawaited(syncQueue());
        return;
      }
      await api.scopedWrite(
        capturedScope,
        documentNodeMutationTrackingCommand,
        {'operation': 'sample', 'input': payload},
      );
      if (ticket != generation || windowKey != activeWindow || !authorized) {
        return;
      }
      cadence.delivered();
      lastContact = samplingClock.elapsed;
      lastSample = p.timestamp;
      lastLocation = {
        'latitude': p.latitude,
        'longitude': p.longitude,
        'accuracyM': p.accuracy,
        'observedAt': p.timestamp.toUtc().toIso8601String(),
      };
      status = 'Automatic duty location active';
    } catch (e) {
      if (ticket != generation || windowKey != activeWindow) return;
      cadence.failed();
      if (e is StateError) {
        await stop();
        status = e.message.toString();
        return;
      }
      if (e is ApiFailure &&
          [
            'FORBIDDEN',
            'UNAUTHENTICATED',
            'SCOPE_CHANGED',
            'CONFLICT',
          ].contains(e.code)) {
        await stop();
        status = 'Sharing stopped. Refreshing duty authorization.';
      } else {
        status = 'Sample not received. HR will see the last received location.';
      }
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  Future<void> syncQueue({bool force = false}) async {
    final store = queue, current = scope;
    if (store == null ||
        current == null ||
        syncingQueue ||
        (!force && samplingClock.elapsed < nextSync)) {
      return;
    }
    syncingQueue = true;
    final ticket = generation;
    try {
      // Bound each drain to 500 samples so GPS and ordinary HR requests stay responsive.
      for (var page = 0; page < 5; page++) {
        if (ticket != generation || store != queue) return;
        final pending = await store.pending();
        if (pending.isEmpty) break;
        final first = pending.first;
        if (first['organizationId'] != current.organizationId ||
            first['actorId'] != current.actorId) {
          throw StateError('Offline queue identity mismatch');
        }
        final batch = pending
            .where(
              (e) =>
                  e['grantId'] == first['grantId'] &&
                  e['siteId'] == first['siteId'],
            )
            .toList();
        final original = SiteScope(
          current.organizationId,
          current.actorId,
          current.permissionVersion,
          first['siteId'] as String,
        );
        Map<String, dynamic> response;
        try {
          response = await api.scopedWrite(
            original,
            documentNodeMutationTrackingCommand,
            {
              'operation': 'batch',
              'input': {
                'grantId': first['grantId'],
                'samples': batch.map((e) => e['sample']).toList(),
              },
            },
          );
        } on ApiFailure catch (e) {
          if (!['FORBIDDEN', 'NOT_FOUND', 'BAD_INPUT'].contains(e.code)) {
            rethrow;
          }
          response = {
            'trackingCommand': {
              'results': batch
                  .map(
                    (row) => {
                      'clientId': row['sample']['clientId'],
                      'status': 'rejected',
                      'reason': e.code,
                    },
                  )
                  .toList(),
            },
          };
        }
        if (ticket != generation || store != queue) return;
        final results = (response['trackingCommand']['results'] as List)
            .map((e) => TrackingJson.from(e as Map))
            .toList();
        final expected = batch.map((e) => e['sample']['clientId']).toSet();
        if (results.length != expected.length ||
            results.map((e) => e['clientId']).toSet().length !=
                expected.length ||
            results.any(
              (e) =>
                  !expected.contains(e['clientId']) ||
                  !['accepted', 'rejected'].contains(e['status']),
            )) {
          throw StateError('Upload acknowledgement was incomplete');
        }
        await store.acknowledge(results);
        final accepted = results
            .where((e) => e['status'] == 'accepted')
            .map((e) => e['clientId'])
            .toSet();
        if (accepted.isNotEmpty && original.siteId == current.siteId) {
          lastUploaded = DateTime.now();
          lastContact = samplingClock.elapsed;
          status = tracking
              ? 'Automatic duty location active · uploads received'
              : 'Duty locations synchronized';
        }
        if (results.any(
              (e) => [
                'AUTHORIZATION_CHANGED',
                'FORBIDDEN',
                'NOT_FOUND',
              ].contains(e['reason']),
            ) &&
            offlineGrant?['id'] == first['grantId']) {
          offlineGrant = null;
          cachedContext = null;
          savedContextKey = null;
          await store.saveContext(current, {});
          await stop();
          status =
              'HR duty authorization changed. Some saved readings were rejected.';
        }
        syncFailures = 0;
        nextSync = Duration.zero;
      }
    } catch (e) {
      if (ticket != generation) return;
      syncFailures = math.min(syncFailures + 1, 5);
      nextSync =
          samplingClock.elapsed +
          Duration(
            seconds:
                math.min(300, 5 * (1 << syncFailures)) +
                math.Random().nextInt(5),
          );
      status = 'Locations saved securely · upload will retry when connected';
    } finally {
      syncingQueue = false;
      if (ticket == generation && store == queue) {
        await updateQueueCounts();
        notifyListeners();
      }
    }
  }

  /// Tells HR the phone is connected when no accepted upload happened recently:
  /// a still phone receives no GPS fixes, which is not a lost signal. Sent only
  /// while sharing (or blocked by device location) under a downloaded grant.
  Future<void> heartbeat() async {
    final current = scope, grant = offlineGrant, cadence = sampler;
    if (current == null ||
        grant == null ||
        cadence == null ||
        offline ||
        heartbeating ||
        !authorized ||
        !(tracking || needsLocation)) {
      return;
    }
    final since = lastContact;
    if (since != null &&
        samplingClock.elapsed - since <
            Duration(seconds: cadence.contactSeconds)) {
      return;
    }
    heartbeating = true;
    final ticket = generation;
    try {
      final result = await api.scopedWrite(
        current,
        documentNodeMutationTrackingCommand,
        {
          'operation': 'heartbeat',
          'input': {
            'grantId': grant['id'],
            'state': tracking ? 'tracking' : 'location_off',
          },
        },
      );
      final reply = result['trackingCommand'];
      if (ticket == generation &&
          reply is Map &&
          reply['status'] == 'accepted') {
        lastContact = samplingClock.elapsed;
      }
    } catch (_) {
      /* The next poll retries; HR keeps the last contact time. */
    } finally {
      heartbeating = false;
    }
  }

  /// Android interval changes require resubscribing. Only do that while the
  /// activity is visible: background foreground-service restarts can be denied.
  /// iOS has no interval control; it still benefits from adaptive radio uploads.
  Future<void> adjustCadence(int ticket, SiteScope capturedScope) async {
    if (!Platform.isAndroid ||
        adjusting ||
        !foreground ||
        !tracking ||
        !authorized ||
        sampler == null ||
        nativeSeconds == sampler!.intervalSeconds ||
        (lastNativeChange != null &&
            samplingClock.elapsed - lastNativeChange! <
                const Duration(seconds: 60))) {
      return;
    }
    adjusting = true;
    final window = activeWindow;
    try {
      await stop(cancelLease: false);
      if (ticket == generation &&
          window == activeWindow &&
          foreground &&
          authorized &&
          enabledOnDevice) {
        await start(ticket, capturedScope);
      }
    } finally {
      adjusting = false;
    }
  }

  Future<void> stop({bool cancelLease = true}) async {
    streamGeneration++;
    tracking = false;
    needsLocation = false;
    final subscription = positions;
    positions = null;
    if (cancelLease) {
      expiry?.cancel();
      leaseClock.stop();
      leaseClock.reset();
    }
    await subscription?.cancel();
    notifyListeners();
  }

  Future<void> close() async {
    generation++;
    scope = null;
    poller?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    await stop();
    final store = queue;
    queue = null;
    await store?.close();
  }
}
