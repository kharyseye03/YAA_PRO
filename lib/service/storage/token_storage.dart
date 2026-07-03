import 'package:shared_preferences/shared_preferences.dart';
import '../../model/auth/auth_response.dart';

/// Stockage local des tokens d'authentification.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kExpiresAt = 'expires_at';
  static const _kPhone = 'user_phone';

  Future<void> savePhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPhone, phone);
  }

  Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPhone);
  }

  Future<void> saveTokens(AuthResponse auth) async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAt = DateTime.now()
        .add(Duration(seconds: auth.expiresIn))
        .millisecondsSinceEpoch;
    await prefs.setString(_kAccessToken, auth.accessToken);
    await prefs.setString(_kRefreshToken, auth.refreshToken);
    await prefs.setInt(_kExpiresAt, expiresAt);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAccessToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRefreshToken);
  }

  /// True si le token existe et n'est pas expiré (marge de 30s).
  Future<bool> hasValidToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kAccessToken);
    final expiresAt = prefs.getInt(_kExpiresAt);
    if (token == null || expiresAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch < expiresAt - 30 * 1000;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kExpiresAt);
    await prefs.remove(_kPhone);
  }
}
