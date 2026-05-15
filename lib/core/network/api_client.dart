import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  late final Dio _dio;
  Dio get dio => _dio;

  void init({required String baseUrl, String? authToken}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (authToken != null) {
      setAuthToken(authToken);
    }

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }

    _dio.interceptors.add(_ErrorInterceptor());
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final message = switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'La connexion a expiré. Vérifiez votre réseau.',
      DioExceptionType.connectionError =>
        'Impossible de se connecter. Vérifiez votre connexion internet.',
      DioExceptionType.badResponse => _handleBadResponse(err.response),
      DioExceptionType.cancel => 'Requête annulée.',
      _ => 'Une erreur est survenue. Veuillez réessayer.',
    };

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        error: message,
        type: err.type,
        response: err.response,
      ),
    );
  }

  String _handleBadResponse(Response? response) {
    if (response == null) return 'Erreur serveur inconnue.';

    return switch (response.statusCode) {
      400 => 'Requête invalide.',
      401 => 'Session expirée. Veuillez vous reconnecter.',
      403 => 'Accès refusé.',
      404 => 'Ressource introuvable.',
      409 => 'Conflit de données.',
      422 => 'Données invalides.',
      429 => 'Trop de requêtes. Réessayez dans un instant.',
      500 || 502 || 503 => 'Erreur serveur. Réessayez plus tard.',
      _ => 'Erreur ${response.statusCode}.',
    };
  }
}
