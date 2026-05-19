import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/app_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: CustomScrollView(
        slivers: [
          // Header gradient avec avatar
          SliverToBoxAdapter(child: _buildProfileHeader()),

          // Carte infos véhicule
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimens.screenPadding.w,
                AppDimens.lg.h,
                AppDimens.screenPadding.w,
                0,
              ),
              child: _VehicleCard(),
            ),
          ),

          // Stats globales
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimens.screenPadding.w,
                AppDimens.lg.h,
                AppDimens.screenPadding.w,
                0,
              ),
              child: _StatsCard(),
            ),
          ),

          // Menu
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimens.screenPadding.w,
                AppDimens.lg.h,
                AppDimens.screenPadding.w,
                0,
              ),
              child: _MenuCard(),
            ),
          ),

          // Déconnexion
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimens.screenPadding.w,
                AppDimens.lg.h,
                AppDimens.screenPadding.w,
                AppDimens.xl.h,
              ),
              child: OutlinedButton(
                onPressed: () => context.goNamed(RouteNames.login),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: Size(double.infinity, 52.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded,
                        size: 18.r, color: AppColors.error),
                    SizedBox(width: AppDimens.sm.w),
                    Text(
                      'Se déconnecter',
                      style: TextStyle(
                        fontFamily: 'Archivo',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0E3BB8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimens.screenPadding.w,
            AppDimens.xl.h,
            AppDimens.screenPadding.w,
            AppDimens.xxxl.h,
          ),
          child: Column(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 88.r,
                    height: 88.r,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.3),
                          width: 2),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.white.withValues(alpha: 0.7),
                      size: 48.r,
                    ),
                  ),
                  Positioned(
                    bottom: 2.h,
                    right: 2.w,
                    child: Container(
                      width: 26.r,
                      height: 26.r,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: Icon(Icons.check_rounded,
                          color: AppColors.white, size: 14.r),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimens.md.h),

              // Nom
              Text(
                'Mamekh Seye',
                style: TextStyle(
                  fontFamily: 'Archivo',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'mamekharyseye03@gmail.com',
                style: TextStyle(
                  fontFamily: 'Archivo',
                  fontSize: 13.sp,
                  color: AppColors.white.withValues(alpha: 0.65),
                ),
              ),
              SizedBox(height: AppDimens.lg.h),

              // Note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded,
                      color: const Color(0xFFF4C430), size: 20.r),
                  SizedBox(width: 4.w),
                  Text(
                    '4.8',
                    style: TextStyle(
                      fontFamily: 'Archivo',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '(47 avis)',
                    style: TextStyle(
                      fontFamily: 'Archivo',
                      fontSize: 13.sp,
                      color: AppColors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Carte véhicule ──────────────────────────────────────────────
class _VehicleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppDimens.lg.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: Icon(Icons.two_wheeler_rounded,
                    color: AppColors.secondary, size: 20.r),
              ),
              SizedBox(width: AppDimens.md.w),
              Text('Mon véhicule', style: AppTextStyles.labelMedium),
              const Spacer(),
              Icon(Icons.edit_outlined, color: AppColors.grey400, size: 18.r),
            ],
          ),
          SizedBox(height: AppDimens.lg.h),
          _VehicleInfo(label: 'Type', value: 'Moto'),
          _VehicleInfo(label: 'Marque', value: 'Honda CB 125'),
          _VehicleInfo(label: 'Immatriculation', value: 'DK 4421 AB'),
          _VehicleInfo(label: 'Assurance', value: 'N° 8874-2025-MK'),
        ],
      ),
    );
  }
}

class _VehicleInfo extends StatelessWidget {
  final String label;
  final String value;
  const _VehicleInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppDimens.sm.h),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const Spacer(),
          Text(value,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.dark)),
        ],
      ),
    );
  }
}

// ── Carte stats ─────────────────────────────────────────────────
class _StatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppDimens.lg.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistiques globales', style: AppTextStyles.labelMedium),
          SizedBox(height: AppDimens.lg.h),
          Row(
            children: [
              _StatItem(value: '47', label: 'Livraisons', color: AppColors.primary),
              _StatDivider(),
              _StatItem(value: '312 km', label: 'Parcourus', color: AppColors.secondary),
              _StatDivider(),
              _StatItem(value: '4.8 ⭐', label: 'Note moy.', color: const Color(0xFFF4C430)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatItem({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.h4.copyWith(color: color),
              textAlign: TextAlign.center),
          SizedBox(height: 4.h),
          Text(label,
              style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40.h, color: AppColors.grey200);
  }
}

// ── Menu paramètres ─────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  static const _items = [
    _MenuItem(icon: Icons.notifications_outlined, label: 'Notifications', color: AppColors.primary),
    _MenuItem(icon: Icons.language_outlined, label: 'Langue', color: AppColors.secondary),
    _MenuItem(icon: Icons.help_outline_rounded, label: 'Aide & Support', color: AppColors.success),
    _MenuItem(icon: Icons.privacy_tip_outlined, label: 'Confidentialité', color: AppColors.grey600),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final isLast = i == _items.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppDimens.lg.w, vertical: AppDimens.md.h),
                  child: Row(
                    children: [
                      Container(
                        width: 36.r,
                        height: 36.r,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        ),
                        child: Icon(item.icon, color: item.color, size: 18.r),
                      ),
                      SizedBox(width: AppDimens.md.w),
                      Text(item.label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.dark)),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          color: AppColors.grey400, size: 20.r),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: (AppDimens.lg + 36 + AppDimens.md).w,
                  color: AppColors.grey100,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  const _MenuItem({required this.icon, required this.label, required this.color});
}
