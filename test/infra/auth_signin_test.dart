import 'dart:convert';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kshetra_poojari/core/network/api_client.dart';
import 'package:kshetra_poojari/features/auth/domain/entities/user.dart';
import 'package:kshetra_poojari/features/auth/infrastructure/data_sources/remote/auth_api.dart';
import 'package:kshetra_poojari/features/auth/infrastructure/repositories/auth_repository_impl.dart';

const _base = 'https://api.temple.example';

class _AuthServer implements HttpClientAdapter {
  _AuthServer({this.status = 200, this.body = const {}});

  int status;
  Map<String, dynamic> body;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    // The CSRF prime is a GET and always succeeds.
    if (options.method == 'GET' && options.path.contains('/csrf/')) {
      return ResponseBody.fromString(
        '{}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
          'set-cookie': ['csrftoken=tok; Path=/'],
        },
      );
    }
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

Future<(AuthRepositoryImpl, _AuthServer)> _repo(_AuthServer server) async {
  final client = await ApiClient.create(
    baseUrl: _base,
    jar: DefaultCookieJar(),
    adapter: server,
  );
  return (AuthRepositoryImpl(AuthApi(client)), server);
}

void main() {
  test('a successful sign-in yields the poojari', () async {
    final (repo, _) = await _repo(
      _AuthServer(
        body: const {
          'message': 'Poojari signin successful',
          'user': {
            'id': 41,
            'username': 'sharma',
            'phone_number': '9847000000',
            'email': 'sharma@example.com',
            'role': 'temple_poojari',
          },
          'profile_status': 'active',
        },
      ),
    );

    final result = await repo.signIn(
      phoneNumber: '9847000000',
      password: 'secret',
    );

    expect(result, isA<SignedIn>());
    expect((result as SignedIn).user.id, 41);
  });

  test('a 200 with requires_password_setup is NOT a sign-in', () async {
    // The account exists but has never had a password. Reading `user` first
    // would leave the app spinning on a body that has no user at all.
    final (repo, _) = await _repo(
      _AuthServer(
        body: const {
          'message':
              'Account pending activation. OTP sent to set your password.',
          'requires_password_setup': true,
          'phone_number': '9847000000',
        },
      ),
    );

    final result = await repo.signIn(
      phoneNumber: '9847000000',
      password: 'secret',
    );

    expect(result, isA<NeedsPasswordSetup>());
    expect((result as NeedsPasswordSetup).phoneNumber, '9847000000');
  });

  test('401 surfaces the server message', () async {
    final (repo, _) = await _repo(
      _AuthServer(status: 401, body: const {'error': 'Invalid credentials'}),
    );

    final result = await repo.signIn(phoneNumber: '98470', password: 'wrong');

    expect(result, isA<SignInFailed>());
    expect((result as SignInFailed).message, 'Invalid credentials');
  });

  test('403 for a non-poojari account is a failure, not a crash', () async {
    final (repo, _) = await _repo(
      _AuthServer(
        status: 403,
        body: const {'error': 'Access denied. No poojari account found'},
      ),
    );

    final result = await repo.signIn(phoneNumber: '98470', password: 'x');
    expect(result, isA<SignInFailed>());
  });

  test('sign-in primes CSRF first, and posts the phone path', () async {
    final (repo, server) = await _repo(
      _AuthServer(
        body: const {
          'user': {'id': 41, 'username': 'sharma', 'role': 'temple_poojari'},
        },
      ),
    );

    await repo.signIn(phoneNumber: '9847000000', password: 'secret');

    expect(server.requests.first.path, contains('/csrf/'));
    final signIn = server.requests.last;
    final sent = signIn.data as Map<String, dynamic>;
    expect(sent['phone_number'], '9847000000');
    expect(sent['password'], 'secret');
    // Absent rather than null — the server treats the two differently.
    expect(sent.containsKey('username'), isFalse);
    expect(sent.containsKey('fcm_token'), isFalse);
  });

  test('signOut empties the jar even when the server call fails', () async {
    final server = _AuthServer(status: 500, body: const {'error': 'boom'});
    final client = await ApiClient.create(
      baseUrl: _base,
      jar: DefaultCookieJar(),
      adapter: server,
    );
    final repo = AuthRepositoryImpl(AuthApi(client));

    // Give it a session to clear.
    await client.dio.get<dynamic>('/api/auth/csrf/');

    await repo.signOut();

    // Keeping a session the poojari asked to end would be worse than the
    // failed request.
    expect(await client.hasSessionCookie(), isFalse);
  });
}
