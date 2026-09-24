import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../infrastructure/data_sources/remote/dashboard_api.dart';
import '../../infrastructure/repositories/dashboard_repository_impl.dart';

/// The dashboard feature's one door to the network. Tests override this with
/// a fake; nothing above `infrastructure/` knows Dio exists.
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(DashboardApi(ref.watch(apiClientProvider))),
);
