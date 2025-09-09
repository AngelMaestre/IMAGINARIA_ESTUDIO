// lib/screens/list_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../models/post.dart';
import '../services/favorites.dart';
import '../services/auth_guard.dart';
import 'webview_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../services/wp_api.dart';

class ListScreen extends StatefulWidget {
  final String title;

  /// Loader simple (compatibilidad). Si usas paginación, puedes dejarlo en null.
  final Future<List<PostItem>> Function()? loader;

  /// Loader paginado. Si lo proporcionas, se usa scroll infinito.
  /// Debe devolver PostsPage desde wp_api.dart.
  final Future<PostsPage> Function(int page)? pagedLoader;

  /// Lista inicial (por ejemplo, la del rail) para mostrar al instante.
  final List<PostItem>? initial;

  const ListScreen({
    super.key,
    required this.title,
    this.loader,
    this.pagedLoader,
    this.initial,
  }) : assert(
          loader != null || pagedLoader != null,
          'Debes proveer loader o pagedLoader',
        );

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen>
    with AutomaticKeepAliveClientMixin<ListScreen> {
  final fav = FavoritesService();
  final _scroll = ScrollController();

  // Estado
  List<PostItem> _items = [];
  bool _firstPaintedFromInitial = false;

  // Paginación
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _page = 1;

  @override
  void initState() {
    super.initState();

    // Pintar initial si existe
    if (widget.initial != null && widget.initial!.isNotEmpty) {
      _items = List<PostItem>.from(widget.initial!);
      _firstPaintedFromInitial = true;
    }

    // Carga inicial
    _loadFirst();

    // Listener para cargar más al acercarse al final
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.pagedLoader == null) return; // sin paginación
    if (_isLoadingMore || !_hasMore) return;

    final pos = _scroll.position;
    const threshold = 300; // píxeles antes del final
    if (pos.pixels + threshold >= pos.maxScrollExtent) {
      _loadMore();
    }
  }

  Future<void> _loadFirst() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      if (widget.pagedLoader != null) {
        _page = 1;
        final page = await widget.pagedLoader!(_page);
        _items = page.items;
        _hasMore = page.hasMore;
      } else if (widget.loader != null) {
        final list = await widget.loader!();
        _items = list;
        _hasMore = false; // sin paginación
      }
    } catch (_) {
      // mantenemos lo que hubiera (initial si había)
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (widget.pagedLoader == null) return;
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _page + 1;
      final page = await widget.pagedLoader!(nextPage);
      _page = nextPage;

      if (page.items.isNotEmpty) {
        _items.addAll(page.items);
      }
      _hasMore = page.hasMore;
    } catch (_) {
      // ignora errores de carga incremental
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _refresh() async {
    try {
      if (widget.pagedLoader != null) {
        _page = 1;
        final page = await widget.pagedLoader!(_page);
        if (!mounted) return;
        setState(() {
          _items = page.items;
          _hasMore = page.hasMore;
        });
      } else if (widget.loader != null) {
        final list = await widget.loader!();
        if (!mounted) return;
        setState(() {
          _items = list;
          _hasMore = false;
        });
      }
    } catch (_) {
      // mantener items actuales
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isColdStart = !_firstPaintedFromInitial && _items.isEmpty && _isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: isColdStart
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _items.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, i) {
                  // Indicador de carga incremental al final
                  if (_isLoadingMore && i == _items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final it = _items[i];
                  final bool isLocked = it.sourceKey == 'comunidad' &&
                      (fb.FirebaseAuth.instance.currentUser == null);

                  final title = (it.title ?? 'Sin título')
                      .replaceAll(RegExp(r'<[^>]*>'), '');
                  final subtitle = (it.excerpt != null && it.excerpt!.isNotEmpty)
                      ? it.excerpt!.replaceAll(RegExp(r'<[^>]*>'), '')
                      : it.sourceKey;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: isLocked
                          ? const Icon(Icons.lock, color: Colors.white70)
                          : null,
                      contentPadding: const EdgeInsets.all(12),
                      title: Text(
                        title,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onTap: () async {
                        if (it.sourceKey == 'comunidad') {
                          final ok = await ensureSignedIn(context);
                          if (!ok) return;
                          if (!mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WebViewScreen(
                                initialUri: Uri.parse(it.link),
                                title: 'Imaginaria',
                                inAppHosts: const {
                                  'imaginariaestudio.com',
                                  'www.imaginariaestudio.com',
                                  'lavidaenletras.com',
                                  'www.lavidaenletras.com',
                                  'muchamusica.com',
                                  'www.muchamusica.com',
                                },
                              ),
                            ),
                          );

                        } else {
                          launchUrlString(
                            it.link,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      trailing: Wrap(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share),
                            color: Colors.white70,
                            onPressed: () => Share.share(it.link),
                            tooltip: 'Compartir',
                          ),
                          FutureBuilder<bool>(
                            future: fav.isFavorite(it),
                            builder: (c, s) {
                              final isFav = s.data ?? false;
                              return IconButton(
                                icon: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                ),
                                color: isFav ? Colors.redAccent : Colors.white70,
                                tooltip: isFav
                                    ? 'Quitar de favoritos'
                                    : 'Añadir a favoritos',
                                onPressed: () async {
                                  await fav.toggle(it);
                                  if (mounted) setState(() {});
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
