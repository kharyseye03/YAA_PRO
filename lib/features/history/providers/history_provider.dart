import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/order/history_mission.dart';
import '../../auth/providers/auth_notifier.dart';

/// Toutes les missions du livreur, de la plus récente à la plus
/// ancienne.
final allMissionsProvider =
    FutureProvider<List<HistoryMission>>((ref) async {
  final missions = await ref.read(apiServiceProvider).getAllMissions();
  missions.sort((a, b) {
    if (a.date == null || b.date == null) return 0;
    return b.date!.compareTo(a.date!);
  });
  return missions;
});

/// Missions achevées (livrées ou annulées), regroupées par jour.
typedef HistoryDay = ({
  String label,
  double total,
  List<HistoryMission> missions,
});

final historyByDayProvider =
    Provider<AsyncValue<List<HistoryDay>>>((ref) {
  return ref.watch(allMissionsProvider).whenData((missions) {
    final terminees =
        missions.where((m) => m.statutEnum.isFinished).toList();
    return _groupByDay(terminees);
  });
});

/// Total gagné sur l'ensemble de l'historique.
final historyTotalProvider = Provider<AsyncValue<({int nombre, double gain})>>(
  (ref) => ref.watch(allMissionsProvider).whenData((missions) {
    final terminees = missions.where((m) => m.statutEnum.isFinished);
    return (
      nombre: terminees.length,
      gain: terminees.fold<double>(0, (s, m) => s + m.gainLivreur),
    );
  }),
);

List<HistoryDay> _groupByDay(List<HistoryMission> missions) {
  final grouped = <DateTime, List<HistoryMission>>{};
  for (final m in missions) {
    final d = m.date;
    if (d == null) continue;
    grouped.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(m);
  }

  final jours = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
  return jours.map((jour) {
    final duJour = grouped[jour]!;
    return (
      label: _dayLabel(jour),
      total: duJour.fold<double>(0, (s, m) => s + m.gainLivreur),
      missions: duJour,
    );
  }).toList();
}

String _dayLabel(DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Aujourd\'hui';
  if (diff == 1) return 'Hier';

  const mois = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  final label = '${day.day} ${mois[day.month - 1]}';
  return day.year == now.year ? label : '$label ${day.year}';
}
