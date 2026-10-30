import 'dart:async';

/// File d'attente des demandes d'autorisation système.
///
/// Le système n'affiche qu'une boîte de dialogue d'autorisation à la
/// fois. Si une deuxième demande part pendant que la première est à
/// l'écran, elle n'est pas montrée — et, plus traître, le greffon qui
/// l'a émise ne reçoit jamais son résultat. La demande perdue ne
/// ressurgit qu'au retour suivant dans l'app, ce qui donne
/// l'impression que l'app oublie de poser la question.
///
/// C'est le cas à la connexion du coursier : l'enregistrement du jeton
/// de notification et le premier point GPS de l'accueil partent dans
/// la même image.
///
/// Toute demande d'autorisation passe donc par ici. L'ordre est celui
/// des appels ; une seule boîte est en vol à la fois.
class FileAutorisations {
  FileAutorisations._();

  /// Maillon de queue. Ne porte jamais d'erreur : [enFile] attrape
  /// tout pour son appelant, sans quoi une demande refusée casserait
  /// la file pour toutes les suivantes.
  static Future<void> _queue = Future<void>.value();

  /// Exécute [demande] quand les demandes précédentes sont terminées.
  ///
  /// Le résultat — et l'éventuelle erreur — revient à l'appelant comme
  /// s'il avait appelé directement.
  static Future<T> enFile<T>(Future<T> Function() demande) {
    final resultat = Completer<T>();

    _queue = _queue.then((_) async {
      try {
        resultat.complete(await demande());
      } catch (e, pile) {
        resultat.completeError(e, pile);
      }
    });

    return resultat.future;
  }
}
