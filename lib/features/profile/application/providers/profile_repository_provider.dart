import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../infrastructure/data_sources/remote/profile_api.dart';
import '../../infrastructure/repositories/profile_repository_impl.dart';

/// The profile feature's one door to the network. Tests override this with a
/// fake; nothing above `infrastructure/` knows Dio exists.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ProfileApi(ref.watch(apiClientProvider))),
);
