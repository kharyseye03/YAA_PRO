import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;
    context.goNamed(RouteNames.onboarding);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // ── Coin haut-gauche : bracket primary ──────────────
          Positioned(
            top: 52,
            left: 36,
            child: SizedBox(
              width: 36,
              height: 36,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        width: 2),
                    left: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        width: 2),
                  ),
                ),
              ),
            ),
          ),
          // ── Coin bas-droite : bracket secondary ─────────────
          Positioned(
            bottom: 52,
            right: 36,
            child: SizedBox(
              width: 36,
              height: 36,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: AppColors.secondary.withValues(alpha: 0.30),
                        width: 2),
                    right: BorderSide(
                        color: AppColors.secondary.withValues(alpha: 0.30),
                        width: 2),
                  ),
                ),
              ),
            ),
          ),
          // ── Logo centré avec animation ───────────────────────
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo-pro3.jpeg',
                      width: 300,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Barre de chargement fine en bas ─────────────────
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: SizedBox(
                  width: 48,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.10),
                    color: AppColors.primary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
