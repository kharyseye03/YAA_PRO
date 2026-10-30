import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../api/api_service.dart';
import '../location/location_service.dart';
import '../permissions/file_autorisations.dart';

/// Notifications push, de bout en bout.
///
/// Trois acteurs : le backend décide qu'il se passe quelque chose,
/// Firebase achemine le message, cette classe le reçoit et l'affiche.
/// Le lien entre les trois est le **jeton** : une chaîne que Firebase
/// attribue à chaque installation et que le backend range à côté du
/// compte. Sans [enregistrerAppareil], tout le reste est inutile —
/// Firebase ne saurait à quel téléphone parler.
///
/// **Rien ici ne doit empêcher l'app de démarrer.** Une notification
/// est un confort ; un coursier dont l'app ne s'ouvre plus, c'est une
/// journée de travail perdue. D'où les `try` un peu partout et
/// [_actif], qui coupe proprement le reste quand l'initialisation
/// échoue — notamment sur iOS tant que `GoogleService-Info.plist`
/// n'est pas en place.

/// Canal Android. **Doit être identique** à la valeur déclarée dans
/// `AndroidManifest.xml` : app fermée, c'est Android qui affiche la
/// notification, en lisant le manifeste. Deux valeurs différentes
/// donnent deux canaux, dont un que le coursier croit avoir coupé.
const String _canalId = 'yaa_pro_courses';

const AndroidNotificationChannel _canal = AndroidNotificationChannel(
  _canalId,
  'Courses et missions',
  description:
      'Nouvelles courses disponibles et suivi de vos missions en cours.',
  importance: Importance.high,
);

