import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/order/mission.dart';
import '../../auth/providers/auth_notifier.dart';

/// Missions disponibles, triées par date de création décroissante
/// (la plus récente en premier).
/// Rechargeable via ref.invalidate(availableOrdersProvider).
final availableOrdersProvider =
    FutureProvider<List<Mission>>((ref) async {
  final orders = await ref.read(apiServiceProvider).getAvailableOrders();
  orders.sort((a, b) {
    if (a.dateCreationMission == null && b.dateCreationMission == null) {
      return 0;
    }
    if (a.dateCreationMission == null) return 1;
    if (b.dateCreationMission == null) return -1;
    return b.dateCreationMission!.compareTo(a.dateCreationMission!);
  });
  return orders;
});
