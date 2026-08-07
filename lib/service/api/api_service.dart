import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../config/api/api_config.dart';
import '../../model/auth/auth_response.dart';
import '../../model/driver/driver_detail.dart';
import '../../model/gains/gains_summary.dart';
import '../../model/order/history_mission.dart';
import '../../model/order/mission.dart';
import '../storage/token_storage.dart';

class ApiService {
  // ── Session ───────────────────────────────────────────────

  /// Renouvellement en cours, partagé par tous les appels : si
  /// plusieurs requêtes expirent en même temps, une seule demande
  /// un nouveau token et les autres attendent son résultat.
  Future<String>? _refreshing;

  /// Access token valide, renouvelé si nécessaire.
  /// `null` si la session ne peut plus être prolongée.
  Future<String?> _validToken() async {
    if (await TokenStorage.instance.hasValidToken()) {
      return TokenStorage.instance.getAccessToken();
    }
    return _renewToken();
  }

  Future<String?> _renewToken() async {
    _refreshing ??=
        _performRefresh().whenComplete(() => _refreshing = null);
    try {
      return await _refreshing;
    } catch (e) {
      debugPrint('🔒 Refresh impossible → $e');
      return null;
    }
  }

  Future<String> _performRefresh() async {
    final refresh = await TokenStorage.instance.getRefreshToken();
    if (refresh == null) throw Exception('Aucun refresh token.');
    debugPrint('🔄 Renouvellement du token…');
    final auth = await refreshToken(refreshToken: refresh);
    await TokenStorage.instance.saveTokens(auth);
    debugPrint('🔄 Token renouvelé');
    return auth.accessToken;
  }

  /// Exécute une requête authentifiée.
  ///
  /// Le token est renouvelé en amont s'il a expiré, et la requête est
  /// rejouée une fois si le serveur répond quand même 401 (token
  /// révoqué côté Keycloak, horloge décalée…).
  Future<http.Response> _authed(
    Future<http.Response> Function(String token) send,
  ) async {
    var token = await _validToken();
    if (token == null) throw _sessionExpired();

    var response = await send(token);
    if (response.statusCode != 401) return response;

    debugPrint('🔒 401 reçu → nouvelle tentative après renouvellement');
    token = await _renewToken();
    if (token == null) throw _sessionExpired();

    response = await send(token);
    if (response.statusCode == 401) throw _sessionExpired();
    return response;
  }

  /// La session ne peut plus être prolongée.
  ///
  /// On n'efface surtout pas le stockage ici : cette méthode peut être
  /// appelée par une requête restée en vol pendant que l'utilisateur
  /// se reconnecte, et elle effacerait les tokens tout juste
  /// enregistrés. Le nettoyage est fait à la déconnexion et au
  /// démarrage (tryAutoLogin).
  Exception _sessionExpired() =>
      Exception('Session expirée. Reconnectez-vous.');

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
          'client_id': ApiConfig.keycloakClientId,
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
          'client_id': ApiConfig.keycloakClientId,
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

