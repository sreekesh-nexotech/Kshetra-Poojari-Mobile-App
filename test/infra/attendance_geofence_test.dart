import 'dart:convert';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kshetra_poojari/core/error/failure.dart';
import 'package:kshetra_poojari/core/network/api_client.dart';
import 'package:kshetra_poojari/core/network/network_exceptions.dart';
import 'package:kshetra_poojari/core/utils/date_utils.dart';
import 'package:kshetra_poojari/features/dashboard/infrastructure/data_sources/remote/dashboard_api.dart';
import 'package:kshetra_poojari/features/dashboard/infrastructure/repositories/dashboard_repository_impl.dart';

/// Answers every request with one canned body/status, and records what was
/// sent — the geofence's contract is as much about the request as the reply.
class _FakeServer implements HttpClientAdapter {
  _FakeServer(this.body, {this.status = 200});

  final Map<String, dynamic> body;
  final int status;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
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

Future<(DashboardRepositoryImpl, _FakeServer)> _repo(
  Map<String, dynamic> body, {
  int status = 200,
}) async {
  final server = _FakeServer(body, status: status);
  final client = await ApiClient.create(
    baseUrl: 'https://api.temple.example',
    jar: DefaultCookieJar(),
    adapter: server,
  );
  return (DashboardRepositoryImpl(DashboardApi(client)), server);
}

const _site = {
  'id': 2,
  'name': 'Main Temple',
  'latitude': '10.123456',
  'longitude': '76.654321',
  'radius_meters': 200,
};

void main() {
  group('GET /attendance/location/ (§2)', () {
    test(
      'parses the site, keeping all six decimals of each coordinate',
      () async {
        final (repo, server) = await _repo({'location': _site});
        final site = await repo.attendanceLocation();

        expect(
          server.requests.single.path,
          '/api/poojari/attendance/location/',
        );
        expect(site, isNotNull);
        expect(site!.id, 2);
        expect(site.name, 'Main Temple');
        // The coordinates arrive as strings precisely so this digit survives.
        expect(site.latitude, 10.123456);
        expect(site.longitude, 76.654321);
        expect(site.radiusMeters, 200);
      },
    );

    test(
      'a null location is a 200, and comes back as null — not an error',
      () async {
        final (repo, _) = await _repo({'location': null});
        expect(await repo.attendanceLocation(), isNull);
      },
    );
  });

  group('POST /attendance/ (§3)', () {
    test(
      'sends the coordinates as strings, and no client-side distance',
      () async {
        final (repo, server) = await _repo({
          'message': 'Attendance marked',
          'created': true,
        }, status: 201);

        await repo.markAttendance(
          latitude: '10.123456',
          longitude: '76.654321',
        );

        final sent = server.requests.single;
        expect(sent.method, 'POST');
        expect(sent.path, '/api/poojari/attendance/');

        final body = sent.data as Map<String, dynamic>;
        expect(body['status'], 'present');
        // Strings, not doubles: a JSON float loses the sixth decimal place.
        expect(body['latitude'], isA<String>());
        expect(body['latitude'], '10.123456');
        expect(body['longitude'], '76.654321');
        // The server ignores a client-supplied distance and computes its own,
        // so sending one would be noise that invites someone to trust it.
        expect(body.containsKey('distance_meters'), isFalse);
        // No date: the temple's Asia/Kolkata day beats a device clock.
        expect(body.containsKey('date'), isFalse);
      },
    );

    test(
      '403 outside the premises carries the distance, radius and site',
      () async {
        final (repo, _) = await _repo({
          'error': 'Outside temple premises',
          'detail':
              'You need to be inside the temple premises to mark attendance.',
          'distance_meters': 178773,
          'radius_meters': 200,
          'location': _site,
        }, status: 403);

        final e = await repo
            .markAttendance(latitude: '1.0', longitude: '1.0')
            .then<ApiException?>((_) => null)
            .catchError((Object e) => e as ApiException);

        expect(e!.isOutsidePremises, isTrue);
        expect(e.distanceMeters, 178773);
        expect(e.radiusMeters, 200);
        expect(e.location, isNotNull);
      },
    );

    test(
      '403 outside the premises must NOT be read as an auth failure',
      () async {
        // The whole point of the `error`-key rule: signing the poojari out for
        // standing in the wrong car park would be a spectacular way to fail.
        final e = ApiException.fromResponse(403, {
          'error': 'Outside temple premises',
          'distance_meters': 850,
          'radius_meters': 200,
        });

        expect(e.isForbidden, isFalse);
        expect(Failure.from(e).action, isNot(FailureAction.signOut));
      },
    );

    test('403 from the auth layer (detail only) still signs out', () async {
      final e = ApiException.fromResponse(403, {
        'detail': 'Authentication credentials were not provided.',
      });

      expect(e.isForbidden, isTrue);
      expect(e.isOutsidePremises, isFalse);
      expect(Failure.from(e, hasSession: false).action, FailureAction.signOut);
    });

    test('409 is flagged as a missing temple configuration', () async {
      final e = ApiException.fromResponse(409, {
        'error': 'No temple location configured',
        'detail': 'Attendance cannot be verified yet.',
      });

      expect(e.isNoTempleLocation, isTrue);
      expect(e.isOutsidePremises, isFalse);
    });

    test('400 keeps the per-field details the copy is chosen from', () async {
      final e = ApiException.fromResponse(400, {
        'error': 'Invalid input',
        'details': {
          'latitude': ['Location is required to mark attendance for today.'],
        },
      });

      expect(e.details!.containsKey('latitude'), isTrue);
    });
  });

  group("today is the temple's day, not the device's (§5)", () {
    test('00:30 IST is that day, not the UTC day before it', () {
      // 2026-09-09T19:00Z is 2026-09-10T00:30 in Asia/Kolkata. A poojari
      // marking then is standing in the 10th, whatever their phone says.
      expect(AppTime.istToday(DateTime.utc(2026, 9, 9, 19)), '2026-09-10');
    });

    test('23:00 IST has not rolled over yet', () {
      expect(AppTime.istToday(DateTime.utc(2026, 9, 10, 17, 30)), '2026-09-10');
    });

    test('a device clock ahead of IST does not show tomorrow', () {
      // Same instant as above, expressed in UTC+10 — Sep 11 locally, still
      // Sep 10 at the temple.
      final tokyoWallClock = DateTime.parse('2026-09-11T03:30:00+10:00');
      expect(AppTime.istToday(tokyoWallClock), '2026-09-10');
    });
  });
}
