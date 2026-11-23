import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/env.dart';

/// Sentry crash reporting.
///
/// [init] wraps the whole launch, so an exception thrown while bootstrapping
/// (a bad `--dart-define`, a cookie-jar failure) is reported too, not only
/// errors after the first frame. Flutter framework errors, uncaught async
/// errors and native (Android/iOS) crashes are captured automatically.
///
/// Privacy: `sendDefaultPii` stays false, so request headers and cookies (the
/// Django `sessionid` / `csrftoken`) and the device IP are never attached, and
/// HTTP request/response bodies (passwords, OTPs) are not sent. The only user
/// detail attached is the numeric poojari id — see [setUser].
abstract final class CrashReporting {
  CrashReporting._();

  static bool get isEnabled => Env.sentryDsn.isNotEmpty;

  static Future<void> init({required FutureOr<void> Function() appRunner}) {
    if (!isEnabled) return Future.sync(appRunner);

    return SentryFlutter.init((options) {
      options
        ..dsn = Env.sentryDsn
        // Keeps local debugging out of the prod/staging issue streams.
        ..environment = kDebugMode ? 'debug' : Env.flavorName
        ..sendDefaultPii = false
        ..attachScreenshot = false
        ..attachViewHierarchy = false
        // Performance tracing: 1 in 5 navigations / HTTP calls.
        ..tracesSampleRate = 0.2;
    }, appRunner: appRunner);
  }

  /// Tags subsequent events with the signed-in poojari, or clears it on
  /// sign-out. Id only — no name, phone or email leaves the device.
  static void setUser(int? poojariId) {
    if (!isEnabled) return;
    final user = poojariId == null
        ? null
        : SentryUser(id: poojariId.toString());
    unawaited(Future.sync(() => Sentry.configureScope((s) => s.setUser(user))));
  }

  /// Reports an error that was caught and handled, so it still shows up as
  /// an issue in Sentry.
  static Future<void> captureException(Object error, [StackTrace? stack]) =>
      isEnabled
      ? Sentry.captureException(error, stackTrace: stack)
      : Future.value();
}
