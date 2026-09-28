import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:gql/ast.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql/client.dart';
import 'package:uuid/uuid.dart';
import 'graphql/operations.graphql.dart';
import 'graphql/schema.graphql.dart';
import 'scope.dart';
import 'operation_vault.dart';
import 'tracking_store.dart';
import 'dio_graphql_link.dart';

class ApiFailure implements Exception {
  const ApiFailure(this.code, this.message);
  final String code, message;
  @override
  String toString() => message;
}

class HrApi {
  HrApi({String? baseUrl}) {
    final endpoint =
        baseUrl ??
        const String.fromEnvironment(
          'API_URL',
          defaultValue: 'http://10.0.2.2:4000',
        );
    if (const bool.fromEnvironment('dart.vm.product') &&
        !endpoint.startsWith('https://')) {
      throw StateError('Release builds require an HTTPS API_URL');
    }
    dio = Dio(
      BaseOptions(
        baseUrl: endpoint,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'x-client': 'mobile'},
      ),
    );
    // Exactly one GraphQL client. Its normalized cache is disabled for all HR
    // reads and writes; Riverpod owns scope-keyed in-memory values.
    transport = DioGraphqlLink(dio, () => access);
    client = GraphQLClient(
      link: transport,
      // Dio owns bounded connect/receive deadlines and cancellation. graphql 5.2.4
      // keeps listening after its stream timeout and can complete twice on a late
      // transport response. Avoid competing timers; Dio remains bounded.
      queryRequestTimeout: null,
      cache: GraphQLCache(store: InMemoryStore()),
      defaultPolicies: DefaultPolicies(
        query: Policies(fetch: FetchPolicy.noCache),
        mutate: Policies(fetch: FetchPolicy.noCache),
        watchQuery: Policies(fetch: FetchPolicy.noCache),
      ),
    );
  }
  final storage = const FlutterSecureStorage();
  late final Dio dio;
  late final GraphQLClient client;
  late final DioGraphqlLink transport;
  String? access;
  String? refreshToken;
  Future<void>? _refreshing;
  int _authEpoch = 0;
  final scopeEpoch = ScopeEpoch();
  Future<void> Function()? beforeClear;
  final invalidations = StreamController<String>.broadcast();
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(
          headers: {if (access != null) 'authorization': 'Bearer $access'},
        ),
      );
      return response.data!;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ApiFailure(
        data is Map ? '${data['code'] ?? 'REQUEST_FAILED'}' : 'OFFLINE',
        data is Map
            ? '${data['message'] ?? 'Request failed'}'
            : 'Unable to connect. Check your connection and retry.',
      );
    }
  }

  Future<void> _save(Map<String, dynamic> result) async {
    access = result['accessToken'] as String;
    refreshToken = result['refreshToken'] as String?;
    // One secure-storage item avoids mixed token pairs after rotation.
    await storage.write(
      key: 'session',
      value: jsonEncode({'accessToken': access, 'refreshToken': refreshToken}),
    );
  }

  Future<bool> restore() async {
    final saved = await storage.read(key: 'session');
    if (saved == null) return false;
    final values = jsonDecode(saved) as Map<String, dynamic>;
    access = values['accessToken'] as String?;
    refreshToken = values['refreshToken'] as String?;
    try {
      await refresh();
      return true;
    } on ApiFailure catch (e) {
      if (e.code == "OFFLINE") return true;
      await clear();
      return false;
    } catch (_) {
      await clear();
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _authEpoch++;
    // One device ID per account: the server binds an ID to its first account,
    // and duty/tracking sessions stay tied to it when people share a phone.
    final key = 'device_id:${email.trim().toLowerCase()}';
    final device = await storage.read(key: key) ?? const Uuid().v4();
    await storage.write(key: key, value: device);
    final result = await post('/auth/login', {
      'email': email,
      'password': password,
      'kind': 'mobile',
      'deviceId': device,
    });
    await beforeClear?.call();
    await purgeOfflineIdentity();
    await _save(result);
    return result;
  }

  Future<void> refresh() =>
      _refreshing ??= _rotate().whenComplete(() => _refreshing = null);
  Future<void> _rotate() async {
    final epoch = _authEpoch;
    if (refreshToken == null) throw StateError('Sign in again');
    final result = await post('/auth/refresh', {'refreshToken': refreshToken});
    if (epoch != _authEpoch) throw StateError('Session changed');
    await _save(result);
  }

  Future<void> purgeOfflineIdentity() async {
    final tracking = await storage.read(key: 'tracking_identity');
    if (tracking != null) {
      final identity = jsonDecode(tracking) as Map;
      final queue = await TrackingStore.open(
        identity['organizationId'] as String,
        identity['actorId'] as String,
      );
      await queue.destroy();
      await storage.delete(key: 'tracking_identity');
    }
    final saved = await storage.read(key: 'offline_identity');
    if (saved != null) {
      final identity = jsonDecode(saved) as Map;
      final vault = await OperationVault.open(
        identity['organizationId'] as String,
        identity['actorId'] as String,
      );
      await vault.destroy();
      await storage.delete(key: 'offline_identity');
    }
  }

  Future<bool> hasLocalDwrDrafts() async {
    final saved = await storage.read(key: 'offline_identity');
    if (saved == null) return false;
    final identity = jsonDecode(saved) as Map;
    final vault = await OperationVault.open(
      identity['organizationId'],
      identity['actorId'],
    );
    return (await vault.entries(
      includeDwr: true,
    )).any((row) => row['operation'] == 'dwr_draft');
  }

  Future<void> clear() async {
    await beforeClear?.call();
    await purgeOfflineIdentity();
    _authEpoch++;
    scopeEpoch.change();
    transport.cancelReads();
    access = null;
    refreshToken = null;
    await storage.delete(key: 'session');
    client.cache.store.reset();
  }

  Future<void> uploadOperationPhoto(
    SiteScope scope,
    String id,
    List<int> bytes,
  ) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/files/intents/$id/content',
      queryParameters: {'siteId': scope.siteId},
      data: Stream.value(bytes),
      options: Options(
        headers: {
          'authorization': 'Bearer $access',
          'content-type': 'application/octet-stream',
          'content-length': bytes.length,
        },
      ),
    );
    if (response.data?['status'] != 'ready') {
      throw const ApiFailure(
        'FILE_NOT_READY',
        'Evidence is quarantined or rejected',
      );
    }
  }

  Options sensitiveOptions(SiteScope scope) => Options(
    headers: {
      'authorization': 'Bearer $access',
      'x-permission-version': '${scope.permissionVersion}',
    },
  );

  Future<Uint8List> downloadOperationFile(SiteScope scope, String id) async {
    final response = await dio.get<List<int>>(
      '/files/attachments/$id',
      queryParameters: {'siteId': scope.siteId},
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'authorization': 'Bearer $access'},
      ),
    );
    return Uint8List.fromList(response.data!);
  }

  /// Proposes a photo, phone and basic details for HR review. REST: a photo
  /// exceeds the GraphQL body limit.
  Future<Map<String, dynamic>> requestProfileChange(
    SiteScope scope,
    Map<String, dynamic> body,
  ) => post(
    '/profile/requests?siteId=${Uri.encodeComponent(scope.siteId)}',
    body,
  );

  /// A photo at `employee/<id>` (approved) or `request/<id>` (proposed),
  /// or null when none is visible.
  Future<Uint8List?> profilePhoto(SiteScope scope, String path) async {
    final epoch = scopeEpoch.capture();
    try {
      final response = await dio.get<List<int>>(
        '/profile/photos/$path',
        queryParameters: {'siteId': scope.siteId},
        options: sensitiveOptions(
          scope,
        ).copyWith(responseType: ResponseType.bytes),
      );
      if (!scopeEpoch.isCurrent(epoch)) throw StateError('Site changed');
      return Uint8List.fromList(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await post('/auth/logout', {});
    } finally {
      await clear();
    }
  }

  Future<Map<String, dynamic>> _read(QueryOptions options) async {
    var result = await client.query(options);
    if (result.exception?.graphqlErrors.any(
          (e) => e.extensions?['code'] == 'UNAUTHENTICATED',
        ) ??
        false) {
      try {
        await refresh();
      } on ApiFailure catch (e) {
        if (e.code != 'OFFLINE') {
          await clear();
          invalidations.add('UNAUTHENTICATED');
        }
        rethrow;
      }
      result = await client.query(options);
    }
    if (result.hasException) {
      final code =
          result.exception?.graphqlErrors.firstOrNull?.extensions?['code']
              ?.toString() ??
          'OFFLINE';
      // Codes only: no payload, tokens or profile data.
      debugPrint(
        'graphql read failed: $code '
        '${result.exception?.linkException?.runtimeType ?? ''}',
      );
      if (['SCOPE_CHANGED', 'UNAUTHENTICATED', 'MFA_REQUIRED'].contains(code)) {
        await switchSite();
        invalidations.add(code);
      }
      throw ApiFailure(
        code,
        result.exception?.graphqlErrors.firstOrNull?.message ??
            'Unable to connect. Check your connection and retry.',
      );
    }
    return result.data!;
  }

  Future<Query$Bootstrap> bootstrap() async => Query$Bootstrap.fromJson(
    await _read(
      QueryOptions(
        document: documentNodeQueryBootstrap,
        fetchPolicy: FetchPolicy.noCache,
      ),
    ),
  );
  Future<Query$MyProfile> profile(SiteScope scope) async {
    final generation = scopeEpoch.capture();
    final json = await _read(
      QueryOptions(
        document: documentNodeQueryMyProfile,
        variables: {'siteId': scope.siteId},
        fetchPolicy: FetchPolicy.noCache,
        context: Context.fromList([
          HttpLinkHeaders(
            headers: {'x-permission-version': '${scope.permissionVersion}'},
          ),
        ]),
      ),
    );
    if (!scopeEpoch.isCurrent(generation)) throw StateError('Site changed');
    return Query$MyProfile.fromJson(json);
  }

  Future<void> update(
    SiteScope originalScope,
    String employeeId,
    String phone,
    int version,
  ) async {
    final result = await client.mutate(
      MutationOptions(
        document: documentNodeMutationUpdateProfile,
        variables: {
          'siteId': originalScope.siteId,
          'input': Input$UpdateProfileInput(
            employeeId: employeeId,
            phone: phone,
            expectedVersion: version,
          ).toJson(),
        },
        fetchPolicy: FetchPolicy.noCache,
        context: Context.fromList([
          HttpLinkHeaders(
            headers: {
              'x-permission-version': '${originalScope.permissionVersion}',
            },
          ),
        ]),
      ),
    );
    // Never automatically retry writes; a lost response may have committed.
    if (result.hasException) {
      throw StateError(
        result.exception?.graphqlErrors.firstOrNull?.message ??
            'Save could not be confirmed. Refresh the profile before retrying.',
      );
    }
  }

  Future<Map<String, dynamic>> scopedRead(
    SiteScope scope,
    DocumentNode document, [
    Map<String, dynamic> variables = const {},
  ]) async {
    final generation = scopeEpoch.capture();
    final result = await _read(
      QueryOptions(
        document: document,
        variables: {'siteId': scope.siteId, ...variables},
        fetchPolicy: FetchPolicy.noCache,
        context: Context.fromList([
          HttpLinkHeaders(
            headers: {'x-permission-version': '${scope.permissionVersion}'},
          ),
        ]),
      ),
    );
    if (!scopeEpoch.isCurrent(generation)) {
      throw const ApiFailure('SCOPE_CHANGED', 'Workspace changed');
    }
    return result;
  }

  Future<Query$SiteScope> capabilities(SiteScope s) async =>
      Query$SiteScope.fromJson(await scopedRead(s, documentNodeQuerySiteScope));
  Future<Query$ProfileRequests> requests(SiteScope s) async =>
      Query$ProfileRequests.fromJson(
        await scopedRead(s, documentNodeQueryProfileRequests),
      );
  Future<Query$EmployeeDetails> employeeDetails(SiteScope s, String id) async =>
      Query$EmployeeDetails.fromJson(
        await scopedRead(s, documentNodeQueryEmployeeDetails, {
          'employeeId': id,
        }),
      );
  Future<Query$Employees> team(
    SiteScope s, {
    String search = '',
    String? after,
  }) async => Query$Employees.fromJson(
    await scopedRead(s, documentNodeQueryEmployees, {
      'first': 20,
      'search': search,
      'after': ?after,
    }),
  );
  Future<Query$AccessUsers> accessUsers(SiteScope s, String search) async =>
      Query$AccessUsers.fromJson(
        await scopedRead(s, documentNodeQueryAccessUsers, {'search': search}),
      );
  Future<Query$UserAccess> userAccess(SiteScope s, String id) async =>
      Query$UserAccess.fromJson(
        await scopedRead(s, documentNodeQueryUserAccess, {'userId': id}),
      );
  Future<Map<String, dynamic>> scopedWrite(
    SiteScope s,
    DocumentNode document,
    Map<String, dynamic> variables,
  ) async {
    final generation = scopeEpoch.capture();
    final result = await client.mutate(
      MutationOptions(
        document: document,
        variables: {'siteId': s.siteId, ...variables},
        fetchPolicy: FetchPolicy.noCache,
        context: Context.fromList([
          HttpLinkHeaders(
            headers: {'x-permission-version': '${s.permissionVersion}'},
          ),
        ]),
      ),
    );
    if (result.hasException) {
      final code =
          result.exception?.graphqlErrors.firstOrNull?.extensions?['code']
              ?.toString() ??
          'UNCONFIRMED';
      if (['SCOPE_CHANGED', 'UNAUTHENTICATED', 'MFA_REQUIRED'].contains(code)) {
        await switchSite();
        invalidations.add(code);
      }
      throw ApiFailure(
        code,
        result.exception?.graphqlErrors.firstOrNull?.message ??
            'Save could not be confirmed. Reload before retrying.',
      );
    }
    if (!scopeEpoch.isCurrent(generation)) {
      throw const ApiFailure(
        'SCOPE_CHANGED',
        'Workspace changed. Reload the original site to confirm the result.',
      );
    }
    return result.data!;
  }

  Future<Mutation$SaveFoundation> foundationWrite(
    SiteScope s,
    String operation,
    Input$FoundationInput input,
  ) async => Mutation$SaveFoundation.fromJson(
    await scopedWrite(s, documentNodeMutationSaveFoundation, {
      'operation': operation,
      'input': input.toJson(),
    }),
  );
  Future<Mutation$PreviewAccess> previewAccess(
    SiteScope s,
    String id,
    Input$AccessChangeInput input,
  ) async => Mutation$PreviewAccess.fromJson(
    await scopedWrite(s, documentNodeMutationPreviewAccess, {
      'userId': id,
      'input': input.toJson(),
    }),
  );
  Future<Mutation$SaveAccess> saveAccess(
    SiteScope s,
    String id,
    Input$AccessChangeInput input,
  ) async => Mutation$SaveAccess.fromJson(
    await scopedWrite(s, documentNodeMutationSaveAccess, {
      'userId': id,
      'input': input.toJson(),
    }),
  );

  Future<void> switchSite() async {
    scopeEpoch.change();
    transport.cancelReads();
    client.cache.store.reset();
  }

  void dispose() {
    invalidations.close();
    dio.close(force: true);
    client.link.dispose();
  }
}
