import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../features/auth/application/providers/session_controller.dart';
import '../app.dart';
import '../config/env.dart';
import 'env_loader.dart';

/// Test entry: synchronous, no I/O, no network client.
///
/// Kept separate from [bootstrapApp] so `test/widget_test.dart` can still
/// build the tree in one call. Providers that need a client are simply not
/// overridden — nothing in the boot path reads one.
Widget buildApp({List<Override> overrides = const []}) {
  WidgetsFlutterBinding.ensureInitialized();
  return ProviderScope(overrides: overrides, child: const KshetraApp());
}

/// Production entry.
///
/// The session is resolved *before* the first frame, which is why there is no
/// splash route and no first-frame flash of the login screen.
Future<Widget> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvLoader.validate();

  final client = await ApiClient.create(baseUrl: Env.apiBaseUrl);
  // The sign-in endpoints are @csrf_exempt, but the token must be in the jar
  // before any write that follows.
  try {
    await client.primeCsrf();
  } catch (_) {
    // Offline at launch: sign-in will prime it again on its own.
  }

  final session = await SessionBootstrap.restore(client);

  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(client),
      sessionSeedProvider.overrideWithValue(session),
    ],
    child: const KshetraApp(),
  );
}
