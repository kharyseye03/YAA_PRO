import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/constants.dart';

// ── Modèle course ───────────────────────────────────────────────
class _Course {
  final String date;
  final String from;
  final String to;
  final String amount;
  final String category;
  const _Course({
    required this.date,
    required this.from,
    required this.to,
    required this.amount,
    required this.category,
  });
}

// ── Groupe par jour ─────────────────────────────────────────────
class _DayGroup {
  final String label;
  final String total;
  final List<_Course> courses;
  const _DayGroup({
    required this.label,
    required this.total,
    required this.courses,
  });
}

const _groups = [
  _DayGroup(
    label: 'Aujourd\'hui',
    total: '15 500',
    courses: [
      _Course(date: '14h32', from: 'Sandaga', to: 'Keur Gorgui', amount: '2 300', category: 'Restaurant'),
      _Course(date: '11h15', from: 'Plateau', to: 'Mermoz', amount: '1 800', category: 'Boutique'),
      _Course(date: '09h47', from: 'Point E', to: 'Almadies', amount: '3 800', category: 'Pharmacie'),
      _Course(date: '08h10', from: 'Grand Yoff', to: 'Parcelles', amount: '1 500', category: 'Supermarché'),
      _Course(date: '07h55', from: 'Liberté 6', to: 'Fann', amount: '2 100', category: 'Restaurant'),
      _Course(date: '07h20', from: 'Médina', to: 'Sacré Cœur', amount: '4 000', category: 'Boutique'),
    ],
  ),
  _DayGroup(
    label: 'Hier',
    total: '12 200',
    courses: [
      _Course(date: '17h05', from: 'Almadies', to: 'Ngor', amount: '2 500', category: 'Restaurant'),
      _Course(date: '14h30', from: 'Ouakam', to: 'Mermoz', amount: '3 200', category: 'Pharmacie'),
      _Course(date: '10h15', from: 'Plateau', to: 'Hann', amount: '2 100', category: 'Boutique'),
      _Course(date: '08h40', from: 'Liberté 6', to: 'Grand Dakar', amount: '4 400', category: 'Supermarché'),
    ],
  ),
];

// ── Écran ───────────────────────────────────────────────────────
class GainsScreen extends StatefulWidget {
  const GainsScreen({super.key});

  @override
  State<GainsScreen> createState() => _GainsScreenState();
}

