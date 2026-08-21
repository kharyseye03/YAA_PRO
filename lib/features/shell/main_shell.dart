import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/auto_refresh.dart';
import '../auth/providers/driver_provider.dart';
import '../delivery/delivery_screen.dart';
import '../delivery/providers/active_mission_provider.dart';
import '../home/home_screen.dart';
import '../home/providers/location_provider.dart';
import '../orders/orders_screen.dart';
import '../orders/providers/orders_provider.dart';
import '../gains/gains_screen.dart';
import '../gains/providers/gains_provider.dart';
import '../profile/profile_screen.dart';

/// Provider global pour l'index du tab actif
final shellIndexProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with AutoRefreshMixin {
  static const List<Widget> _screens = [
    HomeScreen(),
    OrdersScreen(),
    GainsScreen(),
    ProfileScreen(),
  ];

  /// Les commandes disponibles apparaissent sans action du livreur :
  /// elles sont rechargées en continu depuis le shell, qui survit aux
  /// changements d'onglet.
  @override
  List<ProviderOrFamily> get autoRefreshTargets => [
        allOrdersProvider,
        availableOrdersProvider,
      ];

  /// Données rechargées en arrivant sur un onglet, pour ne jamais
  /// ouvrir un écran sur un affichage périmé.
  static final Map<int, List<ProviderOrFamily>> _onEnter = {
    0: [allOrdersProvider],
    1: [allOrdersProvider, availableOrdersProvider],
    2: [gainsProvider],
    3: [driverDetailProvider],
  };

  /// Les filtres sont un choix ponctuel, pas une préférence : chaque
  /// onglet se rouvre sur sa vue complète. Sans ça, le livreur
  /// retrouve un filtre posé la veille et ne comprend pas pourquoi sa
  /// liste est vide.
  void _resetFiltres(int index) {
    switch (index) {
      case 1:
        ref.read(orderFilterProvider.notifier).state = OrderFilter.toutes;
        ref.read(nearRadiusProvider.notifier).state =
            kNearRadiusOptions.first;
      case 2:
        ref.read(gainsFilterProvider.notifier).state = const GainsFilter();
    }
  }

  void _onTabTap(int index) {
    _resetFiltres(index);
    for (final provider in _onEnter[index] ?? const <ProviderOrFamily>[]) {
      ref.invalidate(provider);
    }
    ref.read(shellIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    // Publication de la position pendant une mission. Observé ici et
    // non dans l'écran de livraison : le shell survit à tout, alors
    // qu'un écran peut être démonté et couperait le suivi.
    ref.watch(positionPublishingProvider);

    // Mission en cours : l'app bascule entièrement dessus
    if (ref.watch(activeMissionIdProvider) != null) {
      return const DeliveryScreen();
    }

    final currentIndex = ref.watch(shellIndexProvider);
    final ordersCount =
        ref.watch(dashboardOrdersProvider).valueOrNull?.length ?? 0;

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
        onTap: _onTabTap,
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
