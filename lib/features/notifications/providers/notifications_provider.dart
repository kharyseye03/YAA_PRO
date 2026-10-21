import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../model/notification/app_notification.dart';
import '../../auth/providers/auth_notifier.dart';

/// Historique des notifications du coursier, le plus récent en tête.
final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  return ref.read(apiServiceProvider).getNotifications();
});

/// Nombre de non lues, affiché en pastille sur la cloche de l'accueil.
///
/// Séparé de la liste : la pastille est visible en permanence, alors
/// que la liste n'est chargée qu'à l'ouverture de l'écran.
final notificationsNonLuesProvider = FutureProvider<int>((ref) async {
  return ref.read(apiServiceProvider).getNotificationsNonLues();
});
