import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/driver/driver_detail.dart';
import '../../../service/storage/token_storage.dart';
import 'auth_notifier.dart';

/// Détails du livreur connecté (nom, email, photo…).
/// Rechargé via ref.invalidate(driverDetailProvider) après login.
final driverDetailProvider = FutureProvider<DriverDetail?>((ref) async {
  final phone = await TokenStorage.instance.getPhone();
  if (phone == null) return null;
  final api = ref.read(apiServiceProvider);
  return api.getDriverDetail(telephone: phone);
});
