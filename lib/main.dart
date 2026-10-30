import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/constants.dart';
import 'core/utils/app_router.dart';
import 'features/delivery/providers/active_mission_provider.dart';
import 'features/notifications/providers/notifications_provider.dart';
import 'features/orders/providers/orders_provider.dart';
import 'features/shell/main_shell.dart';
import 'service/maps/navigation_service.dart';
import 'service/notifications/push_service.dart';
import 'service/storage/active_mission_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // L'app ne vit qu'en portrait. Tous les écrans sont dimensionnés
  // sur une référence 390×844 : en paysage, l'en-tête et la barre
  // d'onglets mangent la hauteur utile, la feuille de mission n'a plus
  // la place de s'ouvrir et la carte de l'accueil se réduit à une
  // bande. Un coursier à moto ne tient de toute façon pas son
  // téléphone à l'horizontale.
  //
  // Le verrou est posé sur les trois couches : ici pour Flutter,
  // `android:screenOrientation` dans le manifeste et
  // `UISupportedInterfaceOrientations` dans Info.plist pour le natif.
  // Celui-ci n'agit qu'une fois le moteur démarré — sans les deux
  // autres, l'écran de lancement s'afficherait encore de travers sur
  // un téléphone tenu à l'horizontale.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Mission en cours lue avant le premier affichage : voir
  // ActiveMissionIdNotifier. Quelques millisecondes, sous le splash.
  final activeMissionId = await ActiveMissionStorage.instance.get();

  // Contrairement à ce qu'on croit souvent, `debugPrint` n'est PAS
  // supprimé en release : c'est une variable qui pointe sur une
  // fonction appelant `print`, et elle écrit donc dans logcat quel que
  // soit le mode. Or nos journaux contiennent les réponses de l'API —
  // noms des clients, téléphones, adresses de livraison. Les laisser
  // en production les exposerait à quiconque branche le téléphone en
  // USB, ou à un SDK de diagnostic qui capterait les journaux.
  //
  // La remplacer ici par une fonction vide neutralise les 72 appels de
  // l'app d'un coup, sans avoir à encadrer chacun d'eux.
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Par défaut : icônes sombres sur fond blanc (toutes les pages hors home)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  // Aucune mission en cours : un guidage encore actif ne correspond à
  // rien, et sa notification resterait affichée sans moyen de la
  // fermer.
  if (activeMissionId == null) {
    await NavigationService().arreterGuidageOrphelin();
  }

  // Avant runApp : c'est ici que se récupère le message ayant réveillé
  // une app fermée. N'échoue jamais — sans Firebase configuré, le
  // service se désactive et l'app démarre normalement.
  await PushService.instance.initialiser();

  // Conteneur créé à la main plutôt que par ProviderScope : le service
  // de notifications n'est pas un widget et a besoin de changer
  // d'onglet quand le livreur touche une notification.
  final conteneur = ProviderContainer(
    overrides: [
      activeMissionIdProvider
          .overrideWith((ref) => ActiveMissionIdNotifier(activeMissionId)),
    ],
  );

  // Toute notification du backend porte `type: COURSE_STATUT` et un
  // champ `statut` : nouvelle course, annulation… Dans tous les cas la
  // bonne réaction est la même — relire les courses et la mission en
  // cours. L'écran affiché se met alors à jour tout seul : une course
  // annulée disparaît, et l'écran de mission rend la main au tableau
  // de bord, sans que le coursier ait à toucher la notification.
  void rafraichir(Map<String, dynamic> donnees) {
    debugPrint('🔔 Rafraîchissement sur notification → $donnees');
    conteneur.invalidate(activeMissionProvider);
    conteneur.invalidate(allOrdersProvider);
    conteneur.invalidate(availableOrdersProvider);
    // Le backend garde une trace de chaque envoi : la pastille et la
    // liste doivent suivre.
    conteneur.invalidate(notificationsProvider);
    conteneur.invalidate(notificationsNonLuesProvider);
  }

  PushService.instance.onMessage = rafraichir;

  // Le service ne sait pas naviguer : on lui donne ici de quoi le
  // faire. Une annulation renvoie au tableau de bord — la course
  // n'existe plus, la liste n'apprendrait rien ; tout le reste mène à
  // l'onglet des courses.
  PushService.instance.onOuverture = (donnees) {
    rafraichir(donnees);
    final annulee = donnees['statut']?.toString().toUpperCase() == 'ANNULE';
    conteneur.read(shellIndexProvider.notifier).state = annulee ? 0 : 1;
    appRouter.go(RoutePaths.home);
  };

  runApp(UncontrolledProviderScope(
    container: conteneur,
    child: const YaaProApp(),
  ));
}

class YaaProApp extends StatelessWidget {
  const YaaProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // Taille de référence : iPhone 14 Pro
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: false,
      builder: (context, child) => MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
        // L'app est entièrement en français
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [Locale('fr', 'FR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
