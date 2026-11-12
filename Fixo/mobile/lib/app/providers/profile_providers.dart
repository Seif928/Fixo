import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../features/profile/data/profile_repository.dart'
    show DioProfileRepository;
import '../../features/profile/domain/profile_repository.dart';
export '../../features/profile/domain/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return DioProfileRepository(ref.watch(dioClientProvider));
});
