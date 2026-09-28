import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api.dart';
import 'operation_runtime.dart';
import 'scope.dart';
import 'graphql/operations.graphql.dart';

final apiProvider = Provider<HrApi>((ref) {
  final api = HrApi();
  ref.onDispose(api.dispose);
  return api;
});
final operationRuntimeProvider = Provider<OperationRuntime>((ref) {
  final runtime = OperationRuntime(ref.watch(apiProvider));
  ref.onDispose(() => runtime.close());
  return runtime;
});
final bootstrapProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(apiProvider).bootstrap(),
);
final profileProvider = FutureProvider.autoDispose
    .family<Query$MyProfile, SiteScope>(
      (ref, s) => ref.watch(apiProvider).profile(s),
    );

/// Profile photo keyed by scope, `employee/<id>` or `request/<id>`, and a
/// version (null: no photo, nothing is fetched).
final photoProvider = FutureProvider.autoDispose
    .family<Uint8List?, (SiteScope, String, String?)>(
      (ref, k) async =>
          k.$3 == null ? null : ref.watch(apiProvider).profilePhoto(k.$1, k.$2),
    );
final capabilityProvider = FutureProvider.autoDispose
    .family<Query$SiteScope, SiteScope>(
      (ref, s) => ref.watch(apiProvider).capabilities(s),
    );
final requestsProvider = FutureProvider.autoDispose
    .family<Query$ProfileRequests, SiteScope>(
      (ref, s) => ref.watch(apiProvider).requests(s),
    );

extension Capabilities on Query$SiteScope {
  bool can(String key) => scope.capabilities.contains(key);
}
