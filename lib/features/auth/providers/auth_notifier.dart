import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../service/api/api_service.dart';
import '../../../service/storage/token_storage.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._api) : super(const AuthState());

  final ApiService _api;

  String _cleanError(Object e) =>
      e.toString().replaceFirst('Exception: ', '');

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final auth = await _api.login(username: username, password: password);
      await TokenStorage.instance.saveTokens(auth);
      await TokenStorage.instance.savePhone(username);
      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _cleanError(e));
      return false;
    }
  }

  /// Restaure la session au démarrage (splash) : token encore
  /// valide ou refresh, sinon retour au parcours de connexion.
  Future<bool> tryAutoLogin() async {
    try {
      if (await TokenStorage.instance.hasValidToken()) {
        state = state.copyWith(isAuthenticated: true);
        return true;
      }
      final refresh = await TokenStorage.instance.getRefreshToken();
      if (refresh == null) return false;
      final auth = await _api.refreshToken(refreshToken: refresh);
      await TokenStorage.instance.saveTokens(auth);
      state = state.copyWith(isAuthenticated: true);
      return true;
    } catch (_) {
      await TokenStorage.instance.clear();
      return false;
    }
  }

  Future<void> logout() async {
    await TokenStorage.instance.clear();
    state = const AuthState();
  }

  Future<bool> registerDriver({
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
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.registerDriver(
        firstName: firstName,
        lastName: lastName,
        email: email,
        telephone: telephone,
        address: address,
        docType: docType,
        docNumber: docNumber,
        vehicule: vehicule,
        brand: brand,
        licenseNumber: licenseNumber,
        plate: plate,
        insurance: insurance,
        couleur: couleur,
        carteGrise: carteGrise,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _cleanError(e));
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.verifyOtp(email: email, otp: otp);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _cleanError(e));
      return false;
    }
  }

  Future<bool> createPassword({
    required String email,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.createPassword(email: email, newPassword: newPassword);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _cleanError(e));
      return false;
    }
  }

  Future<bool> forgotPassword({
    required String email,
    required String telephone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.forgotPassword(email: email, telephone: telephone);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _cleanError(e));
      return false;
    }
  }

  Future<bool> resendCode({
    required String email,
    required String telephone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.resendCode(email: email, telephone: telephone);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _cleanError(e));
      return false;
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiServiceProvider));
});

// Gardé pour compatibilité avec les imports existants
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});
