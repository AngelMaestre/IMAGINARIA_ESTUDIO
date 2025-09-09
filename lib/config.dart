class AppConfig {
  // Bases WordPress (ajústalas si cambian)
  static const blogBase = 'https://www.lavidaenletras.com';
  static const musicBase = 'https://www.muchamusica.com';
  static const comunidadBase = 'https://imaginariaestudio.com';

  // Endpoints (por defecto posts; cambia a CPTs si procede)
  static const blogEndpoint = '/wp-json/wp/v2/posts';
  static const musicEndpoint = '/wp-json/wp/v2/posts';
static const comunidadEndpoint = '/wp-json/wp/v2/proyecto';

  // UI
  static const appName = 'IMAGINARIA ESTUDIO';
  static const primaryHex = 0xFF8B1111; // vino
  static const backgroundHex = 0xFF111827; // gris oscuro

  // ...
  static const defaultImgBlog = 'https://imaginariaestudio.com/wp-content/uploads/2025/01/fallback-blog.webp';
  static const defaultImgMusic = 'https://imaginariaestudio.com/wp-content/uploads/2025/01/fallback-music.webp';
  static const defaultImgComu = 'https://imaginariaestudio.com/wp-content/uploads/2025/01/fallback-comunidad.webp';

/// URL base en tu web para aceptar el token de Firebase y crear sesión.
  /// Ejemplos:
  /// - Endpoint WP REST (plugin o endpoint propio): https://tuweb.com/wp-json/custom-auth/v1/firebase
  /// - Endpoint página puente:                     https://tuweb.com/firebase-sso
  static const String webSsoEndpoint = 'https://www.imaginariaestudio.com/wp-admin/admin-post.php?action=imaginaria_firebase_login';
}


