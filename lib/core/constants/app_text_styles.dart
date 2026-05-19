import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static const String _fontFamily = 'Archivo';

  // ── Headings ─────────────────────────────────────────────
  static TextStyle get h1 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 28.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.dark,
        height: 1.3,
      );

  static TextStyle get h2 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.dark,
        height: 1.3,
      );

  static TextStyle get h3 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.dark,
        height: 1.3,
      );

  static TextStyle get h4 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.dark,
        height: 1.4,
      );

  // ── Body ─────────────────────────────────────────────────
  static TextStyle get bodyLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.grey800,
        height: 1.5,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.grey800,
        height: 1.5,
      );

  static TextStyle get bodySmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.grey600,
        height: 1.5,
      );

  // ── Labels & Buttons ─────────────────────────────────────
  static TextStyle get labelLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.dark,
        height: 1.4,
      );

  static TextStyle get labelMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.dark,
        height: 1.4,
      );

  static TextStyle get labelSmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.grey700,
        height: 1.4,
      );

  static TextStyle get button => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
        height: 1.4,
        letterSpacing: 0.3,
      );

  // ── Caption & Overline ───────────────────────────────────
  static TextStyle get caption => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 11.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.grey500,
        height: 1.4,
      );

  static TextStyle get overline => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 10.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.grey500,
        height: 1.4,
        letterSpacing: 1.2,
      );

  // ── Price / Earning Styles ────────────────────────────────
  static TextStyle get priceLarge => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 22.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        height: 1.3,
      );

  static TextStyle get priceMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        height: 1.3,
      );

  static TextStyle get priceSmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        height: 1.3,
      );
}
