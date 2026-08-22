import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kshetra_poojari/features/pooja/application/providers/pooja_data_providers.dart';

import 'pooja_fixture.dart';

/// Feeds the demo dataset into the two data seams, so a widget or state test
/// renders the same content the design was signed off against — without a
/// network, and without the app shipping mock data.
List<Override> get kFixtureOverrides => [
  godsSeedProvider.overrideWithValue(PoojaFixture.gods),
  poojaSeedProvider.overrideWithValue(PoojaFixture.tasks()),
];
