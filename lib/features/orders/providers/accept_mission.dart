import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/constants.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../delivery/providers/active_mission_provider.dart';
import 'orders_provider.dart';
import 'refused_missions_provider.dart';

/// Refuse une mission : elle est masquée des listes et reste masquée
/// après redémarrage. Aucun appel API (le back ne gère pas le refus).
void refuseMission(WidgetRef ref, int missionId) {
  ref.read(refusedMissionsProvider.notifier).refuse(missionId);
}

/// Accepte une mission et rafraîchit la liste des missions
/// disponibles. Seul un échec est signalé à l'utilisateur.
/// Retourne true si l'acceptation a réussi.
Future<bool> acceptMission(
  BuildContext context,
  WidgetRef ref,
  int missionId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(apiServiceProvider).acceptMission(missionId);
    // Bascule l'app sur l'écran de mission en cours
    await ref.read(activeMissionIdProvider.notifier).start(missionId);
    ref.invalidate(allOrdersProvider);
    ref.invalidate(availableOrdersProvider);
    // Aucun message de succès : la bascule sur l'écran de mission est
    // en elle-même la confirmation que l'acceptation a fonctionné.
    return true;
  } catch (e) {
    // La mission a pu être prise par un autre coursier entre-temps
    ref.invalidate(allOrdersProvider);
    ref.invalidate(availableOrdersProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error,
      ),
    );
    return false;
  }
}
