import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled variable fonts before any test runs, so golden renders use
/// the real Noto Sans/Serif Malayalam, Roboto and Plus Jakarta Sans faces
/// (otherwise Flutter falls back to the Ahem box font and goldens are useless).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fonts = <String, String>{
    'NotoSansMalayalam': 'assets/fonts/NotoSansMalayalam-Variable.ttf',
    'NotoSerifMalayalam': 'assets/fonts/NotoSerifMalayalam-Variable.ttf',
    'Roboto': 'assets/fonts/Roboto-Variable.ttf',
    'PlusJakartaSans': 'assets/fonts/PlusJakartaSans-Variable.ttf',
    'NotoSansSymbols2': 'assets/fonts/NotoSansSymbols2-Regular.ttf',
  };

  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key)..addFont(rootBundle.load(entry.value));
    await loader.load();
  }

  await testMain();
}
