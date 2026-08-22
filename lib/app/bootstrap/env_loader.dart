import 'package:flutter/foundation.dart';

import '../config/env.dart';

/// Fails the launch loudly on a misconfigured `--dart-define`, rather than
/// letting every request die with an opaque `DioException` later.
///
/// Called from `bootstrapApp()` before the [ApiClient] is built.
abstract final class EnvLoader {
  EnvLoader._();

  static void validate() {
    final raw = Env.apiBaseUrl.trim();
    if (raw.isEmpty) {
      throw StateError(
        'API_BASE_URL is empty. Pass --dart-define=API_BASE_URL=https://…',
      );
    }

    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.isAbsolute || uri.host.isEmpty) {
      throw StateError('API_BASE_URL is not an absolute URL: "$raw"');
    }
    if (!uri.isScheme('http') && !uri.isScheme('https')) {
      throw StateError('API_BASE_URL must be http or https: "$raw"');
    }

    // A release build talking cleartext would send the session cookie in the
    // clear. The debug network-security config permits 10.0.2.2 only.
    if (kReleaseMode && !uri.isScheme('https')) {
      throw StateError('API_BASE_URL must be https in a release build: "$raw"');
    }

    if (raw.endsWith('/')) {
      throw StateError('API_BASE_URL must not end with "/": "$raw"');
    }
  }
}