class _GainsScreenState extends State<GainsScreen> {
  bool _balanceVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDimens.screenPadding.w,
                  AppDimens.lg.h,
                  AppDimens.screenPadding.w,
                  0,
                ),
                child: Text('Mes gains', style: AppTextStyles.h3),
              ),
            ),
          ),

          // ── Card solde ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimens.screenPadding.w,
                AppDimens.lg.h,
                AppDimens.screenPadding.w,
                0,
              ),
              child: Container(
                padding: EdgeInsets.all(AppDimens.xl.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF0E3BB8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.30),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label + icône portefeuille + œil
                    Row(
                      children: [
                        Text(
                          'Solde disponible',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.65),
                          ),
                        ),
                        const Spacer(),
                        Icon(LucideIcons.wallet,
                            color: AppColors.white.withValues(alpha: 0.5),
                            size: 18.r),
                        SizedBox(width: 10.w),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _balanceVisible = !_balanceVisible),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                            ),
                            child: Icon(
                              _balanceVisible
                                  ? LucideIcons.eye
                                  : LucideIcons.eyeOff,
                              color: AppColors.white,
                              size: 16.r,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimens.sm.h),

                    // Montant principal
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _balanceVisible
                              ? Text(
                                  '47 500',
                                  key: const ValueKey('shown'),
                                  style: TextStyle(
                                    fontFamily: 'Archivo',
                                    fontSize: 38.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white,
                                    height: 1.1,
                                  ),
                                )
                              : Text(
                                  '••••••',
                                  key: const ValueKey('hidden'),
                                  style: TextStyle(
                                    fontFamily: 'Archivo',
                                    fontSize: 38.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white.withValues(alpha: 0.5),
                                    height: 1.1,
                                    letterSpacing: 4,
                                  ),
                                ),
                        ),
                        SizedBox(width: 6.w),
                        Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: Text(
                            'FCFA',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimens.xs.h),

                    // Sous-texte gains aujourd'hui
                    Row(
                      children: [
                        Container(
                          width: 6.r,
                          height: 6.r,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          _balanceVisible
                              ? '+15 500 FCFA aujourd\'hui'
                              : '•••••• FCFA aujourd\'hui',
                          style: TextStyle(
                            fontFamily: 'Archivo',
                            fontSize: 12.sp,
                            color: AppColors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimens.xl.h),

                    // Bouton Retirer
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(LucideIcons.arrowUpFromLine, size: 16.r),
                        label: Text(
                          'Retirer mes gains',
                          style: TextStyle(
                            fontFamily: 'Archivo',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.dark,
                          minimumSize: Size(double.infinity, 48.h),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusMd),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Titre section courses ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimens.screenPadding.w,
                AppDimens.xl.h,
                AppDimens.screenPadding.w,
                AppDimens.md.h,
              ),
              child: Text('Mes courses', style: AppTextStyles.labelLarge),
            ),
          ),

          // ── Liste groupée par jour ──────────────────────────
          for (final group in _groups) ...[
            // Label jour + total
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDimens.screenPadding.w,
                  AppDimens.sm.h,
                  AppDimens.screenPadding.w,
                  AppDimens.sm.h,
                ),
                child: Row(
                  children: [
                    Text(
                      group.label,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.grey600),
                    ),
                    const Spacer(),
                    Text(
                      '+${group.total} FCFA',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              ),
            ),
            // Tiles
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppDimens.screenPadding.w,
                0,
                AppDimens.screenPadding.w,
                AppDimens.md.h,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: EdgeInsets.only(bottom: AppDimens.sm.h),
                    child: _CourseTile(course: group.courses[i]),
                  ),
                  childCount: group.courses.length,
                ),
              ),
            ),
          ],

          SliverToBoxAdapter(child: SizedBox(height: 90.h)),
        ],
      ),
    );
  }
}

// ── Tile course ─────────────────────────────────────────────────
class _CourseTile extends StatelessWidget {
  final _Course course;
  const _CourseTile({required this.course});

  static ({Color bg, Color icon}) _catColor(String cat) =>
      switch (cat.toLowerCase()) {
        'restaurant'  => (bg: AppColors.catRestaurantLight, icon: AppColors.catRestaurant),
        'pharmacie'   => (bg: AppColors.catPharmacieLight,  icon: AppColors.catPharmacie),
        'boutique'    => (bg: AppColors.catBoutiqueLight,   icon: AppColors.catBoutique),
        'supermarché' => (bg: AppColors.catSupermarcheLight,icon: AppColors.catSupermarche),
        _             => (bg: AppColors.primarySurface,     icon: AppColors.primary),
      };

  static IconData _catIcon(String cat) =>
      switch (cat.toLowerCase()) {
        'restaurant'  => Icons.restaurant_rounded,
        'pharmacie'   => Icons.local_pharmacy_rounded,
        'boutique'    => Icons.shopping_bag_rounded,
        'supermarché' => Icons.shopping_cart_rounded,
        _             => Icons.local_shipping_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final cc = _catColor(course.category);

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppDimens.md.w, vertical: AppDimens.md.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône catégorie
          Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              color: cc.bg,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: Icon(_catIcon(course.category),
                color: cc.icon, size: 20.r),
          ),
          SizedBox(width: AppDimens.md.w),

          // Trajet
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${course.from} → ${course.to}',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.dark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3.h),
                Text(course.date, style: AppTextStyles.caption),
              ],
            ),
          ),

          // Montant
          Text(
            '+${course.amount} F',
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}
