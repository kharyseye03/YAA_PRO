import 'package:dio/dio.dart';
import '../../config/api/api_config.dart';
import '../../core/network/api_client.dart';
import '../../model/auth/auth_response.dart';

class ApiService {
  final _dio = ApiClient.instance.dio;

  // ── Auth ──────────────────────────────────────────────────

  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await Dio().post(
        ApiConfig.getIamUrl(ApiConfig.loginEndpoint),
        data: {
          'grant_type': 'password',
          'client_id': 'yaa-pro-app',
          'username': username,
          'password': password,
        },
        options: Options(
          headers: ApiConfig.formHeaders,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Identifiants incorrects.');
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Erreur de connexion.');
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
    required String vehicleType,
    required String brand,
    required String licenseNumber,
    required String plate,
    required String insurance,
    String? carteGrisePath,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.getUrl(ApiConfig.registerEndpoint),
        data: {
          'prenom': firstName,
          'nom': lastName,
          'email': email,
          'telephone': telephone,
          'adresse': address,
          'typeDocument': docType,
          'numeroDocument': docNumber,
          'typeVehicule': vehicleType,
          'marque': brand,
          'numeroPermis': licenseNumber,
          'immatriculation': plate,
          'assurance': insurance,
          'password': password,
        },
        options: Options(headers: ApiConfig.headers),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Erreur lors de l\'inscription.');
      }
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Erreur réseau.');
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.getUrl(ApiConfig.verifyOtpEndpoint),
        data: {'email': email, 'otp': otp},
        options: Options(headers: ApiConfig.headers),
      );

      if (response.statusCode != 200) {
        throw Exception('Code invalide.');
      }
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Erreur réseau.');
    }
  }

  Future<void> createPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.getUrl(ApiConfig.resetPasswordEndpoint),
        data: {'email': email, 'newPassword': newPassword},
        options: Options(headers: ApiConfig.headers),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la création du mot de passe.');
      }
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Erreur réseau.');
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post(
        ApiConfig.getUrl(ApiConfig.forgotPasswordEndpoint),
        data: {'email': email},
        options: Options(headers: ApiConfig.headers),
      );
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Erreur réseau.');
    }
  }

  Future<void> resendCode({required String email}) async {
    try {
      await _dio.post(
        ApiConfig.getUrl(ApiConfig.resendCodeEndpoint),
        data: {'email': email},
        options: Options(headers: ApiConfig.headers),
      );
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Erreur réseau.');
    }
  }

  Future<AuthResponse> refreshToken({required String refreshToken}) async {
    try {
      final response = await Dio().post(
        ApiConfig.getIamUrl(ApiConfig.loginEndpoint),
        data: {
          'grant_type': 'refresh_token',
          'client_id': 'yaa-pro-app',
          'refresh_token': refreshToken,
        },
        options: Options(headers: ApiConfig.formHeaders),
      );

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Session expirée.');
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Erreur réseau.');
    }
  }
}
