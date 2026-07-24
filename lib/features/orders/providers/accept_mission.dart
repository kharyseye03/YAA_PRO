import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/constants.dart';
import '../../auth/providers/auth_notifier.dart';
import 'orders_provider.dart';

/// Accepte une mission, affiche le retour à l'utilisateur et
/// rafraîchit la liste des missions disponibles.
/// Retourne true si l'acceptation a réussi.
Future<bool> acceptMission(
  BuildContext context,
  WidgetRef ref,
  int missionId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(apiServiceProvider).acceptMission(missionId);
    ref.invalidate(availableOrdersProvider);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Mission acceptée ! Rendez-vous au point de départ.'),
        backgroundColor: AppColors.success,
      ),
    );
    return true;
  } catch (e) {
    // La mission a pu être prise par un autre coursier entre-temps
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
