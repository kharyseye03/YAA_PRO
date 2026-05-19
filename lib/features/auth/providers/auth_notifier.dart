import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 400));
    state = state.copyWith(isLoading: false);
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

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Gardé pour compatibilité avec les imports existants
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});
