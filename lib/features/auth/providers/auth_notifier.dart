import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_state.dart';

const _tokenKey = 'access_token';
const _emailKey = 'user_email';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._prefs)
      : super(AuthState(isAuthenticated: _prefs.containsKey(_tokenKey)));

  final SharedPreferences _prefs;

  String? get email => _prefs.getString(_emailKey);

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 500));
    await _prefs.setString(_tokenKey, 'mock_token');
    await _prefs.setString(_emailKey, username);
    state = state.copyWith(isLoading: false, isAuthenticated: true);
    return true;
  }

  Future<bool> registerDriver({
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
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 500));
    await _prefs.setString(_emailKey, email);
    state = state.copyWith(isLoading: false);
    return true;
  }

  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(isLoading: false, isAuthenticated: true);
    await _prefs.setString(_tokenKey, 'mock_token');
    return true;
  }

  Future<bool> createPassword({
    required String email,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 500));
    await _prefs.setString(_emailKey, email);
    state = state.copyWith(isLoading: false);
    return true;
  }

  Future<bool> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(isLoading: false);
    return true;
  }

  Future<bool> resendCode({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(isLoading: false);
    return true;
  }

  Future<void> logout() async {
    await _prefs.remove(_tokenKey);
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