  /// Missions disponibles pour le coursier (nécessite le Bearer token).
  ///
  /// [rayon] en mètres, [tri] valeur d'enum backend (ex: MIEUX_PAYE),
  /// [typeService] LIVRAISON ou COURSE.
  Future<List<Mission>> getAvailableOrders({
    double? latitude,
    double? longitude,
    int? rayon,
    String? tri,
    String? typeService,
    int? limit,
  }) async {
    final params = <String, String>{
      if (latitude != null) 'latitude': '$latitude',
      if (longitude != null) 'longitude': '$longitude',
      if (rayon != null) 'rayon': '$rayon',
      if (tri != null) 'tri': tri,
      if (typeService != null) 'typeService': typeService,
      if (limit != null) 'limit': '$limit',
    };
    final uri = Uri.parse(ApiConfig.getUrl(ApiConfig.availableOrdersEndpoint))
        .replace(queryParameters: params.isEmpty ? null : params);
    final url = uri.toString();

    try {
      debugPrint('🌐 GET $url');
      final response = await _authed((token) => http.get(
            uri,
            headers: {'Authorization': 'Bearer $token'},
          ));

      debugPrint('📡 Status → ${response.statusCode}');
      debugPrint('📬 Body → ${response.body}');

      if (response.statusCode == 200) {
        // Réponse enveloppée : { data: [...], message, status, success }
        final decoded = jsonDecode(response.body);
        debugPrint('🔍 Type racine → ${decoded.runtimeType}');

        final List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map<String, dynamic>) {
          debugPrint('🔍 Clés racine → ${decoded.keys.toList()}');
          final data = decoded['data'];
          debugPrint('🔍 Type data → ${data.runtimeType}');
          list = data is List ? data : [];
        } else {
          list = [];
        }

        debugPrint('📦 ${list.length} mission(s) à parser');

        final missions = <Mission>[];
        for (int i = 0; i < list.length; i++) {
          try {
            missions.add(Mission.fromJson(list[i] as Map<String, dynamic>));
          } catch (e) {
            debugPrint('❌ Parsing mission #$i échoué : $e');
            debugPrint('❌ JSON fautif → ${list[i]}');
            rethrow;
          }
        }
        debugPrint('✅ ${missions.length} mission(s) parsée(s)');
        return missions;
      }
      throw Exception(
          'Impossible de charger les commandes (${response.statusCode}).');
    } on http.ClientException catch (e) {
      debugPrint('❌ ClientException → $e');
      throw Exception(
          'Impossible de se connecter. Vérifiez votre connexion.');
    } catch (e, stack) {
      debugPrint('❌ Erreur getAvailableOrders → $e');
      debugPrint('❌ Stack → $stack');
      rethrow;
    }
  }

  /// Détail complet d'une mission (contacts, adresses, statut).
  Future<Mission> getMissionDetail(int missionId) async {
    final url = ApiConfig.getUrl(ApiConfig.missionDetailEndpoint(missionId));
    try {
      debugPrint('🌐 GET $url');
      final response = await _authed((token) => http.get(
            Uri.parse(url),
            headers: {'Authorization': 'Bearer $token'},
          ));
      debugPrint('📡 Status → ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'];
        if (data is Map<String, dynamic>) return Mission.fromJson(data);
        throw Exception('Mission introuvable.');
      }
      throw Exception(_errorMessage(
          response, 'Impossible de charger la mission (${response.statusCode}).'));
    } on http.ClientException {
      throw Exception(
          'Impossible de se connecter. Vérifiez votre connexion.');
    }
  }

  /// Accepte une mission (le coursier s'y assigne).
  Future<Mission> acceptMission(int missionId) async {
    final url = ApiConfig.getUrl(ApiConfig.acceptMissionEndpoint(missionId));
    try {
      final token = await TokenStorage.instance.getAccessToken();
      if (token == null) throw Exception('Non connecté.');

      debugPrint('🌐 PATCH $url');
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📡 Status → ${response.statusCode}');
      debugPrint('📬 Body → ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          return Mission.fromJson(data);
        }
        throw Exception('Réponse inattendue du serveur.');
      }
      if (response.statusCode == 401) {
        throw Exception('Session expirée. Reconnectez-vous.');
      }
      if (response.statusCode == 409) {
        throw Exception('Cette mission a déjà été acceptée.');
      }
      throw Exception(_errorMessage(
          response, 'Impossible d\'accepter la mission (${response.statusCode}).'));
    } on http.ClientException {
      throw Exception(
          'Impossible de se connecter. Vérifiez votre connexion.');
    }
  }

  /// Marque le colis comme récupéré : la mission passe en
  /// PRISE_EN_CHARGE_EFFECTUEE et le livreur part vers la livraison.
  Future<Mission> pickupMission(int missionId) => _patchMission(
        ApiConfig.pickupMissionEndpoint(missionId),
        'Impossible de confirmer la récupération',
      );

  /// Clôture la mission : passage en COURSE_TERMINEE.
  Future<Mission> deliverMission(int missionId) => _patchMission(
        ApiConfig.deliverMissionEndpoint(missionId),
        'Impossible de confirmer la livraison',
      );

  /// Fait avancer une mission via un PATCH et retourne son nouvel état.
  Future<Mission> _patchMission(String endpoint, String errorLabel) async {
    final url = ApiConfig.getUrl(endpoint);
    try {
      debugPrint('🌐 PATCH $url');
      final response = await _authed((token) => http.patch(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ));

      debugPrint('📡 Status → ${response.statusCode}');
      debugPrint('📬 Body → ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'];
        if (data is Map<String, dynamic>) return Mission.fromJson(data);
        throw Exception('Réponse inattendue du serveur.');
      }
      throw Exception(
          _errorMessage(response, '$errorLabel (${response.statusCode}).'));
    } on http.ClientException {
      throw Exception(
          'Impossible de se connecter. Vérifiez votre connexion.');
    }
  }

  /// Historique des missions du livreur, avec le détail des gains.
  Future<List<HistoryMission>> getAllMissions() async {
    final url = ApiConfig.getUrl(ApiConfig.allMissionsEndpoint);
    try {
      debugPrint('🌐 GET $url');
      final response = await _authed((token) => http.get(
            Uri.parse(url),
            headers: {'Authorization': 'Bearer $token'},
          ));
      debugPrint('📡 Status → ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final list = body['data'] as List<dynamic>? ?? [];
        return list
            .map((e) => HistoryMission.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception(_errorMessage(response,
          'Impossible de charger l\'historique (${response.statusCode}).'));
    } on http.ClientException {
      throw Exception(
          'Impossible de se connecter. Vérifiez votre connexion.');
    }
  }

  // ── Gains ─────────────────────────────────────────────────

  /// Gains du livreur et historique de ses missions terminées.
  ///
  /// [typeService] : LIVRAISON, COURSE ou LIVRAISON_COMMANDE.
  /// [dateDebut] / [dateFin] : bornes au format `2026-07-28`.
  Future<GainsSummary> getGains({
    String? typeService,
    String? dateDebut,
    String? dateFin,
  }) async {
    final params = <String, String>{
      if (typeService != null) 'typeService': typeService,
      if (dateDebut != null) 'dateDebut': dateDebut,
      if (dateFin != null) 'dateFin': dateFin,
    };
    final url = Uri.parse(ApiConfig.getUrl(ApiConfig.gainsEndpoint))
        .replace(queryParameters: params.isEmpty ? null : params)
        .toString();
    try {
      debugPrint('🌐 GET $url');
      final response = await _authed((token) => http.get(
            Uri.parse(url),
            headers: {'Authorization': 'Bearer $token'},
          ));
      debugPrint('📡 Status → ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'];
        if (data is Map<String, dynamic>) return GainsSummary.fromJson(data);
        return GainsSummary.empty;
      }
      throw Exception(_errorMessage(
          response, 'Impossible de charger vos gains (${response.statusCode}).'));
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
