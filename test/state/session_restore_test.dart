import 'dart:convert';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kshetra_poojari/core/network/api_client.dart';
import 'package:kshetra_poojari/features/auth/application/providers/session_controller.dart';
import 'package:kshetra_poojari/features/auth/application/states/session_state.dart';

const _base = 'https://api.temple.example';

const _profile = {
  'id': 41,
  'username': 'sharma',
  'email': 'sharma@example.com',
  'first_name': 'Sharma',
  'last_name': null,
  'phone_number': '9847000000',
  'role': 'temple_poojari',
};

/// Answers `/api/poojari/profile/` however the test asks it to.
class _ProfileServer implements HttpClientAdapter {
  _ProfileServer({this.status = 200, this.body = _profile, this.throwType});

  int status;
  Map<String, dynamic> body;
  DioExceptionType? throwType;
  List<String> setCookies = const [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (throwType != null) {
      throw DioException(requestOptions: options, type: throwType!);
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        if (setCookies.isNotEmpty) 'set-cookie': setCookies,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<ApiClient> _client(_ProfileServer server) =>
    ApiClient.create(baseUrl: _base, jar: DefaultCookieJar(), adapter: server);

/// Puts a sessionid in the jar, the way a real sign-in would.
Future<void> _seedSession(ApiClient client, _ProfileServer server) async {
  server.setCookies = ['sessionid=abc; Path=/'];
  await client.dio.get<dynamic>('/api/auth/csrf/');
  server.setCookies = const [];
}

void main() {
  test('200 restores the poojari', () async {
    final server = _ProfileServer();
    final client = await _client(server);

    final state = await SessionBootstrap.restore(client);

    expect(state.status, SessionStatus.authenticated);
    expect(state.isAuthenticated, isTrue);
    expect(state.user?.id, 41);
    expect(state.user?.displayName, 'Sharma');
  });

  test('403 signs them out and empties the jar', () async {
    final server = _ProfileServer(status: 403, body: const {'detail': 'nope'});
    final client = await _client(server);
    await _seedSession(client, server);
    expect(await client.hasSessionCookie(), isTrue);

    final state = await SessionBootstrap.restore(client);

    expect(state.status, SessionStatus.unauthenticated);
    expect(state.isAuthenticated, isFalse);
    // A real rejection must not leave a dead cookie behind.
    expect(await client.hasSessionCookie(), isFalse);
  });

  test('a timeout with a cookie still held keeps them signed in', () async {
    final server = _ProfileServer(throwType: DioExceptionType.connectionError);
    final client = await _client(server);
    // Seed before the adapter starts throwing.
    server.throwType = null;
    await _seedSession(client, server);
    server.throwType = DioExceptionType.connectionError;

    final state = await SessionBootstrap.restore(client);

    // Logging a poojari out because the temple wifi dropped is the worst
    // failure mode here — the cookie is still valid, so they stay in.
    expect(state.status, SessionStatus.stale);
    expect(state.isAuthenticated, isTrue);
    expect(await client.hasSessionCookie(), isTrue);
  });

  test('a timeout with no cookie means signed out', () async {
    final server = _ProfileServer(throwType: DioExceptionType.connectionError);
    final client = await _client(server);

    final state = await SessionBootstrap.restore(client);

    expect(state.status, SessionStatus.unauthenticated);
    expect(state.isAuthenticated, isFalse);
  });

  test('a 500 is not mistaken for a sign-out', () async {
    final server = _ProfileServer();
    final client = await _client(server);
    await _seedSession(client, server);
    // Only now does the server start failing.
    server.status = 500;
    server.body = const {'error': 'boom'};

    final state = await SessionBootstrap.restore(client);

    expect(state.status, SessionStatus.stale);
    expect(state.isAuthenticated, isTrue);
  });

  test('an unresolved session is not treated as signed in', () {
    const state = SessionState();
    expect(state.isResolved, isFalse);
    expect(state.isAuthenticated, isFalse);
  });
}
