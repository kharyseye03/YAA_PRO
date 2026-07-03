import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/order/commande_livraison.dart';
import '../../auth/providers/auth_notifier.dart';

/// Commandes disponibles pour livraison.
/// Rechargeable via ref.invalidate(availableOrdersProvider).
final availableOrdersProvider =
    FutureProvider<List<CommandeLivraison>>((ref) async {
  return ref.read(apiServiceProvider).getAvailableOrders();
});
