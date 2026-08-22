import 'package:dio/dio.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/endpoints.dart';
import '../../../../../core/network/network_exceptions.dart';

/// The auth HTTP calls. Sign-in is deliberately *not* routed through the
/// error mapper: it answers 200 for two different outcomes, so the caller
/// needs the raw body and status.
class AuthApi {
  const AuthApi(this._client);

  final ApiClient _client;

  Dio get _dio => _client.dio;

  Future<void> primeCsrf() => _client.primeCsrf();

  Future<({int status, Map<String, dynamic> body})> poojariSignIn({
    String? username,
    String? phoneNumber,
    required String password,
    String? fcmToken,
  }) async {
    final res = await _dio.post<dynamic>(
      Endpoints.poojariSignIn,
      data: {
        'username': ?username,
        'phone_number': ?phoneNumber,
        'password': password,
        'fcm_token': ?fcmToken,
      },
    );
    return (status: res.statusCode ?? 0, body: _map(res));
  }

  /// `GET /api/poojari/profile/` — the read is on the **list** route, with no
  /// id in the path.
  Future<({int status, Map<String, dynamic> body})> profile() async {
    final res = await _dio.get<dynamic>(Endpoints.profile);
    return (status: res.statusCode ?? 0, body: _map(res));
  }

  Future<void> logout() async {
    final res = await _dio.post<dynamic>(Endpoints.logout);
    final code = res.statusCode ?? 0;
    // A 403 here just means the session was already gone — still a success
    // from the app's point of view.
    if (code >= 400 && code != 403) {
      throw ApiException.fromResponse(code, _map(res));
    }
  }

  Future<void> clearSession() => _client.clearSession();

  Future<bool> hasSessionCookie() => _client.hasSessionCookie();

  Map<String, dynamic> _map(Response<dynamic> res) {
    final data = res.data;
    return data is Map<String, dynamic> ? data : const <String, dynamic>{};
  }
}
