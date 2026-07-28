import 'package:shared_preferences/shared_preferences.dart';

/// Retient la mission en cours du livreur pour la retrouver après
/// une fermeture de l'app.
///
/// Solution temporaire : à remplacer par l'endpoint backend
/// « ma mission en cours » quand il sera disponible.
class ActiveMissionStorage {
  ActiveMissionStorage._();
  static final ActiveMissionStorage instance = ActiveMissionStorage._();

  static const _key = 'active_mission_id';

  Future<void> save(int missionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, missionId);
  }

  Future<int?> get() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
