import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kshetra_poojari/core/network/api_client.dart';
import 'package:kshetra_poojari/features/auth/application/providers/session_controller.dart';
import 'package:kshetra_poojari/features/auth/application/states/session_state.dart';

const _base = 'https://api.temple.example';

// Header shapes copied from the production server's actual responses.
const _csrf =
    'csrftoken=CSRF; expires=Thu, 23 Sep 2027 06:13:20 GMT; Max-Age=31449600; '
    'Path=/; SameSite=Lax; Secure';

const _profile = {
  'id': 81,
  'username': 'sharma',
  'email': '',
  'first_name': 'Sharma',
  'last_name': null,
  'phone_number': null,
  'role': 'temple_poojari',
};

/// Answers every path with the profile body and whatever cookies it is told to
/// set, and records the `Cookie` header each request carried.
class _Server implements HttpClientAdapter {
  List<String> setCookies = const [];
  final List<String?> cookieHeaders = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    cookieHeaders.add(options.headers['cookie'] as String?);
    return ResponseBody.fromString(
      jsonEncode(_profile),
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

/// Closing the app throws away every object in memory. The only thing that
/// makes it to the next launch is the jar's directory, so each "launch" here
/// builds a brand-new [PersistCookieJar] and [ApiClient] on that directory.
///
/// The other session tests use an in-memory [DefaultCookieJar], which means
/// they can't catch a cookie that only lived in memory.
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('kshetra_jar'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<ApiClient> launch(_Server server) => ApiClient.create(
    baseUrl: _base,
    jar: PersistCookieJar(storage: FileStorage('${dir.path}/.cookies/')),
    adapter: server,
  );

  for (final (label, sessionCookie) in [
    (
      'a dated sessionid (Django default)',
      'sessionid=SESS; expires=Thu, 08 Oct 2099 06:13:20 GMT; HttpOnly; '
          'Max-Age=1209600; Path=/; SameSite=Lax; Secure',
    ),
    (
      'an undated sessionid (SESSION_EXPIRE_AT_BROWSER_CLOSE)',
      'sessionid=SESS; HttpOnly; Path=/; SameSite=Lax; Secure',
    ),
  ]) {
    test('$label survives closing and reopening the app', () async {
      // First launch: sign in.
      final first = _Server();
      final before = await launch(first);
      first.setCookies = [_csrf];
      await before.primeCsrf();
      first.setCookies = [_csrf, sessionCookie];
      await before.dio.post<dynamic>('/api/auth/poojari-signin/');

      // Second launch, in the same order bootstrapApp() runs things.
      final second = _Server();
      final after = await launch(second);
      expect(await after.hasSessionCookie(), isTrue);
      second.setCookies = [_csrf];
      await after.primeCsrf();
      second.setCookies = const [];

      final state = await SessionBootstrap.restore(after);

      expect(state.status, SessionStatus.authenticated);
      expect(state.user?.id, 81);
      // The profile probe must have actually carried the session.
      expect(second.cookieHeaders.last, contains('sessionid=SESS'));
    });
  }

  test('a manual sign-out also clears the cookie from disk', () async {
    final first = _Server();
    final before = await launch(first);
    first.setCookies = [
      _csrf,
      'sessionid=SESS; Max-Age=1209600; Path=/; Secure',
    ];
    await before.primeCsrf();
    expect(await before.hasSessionCookie(), isTrue);
    await before.clearSession();

    final after = await launch(_Server());
    expect(await after.hasSessionCookie(), isFalse);
  });
}
