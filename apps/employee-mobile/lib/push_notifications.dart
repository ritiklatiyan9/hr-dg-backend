import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api.dart';
import 'scope.dart';

/// App-wide push transport. The server inbox remains the source of truth:
/// a push carries only ids and a generic title, and every page it opens
/// re-checks authorization on load.
class PushNotifications {
  PushNotifications._();
  static final instance = PushNotifications._();
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static bool get configured =>
      [apiKey, appId, senderId, projectId].every((v) => v.isNotEmpty);

  StreamSubscription<String>? _tokens;
  StreamSubscription<RemoteMessage>? _opened;
  String? _registered;

  /// Called when the user taps a notification (data: siteId, module,
  /// eventType, entityId, inboxId).
  void Function(Map<String, dynamic> data)? onOpen;

  /// Called for a message that arrives while the app is open.
  void Function(String title, String body, Map<String, dynamic> data)?
  onForeground;

  /// Registers this device for the signed-in user. Safe to call on every
  /// site change: an unchanged token is not sent again. Returns a status line.
  Future<String> enable(HrApi api, SiteScope scope) async {
    if (!configured) {
      return 'Push is not configured in this build. Your in-app inbox still works.';
    }
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: senderId,
          projectId: projectId,
        ),
      );
    }
    final messaging = FirebaseMessaging.instance;
    final consent = await messaging.requestPermission();
    if (consent.authorizationStatus == AuthorizationStatus.denied) {
      return 'Notifications are turned off for this app in system settings. Your in-app inbox still works.';
    }
    if (Platform.isIOS && await messaging.getAPNSToken() == null) {
      return 'APNs registration is not ready. Check signed push capabilities, then retry.';
    }
    await messaging.setAutoInitEnabled(true);
    Future<void> register(String token) async {
      final key = '${scope.actorId}|${scope.siteId}|$token';
      if (_registered == key) return;
      await api.post('/notifications/register', {
        'siteId': scope.siteId,
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
      _registered = key;
    }

    final token = await messaging.getToken();
    if (token == null) return 'Push token is unavailable. Retry later.';
    await register(token);
    await _tokens?.cancel();
    _tokens = messaging.onTokenRefresh.listen((token) async {
      try {
        await register(token);
      } catch (_) {
        /* Retried on the next launch or site change; never claimed delivered. */
      }
    });
    if (_opened == null) {
      _opened = FirebaseMessaging.onMessageOpenedApp.listen(
        (m) => onOpen?.call(m.data),
      );
      FirebaseMessaging.onMessage.listen(
        (m) => onForeground?.call(
          m.notification?.title ?? 'Defence Garden HR',
          m.notification?.body ?? '',
          m.data,
        ),
      );
      final initial = await messaging.getInitialMessage();
      if (initial != null) onOpen?.call(initial.data);
    }
    return 'Notifications are on for payroll, tasks, attendance, leave, daily reports and HR updates.';
  }

  /// Sign-out: the next account registers its own device row.
  void forget() => _registered = null;
}
