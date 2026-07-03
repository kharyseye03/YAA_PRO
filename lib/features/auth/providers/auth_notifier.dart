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

  // ── Mocks : APIs pas encore fournies ────────────────────────

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
    await Future.delayed(const Duration(milliseconds: 400));
    state = state.copyWith(isLoading: false);
    return true;
  }

  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 400));
    state = state.copyWith(isLoading: false);
    return true;
  }

  Future<bool> createPassword({
    required String email,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 400));
    state = state.copyWith(isLoading: false);
    return true;
  }

  Future<bool> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 400));
    state = state.copyWith(isLoading: false);
    return true;
  }

  Future<bool> resendCode({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 400));
    state = state.copyWith(isLoading: false);
    return true;
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
