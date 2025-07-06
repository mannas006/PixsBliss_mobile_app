import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/update_service.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

final updateInfoProvider = FutureProvider<UpdateInfo?>((ref) async {
  final updateService = ref.read(updateServiceProvider);
  return await updateService.checkForUpdate();
});

final updateDownloadProgressProvider = StateProvider<double>((ref) => 0.0);

final isDownloadingProvider = StateProvider<bool>((ref) => false);

final downloadStatusProvider = StateProvider<String>((ref) => ''); 