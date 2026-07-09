import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../config/api/api_config.dart';
import '../../model/auth/auth_response.dart';
import '../../model/driver/driver_detail.dart';
import '../../model/order/commande_livraison.dart';
import '../storage/token_storage.dart';

class ApiService {
  // ── Auth ──────────────────────────────────────────────────

  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getIamUrl(ApiConfig.loginEndpoint)),
        headers: ApiConfig.formHeaders,
        body: {
          'grant_type': 'password',
          'client_id': 'yaa',
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      if (response.statusCode == 401 || response.statusCode == 400) {
        throw Exception('Identifiants incorrects.');
      }
      throw Exception('Erreur serveur (${response.statusCode}).');
    } on http.ClientException {
      throw Exception(
          'Impossible de se connecter. Vérifiez votre connexion.');
    }
  }

  Future<AuthResponse> refreshToken({required String refreshToken}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getIamUrl(ApiConfig.loginEndpoint)),
        headers: ApiConfig.formHeaders,
        body: {
          'grant_type': 'refresh_token',
          'client_id': 'yaa',
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      throw Exception('Session expirée.');
    } on http.ClientException {
      throw Exception(
          'Impossible de se connecter. Vérifiez votre connexion.');
    }
  }

  // ── Inscription ───────────────────────────────────────────

  /// Extrait le message d'erreur du body de réponse si présent.
  String _errorMessage(http.Response response, String fallback) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['message'] as String? ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> registerDriver({
    required String firstName,
    required String lastName,
    required String email,
    required String telephone,
    required String address,
    required String docType,
    required String docNumber,
    required String vehicule,
    required String brand,
    required String licenseNumber,
    required String plate,
    required String insurance,
    required String couleur,
    required String carteGrise,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl(ApiConfig.registerEndpoint)),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'telephone': telephone,
          'adresseHabitation': address,
          'vehicule': vehicule,
          'type': docType,
          'pieceNumber': docNumber,
          'marque': brand,
          'immatriculation': plate,
          'assurance': insurance,
          'permis': licenseNumber,
          'couleur': couleur,
          'carteGrise': carteGrise,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }
      throw Exception(_errorMessage(
          response, 'Erreur lors de l\'inscription (${response.statusCode}).'));
    } on http.ClientException {
      throw Exception(
          'Impossible de se connecter. Vérifiez votre connexion.');
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl(ApiConfig.verifyOtpEndpoint)),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }
      throw Exception(_errorMessage(response, 'Code invalide.'));
    } on http.ClientException {
      throw Exception(
          'Impossible de se connecter. Vérifiez votre connexion.');
    }
  }

  Future<void> createPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl(ApiConfig.resetPasswordEndpoint)),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({'email': email, 'newPassword': newPassword}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }
      throw Exception(_errorMessage(
          response, 'Erreur lors de la création du mot de passe.'));
    } on http.ClientException {
      throw Exception(
          'Impossible de se connecter. Vérifiez votre connexion.');
    }
  }

  Future<void> forgotPassword({
    required String email,
    required String telephone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl(ApiConfig.forgotPasswordEndpoint)),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({'email': email, 'telephone': telephone}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }
      throw Exception(_errorMessage(
          response, 'Erreur lors de l\'envoi du code (${response.statusCode}).'));
    } on http.ClientException {
      throw Exception(
          'Impossible de se connecter. Vérifiez votre connexion.');
    }
  }

  Future<void> resendCode({
    required String email,
    required String telephone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl(ApiConfig.resendCodeEndpoint)),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({'email': email, 'telephone': telephone}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }
      throw Exception(_errorMessage(
          response, 'Impossible de renvoyer le code (${response.statusCode}).'));
    } on http.ClientException {
      throw Exception(
          'Impossible de se connecter. Vérifiez votre connexion.');
    }
  }

  // ── Livreur ───────────────────────────────────────────────

  Future<DriverDetail> getDriverDetail({required String telephone}) async {
    try {
      final uri = Uri.parse(
              ApiConfig.getUrl(ApiConfig.driverDetailEndpoint))
          .replace(queryParameters: {'telephone': telephone});
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return DriverDetail.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      throw Exception('Impossible de charger le profil.');
    } on http.ClientException {
      throw Exception(
          'Impossible de se connecter. Vérifiez votre connexion.');
    }
  }

  // ── Commandes ─────────────────────────────────────────────

  /// Commandes disponibles pour livraison (nécessite le Bearer token).
  Future<List<CommandeLivraison>> getAvailableOrders() async {
    try {
      final token = await TokenStorage.instance.getAccessToken();
      if (token == null) throw Exception('Non connecté.');

      final response = await http.get(
        Uri.parse(ApiConfig.getUrl(ApiConfig.availableOrdersEndpoint)),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((e) =>
                CommandeLivraison.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Reconnectez-vous.');
      }
      throw Exception(
          'Impossible de charger les commandes (${response.statusCode}).');
    } on http.ClientException {
      throw Exception(
          'Impossible de se connecter. Vérifiez votre connexion.');
    }
  }

  Future<void> updateProfile({
    required String email,
    required String firstName,
    required String lastName,
    required String telephone,
    String? imagePath,
  }) async {
    try {
      final uri =
          Uri.parse(ApiConfig.getUrl(ApiConfig.updateProfileEndpoint));
      final request = http.MultipartRequest('PUT', uri)
        ..fields['firstName'] = firstName
        ..fields['lastName'] = lastName
        ..fields['email'] = email
        ..fields['telephone'] = telephone;

      if (imagePath != null) {
        final ext = imagePath.split('.').last.toLowerCase();
        final mimeType = switch (ext) {
          'jpg' || 'jpeg' => 'image/jpeg',
          'png' => 'image/png',
          'gif' => 'image/gif',
          'webp' => 'image/webp',
          _ => 'image/jpeg',
        };
        final parts = mimeType.split('/');
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imagePath,
            contentType: MediaType(parts[0], parts[1]),
          ),
        );
      }

      final streamed = await request.send().timeout(
            const Duration(seconds: ApiConfig.connectionTimeout),
            onTimeout: () =>
                throw TimeoutException('Le serveur ne répond pas.'),
          );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      Map<String, dynamic> data = {};
      if (response.body.isNotEmpty) {
        try {
          data = json.decode(response.body) as Map<String, dynamic>;
        } catch (_) {}
      }
      final errorMessage =
          data['message'] as String? ?? 'Erreur ${response.statusCode}';
      throw Exception(errorMessage);
    } on SocketException {
      throw Exception('Pas de connexion internet.');
    } on TimeoutException catch (e) {
      throw Exception(e.message);
    }
  }
}
