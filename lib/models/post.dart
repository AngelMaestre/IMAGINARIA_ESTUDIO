// lib/models/post.dart
class PostItem {
  final int id;
  final String? title;
  final String link;
  final String? imageUrl;
  final String sourceKey;
  final String? excerpt; // opcional

  PostItem({
    required this.id,
    required this.title,
    required this.link,
    required this.imageUrl,
    required this.sourceKey,
    this.excerpt,
  });

  /// Construcción directa desde WordPress REST API
  factory PostItem.fromWpJson(Map<String, dynamic> json, String sourceKey) {
    final id = json['id'] is int ? json['id'] as int : 0;

    // Título
    String? title;
    final titleObj = json['title'];
    if (titleObj is Map && titleObj['rendered'] != null) {
      title = titleObj['rendered'] as String;
    }

    // Link
    final link = json['link']?.toString() ?? '';

    // Excerpt (opcional)
    String? excerpt;
    final exc = json['excerpt'];
    if (exc is Map && exc['rendered'] is String) {
      excerpt = exc['rendered'] as String;
    }

    // Imagen (prioridades + fallbacks)
    String? imageUrl;

    // 1) Featured media con tamaños razonables
    try {
      final emb = json['_embedded'];
      if (emb is Map && emb['wp:featuredmedia'] is List && (emb['wp:featuredmedia'] as List).isNotEmpty) {
        final media = Map<String, dynamic>.from((emb['wp:featuredmedia'] as List).first as Map);
        final sizes = (media['media_details'] as Map?)?['sizes'] as Map?;
        if (sizes != null) {
          final candidates = ['medium_large', 'large', 'medium'];
          for (final key in candidates) {
            final m = sizes[key];
            if (m is Map && m['source_url'] is String) {
              imageUrl = m['source_url'] as String;
              break;
            }
          }
        }
        imageUrl ??= media['source_url']?.toString();
      }
    } catch (_) {}

    // 2) Fallback Yoast OG image
    if (imageUrl == null) {
      try {
        final yoast = json['yoast_head_json'];
        if (yoast is Map && yoast['og_image'] is List && (yoast['og_image'] as List).isNotEmpty) {
          final og0 = Map<String, dynamic>.from((yoast['og_image'] as List).first as Map);
          if (og0['url'] is String) {
            imageUrl = og0['url'] as String;
          }
        }
      } catch (_) {}
    }

    // 3) Fallback: primera <img> del contenido
    if (imageUrl == null) {
      try {
        final content = json['content'];
        if (content is Map && content['rendered'] is String) {
          final html = content['rendered'] as String;
          // 👉 triple comilla raw para permitir comillas simples y dobles dentro
          final reg = RegExp(
            r'''<img[^>]+src=["']([^"']+)["']''',
            caseSensitive: false,
          );
          final m = reg.firstMatch(html);
          if (m != null) imageUrl = m.group(1);
        }
      } catch (_) {}
    }

    return PostItem(
      id: id,
      title: title,
      link: link,
      imageUrl: imageUrl,
      sourceKey: sourceKey,
      excerpt: excerpt,
    );
  }

  /// Para cargar desde caché
  factory PostItem.fromJson(Map<String, dynamic> json) {
    return PostItem(
      id: json['id'] as int,
      title: json['title'] as String?,
      link: json['link'] as String,
      imageUrl: json['imageUrl'] as String?,
      sourceKey: json['sourceKey'] as String,
      excerpt: json['excerpt'] as String?,
    );
  }

  /// Para guardar en caché
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'link': link,
      'imageUrl': imageUrl,
      'sourceKey': sourceKey,
      'excerpt': excerpt,
    };
  }
}
