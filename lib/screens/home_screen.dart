// lib/screens/home_screen.dart
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Haptics + Clipboard
import 'package:flutter/foundation.dart'; // kReleaseMode
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:shared_preferences/shared_preferences.dart'; // hint primera vez
import '../config.dart';
import '../services/wp_api.dart';
import '../services/favorites.dart';
import '../models/post.dart';
import '../widgets/post_card.dart';
import 'list_screen.dart';
import 'favorites_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb; // alias
import '../services/auth_guard.dart';
import 'webview_screen.dart';
import 'auth_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'upload_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/push_service.dart';

/// Flag para mostrar/ocultar "Subir" en el menú lateral.
const bool kEnableUploads = false;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final api = WordPressApi();
  final fav = FavoritesService();
  late Future<List<PostItem>> fBlog;
  late Future<List<PostItem>> fMusic;
  late Future<List<PostItem>> fComu;
  bool _authBusy = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    fBlog = api.latestBlog();
    fMusic = api.latestMusic();
    fComu = api.latestComunidad();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowMenuHint());
  }

  Future<void> _maybeShowMenuHint() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final seen = sp.getBool('menu_hint_seen') ?? false;
      if (seen || !mounted) return;
      final snack = SnackBar(
        behavior: SnackBarBehavior.floating,
        content: const Text('Nuevo menú lateral ➜ toca “Menú” arriba para explorar'),
        action: SnackBarAction(
          label: 'Abrir',
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
        duration: const Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(snack);
      await sp.setBool('menu_hint_seen', true);
    } catch (_) {}
  }

  Future<void> _debugCopyFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener el token FCM')),
        );
        return;
      }
      await Clipboard.setData(ClipboardData(text: token));
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token FCM copiado (${token.substring(0, 8)}… )')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error obteniendo token: $e')),
      );
    }
  }

  Future<void> _refreshAll() async {
    await api.invalidateAllRails();
    if (!mounted) return;
    setState(() {
      fBlog = api.latestBlog(force: true);
      fMusic = api.latestMusic(force: true);
      fComu = api.latestComunidad(force: true);
    });
    await Future.wait([
      fBlog.catchError((_) => <PostItem>[]),
      fMusic.catchError((_) => <PostItem>[]),
      fComu.catchError((_) => <PostItem>[]),
    ]);

    if (!mounted) return;
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contenido actualizado'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  double _railCacheExtent(BuildContext context) {
    final mq = MediaQuery.of(context);
    final logicalWidth = mq.size.width;
    final dpr = mq.devicePixelRatio.clamp(1.0, 3.0);
    final base = logicalWidth * 2.5;
    final value = (base * (dpr / 2)).clamp(300.0, 1200.0);
    return value;
  }

  void _openInApp(String link) {
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
    final cacheExtent = _railCacheExtent(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: const SizedBox(),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x700B0B0C),
                      Color(0x400B0B0C),
                      Color(0x000B0B0C),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        title: const Text(AppConfig.appName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.menu),
              label: const Text('Menú'),
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: const Size(0, 36),
              ),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ),
          if (!kReleaseMode)
            IconButton(
              tooltip: 'Copiar Token FCM',
              icon: const Icon(Icons.key),
              onPressed: _debugCopyFcmToken,
            ),
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
          ),
          if (!kReleaseMode)
            IconButton(
              tooltip: 'DEV: Noti instantánea',
              icon: const Icon(Icons.bolt),
              onPressed: () {
                PushService.debugShowLocal(
                  title: 'Novedad (DEV)',
                  body: 'Pulsa para abrir',
                  link: 'https://www.imaginariaestudio.com/',
                  browser: false,
                );
              },
            ),
          // 👇 aquí puede ir tu bloque de usuario/cuenta si lo tenías en actions
        ],
      ),
      endDrawer: _GlassSideMenu(
        onClose: () => Navigator.of(context).maybePop(),
        items: [
          _MenuItem(
            icon: Icons.menu_book,
            label: 'Blog',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ListScreen(
                  title: 'Blog',
                  pagedLoader: (p) => WordPressApi().pagedBlog(page: p, perPage: 20),
                ),
              ));
            },
          ),
          _MenuItem(
            icon: Icons.music_note,
            label: 'Música',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ListScreen(
                  title: 'Música',
                  pagedLoader: (p) => WordPressApi().pagedMusic(page: p, perPage: 20),
                ),
              ));
            },
          ),
          _MenuItem(
            icon: Icons.groups,
            label: 'Comunidad',
            onTap: () async {
              Navigator.of(context).pop();
              final ok = await ensureSignedIn(context);
              if (!ok || !mounted) return;
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ListScreen(
                  title: 'Comunidad',
                  pagedLoader: (p) => WordPressApi().pagedComunidad(page: p, perPage: 20),
                ),
              ));
            },
          ),
          _MenuItem(
            icon: Icons.favorite,
            label: 'Favoritos',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          ),
          if (kEnableUploads)
            _MenuItem(
              icon: Icons.upload_file,
              label: 'Subir (WIP)',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UploadScreen()),
                );
              },
            ),
          _MenuItem(
            icon: Icons.settings,
            label: 'Ajustes',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          key: const PageStorageKey('home-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _rail('Blog · LaVidaEnLetras', fBlog, cacheExtent: cacheExtent),
              _rail('Música · MuchaMúsica', fMusic, cacheExtent: cacheExtent),
              _rail('Comunidad · Imaginaria', fComu, cacheExtent: cacheExtent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rail(String title, Future<List<PostItem>> future, {double? cacheExtent}) {
    return FutureBuilder<List<PostItem>>(
      future: future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final items = snapshot.data ?? <PostItem>[];

        final titleMain = title.split(' · ').first;
        final titleBrand = title.split(' · ').length > 1 ? title.split(' · ').last : '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: titleMain,
              brand: titleBrand,
              icon: titleMain.startsWith('Blog')
                  ? Icons.menu_book
                  : titleMain.startsWith('Música')
                      ? Icons.music_note
                      : Icons.groups,
              onSeeAll: () {
                late final Future<PostsPage> Function(int page) paged;
                if (titleMain.startsWith('Blog')) {
                  paged = (page) => WordPressApi().pagedBlog(page: page, perPage: 20);
                } else if (titleMain.startsWith('Música')) {
                  paged = (page) => WordPressApi().pagedMusic(page: page, perPage: 20);
                } else {
                  paged = (page) => WordPressApi().pagedComunidad(page: page, perPage: 20);
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ListScreen(
                      title: titleMain,
                      pagedLoader: paged,
                      initial: items,
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white24, Colors.white10, Colors.transparent],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 240,
              child: loading && items.isEmpty
                  ? _skeletonRail()
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      cacheExtent: cacheExtent ?? 600,
                      itemBuilder: (context, i) {
                        final it = items[i];
                        final bool isLocked = it.sourceKey == 'comunidad' &&
                            (fb.FirebaseAuth.instance.currentUser == null);
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.95, end: 1.0),
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOut,
                          builder: (context, scale, child) =>
                              Transform.scale(scale: scale, child: child),
                          child: PostCard(
                            item: it,
                            locked: isLocked,
                            onTap: () async {
                              if (it.sourceKey == 'comunidad') {
                                final ok = await ensureSignedIn(context);
                                if (!ok || !mounted) return;
                                _openInApp(it.link);
                              } else {
                                launchUrlString(it.link, mode: LaunchMode.externalApplication);
                              }
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.share, color: Colors.white70),
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
                                        color: isFav ? Colors.redAccent : Colors.white70,
                                      ),
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
          ],
        );
      },
    );
  }

  Widget _skeletonRail() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, __) => Container(
        width: 320,
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}
class SectionHeader extends StatelessWidget {
  final String title;
  final String brand;
  final VoidCallback onSeeAll;
  final IconData icon;
  const SectionHeader({
    super.key,
    required this.title,
    required this.brand,
    required this.onSeeAll,
    this.icon = Icons.star,
  });

  @override
  Widget build(BuildContext context) {
    const brandGrad = [Color(0xFF8B1111), Color(0xFF9CA3AF)];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (rect) =>
                const LinearGradient(colors: brandGrad).createShader(rect),
            child: const Text(' ', style: TextStyle(fontSize: 0)),
          ),
          ShaderMask(
            shaderCallback: (rect) =>
                const LinearGradient(colors: brandGrad).createShader(rect),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: .2,
              ),
            ),
          ),
          if (brand.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                brand,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const Spacer(),
          TextButton(onPressed: onSeeAll, child: const Text('Ver todo')),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _MenuItem({required this.icon, required this.label, required this.onTap});
}

class _GlassSideMenu extends StatelessWidget {
  final List<_MenuItem> items;
  final VoidCallback onClose;
  const _GlassSideMenu({required this.items, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: const SizedBox(),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111827).withOpacity(0.94),
                border: Border.all(color: Colors.white12),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  ListTile(
                    title: const Text(
                      'Imaginaria',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white12),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (_, i) {
                        final it = items[i];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: Colors.white12),
                          ),
                          leading: Icon(it.icon),
                          title: Text(it.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                          onTap: it.onTap,
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: items.length,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
