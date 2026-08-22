import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'endpoints.dart';

/// The Django transport.
///
/// This backend uses **session authentication** — there is no JWT and no
/// `Authorization: Bearer`. Two cookies are the whole credential:
///
/// * `sessionid` — who you are, set by `login()` on sign-in.
/// * `csrftoken` — proof a write is not cross-site.
///
/// DRF's `SessionAuthentication` enforces CSRF on every unsafe method for an
/// authenticated user, so `X-CSRFToken` must be echoed back from the jar on
/// every POST/PATCH/PUT/DELETE. Missing it is a `403 CSRF Failed`, and it is
/// the single most common way this integration fails.
///
/// See `docs-flutter/pooja.md` §3.
class ApiClient {
  ApiClient._(this.dio, this._jar, this._baseUri);

  final Dio dio;
  final CookieJar _jar;
  final Uri _baseUri;

  /// [jar] is injectable so tests can hand in an in-memory [DefaultCookieJar]
  /// and skip path_provider's platform channel. Production passes nothing and
  /// gets a jar backed by the application-support directory.
  static Future<ApiClient> create({
    required String baseUrl,
    CookieJar? jar,
    HttpClientAdapter? adapter,
  }) async {
    // ignoreExpires stays false: a real session expiry must log the poojari
    // out rather than leaving a dead cookie that 403s every call.
    final resolvedJar =
        jar ??
        PersistCookieJar(
          storage: FileStorage(
            '${(await getApplicationSupportDirectory()).path}/.cookies/',
          ),
        );

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        // Let 4xx reach our own error mapping instead of throwing on status.
        validateStatus: (code) => code != null && code < 500,
        headers: {'Accept': 'application/json'},
        contentType: Headers.jsonContentType,
      ),
    );

    if (adapter != null) dio.httpClientAdapter = adapter;

    final client = ApiClient._(dio, resolvedJar, Uri.parse(baseUrl));
    dio.interceptors
      ..add(CookieManager(resolvedJar))
      ..add(InterceptorsWrapper(onRequest: client._attachCsrf));
    return client;
  }

  static const Set<String> _unsafe = {'POST', 'PUT', 'PATCH', 'DELETE'};

  Future<void> _attachCsrf(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_unsafe.contains(options.method.toUpperCase())) {
      final token = await csrfToken();
      if (token != null) options.headers['X-CSRFToken'] = token;
      // Django checks Referer on HTTPS and rejects a missing one.
      options.headers['Referer'] = _baseUri.toString();
    }
    handler.next(options);
  }

  Future<String?> csrfToken() => _cookieValue('csrftoken');

  /// Whether a session cookie is still on disk. Used to tell "signed out" from
  /// "offline" when the profile probe fails at cold start (pooja.md §10).
  Future<bool> hasSessionCookie() async =>
      await _cookieValue('sessionid') != null;

  Future<String?> _cookieValue(String name) async {
    final cookies = await _jar.loadForRequest(_baseUri);
    for (final c in cookies) {
      if (c.name == name) return c.value;
    }
    return null;
  }

  /// Call once at startup, before the login form is submitted. The sign-in
  /// endpoints are `@csrf_exempt`, but everything after them is not.
  Future<void> primeCsrf() => dio.get<dynamic>(Endpoints.csrf);

  Future<void> clearSession() => _jar.deleteAll();
}

/// Overridden in `bootstrapApp()`. Throwing rather than defaulting means a
/// forgotten override fails loudly at first use instead of silently no-oping.
final apiClientProvider = Provider<ApiClient>(
  (ref) => throw StateError(
    'apiClientProvider must be overridden in bootstrapApp()',
  ),
);