/// Reçoit les messages quand l'app est fermée ou en arrière-plan.
///
/// Tourne dans un isolate séparé, sans accès à l'état de l'app : ni
/// providers, ni navigation. On ne fait donc rien ici — Android se
/// charge d'afficher la notification à partir du bloc `notification`
/// du message. Cette fonction doit exister, être de premier niveau et
/// porter l'annotation, sinon Firebase refuse de s'enregistrer.
@pragma('vm:entry-point')
Future<void> _messageEnArrierePlan(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final _local = FlutterLocalNotificationsPlugin();

  bool _actif = false;
  String? _jeton;

  /// Le serveur connaît ce jeton. Faux tant qu'il ne le connaît pas,
  /// ce qui autorise [reprendreEnregistrement] à réessayer.
  bool _enregistre = false;

  /// L'écoute du renouvellement du jeton, posée une seule fois.
  bool _ecouteRenouvellement = false;

  /// Retenu pour être libéré proprement ; en pratique le service vit
  /// aussi longtemps que l'app.
  AppLifecycleListener? _cycleDeVie;

  /// Appelé quand le coursier touche une notification. Renseigné par
  /// l'application une fois le routeur construit — le service ne sait
  /// pas naviguer, il se contente de transmettre les données.
  void Function(Map<String, dynamic> donnees)? onOuverture;

  /// Appelé dès qu'un message arrive, app ouverte, sans attendre que
  /// le coursier touche la notification. C'est ce qui permet à l'écran
  /// affiché de se mettre à jour — une course annulée doit disparaître
  /// même s'il ne regarde pas la barre de notifications.
  void Function(Map<String, dynamic> donnees)? onMessage;

  // ── Démarrage ────────────────────────────────────────────────

  /// À appeler une fois au lancement, avant `runApp`.
  Future<void> initialiser() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Configuration absente : l'app continue sans notifications
      // plutôt que de ne pas démarrer.
      debugPrint('⚠️ Firebase indisponible, notifications désactivées : $e');
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(_messageEnArrierePlan);
      await _preparerAffichageLocal();

      // App au premier plan : Android n'affiche rien tout seul, c'est
      // à nous de le faire. iOS sait le faire, on le lui demande.
      FirebaseMessaging.onMessage.listen(_auPremierPlan);
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // App en arrière-plan, le coursier touche la notification.
      FirebaseMessaging.onMessageOpenedApp.listen(_ouvrir);

      // App fermée : le message qui l'a réveillée n'arrive par aucun
      // flux, il faut aller le chercher.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _ouvrir(initial);

      _actif = true;

      // Un enregistrement qui a échoué — démarrage sans réseau, jeton
      // APNs pas encore délivré — ne se retentait jamais : l'appareil
      // restait inconnu du backend jusqu'à la connexion suivante. Le
      // retour au premier plan est le bon moment pour réessayer.
      _cycleDeVie ??= AppLifecycleListener(
        onResume: () => reprendreEnregistrement(),
      );
    } catch (e) {
      debugPrint('⚠️ Initialisation des notifications échouée : $e');
    }
  }

  Future<void> _preparerAffichageLocal() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(
          // L'autorisation est demandée plus tard, au bon moment, par
          // [enregistrerAppareil] — pas au premier lancement.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (reponse) {
        final charge = reponse.payload;
        if (charge == null || charge.isEmpty) return;
        onOuverture?.call(_decoder(charge));
      },
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_canal);
  }

  // ── Jeton ────────────────────────────────────────────────────

  /// Demande l'autorisation, récupère le jeton et l'envoie au backend.
  ///
  /// À appeler **après la connexion** : le backend range le jeton à
  /// côté d'un compte, il lui faut donc un utilisateur authentifié.
  /// C'est aussi le bon moment pour la demande d'autorisation — un
  /// coursier qui vient de se connecter comprend pourquoi on la lui
  /// demande, ce qui n'est pas le cas au tout premier lancement.
  Future<void> enregistrerAppareil() async {
    if (!_actif) return;
    try {
      // Laisser la localisation poser sa question d'abord : l'accueil
      // l'attend pour afficher la carte, les notifications peuvent
      // patienter. Le délai n'est qu'un garde-fou, pour le cas où
      // aucun écran ne demanderait la position ; la file, elle,
      // garantit dans tous les cas qu'une seule boîte est à l'écran.
      await LocationService.autorisationTranchee
          .timeout(const Duration(seconds: 10), onTimeout: () {});

      final reglages = await FileAutorisations.enFile(
          () => FirebaseMessaging.instance.requestPermission());
      if (reglages.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('ℹ️ Notifications refusées par le coursier');
        return;
      }

      // Sur iOS, le jeton Firebase est dérivé du jeton APNs, qu'Apple
      // délivre de façon asynchrone après l'acceptation. Demander le
      // jeton trop tôt renvoie `null` — et comme on abandonne sur
      // `null`, l'appareil ne serait jamais enregistré au premier
      // lancement, celui qui compte. On laisse donc APNs répondre.
      if (Platform.isIOS && !await _attendreJetonApns()) {
        debugPrint('⚠️ Jeton APNs indisponible, enregistrement reporté');
        return;
      }

      final jeton = await FirebaseMessaging.instance.getToken();
      if (jeton == null) return;
      // Jamais dans un build livré : le jeton identifie l'appareil.
      // En debug, il sert à envoyer une notification de test depuis la
      // console Firebase sans attendre le backend.
      if (kDebugMode) debugPrint('🔑 Jeton FCM : $jeton');
      await _envoyerAuBackend(jeton);

      // Firebase renouvelle le jeton de lui-même : réinstallation,
      // restauration, effacement des données. Sans cette écoute, les
      // notifications cessent d'arriver un jour, sans rien signaler.
      //
      // Posée une fois pour toutes : `enregistrerAppareil` est appelé
      // à chaque connexion et au retour au premier plan, et reposer
      // l'écoute empilerait les abonnements — le jeton partirait
      // alors en plusieurs exemplaires.
      if (!_ecouteRenouvellement) {
        _ecouteRenouvellement = true;
        FirebaseMessaging.instance.onTokenRefresh.listen(_envoyerAuBackend);
      }
    } catch (e) {
      debugPrint('⚠️ Enregistrement du jeton échoué : $e');
    }
  }

  /// Attend qu'Apple ait délivré le jeton APNs, au plus dix secondes.
  ///
  /// Il arrive presque toujours en moins d'une seconde ; l'attente ne
  /// se voit pas, puisqu'elle a lieu après la connexion, pendant que
  /// l'accueil se remplit. Sans réseau, ou sur un simulateur, il ne
  /// vient jamais — d'où la sortie au bout du délai, qui laisse
  /// [reprendreEnregistrement] et `onTokenRefresh` rattraper le coup.
  Future<bool> _attendreJetonApns() async {
    for (var essai = 0; essai < 10; essai++) {
      final apns = await FirebaseMessaging.instance.getAPNSToken();
      if (apns != null) return true;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return false;
  }

  /// Envoie le jeton au backend, en réessayant.
  ///
  /// L'enregistrement n'a lieu qu'à la connexion. S'il échoue — réseau
  /// qui flanche, backend qui redémarre —, rien ne le retentait et
  /// l'appareil restait inconnu du serveur jusqu'à la connexion
  /// suivante, sans que personne ne s'en aperçoive.
  Future<void> _envoyerAuBackend(String jeton) async {
    _jeton = jeton;

    for (var essai = 1; essai <= 3; essai++) {
      try {
        await ApiService().enregistrerAppareil(
          token: jeton,
          plateforme: Platform.isIOS ? 'ios' : 'android',
        );
        _enregistre = true;
        return;
      } catch (e) {
        debugPrint('⚠️ Envoi du jeton au backend échoué (essai $essai) : $e');
        if (essai < 3) {
          await Future<void>.delayed(Duration(seconds: 2 * essai));
        }
      }
    }
    // Les trois tentatives ont échoué : [reprendreEnregistrement] le
    // retentera au prochain retour au premier plan.
    _enregistre = false;
  }

  /// Reprend l'enregistrement s'il n'a jamais abouti.
  ///
  /// Appelé au retour au premier plan. Ne fait rien dans le cas normal,
  /// où le serveur connaît déjà ce jeton ; sert aux fois où l'app a
  /// démarré sans réseau, ou avant qu'Apple ait délivré son jeton APNs.
  Future<void> reprendreEnregistrement() async {
    if (!_actif || _enregistre) return;
    await enregistrerAppareil();
  }

  /// À appeler **à la déconnexion**, avant d'effacer la session.
  ///
  /// Sans ça, le coursier suivant à se connecter sur ce téléphone
  /// reçoit les notifications du précédent : ses courses, ses clients.
  Future<void> oublierAppareil() async {
    if (!_actif) return;
    // La lecture du jeton est elle aussi sous `try` : sur iOS,
    // `getToken` lève quand Apple n'a pas délivré de jeton APNs — ce
    // qui arrive dès que la capacité push manque au build. Hors du
    // `try`, l'exception remonterait jusqu'à `logout`, qui n'irait
    // jamais jusqu'à effacer la session : impossible de se
    // déconnecter.
    try {
      final jeton = _jeton ?? await FirebaseMessaging.instance.getToken();
      // Borné comme deleteToken juste en dessous : la déconnexion
      // attend cet appel, et un coursier en mauvaise couverture ne
      // doit pas rester coincé sur l'écran précédent pour autant.
      if (jeton != null) {
        await ApiService()
            .supprimerAppareil(token: jeton)
            .timeout(const Duration(seconds: 3));
      }
    } catch (e) {
      debugPrint('⚠️ Suppression du jeton côté backend échouée : $e');
    }
    try {
      // Firebase en fabriquera un neuf à la prochaine connexion.
      //
      // Borné dans le temps : cet appel part sur le réseau, et la
      // déconnexion l'attend. Sans limite, un coursier en zone de
      // mauvaise couverture reste bloqué sur l'écran précédent.
      await FirebaseMessaging.instance
          .deleteToken()
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
    _jeton = null;
    _enregistre = false;
  }

  // ── Réception ────────────────────────────────────────────────

  Future<void> _auPremierPlan(RemoteMessage message) async {
    debugPrint('🔔 Message reçu → ${message.data}');
    onMessage?.call(message.data);
    await _afficherAuPremierPlan(message);
  }

  Future<void> _afficherAuPremierPlan(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;
    await _local.show(
      id: message.hashCode,
      title: notif.title,
      body: notif.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _canal.id,
          _canal.name,
          channelDescription: _canal.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: _encoder(message.data),
    );
  }

  void _ouvrir(RemoteMessage message) => onOuverture?.call(message.data);

  // Le payload de flutter_local_notifications est une simple chaîne :
  // on y range les données sous forme `cle=valeur;cle=valeur`. Les
  // valeurs venant de FCM sont toujours des chaînes, jamais de
  // séparateur à échapper en pratique.
  String _encoder(Map<String, dynamic> donnees) =>
      donnees.entries.map((e) => '${e.key}=${e.value}').join(';');

  Map<String, dynamic> _decoder(String charge) {
    final sortie = <String, dynamic>{};
    for (final morceau in charge.split(';')) {
      final i = morceau.indexOf('=');
      if (i > 0) sortie[morceau.substring(0, i)] = morceau.substring(i + 1);
    }
    return sortie;
  }
}
