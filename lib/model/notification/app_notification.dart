import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Une notification reçue par le coursier, telle que le backend la
/// conserve.
///
/// À ne pas confondre avec la notification Android affichée par
/// Firebase : celle-ci ne vit que le temps où elle est à l'écran. Le
/// backend garde la trace de chaque envoi, et c'est cette liste que
/// l'écran Notifications affiche.
class AppNotification {
  final int id;
  final String titre;
  final String message;

  /// Toujours `COURSE_STATUT` aujourd'hui ; le détail est dans
  /// [statut].
  final String type;

  /// Charge utile du message, que le backend renvoie sous forme de
  /// **chaîne JSON** et non d'objet — d'où le décodage ici.
  final Map<String, dynamic> donnees;

  final bool lue;
  final DateTime? date;

  const AppNotification({
    required this.id,
    required this.titre,
    required this.message,
    required this.type,
    required this.donnees,
    required this.lue,
    required this.date,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num?)?.toInt() ?? 0,
      titre: json['title'] as String? ?? '',
      message: json['body'] as String? ?? '',
      type: json['type'] as String? ?? '',
      donnees: _decoderDonnees(json['data']),
      lue: json['lue'] as bool? ?? false,
      date: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  static Map<String, dynamic> _decoderDonnees(Object? brut) {
    if (brut is Map<String, dynamic>) return brut;
    if (brut is String && brut.isNotEmpty) {
      try {
        final decode = jsonDecode(brut);
        if (decode is Map<String, dynamic>) return decode;
      } catch (e) {
        debugPrint('Données de notification illisibles : $e');
      }
    }
    return const {};
  }

  /// `NOUVELLE_COURSE`, `ANNULE`… vide si le backend ne l'a pas mis.
  String get statut => donnees['statut']?.toString() ?? '';

  /// Référence de la course concernée, quand elle est connue.
  String? get codeCourse => donnees['livraisonCode']?.toString();

  bool get estAnnulation => statut.toUpperCase() == 'ANNULE';

  /// « à l'instant », « il y a 12 min », « hier »…
  String get anciennete {
    if (date == null) return '';
    final ecart = DateTime.now().difference(date!);
    if (ecart.inMinutes < 1) return 'À l\'instant';
    if (ecart.inMinutes < 60) return 'Il y a ${ecart.inMinutes} min';
    if (ecart.inHours < 24) return 'Il y a ${ecart.inHours} h';
    if (ecart.inDays == 1) return 'Hier';
    if (ecart.inDays < 7) return 'Il y a ${ecart.inDays} jours';
    final d = date!;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
