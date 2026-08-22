import 'dart:convert';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kshetra_poojari/core/network/api_client.dart';

/// Records every request and answers with an empty 200, so the interceptor can
/// be inspected without a server. Optionally sets cookies on the first reply,
/// the way `/api/auth/poojari-signin/` does.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.setCookies = const []});

  final List<String> setCookies;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        if (setCookies.isNotEmpty) 'set-cookie': setCookies,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const String _base = 'https://api.temple.example';

Future<(ApiClient, _RecordingAdapter)> _client({
  List<String> setCookies = const [],
}) async {
  final adapter = _RecordingAdapter(setCookies: setCookies);
  final client = await ApiClient.create(
    baseUrl: _base,
    jar: DefaultCookieJar(),
    adapter: adapter,
  );
  return (client, adapter);
}

void main() {
  group('CSRF interceptor', () {
    test('a GET carries neither X-CSRFToken nor Referer', () async {
      final (client, adapter) = await _client(
        setCookies: ['csrftoken=abc123; Path=/'],
      );

      await client.primeCsrf();
      await client.dio.get<dynamic>('/api/poojari/profile/');

      final profile = adapter.requests.last;
      expect(profile.headers.containsKey('X-CSRFToken'), isFalse);
      expect(profile.headers.containsKey('Referer'), isFalse);
    });

    test('a PATCH echoes the csrftoken cookie back as X-CSRFToken', () async {
      final (client, adapter) = await _client(
        setCookies: ['csrftoken=abc123; Path=/'],
      );

      // Priming is what puts the token in the jar.
      await client.primeCsrf();
      await client.dio.patch<dynamic>(
        '/api/poojari/pooja-management/',
        data: {'order_id': 1},
      );

      final patch = adapter.requests.last;
      expect(patch.headers['X-CSRFToken'], 'abc123');
      // Django rejects a missing Referer on HTTPS.
      expect(patch.headers['Referer'], _base);
    });

    test('every unsafe method gets the header, not just PATCH', () async {
      final (client, adapter) = await _client(
        setCookies: ['csrftoken=tok; Path=/'],
      );
      await client.primeCsrf();

      await client.dio.post<dynamic>('/api/auth/logout/');
      expect(adapter.requests.last.headers['X-CSRFToken'], 'tok');

      await client.dio.delete<dynamic>('/x/');
      expect(adapter.requests.last.headers['X-CSRFToken'], 'tok');

      await client.dio.put<dynamic>('/x/');
      expect(adapter.requests.last.headers['X-CSRFToken'], 'tok');
    });

    test('a write before priming still sends Referer, just no token', () async {
      // Sign-in itself is @csrf_exempt, so this is the legitimate case.
      final (client, adapter) = await _client();

      await client.dio.post<dynamic>('/api/auth/poojari-signin/');

      final signIn = adapter.requests.last;
      expect(signIn.headers.containsKey('X-CSRFToken'), isFalse);
      expect(signIn.headers['Referer'], _base);
    });
  });

  group('session cookie', () {
    test('hasSessionCookie is false until the server sets one', () async {
      final (client, _) = await _client();
      expect(await client.hasSessionCookie(), isFalse);
    });

    test('hasSessionCookie is true after sign-in, false after clear', () async {
      final (client, _) = await _client(
        setCookies: ['sessionid=xyz; Path=/', 'csrftoken=abc; Path=/'],
      );

      await client.dio.post<dynamic>('/api/auth/poojari-signin/');
      expect(await client.hasSessionCookie(), isTrue);
      expect(await client.csrfToken(), 'abc');

      await client.clearSession();
      expect(await client.hasSessionCookie(), isFalse);
    });
  });

  group('validateStatus', () {
    test(
      'a 4xx resolves instead of throwing, so we can map the body',
      () async {
        final adapter = _RecordingAdapter();
        final client = await ApiClient.create(
          baseUrl: _base,
          jar: DefaultCookieJar(),
          adapter: adapter,
        );

        // Swap in an adapter that answers 403 with a DRF-shaped body.
        client.dio.httpClientAdapter = _StatusAdapter(
          403,
          jsonEncode({'detail': 'CSRF Failed: CSRF token missing'}),
        );

        final res = await client.dio.patch<dynamic>(
          '/api/poojari/pooja-management/',
        );
        expect(res.statusCode, 403);
        expect((res.data as Map)['detail'], contains('CSRF Failed'));
      },
    );
  });
}

class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.status, this.body);

  final int status;
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    body,
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
