// lib/services/wp_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/post.dart';
import 'cache.dart';

/// Resultado de una página paginada
class PostsPage {
  final List<PostItem> items;
  final int page;
  final int totalPages;

  PostsPage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;
}

class WordPressApi {
  // Claves de caché por rail (para latest*)
  static const _kBlog  = 'rail:blog';
  static const _kMusic = 'rail:music';
  static const _kComu  = 'rail:comu';

  // TTL por rail
  static const _ttlBlog  = Duration(minutes: 30);
  static const _ttlMusic = Duration(minutes: 15);
  static const _ttlComu  = Duration(minutes: 5);

  // ---------------------------
  // Métodos "latest" con caché
  // ---------------------------
  Future<List<PostItem>> latestBlog({bool force = false, int perPage = 20}) {
    return _cachedPosts(
      key: _kBlog,
      baseUrl: AppConfig.blogBase,
      endpoint: AppConfig.blogEndpoint,
      sourceKey: 'blog',
      perPage: perPage,
      force: force,
      ttl: _ttlBlog,
    );
  }

  Future<List<PostItem>> latestMusic({bool force = false, int perPage = 20}) {
    return _cachedPosts(
      key: _kMusic,
      baseUrl: AppConfig.musicBase,
      endpoint: AppConfig.musicEndpoint,
      sourceKey: 'music',
      perPage: perPage,
      force: force,
      ttl: _ttlMusic,
    );
  }

  Future<List<PostItem>> latestComunidad({bool force = false, int perPage = 20}) {
    return _cachedPosts(
      key: _kComu,
      baseUrl: AppConfig.comunidadBase,
      endpoint: AppConfig.comunidadEndpoint,
      sourceKey: 'comunidad',
      perPage: perPage,
      force: force,
      ttl: _ttlComu,
    );
  }

  /// Invalida la caché de los rails
  Future<void> invalidateAllRails() async {
    await AppCache.invalidate(_kBlog);
    await AppCache.invalidate(_kMusic);
    await AppCache.invalidate(_kComu);
  }

  // --------------------------------
  // NUEVO: Fetch paginado (sin caché)
  // --------------------------------

  /// Devuelve una página de posts y las cabeceras de paginación de WP.
  ///
  /// Usa los encabezados `X-WP-TotalPages` para saber si hay más páginas.
  Future<PostsPage> fetchPostsPage({
    required String baseUrl,
    required String endpoint,
    required String sourceKey,
    required int page,
    int perPage = 20,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint?_embed&per_page=$perPage&page=$page');
    final resp = await http.get(uri, headers: {'Accept': 'application/json'});
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode} - ${resp.body}');
    }

    final data = json.decode(resp.body);
    final items = (data is List)
        ? data
            .map<PostItem>((e) => PostItem.fromWpJson(
                  Map<String, dynamic>.from(e as Map),
                  sourceKey,
                ))
            .toList()
        : <PostItem>[];

    final totalPagesStr = resp.headers['x-wp-totalpages'] ?? resp.headers['X-WP-TotalPages'];
    final totalPages = int.tryParse(totalPagesStr ?? '') ?? 1;

    return PostsPage(items: items, page: page, totalPages: totalPages);
  }

  // Helpers de conveniencia por sección
  Future<PostsPage> pagedBlog({required int page, int perPage = 20}) {
    return fetchPostsPage(
      baseUrl: AppConfig.blogBase,
      endpoint: AppConfig.blogEndpoint,
      sourceKey: 'blog',
      page: page,
      perPage: perPage,
    );
  }

  Future<PostsPage> pagedMusic({required int page, int perPage = 20}) {
    return fetchPostsPage(
      baseUrl: AppConfig.musicBase,
      endpoint: AppConfig.musicEndpoint,
      sourceKey: 'music',
      page: page,
      perPage: perPage,
    );
  }

  Future<PostsPage> pagedComunidad({required int page, int perPage = 20}) {
    return fetchPostsPage(
      baseUrl: AppConfig.comunidadBase,
      endpoint: AppConfig.comunidadEndpoint,
      sourceKey: 'comunidad',
      page: page,
      perPage: perPage,
    );
  }

  // -------------------------------------------------
  // Internos usados por los "latest" con caché (SWr)
  // -------------------------------------------------
  Future<List<PostItem>> _cachedPosts({
    required String key,
    required String baseUrl,
    required String endpoint,
    required String sourceKey,
    required int perPage,
    required bool force,
    required Duration ttl,
  }) async {
    if (!force) {
      final cachedList = await AppCache.get<List<dynamic>>(
        key,
        ttl: ttl,
        fromListJson: (list) => list,
      );
      if (cachedList != null && cachedList.isNotEmpty) {
        _revalidate(
          key: key,
          baseUrl: baseUrl,
          endpoint: endpoint,
          perPage: perPage,
        );
        return _mapToPosts(cachedList, sourceKey);
      }
    }

    final freshRaw = await _fetchRaw(
      baseUrl: baseUrl,
      endpoint: endpoint,
      perPage: perPage,
    );
    await AppCache.set(key, freshRaw);
    return _mapToPosts(freshRaw, sourceKey);
  }

  Future<List<Map<String, dynamic>>> _fetchRaw({
    required String baseUrl,
    required String endpoint,
    required int perPage,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint?_embed&per_page=$perPage');
    final resp = await http.get(uri, headers: {'Accept': 'application/json'});
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode} - ${resp.body}');
    }
    final data = json.decode(resp.body);
    if (data is! List) return <Map<String, dynamic>>[];
    return data
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  void _revalidate({
    required String key,
    required String baseUrl,
    required String endpoint,
    required int perPage,
  }) async {
    try {
      final freshRaw = await _fetchRaw(
        baseUrl: baseUrl,
        endpoint: endpoint,
        perPage: perPage,
      );
      await AppCache.set(key, freshRaw);
    } catch (_) {/* no-op */}
  }

  List<PostItem> _mapToPosts(List<dynamic> list, String sourceKey) {
    return list
        .map<PostItem>((e) => PostItem.fromWpJson(
              Map<String, dynamic>.from(e as Map),
              sourceKey,
            ))
        .toList();
  }
}
