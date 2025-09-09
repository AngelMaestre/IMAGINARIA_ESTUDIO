// lib/screens/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../services/wp_api.dart';
import '../services/favorites.dart';
import '../models/post.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../services/auth_guard.dart';
import 'webview_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final api = WordPressApi();
  final fav = FavoritesService();
  bool _loading = true;
  List<PostItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final blog = await api.latestBlog().catchError((_) => <PostItem>[]);
      final music = await api.latestMusic().catchError((_) => <PostItem>[]);
      final comu = await api.latestComunidad().catchError((_) => <PostItem>[]);
      final all = <PostItem>[...blog, ...music, ...comu];

      // Filtrar por favoritos de forma defensiva
      final checks = await Future.wait(all.map((p) => fav.isFavorite(p).catchError((_) => false)));
      final favs = <PostItem>[];
      for (int i = 0; i < all.length; i++) {
        if (checks[i] == true) favs.add(all[i]);
      }

      if (!mounted) return;
      setState(() => _items = favs);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() => _load();

  void _openInternal(String link) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebViewScreen(
          initialUri: Uri.parse(link),
          title: 'Imaginaria',
          inAppHosts: const {
            'imaginariaestudio.com','www.imaginariaestudio.com',
            'lavidaenletras.com','www.lavidaenletras.com',
            'muchamusica.com','www.muchamusica.com',
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // SIEMPRE un scrollable (para RefreshIndicator)
    Widget body;
    if (_loading) {
      body = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 200),
        ],
      );
    } else if (_items.isEmpty) {
      body = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.favorite_border, size: 64, color: Colors.white54),
          SizedBox(height: 12),
          Center(child: Text('Aún no hay favoritos')),
          SizedBox(height: 120),
        ],
      );
    } else {
      body = ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _FavoriteTile(
          item: _items[i],
          onOpen: (link, isComunidad) async {
            if (isComunidad) {
              final ok = await ensureSignedIn(context);
              if (!ok || !mounted) return;
              _openInternal(link);
            } else {
              launchUrlString(link, mode: LaunchMode.externalApplication);
            }
          },
          onToggleFav: () async {
            await fav.toggle(_items[i]);
            await _load(); // refresca
          },
          isFav: true,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: RefreshIndicator(onRefresh: _refresh, child: body),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  final PostItem item;
  final Future<void> Function() onToggleFav;
  final void Function(String link, bool isComunidad) onOpen;
  final bool isFav;

  const _FavoriteTile({
    required this.item,
    required this.onToggleFav,
    required this.onOpen,
    required this.isFav,
  });

  String _plain(String? htmlOrNull) {
    final s = (htmlOrNull ?? '').replaceAll(RegExp(r'<[^>]*>'), '').trim();
    return s.isEmpty ? 'Sin título' : s;
  }

  @override
  Widget build(BuildContext context) {
    // Datos defensivos
    final title = _plain(item.title);
    final subtitle = _plain(item.excerpt?.isNotEmpty == true ? item.excerpt : item.sourceKey);
    final link = item.link;
    final isComunidad = item.sourceKey == 'comunidad';
    final locked = isComunidad && (fb.FirebaseAuth.instance.currentUser == null);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 84), // 🔒 garantiza layout
      child: Material(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onOpen(link, isComunidad),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (locked)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.lock, color: Colors.white70),
                  ),
                // Título + subtítulo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Acciones
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white70),
                      onPressed: () => Share.share(link),
                      tooltip: 'Compartir',
                    ),
                    IconButton(
                      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.redAccent : Colors.white70),
                      tooltip: isFav ? 'Quitar de favoritos' : 'Añadir a favoritos',
                      onPressed: onToggleFav,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
