import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/app_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Status bar transparente sur l'image
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Image de fond plein écran ──────────────────────
          Image.asset(
            'assets/images/ob2.jpeg',
            fit: BoxFit.cover,
          ),

          // ── Gradient overlay : léger en haut, dense en bas ─
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.35, 0.65, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),

          // ── Contenu ───────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),

                  // Titre + sous-titre + bouton en bas
                  Text(
                    'Livrez.\nGagnez.\nSoyez libre.',
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: AppDimens.lg),
                  Text(
                    'Rejoignez la flotte YAA PRO et gérez vos livraisons en toute autonomie. Choisissez vos horaires, suivez vos gains, livrez partout.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.white.withValues(alpha: 0.82),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppDimens.xxxl),

                  // Bouton Commencer
                  SizedBox(
                    width: double.infinity,
                    height: AppDimens.buttonHeight,
                    child: ElevatedButton(
                      onPressed: () => context.goNamed(RouteNames.register),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Commencer',
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.lg),

                  // Lien connexion
                  Center(
                    child: GestureDetector(
                      onTap: () => context.goNamed(RouteNames.login),
                      child: RichText(
                        text: TextSpan(
                          text: 'Déjà un compte ?  ',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.white.withValues(alpha: 0.65),
                          ),
                          children: [
                            TextSpan(
                              text: 'Se connecter',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.white,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
