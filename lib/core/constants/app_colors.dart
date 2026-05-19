import 'dart:ui';

abstract final class AppColors {
  // ── Primary ──────────────────────────────────────────────
  static const Color primary = Color(0xFF1A1A2E);
  static const Color primaryLight = Color(0xFF2A2A45);
  static const Color primaryDark = Color(0xFF121220);
  static const Color primarySurface = Color(0xFFF0F1F7);
  //static const Color primarySurface = Color(0xFFE8EEFE);

  // ── Secondary / Accent ───────────────────────────────────
  static const Color secondary = Color(0xFFFF6B35);
  static const Color secondaryLight = Color(0xFFFF9A6C);
  static const Color secondaryDark = Color(0xFFCC5529);

  // ── Neutrals ─────────────────────────────────────────────
  static const Color black = Color(0xFF000000);
  static const Color dark = Color(0xFF1A1A2E);
  static const Color grey900 = Color(0xFF212121);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);

  // ── Background & Surface ─────────────────────────────────
  static const Color background = Color(0xFFF8F9FD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color scaffold = Color(0xFFF8F9FD);

  // ── Semantic ─────────────────────────────────────────────
  static const Color success = Color(0xFF27AE60);
  static const Color successLight = Color(0xFFE8F8EF);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFFEF5E7);
  static const Color error = Color(0xFFE74C3C);
  static const Color errorLight = Color(0xFFFDECEB);
  static const Color info = Color(0xFF4F7CFF);
  static const Color infoLight = Color(0xFFE9F0FD);

  // ── Delivery Status Colors ───────────────────────────────
  static const Color statusPending = Color(0xFFF39C12);
  static const Color statusAccepted = Color(0xFF2F80ED);
  static const Color statusPickup = Color(0xFF9B59B6);
  static const Color statusDelivered = Color(0xFF27AE60);
  static const Color statusCancelled = Color(0xFFE74C3C);

  // ── Category Colors ──────────────────────────────────────
  static const Color catRestaurant      = Color(0xFFFF6B35);
  static const Color catRestaurantLight = Color(0xFFFFF0EB);
  static const Color catPharmacie       = Color(0xFF27AE60);
  static const Color catPharmacieLight  = Color(0xFFE8F8EF);
  static const Color catBoutique        = Color(0xFF9B59B6);
  static const Color catBoutiqueLight   = Color(0xFFF3EAF8);
  static const Color catSupermarche     = Color(0xFF00ACC1);
  static const Color catSupermarcheLight= Color(0xFFE0F7FA);
}
