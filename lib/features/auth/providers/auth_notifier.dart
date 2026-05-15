import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../service/api/api_service.dart';
import 'auth_state.dart';

const _tokenKey = 'access_token';
const _refreshTokenKey = 'refresh_token';
const _emailKey = 'user_email';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._prefs)
      : super(AuthState(isAuthenticated: _prefs.containsKey(_tokenKey)));

  final SharedPreferences _prefs;

  String? get token => _prefs.getString(_tokenKey);
  String? get email => _prefs.getString(_emailKey);

  static Map<String, dynamic>? decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      final padding = payload.length % 4;
      if (padding != 0) payload += '=' * (4 - padding);
      final decoded = utf8.decode(base64.decode(payload));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JWT decode error: $e');
      return null;
    }
  }

  static String? _extractEmailFromJwt(String token) =>
      decodeJwtPayload(token)?['email'] as String?;

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ApiService().login(
        username: username,
        password: password,
      );
      await _prefs.setString(_tokenKey, response.accessToken);
      await _prefs.setString(_refreshTokenKey, response.refreshToken);

      final emailFromToken = _extractEmailFromJwt(response.accessToken);
      if (emailFromToken != null) {
        await _prefs.setString(_emailKey, emailFromToken);
      }

      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Inscription livreur — champs spécifiques au livreur.
  Future<bool> registerDriver({
    required String firstName,
    required String lastName,
    required String email,
    required String telephone,
    required String vehicleType,
    required String vehiclePlate,
    required String licenseNumber,
    required String cniNumber,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ApiService().registerDriver(
        firstName: firstName,
        lastName: lastName,
        email: email,
        telephone: telephone,
        vehicleType: vehicleType,
        vehiclePlate: vehiclePlate,
        licenseNumber: licenseNumber,
        cniNumber: cniNumber,
      );
      await _prefs.setString(_emailKey, email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ApiService().verifyOtp(email: email, otp: otp);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> createPassword({
    required String email,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ApiService().createPassword(email: email, newPassword: newPassword);
      await _prefs.setString(_emailKey, email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ApiService().forgotPassword(email: email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> resendCode({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ApiService().resendCode(email: email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> refreshToken() async {
    final storedRefreshToken = _prefs.getString(_refreshTokenKey);
    if (storedRefreshToken == null) {
      await logout();
      return false;
    }
    try {
      final response = await ApiService().refreshToken(
        refreshToken: storedRefreshToken,
      );
      await _prefs.setString(_tokenKey, response.accessToken);
      await _prefs.setString(_refreshTokenKey, response.refreshToken);
      final emailFromToken = _extractEmailFromJwt(response.accessToken);
      if (emailFromToken != null) {
        await _prefs.setString(_emailKey, emailFromToken);
      }
      return true;
    } catch (e) {
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_emailKey);
    state = const AuthState();
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in main.dart');
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthNotifier(prefs);
});
