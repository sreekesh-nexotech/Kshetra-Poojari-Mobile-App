import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/repositories/pooja_repository.dart';
import '../../infrastructure/data_sources/remote/pooja_api.dart';
import '../../infrastructure/repositories/pooja_repository_impl.dart';

/// The pooja feature's one door to the network. Tests override this with a
/// fake; nothing above `infrastructure/` knows Dio exists.
final poojaRepositoryProvider = Provider<PoojaRepository>(
  (ref) => PoojaRepositoryImpl(PoojaApi(ref.watch(apiClientProvider))),
);
