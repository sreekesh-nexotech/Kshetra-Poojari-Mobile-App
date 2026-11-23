import 'dart:convert';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kshetra_poojari/core/network/api_client.dart';
import 'package:kshetra_poojari/features/auth/application/providers/session_controller.dart';
import 'package:kshetra_poojari/features/auth/application/states/session_state.dart';
import 'package:kshetra_poojari/features/auth/domain/entities/user.dart';

const _base = 'https://api.temple.example';

/// Answers every request with whatever status/body the test sets.
class _Server implements HttpClientAdapter {
  int status = 200;
  Map<String, dynamic> body = const {};
  List<String> setCookies = const [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      if (setCookies.isNotEmpty) 'set-cookie': setCookies,
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Server server;
  late ApiClient client;
  late int rejections;

  setUp(() async {
    server = _Server();
    client = await ApiClient.create(
      baseUrl: _base,
      jar: DefaultCookieJar(),
      adapter: server,
    );
    rejections = 0;
    client.onSessionRejected = () => rejections++;
  });

  group('ApiClient.onSessionRejected', () {
    test('fires on an auth-layer 403 (DRF "detail" body)', () async {
      server
        ..status = 403
        ..body = {'detail': 'Authentication credentials were not provided.'};

      await client.dio.get<dynamic>('/api/poojari/profile/');

      expect(rejections, 1);
    });

    test('does not fire on an application 403 ("error" body)', () async {
      server
        ..status = 403
        ..body = {
          'error': 'Outside temple premises',
          'distance_meters': 900,
          'radius_meters': 200,
        };

      await client.dio.post<dynamic>('/api/poojari/attendance/');

      expect(rejections, 0);
    });

    test('does not fire on a rejected sign-in', () async {
      server
        ..status = 403
        ..body = {'detail': 'Not a poojari account.'};

      await client.dio.post<dynamic>('/api/auth/poojari-signin/');

      expect(rejections, 0);
    });

    test('does not fire on success', () async {
      await client.dio.get<dynamic>('/api/poojari/profile/');

      expect(rejections, 0);
    });
  });

  group('SessionController', () {
    ProviderContainer container() {
      final c = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(client),
          sessionSeedProvider.overrideWithValue(
            const SessionState(
              status: SessionStatus.authenticated,
              user: PoojariUser(id: 41, username: 'sharma'),
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('a 403 mid-use signs the poojari out and empties the jar', () async {
      final c = container();
      c.read(sessionControllerProvider); // wires the hook

      server.setCookies = ['sessionid=abc; Path=/'];
      await client.dio.get<dynamic>('/api/auth/csrf/');
      server
        ..setCookies = const []
        ..status = 403
        ..body = {'detail': 'Authentication credentials were not provided.'};

      // Several screens 403 at once when a session dies.
      await Future.wait([
        client.dio.get<dynamic>('/api/poojari/profile/'),
        client.dio.get<dynamic>('/api/poojari/pooja-management/'),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(
        c.read(sessionControllerProvider).status,
        SessionStatus.unauthenticated,
      );
      expect(await client.hasSessionCookie(), isFalse);
    });

    test('an application 403 keeps the poojari signed in', () async {
      final c = container();
      c.read(sessionControllerProvider);

      server
        ..status = 403
        ..body = {'error': 'This booking is assigned to another poojari'};
      await client.dio.patch<dynamic>('/api/poojari/pooja-management/');

      expect(c.read(sessionControllerProvider).isAuthenticated, isTrue);
    });
  });
}
