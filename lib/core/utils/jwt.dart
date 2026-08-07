import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Rôle exigé pour accéder à l'application livreur.
const String kRoleLivreur = 'LIVREUR';

/// Contenu (payload) d'un JWT, sans vérification de signature.
///
/// La signature est validée par le serveur : ici on se contente de
/// lire les informations pour adapter l'interface et refuser un
/// compte qui n'a rien à faire dans l'app.
Map<String, dynamic> decodeJwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return const {};
    final payload =
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final decoded = jsonDecode(payload);
    return decoded is Map<String, dynamic> ? decoded : const {};
  } catch (e) {
    debugPrint('❌ Token illisible → $e');
    return const {};
  }
}

/// Rôles du realm portés par le token (`realm_access.roles`).
List<String> realmRolesOf(String token) {
  final realmAccess = decodeJwtPayload(token)['realm_access'];
  if (realmAccess is! Map) return const [];
  final roles = realmAccess['roles'];
  if (roles is! List) return const [];
  return roles.whereType<String>().toList();
}

/// True si le token autorise l'accès à l'application livreur.
bool estLivreur(String token) =>
    realmRolesOf(token).contains(kRoleLivreur);
