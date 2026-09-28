import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api.dart';
import 'mobile_ui.dart';
import 'providers.dart';
import 'scope.dart';

/// Selected site plus an epoch that increments on every scope change so the
/// shell can lazily reset branch navigation stacks that were built for an
/// earlier site.
@immutable
class WorkspaceSelection {
  const WorkspaceSelection({this.siteId, this.epoch = 0});
  final String? siteId;
  final int epoch;
}

class WorkspaceController extends Notifier<WorkspaceSelection> {
  @override
  WorkspaceSelection build() => const WorkspaceSelection();

  /// Selects a site. Callers must have already handled unsaved work, cancelled
  /// reads and stopped tracking through [WorkspaceActions.changeSite].
  void select(String? siteId, {required String actorId}) {
    state = WorkspaceSelection(siteId: siteId, epoch: state.epoch + 1);
    if (siteId != null) writePreference('last_site:$actorId', siteId);
  }

  void reset() => state = WorkspaceSelection(epoch: state.epoch + 1);
}

final workspaceProvider =
    NotifierProvider<WorkspaceController, WorkspaceSelection>(
      WorkspaceController.new,
    );

/// The immutable access key for the selected site, or null when no permitted
/// site is selected. Includes the permission version, so a permission change
/// yields a new key and every scoped provider reloads.
final currentScopeProvider = Provider.autoDispose<SiteScope?>((ref) {
  final b = ref.watch(bootstrapProvider).value?.bootstrap;
  final selected = ref.watch(workspaceProvider).siteId;
  if (b == null || selected == null) return null;
  if (!b.sites.any((s) => s.id == selected)) return null;
  return SiteScope(
    b.organization.id,
    b.actor.id,
    b.actor.permissionVersion,
    selected,
  );
});

/// Registry of pages with unsaved changes. Forms mark themselves so tab
/// re-selection, site switches and sign-out can ask before discarding work.
class UnsavedWork extends ChangeNotifier {
  final _labels = <String, String>{};
  bool get any => _labels.isNotEmpty;
  String? get label => _labels.values.firstOrNull;
  void mark(String key, String label, bool dirty) {
    final changed = dirty ? _labels[key] != label : _labels.containsKey(key);
    if (dirty) {
      _labels[key] = label;
    } else {
      _labels.remove(key);
    }
    if (changed) notifyListeners();
  }
}

final unsavedWorkProvider = Provider<UnsavedWork>((ref) => UnsavedWork());

/// Employee-facing explanation of failures. Never surfaces raw exception
/// strings for known transport and authorization codes.
String friendlyError(Object error) {
  if (error is ApiFailure) {
    switch (error.code) {
      case 'OFFLINE':
      case 'NETWORK_ERROR':
        return tr(
          'You are offline. Check your connection and try again.',
          'आप ऑफ़लाइन हैं। कनेक्शन जाँचकर फिर कोशिश करें।',
        );
      case 'FORBIDDEN':
        return tr(
          'You do not have access to this at the selected site.',
          'चयनित साइट पर आपको इसकी अनुमति नहीं है।',
        );
      case 'SCOPE_CHANGED':
        return tr(
          'Your workspace changed. Reload to continue.',
          'आपका कार्यक्षेत्र बदल गया। जारी रखने के लिए फिर लोड करें।',
        );
      case 'UNAUTHENTICATED':
      case 'MFA_REQUIRED':
        return tr('Please sign in again.', 'कृपया फिर से साइन इन करें।');
      case 'CONFLICT':
        return tr(
          'This record changed on the server. Reload before trying again.',
          'यह रिकॉर्ड सर्वर पर बदल गया। फिर कोशिश करने से पहले लोड करें।',
        );
      case 'CONFIGURATION_REQUIRED':
        return tr(
          'HR must finish configuring this site first.',
          'पहले एचआर को इस साइट की सेटिंग पूरी करनी होगी।',
        );
      case 'UNCONFIRMED':
        return tr(
          'The save could not be confirmed. Reload before retrying.',
          'सहेजने की पुष्टि नहीं हो सकी। फिर कोशिश करने से पहले लोड करें।',
        );
    }
    return error.message;
  }
  final text = error.toString();
  const prefixes = [
    'Exception: ',
    'Bad state: ',
    'StateError: ',
    'Invalid argument(s): ',
  ];
  for (final p in prefixes) {
    if (text.startsWith(p)) return text.substring(p.length);
  }
  return text;
}

/// Actions that change the authenticated workspace. Each one cancels reads,
/// discards stale values and reloads capabilities for the new scope.
class WorkspaceActions {
  WorkspaceActions(this.ref);
  final Ref ref;

  /// Restores the last used site for this actor, or auto-selects a single site.
  Future<void> restoreSelection(String actorId, List<String> siteIds) async {
    if (ref.read(workspaceProvider).siteId != null) return;
    String? pick;
    if (siteIds.length == 1) {
      pick = siteIds.single;
    } else {
      final saved = await readPreference('last_site:$actorId');
      if (saved != null && siteIds.contains(saved)) pick = saved;
    }
    if (pick != null && ref.read(workspaceProvider).siteId == null) {
      ref.read(workspaceProvider.notifier).select(pick, actorId: actorId);
    }
  }

  /// Drops every scoped value. Called before a site switch, on permission
  /// changes and on sign-out.
  Future<void> clearScoped() async {
    await ref.read(apiProvider).switchSite();
    ref.invalidate(profileProvider);
    ref.invalidate(capabilityProvider);
    ref.invalidate(requestsProvider);
  }

  Future<void> selectSite(String? siteId, {required String actorId}) async {
    await clearScoped();
    ref.read(workspaceProvider.notifier).select(siteId, actorId: actorId);
  }
}

final workspaceActionsProvider = Provider<WorkspaceActions>(
  (ref) => WorkspaceActions(ref),
);
