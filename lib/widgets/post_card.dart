// lib/widgets/post_card.dart
import 'dart:ui' as ui; // 👈 para ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/post.dart';

class PostCard extends StatelessWidget {
  final PostItem item;
  final bool locked;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Si lo pasas, fuerza la calidad. Si es null, se auto-detecta (Wi-Fi alta, datos media).
  final bool? highQuality;

  const PostCard({
    super.key,
    required this.item,
    this.locked = false,
    this.onTap,
    this.trailing,
    this.highQuality,
  });

  Future<bool> _isWifi() async {
    final c = await Connectivity().checkConnectivity();
    return c == ConnectivityResult.wifi;
  }

  @override
  Widget build(BuildContext context) {
    const cardWidth = 180;
    const cardHeight = 240;

    return Container(
      width: cardWidth.toDouble(),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: locked ? null : onTap,
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          color: const Color(0xFF1E1E1E),
          child: Stack(
            children: [
              // ====== Capa 1: Low-res BLUR ======
              Positioned.fill(
                child: _BlurLowResImage(
                  url: item.imageUrl,
                  // Low-res fijo, super ligero; si no hay url, pinta un fondo.
                  fallbackColor: Colors.black26,
                ),
              ),

              // ====== Capa 2: Imagen buena (con calidad adaptativa) ======
              if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                Positioned.fill(
                  child: FutureBuilder<bool>(
                    future: highQuality != null ? Future.value(highQuality) : _isWifi(),
                    builder: (context, snap) {
                      final useHigh = snap.data ?? false; // mientras detecta, media
                      final dpr = MediaQuery.of(context).devicePixelRatio;
                      // Ajuste de tamaño según red
                      final scale = useHigh ? 1.2 : 0.8;
                      final memW = (cardWidth * dpr * scale).round().clamp(220, 1200);
                      final memH = (cardHeight * dpr * scale).round().clamp(240, 1400);

                      return CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: memW,
                        memCacheHeight: memH,
                        maxWidthDiskCache: memW,
                        maxHeightDiskCache: memH,
                        // Deja que se vea el BLUR detrás mientras entra
                        placeholder: (_, __) => const SizedBox.shrink(),
                        fadeInDuration: const Duration(milliseconds: 160),
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                        ),
                      );
                    },
                  ),
                ),

              // ====== Capa 3: Overlay para contraste del texto ======
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.70)],
                    ),
                  ),
                ),
              ),

              // ====== Capa 4: Candado si está bloqueado ======
              if (locked)
                Positioned.fill(
                  child: Container(
                    color: Colors.black38,
                    child: const Center(
                      child: Icon(Icons.lock, size: 48, color: Colors.white70),
                    ),
                  ),
                ),

              // ====== Capa 5: Contenido inferior (título + acciones) ======
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title ?? 'Sin título',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 2),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (trailing != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [trailing!],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fondo borroso con mini-carga real de la misma imagen en ultra-baja resolución.
/// Si no hay URL, pinta [fallbackColor].
class _BlurLowResImage extends StatelessWidget {
  final String? url;
  final Color fallbackColor;

  const _BlurLowResImage({
    required this.url,
    required this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(color: fallbackColor);
    }

    // Cargamos la MISMA URL pero en extra pequeño, y la desenfocamos.
    // Esto evita “flicker” y da impresión de carga instantánea.
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final tinyW = (48 * dpr).round(); // ~48px lógicos
    final tinyH = (64 * dpr).round();

    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        memCacheWidth: tinyW,
        memCacheHeight: tinyH,
        maxWidthDiskCache: tinyW,
        maxHeightDiskCache: tinyH,
        fadeInDuration: const Duration(milliseconds: 80),
        placeholder: (_, __) => Container(color: fallbackColor),
        errorWidget: (_, __, ___) => Container(color: fallbackColor),
      ),
    );
  }
}
