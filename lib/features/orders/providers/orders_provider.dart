import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/order/commande_livraison.dart';
import '../../auth/providers/auth_notifier.dart';

/// Commandes disponibles pour livraison, triées par date de
/// création décroissante (la plus récente en premier).
/// Rechargeable via ref.invalidate(availableOrdersProvider).
final availableOrdersProvider =
    FutureProvider<List<CommandeLivraison>>((ref) async {
  final orders = await ref.read(apiServiceProvider).getAvailableOrders();
  orders.sort((a, b) {
    if (a.createdDate == null && b.createdDate == null) return 0;
    if (a.createdDate == null) return 1;
    if (b.createdDate == null) return -1;
    return b.createdDate!.compareTo(a.createdDate!);
  });
  return orders;
});
