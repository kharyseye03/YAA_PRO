class ApiConfig {
  // ── Keycloak (IAM) ────────────────────────────────────────
  static const String iamBaseUrl = 'https://REPLACE_IAM_URL';
  static const String loginEndpoint = '/realms/yaa-delivery/protocol/openid-connect/token';

  // ── API Base ──────────────────────────────────────────────
  static const String _ngrokBaseUrl = 'https://REPLACE_API_URL';
  static const String baseUrl = '$_ngrokBaseUrl/api/v1';

  // ── Endpoints Auth ────────────────────────────────────────
  static const String registerEndpoint = '/registrations/livreur';
  static const String verifyOtpEndpoint = '/registrations/otp';
  static const String resetPasswordEndpoint = '/registrations/reset-password';
  static const String forgotPasswordEndpoint = '/registrations/forgot-password';
  static const String resendCodeEndpoint = '/registrations/resend-code';

  // ── Endpoints Livreur ─────────────────────────────────────
  static const String driverDetailEndpoint = '/livreurs/detail';
  static const String updateProfileEndpoint = '/livreurs/update';
  static const String driverStatusEndpoint = '/livreurs/status';

  // ── Endpoints Livraisons ──────────────────────────────────
  static const String availableOrdersEndpoint = '/livraisons/disponibles';
  static const String activeDeliveryEndpoint = '/livraisons/active';
  static const String deliveryHistoryEndpoint = '/livraisons/historique';
  static String acceptOrderUrl(String id) => '$baseUrl/livraisons/$id/accepter';
  static String declineOrderUrl(String id) => '$baseUrl/livraisons/$id/decliner';
  static String updateStatusUrl(String id) => '$baseUrl/livraisons/$id/statut';
  static String deliveryDetailUrl(String id) => '$baseUrl/livraisons/$id';

  // ── Timeouts ──────────────────────────────────────────────
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;

  // ── Headers ───────────────────────────────────────────────
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  static Map<String, String> get formHeaders => {
    'Content-Type': 'application/x-www-form-urlencoded',
    'ngrok-skip-browser-warning': 'true',
  };

  static String getUrl(String endpoint) => '$baseUrl$endpoint';
  static String getIamUrl(String endpoint) => '$iamBaseUrl$endpoint';
  static String getImageUrl(String fileName) => '$baseUrl/files/$fileName';
}
