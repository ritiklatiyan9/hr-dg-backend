import 'dart:async';
import 'package:dio/dio.dart' as http;
import 'package:gql/ast.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart';

/// A terminating transport for the single GraphQL client. Reads can be
/// cancelled on a scope change; writes keep their captured variables.
class DioGraphqlLink extends Link {
  DioGraphqlLink(this.dio, this.accessToken);
  final http.Dio dio;
  final String? Function() accessToken;
  final _reads = <http.CancelToken>{};
  void cancelReads() {
    for (final token in _reads.toList()) {
      token.cancel('Site changed');
    }
    _reads.clear();
  }

  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    final read = request.operation.document.definitions
        .whereType<OperationDefinitionNode>()
        .every((definition) => definition.type == OperationType.query);
    final cancel = http.CancelToken();
    if (read) _reads.add(cancel);
    try {
      final result = await dio.post<Map<String, dynamic>>(
        '/graphql',
        data: const RequestSerializer().serializeRequest(request),
        cancelToken: cancel,
        options: http.Options(
          headers: {
            if (accessToken() != null)
              'authorization': 'Bearer ${accessToken()}',
            ...?request.context.entry<HttpLinkHeaders>()?.headers,
          },
        ),
      );
      yield const ResponseParser().parseResponse(result.data!);
    } finally {
      _reads.remove(cancel);
    }
  }

  @override
  Future<void> dispose() async {
    cancelReads();
  }
}
