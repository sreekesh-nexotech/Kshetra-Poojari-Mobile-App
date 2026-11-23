import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/bootstrap/app_bootstrap.dart';
import 'app/monitoring/crash_reporting.dart';

Future<void> main() async {
  // Sentry starts first so a failure inside bootstrapApp() is reported too.
  await CrashReporting.init(
    // Awaits the cookie jar and the session probe, so the first frame already
    // knows whether this poojari is signed in.
    appRunner: () async => runApp(SentryWidget(child: await bootstrapApp())),
  );
}
