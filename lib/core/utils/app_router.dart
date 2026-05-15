import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/forgot_verification_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/auth/verification_screen.dart';
import '../../features/auth/providers/auth_notifier.dart';
import '../../features/home/home_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/delivery/delivery_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/starter/onboarding/onboarding_screen.dart';
import '../../features/starter/splash/splash_screen.dart';

const _protectedRoutes = {
  '/home', '/orders', '/delivery', '/history', '/profile',
};

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

abstract final class RoutePaths {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String verification = '/verification';
  static const String forgotPassword = '/forgot-password';
  static const String forgotVerification = '/forgot-verification';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String orders = '/orders';
  static const String delivery = '/delivery';
  static const String history = '/history';
  static const String profile = '/profile';
}

abstract final class RouteNames {
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String register = 'register';
  static const String verification = 'verification';
  static const String forgotPassword = 'forgotPassword';
  static const String forgotVerification = 'forgotVerification';
  static const String resetPassword = 'resetPassword';
  static const String home = 'home';
  static const String orders = 'orders';
  static const String delivery = 'delivery';
  static const String history = 'history';
  static const String profile = 'profile';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    refreshListenable: _RouterNotifier(ref),
    redirect: (context, state) {
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      final location = state.matchedLocation;
      if (!isAuthenticated && _protectedRoutes.contains(location)) {
        return RoutePaths.login;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── Auth ───────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.verification,
        name: RouteNames.verification,
        builder: (context, state) => VerificationScreen(
          email: state.extra as String,
        ),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotVerification,
        name: RouteNames.forgotVerification,
        builder: (context, state) => ForgotVerificationScreen(
          email: state.extra as String,
        ),
      ),
      GoRoute(
        path: RoutePaths.resetPassword,
        name: RouteNames.resetPassword,
        builder: (context, state) => ResetPasswordScreen(
          email: state.extra as String,
        ),
      ),

      // ── Main ───────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.orders,
        name: RouteNames.orders,
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: RoutePaths.delivery,
        name: RouteNames.delivery,
        builder: (context, state) => const DeliveryScreen(),
      ),
      GoRoute(
        path: RoutePaths.history,
        name: RouteNames.history,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: RoutePaths.profile,
        name: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page introuvable: ${state.uri}')),
    ),
  );
});
