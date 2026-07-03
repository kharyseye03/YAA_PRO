import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/forgot_verification_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/auth/verification_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/delivery/delivery_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/profile/personal_info_screen.dart';
import '../../features/profile/edit_personal_info_screen.dart';
import '../../features/starter/onboarding/onboarding_screen.dart';
import '../../features/starter/splash/splash_screen.dart';

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
  static const String orderDetail = '/order-detail';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String personalInfo = '/personal-info';
  static const String editPersonalInfo = '/edit-personal-info';
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
  static const String orderDetail = 'orderDetail';
  static const String history = 'history';
  static const String profile = 'profile';
  static const String personalInfo = 'personalInfo';
  static const String editPersonalInfo = 'editPersonalInfo';
}

final appRouter = GoRouter(
  initialLocation: RoutePaths.splash,
  debugLogDiagnostics: false,
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
        email: state.extra as String? ?? '',
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
        email: state.extra as String? ?? '',
      ),
    ),
    GoRoute(
      path: RoutePaths.resetPassword,
      name: RouteNames.resetPassword,
      builder: (context, state) => ResetPasswordScreen(
        email: state.extra as String? ?? '',
      ),
    ),

    // ── Main shell (bottom nav) ────────────────────────────
    GoRoute(
      path: RoutePaths.home,
      name: RouteNames.home,
      builder: (context, state) => const MainShell(),
    ),
    GoRoute(
      path: RoutePaths.delivery,
      name: RouteNames.delivery,
      builder: (context, state) => const DeliveryScreen(),
    ),
    GoRoute(
      path: RoutePaths.orderDetail,
      name: RouteNames.orderDetail,
      builder: (context, state) => OrderDetailScreen(
        order: state.extra as OrderDetailArgs?,
      ),
    ),

    // ── Profil ─────────────────────────────────────────────
    GoRoute(
      path: RoutePaths.personalInfo,
      name: RouteNames.personalInfo,
      builder: (context, state) => const PersonalInfoScreen(),
    ),
    GoRoute(
      path: RoutePaths.editPersonalInfo,
      name: RouteNames.editPersonalInfo,
      builder: (context, state) => const EditPersonalInfoScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Page introuvable: ${state.uri}')),
  ),
);
