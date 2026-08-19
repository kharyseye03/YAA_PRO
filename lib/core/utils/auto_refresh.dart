import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fréquence de rechargement des données qui peuvent changer sans que
/// le livreur touche à l'écran — une commande déposée par un client,
/// par exemple.
const Duration kAutoRefreshInterval = Duration(seconds: 30);

/// Recharge périodiquement des providers tant que l'écran est vivant.
///
/// Le minuteur s'arrête quand l'application passe en arrière-plan : il
/// est inutile de consommer de la donnée mobile pour un écran que
/// personne ne regarde. Au retour au premier plan, un rechargement
/// immédiat a lieu — c'est le moment où l'affichage est le plus
/// susceptible d'être périmé.
mixin AutoRefreshMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  Timer? _timer;
  AppLifecycleListener? _lifecycle;

  /// Providers rechargés à chaque tick.
  List<ProviderOrFamily> get autoRefreshTargets;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        refreshNow();
        _startTimer();
      },
      onPause: _stopTimer,
    );
  }

  @override
  void dispose() {
    _stopTimer();
    _lifecycle?.dispose();
    super.dispose();
  }

  /// Recharge sans attendre le prochain tick.
  void refreshNow() {
    if (!mounted) return;
    for (final provider in autoRefreshTargets) {
      ref.invalidate(provider);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(kAutoRefreshInterval, (_) => refreshNow());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
}
