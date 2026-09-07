import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/app_router.dart';
import '../../auth/providers/auth_notifier.dart';

/// Premier écran de l'app, pendant la restauration de session.
///
/// Il reproduit **à l'identique** la fenêtre de lancement affichée par
/// Android — même fond, même logo, même taille, même position. Aucune
/// animation, aucun élément décoratif : la moindre différence entre les
/// deux se lit comme un changement d'écran, et donne l'impression que
/// l'app en affiche un de trop avant de démarrer.
///
/// Le pendant natif de cet écran est `drawable/launch_background.xml`
/// et les `launch_logo.png` de `drawable-*dpi/`. **Toute modification
/// ici doit y être répercutée**, sinon la couture redevient visible.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// Largeur du logo, partagée avec les `launch_logo.png` natifs.
  ///
  /// 121 dp n'est pas un choix esthétique mais une **mesure** : c'est
  /// la taille à laquelle Android 12 affiche l'icône sur son écran de
  /// lancement, une fois le logo poussé au bord de la zone sûre de
  /// l'icône adaptative. Le système impose cette taille et ne permet
  /// pas de l'agrandir ; c'est donc au splash de s'y conformer, sinon
  /// le logo change brutalement de taille entre les deux écrans.
  ///
  /// Relever la mesure après toute modification de `foreground.png` :
  /// capture d'écran pendant le lancement, largeur du logo en pixels,
  /// divisée par la densité de l'appareil.
  static const double logoWidth = 121;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Le délai plancher n'existe que pour éviter un clignotement si la
    // session se restaure instantanément. Il s'ajoute au démarrage du
    // moteur, que l'utilisateur a déjà attendu : on le garde court.
    final results = await Future.wait([
      ref.read(authProvider.notifier).tryAutoLogin(),
      Future.delayed(const Duration(milliseconds: 600)),
    ]);
    if (!mounted) return;
    final loggedIn = results[0] as bool;
    context.goNamed(loggedIn ? RouteNames.home : RouteNames.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Le reste de l'app est clair, ses icônes système sont donc
      // sombres. Sur ce fond bleu il faut les inverser.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Image(
            image: AssetImage('assets/images/logo_white.png'),
            width: SplashScreen.logoWidth,
          ),
        ),
      ),
    );
  }
}
