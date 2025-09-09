// lib/services/auth_linker.dart
import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:url_launcher/url_launcher_string.dart';
import '../config.dart';

class AuthLinker {
  /// Devuelve la URL final para SSO con token y redirect.
  static Future<String?> buildWebSsoUrl({
    String redirectTo = '/mi-cuenta',
  }) async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) {
      dev.log('[AuthLinker] No hay usuario autenticado');
      return null;
    }

    try {
      // IMPORTANTE: si el email no está verificado, el plugin lo rechazará
      await user.reload(); // refresca claims
      final refreshed = fb.FirebaseAuth.instance.currentUser;
      if (refreshed?.emailVerified == false) {
        dev.log('[AuthLinker] Email no verificado: ${refreshed?.email}');
        // (Opcional) Mostrar aviso en UI
      }

      // Algunas versiones pueden inferir String?
      final String? token = await user.getIdToken(true);
      if (token == null || token.isEmpty) {
        dev.log('[AuthLinker] Token vacío o nulo');
        return null;
      }

      final base = AppConfig.webSsoEndpoint; // p.ej. https://www.imaginariaestudio.com/wp-json/imaginaria/v1/firebase
      
      final url =
          '$base?token=${Uri.encodeQueryComponent(token)}&redirect_to=${Uri.encodeComponent(redirectTo)}';

      dev.log('[AuthLinker] URL SSO => $url'); // Útil para depurar (no compartas el token)
      return url;
    } catch (e) {
      dev.log('[AuthLinker] Error obteniendo token: $e');
      return null;
    }
  }

  /// Abre la URL de SSO en el navegador.
  static Future<bool> openWebSso({String redirectTo = '/mi-cuenta'}) async {
    final url = await buildWebSsoUrl(redirectTo: redirectTo);
    if (url == null) return false;
    final ok = await launchUrlString(url, mode: LaunchMode.externalApplication);
    if (!ok) {
      dev.log('[AuthLinker] No se pudo abrir el navegador');
    }
    return ok;
  }
}
