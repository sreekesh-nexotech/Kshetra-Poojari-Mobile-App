import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';

/// Builds the root widget tree: the Riverpod [ProviderScope] wrapping the app.
///
/// Infrastructure bootstrap (Hive box opening, env loading, crash reporting)
/// is intentionally deferred — this session ships the presentation layer only,
/// backed by in-memory mock providers.
Widget buildApp() {
  WidgetsFlutterBinding.ensureInitialized();
  return const ProviderScope(child: KshetraApp());
}
