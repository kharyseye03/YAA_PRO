import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/gains/gains_summary.dart';
import '../../auth/providers/auth_notifier.dart';

/// Gains du livreur et historique de ses missions terminées.
final gainsProvider = FutureProvider<GainsSummary>((ref) async {
  return ref.read(apiServiceProvider).getGains();
});

/// Missions regroupées par jour, du plus récent au plus ancien.
typedef GainsDay = ({String label, double total, List<MissionGain> missions});

final gainsByDayProvider = Provider<AsyncValue<List<GainsDay>>>((ref) {
  return ref.watch(gainsProvider).whenData(_groupByDay);
});

List<GainsDay> _groupByDay(GainsSummary summary) {
  final grouped = <DateTime, List<MissionGain>>{};
  for (final m in summary.missions) {
    final d = m.dateMission ?? m.dateHeureMission;
    if (d == null) continue;
    final key = DateTime(d.year, d.month, d.day);
    grouped.putIfAbsent(key, () => []).add(m);
  }

  final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
  return days.map((day) {
    final missions = grouped[day]!
      ..sort((a, b) {
        final da = a.dateHeureMission;
        final db = b.dateHeureMission;
        if (da == null || db == null) return 0;
        return db.compareTo(da);
      });
    return (
      label: _dayLabel(day),
      total: missions.fold<double>(0, (sum, m) => sum + m.gain),
      missions: missions,
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
