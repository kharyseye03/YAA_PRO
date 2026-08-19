// ⚠️ TEMPLATE — Copiez ce fichier vers api_config.dart
// et remplacez les valeurs par les vraies URLs.
// api_config.dart est ignoré par git (contient les URLs du backend).

class ApiConfig {
  // ── Keycloak (IAM) ────────────────────────────────────────
  static const String keycloakBaseUrl = 'http://VOTRE_IP:PORT';
  static const String loginEndpoint =
      '/realms/yaa-delivery/protocol/openid-connect/token';

  /// Client Keycloak de l'app mobile (login et refresh).
  static const String keycloakClientId = 'yaa-mobile';

  // ── API Base ──────────────────────────────────────────────
  static const String baseUrl = 'http://VOTRE_IP:PORT/api/v1';

  // ── Endpoints Livreur ─────────────────────────────────────
  static const String driverDetailEndpoint = '/registrations/detail';
  static const String updateProfileEndpoint = '/registrations/update';

  // ── Endpoints Commandes ───────────────────────────────────
  static const String availableOrdersEndpoint =
      '/commandes-clients-livreurs/livraison';

  /// Articles de la commande passée chez le commerçant.
  ///
  /// Variante coursier : `/commandes-structures/detail` existe aussi
  /// mais s'adresse au client et plante pour un livreur.
  /// [id] est le `commandeStructureId` porté par la mission, pas l'id
  /// de la mission elle-même.
  static String commandeStructureDetailEndpoint(int id) =>
      '/commandes-livreurs/detail?id=$id';

  // ── Timeouts ──────────────────────────────────────────────
  static const int connectionTimeout = 30;

  // ── Headers ───────────────────────────────────────────────
  static Map<String, String> get formHeaders => {
        'Content-Type': 'application/x-www-form-urlencoded',
      };

  static String getIamUrl(String endpoint) => '$keycloakBaseUrl$endpoint';
  static String getUrl(String endpoint) => '$baseUrl$endpoint';
  static String getImageUrl(String fileName) => '$baseUrl/files/$fileName';
}
