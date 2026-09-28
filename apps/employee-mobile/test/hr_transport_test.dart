import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql/client.dart';
import 'package:defence_garden_employee/api.dart';

class LateAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final network = Future<ResponseBody>.delayed(
      const Duration(milliseconds: 40),
      () => ResponseBody.fromString(
        '{"data":{"ready":true}}',
        200,
        headers: {
          'content-type': ['application/json'],
        },
      ),
    );
    return network.timeout(
      const Duration(milliseconds: 5),
      onTimeout: () => throw DioException(
        requestOptions: options,
        type: DioExceptionType.receiveTimeout,
      ),
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'bounded transport failure ignores a late response without a second completion',
    () async {
      final api = HrApi(baseUrl: 'http://localhost');
      api.dio.httpClientAdapter = LateAdapter();
      final result = await api.client.query(
        QueryOptions(
          document: gql('query {ready}'),
          fetchPolicy: FetchPolicy.noCache,
        ),
      );
      expect(result.hasException, true);
      await Future<void>.delayed(const Duration(milliseconds: 70));
      api.dispose();
    },
  );
}
