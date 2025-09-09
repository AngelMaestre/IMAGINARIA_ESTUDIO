// lib/screens/webview_screen.dart
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class WebViewScreen extends StatefulWidget {
  final Uri initialUri;
  final String? title;           // opcional (para AppBar)
  final Set<String>? inAppHosts; // dominios que se abren dentro del WebView

  const WebViewScreen({
    super.key,
    required this.initialUri,
    this.title,
    this.inAppHosts,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  double _progress = 0;
  bool _canGoBack = false;
  bool _hadError = false;

  // Dominios internos por defecto (ajústalos a tu proyecto)
  Set<String> get _defaultHosts => {
        'imaginariaestudio.com',
        'www.imaginariaestudio.com',
        'lavidaenletras.com',
        'www.lavidaenletras.com',
        'muchamusica.com',
        'www.muchamusica.com',
      };

  Set<String> get _inAppHosts => widget.inAppHosts ?? _defaultHosts;

  @override
  void initState() {
    super.initState();

    final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      // iOS/macOS
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      // Android
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent) // evita parpadeos grises
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _hadError = false),
          onProgress: (p) => setState(() => _progress = p / 100),
          onPageFinished: (_) async => _syncCanGoBack(),
          onWebResourceError: (_) => setState(() => _hadError = true),
          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url);

            // 1) Esquemas externos: abrir con apps nativas
            if (_isExternalScheme(uri.scheme)) {
              _launchExternal(uri);
              return NavigationDecision.prevent;
            }

            // 2) Descargas “obvias” (pdf/zip/mp3 etc.) -> fuera a sistema/navegador
            if (_looksLikeDownload(uri)) {
              _launchExternal(uri);
              return NavigationDecision.prevent;
            }

            // 3) target=_blank / dominios externos -> fuera
            final isInAppHost = _inAppHosts.contains(uri.host);
            if (!isInAppHost) {
              _launchExternal(uri);
              return NavigationDecision.prevent;
            }

            // 4) Todo lo demás, dentro del WebView
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setUserAgent(
        'Mozilla/5.0 (Mobile; FlutterWebView) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
      )
      ..loadRequest(widget.initialUri);

    // ===== Ajustes específicos por plataforma =====
    if (controller.platform is AndroidWebViewController) {
      final AndroidWebViewController a = controller.platform as AndroidWebViewController;
      a.setMediaPlaybackRequiresUserGesture(false);
      a.setJavaScriptMode(JavaScriptMode.unrestricted);
      a.enableZoom(false);
      AndroidWebViewController.enableDebugging(true);

      // (Opcional) logs consola JS:
      a.setOnConsoleMessage((msg) {
        // debugPrint('WV Console: ${msg.messageLevel}: ${msg.message}');
      });

      // ❗️IMPORTANTE: NO registramos setOnShowFileSelector aquí
      // para evitar conflictos de tipos/paquetes. (build limpio)
    } else if (controller.platform is WebKitWebViewController) {
      final WebKitWebViewController w = controller.platform as WebKitWebViewController;
      w.setInspectable(true); // Safari Web Inspector en iOS
    }

    _controller = controller;
  }

  bool _isExternalScheme(String scheme) {
    // Incluye todo lo que deba saltar fuera del WebView
    const external = {
      'tel', 'sms', 'mailto', 'whatsapp', 'tg', 'instagram', 'facebook',
      'twitter', 'fb', 'geo', 'maps'
    };
    return external.contains(scheme);
  }

  bool _looksLikeDownload(Uri uri) {
    final path = uri.path.toLowerCase();
    const exts = [
      '.pdf', '.zip', '.rar', '.7z', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
      '.mp3', '.wav', '.aac', '.flac',
      '.mp4', '.mov', '.avi', '.mkv',
      '.apk'
    ];
    return exts.any(path.endsWith);
  }

  Future<void> _launchExternal(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      final browser = uri.scheme.startsWith('http')
          ? uri
          : Uri.parse('https://${uri.toString()}');
      await launchUrl(browser, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _syncCanGoBack() async {
    final canBack = await _controller.canGoBack();
    if (mounted) setState(() => _canGoBack = canBack);
  }

  Future<void> _pullToRefresh() async {
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? 'Imaginaria';

    return PopScope(
      canPop: !_canGoBack, // gestiona back nativo en Android
      onPopInvoked: (didPop) async {
        if (!didPop && await _controller.canGoBack()) {
          await _controller.goBack();
        }
      },
      child: Scaffold(
        // ===== AppBar estilo “glass” =====
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
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
          title: Text(title),
          actions: [
            IconButton(
              tooltip: 'Abrir en navegador',
              onPressed: () async {
                final url = await _controller.currentUrl();
                if (url != null) _launchExternal(Uri.parse(url));
              },
              icon: const Icon(Icons.open_in_browser),
            ),
            IconButton(
              tooltip: 'Recargar',
              onPressed: () => _controller.reload(),
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: AnimatedOpacity(
              opacity: (_progress > 0 && _progress < 1 && !_hadError) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 180),
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(.65),
                      Colors.white.withOpacity(.25),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.transparent,
                  minHeight: 2,
                ),
              ),
            ),
          ),
        ),

        // ===== Cuerpo con WebView y capa de error =====
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _pullToRefresh,
              child: WebViewWidget(controller: _controller),
            ),
            if (_hadError)
              _ErrorOverlay(onRetry: () {
                setState(() => _hadError = false);
                _controller.reload();
              }),
          ],
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorOverlay({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.98),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 56),
              const SizedBox(height: 12),
              const Text('No se pudo cargar la página.'),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
