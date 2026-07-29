import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Missions refusées par le coursier, conservées entre deux
/// lancements de l'app. Purement local : aucun appel API.
class RefusedMissionsNotifier extends StateNotifier<Set<int>> {
  RefusedMissionsNotifier() : super(<int>{}) {
    _load();
  }

  static const _key = 'refused_missions';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key) ?? const [];
    state = stored.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.map((id) => '$id').toList());
  }

  /// Masque la mission [missionId] des listes.
  Future<void> refuse(int missionId) async {
    if (state.contains(missionId)) return;
    state = {...state, missionId};
    await _persist();
  }

  /// Ré-affiche toutes les missions refusées.
  Future<void> clear() async {
    state = <int>{};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final refusedMissionsProvider =
    StateNotifierProvider<RefusedMissionsNotifier, Set<int>>(
  (ref) => RefusedMissionsNotifier(),
);
