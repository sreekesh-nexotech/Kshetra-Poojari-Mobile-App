import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kshetra_poojari/features/auth/application/providers/session_controller.dart';
import 'package:kshetra_poojari/features/dashboard/application/providers/home_providers.dart';
import 'package:kshetra_poojari/features/pooja/application/providers/pooja_data_providers.dart';
import 'package:kshetra_poojari/features/profile/application/providers/profile_providers.dart';

import 'dashboard_fixture.dart';
import 'pooja_fixture.dart';
import 'profile_fixture.dart';

/// Feeds the demo dataset into the data seams, so a widget or state test
/// renders the same content the design was signed off against — without a
/// network, and without the app shipping mock data.
List<Override> get kFixtureOverrides => [
  godsSeedProvider.overrideWithValue(PoojaFixture.gods),
  poojaSeedProvider.overrideWithValue(PoojaFixture.tasks()),
  malayalamDateSeedProvider.overrideWithValue(DashboardFixture.malayalamDate),
  upcomingDaysSeedProvider.overrideWithValue(DashboardFixture.upcoming),
  sessionSeedProvider.overrideWithValue(ProfileFixture.session),
  assignedGodsLabelSeedProvider.overrideWithValue(
    ProfileFixture.assignedGodsLabel,
  ),
  monthKpisSeedProvider.overrideWithValue(ProfileFixture.monthKpis),
  weekDaysSeedProvider.overrideWithValue(ProfileFixture.weekDays),
];
