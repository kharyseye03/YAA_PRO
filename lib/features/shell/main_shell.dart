import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';
import '../../core/constants/constants.dart';
import '../home/home_screen.dart';
import '../orders/orders_screen.dart';
import '../orders/providers/orders_provider.dart';
import '../gains/gains_screen.dart';
import '../profile/profile_screen.dart';

/// Provider global pour l'index du tab actif
final shellIndexProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const List<Widget> _screens = [
    HomeScreen(),
    OrdersScreen(),
    GainsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(shellIndexProvider);
    final ordersCount =
        ref.watch(availableOrdersProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.white,
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _ProBottomNav(
        currentIndex: currentIndex,
        ordersBadge: ordersCount > 0 ? '$ordersCount' : null,
        onTap: (i) => ref.read(shellIndexProvider.notifier).state = i,
      ),
    );
  }
}

// ── Bottom Nav dark pill (style YAA client) ─────────────────────
class _ProBottomNav extends StatelessWidget {
  final int currentIndex;
  final String? ordersBadge;
  final ValueChanged<int> onTap;

  const _ProBottomNav({
    required this.currentIndex,
    required this.ordersBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
      child: Container(
        height: 64.h,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(40.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _NavItem(
              icon: RemixIcons.home_6_fill,
              inactiveIcon: RemixIcons.home_6_line,
              isActive: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: RemixIcons.shopping_bag_2_fill,
              inactiveIcon: RemixIcons.shopping_bag_2_line,
              isActive: currentIndex == 1,
              onTap: () => onTap(1),
              badge: ordersBadge,
            ),
            _NavItem(
              icon: RemixIcons.wallet_3_fill,
              inactiveIcon: RemixIcons.wallet_3_line,
              isActive: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavItem(
              icon: RemixIcons.user_3_fill,
              inactiveIcon: RemixIcons.user_3_line,
              isActive: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData inactiveIcon;
  final bool isActive;
  final VoidCallback onTap;
  final String? badge;

  const _NavItem({
    required this.icon,
    required this.inactiveIcon,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                    horizontal: 14.w, vertical: 8.h),
                child: Icon(
                  isActive ? icon : inactiveIcon,
                  size: 22.r,
                  color: isActive
                      ? AppColors.white
                      : AppColors.white.withValues(alpha: 0.35),
                ),
              ),
              if (badge != null)
                Positioned(
                  top: 2.h,
                  right: 8.w,
                  child: Container(
                    width: 16.r,
                    height: 16.r,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        badge!,
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
