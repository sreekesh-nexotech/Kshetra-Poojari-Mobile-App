import 'dart:convert';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kshetra_poojari/core/network/api_client.dart';
import 'package:kshetra_poojari/core/network/network_exceptions.dart';
import 'package:kshetra_poojari/features/pooja/domain/entities/booking.dart';
import 'package:kshetra_poojari/features/pooja/infrastructure/data_sources/remote/pooja_api.dart';
import 'package:kshetra_poojari/features/pooja/infrastructure/repositories/pooja_repository_impl.dart';

import '../support/fixtures.dart';

/// Answers each path with a canned body, and records what was sent.
class _FakeServer implements HttpClientAdapter {
  _FakeServer(this.routes, {this.status = 200});

  final Map<String, Map<String, dynamic>> routes;
  final int status;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = routes[options.path] ?? const <String, dynamic>{};
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<(PoojaRepositoryImpl, _FakeServer)> _repo(
  Map<String, Map<String, dynamic>> routes, {
  int status = 200,
}) async {
  final server = _FakeServer(routes, status: status);
  final client = await ApiClient.create(
    baseUrl: 'https://api.temple.example',
    jar: DefaultCookieJar(),
    adapter: server,
  );
  return (PoojaRepositoryImpl(PoojaApi(client)), server);
}

void main() {
  group('gods()', () {
    test('sorts by sort_order and drops inactive shrines', () async {
      final (repo, _) = await _repo({
        '/api/booking/poojacategory/': loadFixture('poojacategory.json'),
      });

      final gods = await repo.gods();

      // Fixture order is 7, 3, 5, 9 — sort_order is 3, 1, 2, 4.
      expect(gods.map((g) => g.id), [3, 5, 7]);
      expect(gods.map((g) => g.sortOrder), [1, 2, 3]);
      // id 9 is is_active: false.
      expect(gods.any((g) => g.id == 9), isFalse);
    });

    test('asks only for active rows', () async {
      final (repo, server) = await _repo({
        '/api/booking/poojacategory/': loadFixture('poojacategory.json'),
      });

      await repo.gods();
      expect(server.requests.single.queryParameters['is_active'], true);
    });
  });

  group('todaysWork()', () {
    test('always sends category_id — omitting it is a 400', () async {
      final (repo, server) = await _repo({
        '/api/poojari/pooja-management/': loadFixture('todays_work.json'),
      });

      final work = await repo.todaysWork(3);

      expect(server.requests.single.queryParameters['category_id'], 3);
      expect(work.category.id, 3);
      expect(work.orders, hasLength(3));
    });

    test('a 4xx body becomes an ApiException, not a DioException', () async {
      final (repo, _) = await _repo({
        '/api/poojari/pooja-management/': {'error': 'category_id is required'},
      }, status: 400);

      expect(
        () => repo.todaysWork(3),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', 'category_id is required'),
        ),
      );
    });
  });

  group('markBookings()', () {
    test('sends order_id, order_line_ids and pooja_status', () async {
      final (repo, server) = await _repo({
        '/api/poojari/pooja-management/': loadFixture('patch_completed.json'),
      });

      final r = await repo.markBookings(
        orderId: 4182,
        bookingIds: [9051, 9052],
        status: PoojaStatus.completed,
      );

      final sent = server.requests.single.data as Map<String, dynamic>;
      expect(sent['order_id'], 4182);
      expect(sent['order_line_ids'], [9051, 9052]);
      expect(sent['pooja_status'], 'completed');
      expect(r.bookingsUpdated, 2);
    });

    test('refuses an empty list rather than moving the whole order', () async {
      final (repo, server) = await _repo({
        '/api/poojari/pooja-management/': loadFixture('patch_completed.json'),
      });

      await expectLater(
        repo.markBookings(
          orderId: 4182,
          bookingIds: const [],
          status: PoojaStatus.completed,
        ),
        throwsArgumentError,
      );
      // Crucially, nothing reached the network.
      expect(server.requests, isEmpty);
    });

    test('a 403 reassignment surfaces its own verdict', () async {
      final (repo, _) = await _repo({
        '/api/poojari/pooja-management/': {
          'error': 'Bookings [9052] are assigned to another poojari',
        },
      }, status: 403);

      expect(
        () => repo.markBookings(
          orderId: 4182,
          bookingIds: [9052],
          status: PoojaStatus.completed,
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isAssignedToSomeoneElse,
            'isAssignedToSomeoneElse',
            isTrue,
          ),
        ),
      );
    });
  });
}
