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
import 'service/storage/active_mission_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  runApp(ProviderScope(
    overrides: [
      activeMissionIdProvider
          .overrideWith((ref) => ActiveMissionIdNotifier(activeMissionId)),
    ],
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
