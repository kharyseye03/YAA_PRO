/// Pièce d'identité du livreur.
class PieceIdentite {
  final String type;
  final String numero;

  const PieceIdentite({required this.type, required this.numero});

  /// « CNI » → « Carte nationale d'identité »
  String get typeLabel => switch (type.toUpperCase()) {
        'CNI' => 'Carte nationale d\'identité',
        'PASSEPORT' => 'Passeport',
        _ => type,
      };

  factory PieceIdentite.fromJson(Map<String, dynamic> json) {
    return PieceIdentite(
      type: json['type'] as String? ?? '',
      numero: json['pieceNumber'] as String? ?? '',
    );
  }
}

/// Véhicule déclaré par le livreur.
class VehiculeInfo {
  final String marque;
  final String immatriculation;
  final String couleur;
  final String permis;
  final String assurance;

  const VehiculeInfo({
    required this.marque,
    required this.immatriculation,
    required this.couleur,
    required this.permis,
    required this.assurance,
  });

  /// « TVS 125 · DK-2456-SN »
  String get resume {
    final parts = [marque, immatriculation].where((p) => p.isNotEmpty);
    return parts.join(' · ');
  }

  factory VehiculeInfo.fromJson(Map<String, dynamic> json) {
    return VehiculeInfo(
      marque: json['marque'] as String? ?? '',
      immatriculation: json['immatriculation'] as String? ?? '',
      couleur: json['couleur'] as String? ?? '',
      permis: json['permis'] as String? ?? '',
      assurance: json['assurance'] as String? ?? '',
    );
  }
}

class DriverDetail {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String telephone;
  final String username;
  final String profile;
  final String? address;
  final String? imageFileName;
  final double? latitude;
  final double? longitude;

  /// Note moyenne du livreur, `null` tant qu'il n'a pas été noté.
  final double? notation;
  final int nombreNotations;

  final PieceIdentite? pieceIdentite;
  final VehiculeInfo? vehiculeInfo;

  const DriverDetail({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.telephone,
    required this.username,
    required this.profile,
    this.address,
    this.imageFileName,
    this.latitude,
    this.longitude,
    this.notation,
    this.nombreNotations = 0,
    this.pieceIdentite,
    this.vehiculeInfo,
  });

  String get fullName => '$firstName $lastName';

  /// True si le livreur a déjà reçu au moins une note.
  bool get estNote => notation != null && nombreNotations > 0;

  factory DriverDetail.fromJson(Map<String, dynamic> json) {
    return DriverDetail(
      id: json['id'] as int,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
      username: json['username'] as String? ?? '',
      profile: json['profile'] as String? ?? '',
      address: json['address'] as String?,
      imageFileName: json['imageFileName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      notation: (json['notation'] as num?)?.toDouble(),
      nombreNotations: (json['nombreNotations'] as num?)?.toInt() ?? 0,
      pieceIdentite: json['pieceIdentite'] is Map<String, dynamic>
          ? PieceIdentite.fromJson(
              json['pieceIdentite'] as Map<String, dynamic>)
          : null,
      vehiculeInfo: json['vehiculeInfo'] is Map<String, dynamic>
          ? VehiculeInfo.fromJson(
              json['vehiculeInfo'] as Map<String, dynamic>)
          : null,
    );
  }
}
