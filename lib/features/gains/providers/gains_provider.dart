import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/gains/gains_summary.dart';
import '../../../model/order/type_service.dart';
import '../../auth/providers/auth_notifier.dart';

/// Périodes proposées au livreur pour consulter ses gains.
enum GainsPeriod {
  tout('Tout'),
  aujourdhui('Aujourd\'hui'),
  septJours('7 jours'),
  trenteJours('30 jours'),
  personnalisee('Personnalisée');

  final String label;
  const GainsPeriod(this.label);

  /// Bornes envoyées à l'API. `null` = pas de filtre de date.
  DateTimeRange? rangeFrom(DateTimeRange? custom) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      tout => null,
      aujourdhui => DateTimeRange(start: today, end: today),
      septJours => DateTimeRange(
          start: today.subtract(const Duration(days: 6)), end: today),
      trenteJours => DateTimeRange(
          start: today.subtract(const Duration(days: 29)), end: today),
      personnalisee => custom,
    };
  }
}

/// Filtres appliqués à l'historique des gains.
class GainsFilter {
  final GainsPeriod period;
  final DateTimeRange? customRange;
  final TypeService? type;

  const GainsFilter({
    this.period = GainsPeriod.tout,
    this.customRange,
    this.type,
  });

  GainsFilter copyWith({
    GainsPeriod? period,
    DateTimeRange? customRange,
    TypeService? type,
    bool clearType = false,
  }) {
    return GainsFilter(
      period: period ?? this.period,
      customRange: customRange ?? this.customRange,
      type: clearType ? null : type ?? this.type,
    );
  }

  DateTimeRange? get range => period.rangeFrom(customRange);
}

final gainsFilterProvider =
    StateProvider<GainsFilter>((ref) => const GainsFilter());

/// `2026-07-28`
String _apiDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Gains du livreur et historique de ses missions terminées,
/// selon les filtres sélectionnés.
final gainsProvider = FutureProvider<GainsSummary>((ref) async {
  final filter = ref.watch(gainsFilterProvider);
  final range = filter.range;

  return ref.read(apiServiceProvider).getGains(
        typeService: filter.type?.value,
        dateDebut: range != null ? _apiDate(range.start) : null,
        dateFin: range != null ? _apiDate(range.end) : null,
      );
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
