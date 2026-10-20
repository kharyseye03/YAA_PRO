import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../api/api_service.dart';

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
      final reglages = await FirebaseMessaging.instance.requestPermission();
      if (reglages.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('ℹ️ Notifications refusées par le coursier');
        return;
      }

      final jeton = await FirebaseMessaging.instance.getToken();
      if (jeton == null) return;
      // Visible uniquement en debug : sert à envoyer une notification
      // de test depuis la console Firebase, sans attendre le backend.
      debugPrint('🔑 Jeton FCM : $jeton');
      await _envoyerAuBackend(jeton);

      // Firebase renouvelle le jeton de lui-même : réinstallation,
      // restauration, effacement des données. Sans cette écoute, les
      // notifications cessent d'arriver un jour, sans rien signaler.
      FirebaseMessaging.instance.onTokenRefresh.listen(_envoyerAuBackend);
    } catch (e) {
      debugPrint('⚠️ Enregistrement du jeton échoué : $e');
    }
  }

  Future<void> _envoyerAuBackend(String jeton) async {
    _jeton = jeton;
    try {
      await ApiService().enregistrerAppareil(
        token: jeton,
        plateforme: Platform.isIOS ? 'ios' : 'android',
      );
    } catch (e) {
      // L'endpoint n'existe pas encore côté backend : on n'en fait pas
      // une erreur visible, le reste de l'app n'en dépend pas.
      debugPrint('⚠️ Envoi du jeton au backend échoué : $e');
    }
  }

  /// À appeler **à la déconnexion**, avant d'effacer la session.
  ///
  /// Sans ça, le coursier suivant à se connecter sur ce téléphone
  /// reçoit les notifications du précédent : ses courses, ses clients.
  Future<void> oublierAppareil() async {
    if (!_actif) return;
    final jeton = _jeton ?? await FirebaseMessaging.instance.getToken();
    try {
      if (jeton != null) await ApiService().supprimerAppareil(token: jeton);
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
