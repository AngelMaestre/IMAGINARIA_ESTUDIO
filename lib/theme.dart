// lib/theme.dart
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

/// Paleta de marca
class AppColors {
  static const Color wine = Color(0xFF8B1111);   // acento
  static const Color dark = Color(0xFF111827);   // fondo principal
  static const Color darkCard = Color(0xFF1F2937);
  static const Color light = Color(0xFFF3F4F6);
}

/// Tema de la app (Material 3)
class AppTheme {
  /// BorderRadius (NO Geometry) para compatibilidad con OutlineInputBorder
  static const BorderRadius kRadius = BorderRadius.all(Radius.circular(16));

  // Esquemas de color base
  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: AppColors.wine,
    brightness: Brightness.dark,
    primary: AppColors.wine,
    background: AppColors.dark,
    surface: AppColors.darkCard,
  );

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: AppColors.wine,
    brightness: Brightness.light,
    primary: AppColors.wine,
    background: AppColors.light,
    surface: Colors.white,
  );

  // Tipografías (fallback al sistema)
  static TextTheme _textTheme(ColorScheme scheme) {
    final base = ThemeData(brightness: scheme.brightness).textTheme;
    return base.apply(
      bodyColor: scheme.onBackground,
      displayColor: scheme.onBackground,
    );
  }

  // AppBar con blur y degradado
  static PreferredSizeWidget glassAppBar({
    required Widget title,
    List<Widget>? actions,
    bool centerTitle = true,
    bool implyLeading = true,
  }) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: implyLeading,
      centerTitle: centerTitle,
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
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0x700B0B0C), Color(0x400B0B0C), Color(0x000B0B0C)],
                ),
              ),
            ),
          ],
        ),
      ),
      title: title,
      actions: actions,
    );
  }

  // ==== THEME DARK ====
  static ThemeData get dark {
    final scheme = _darkScheme;

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: _textTheme(scheme),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      // ✅ Usa CardThemeData
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: kRadius),
        margin: EdgeInsets.zero,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: const Color(0xFF111827).withOpacity(0.94),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), bottomLeft: Radius.circular(24),
          ),
        ),
      ),
      // ✅ Usa DialogThemeData
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: kRadius),
      ),
      dividerTheme: const DividerThemeData(color: Colors.white12, thickness: 1),
      listTileTheme: ListTileThemeData(
        iconColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: kRadius,
          side: const BorderSide(color: Colors.white12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: scheme.outline.withOpacity(.3)),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0B0B0C).withOpacity(.6),
        border: OutlineInputBorder(
          borderRadius: kRadius,
          borderSide: BorderSide(color: scheme.outline.withOpacity(.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: kRadius,
          borderSide: BorderSide(color: scheme.outline.withOpacity(.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: kRadius,
          borderSide: BorderSide(color: scheme.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surface.withOpacity(.98),
        contentTextStyle: TextStyle(color: scheme.onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: kRadius),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(side: BorderSide(color: Colors.white12)),
        backgroundColor: scheme.surface,
        labelStyle: TextStyle(color: scheme.onSurface),
        selectedColor: scheme.primary.withOpacity(.2),
        secondarySelectedColor: scheme.primary.withOpacity(.3),
      ),
    );
  }

  // ==== THEME LIGHT ====
  static ThemeData get light {
    final scheme = _lightScheme;

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: _textTheme(scheme),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      // ✅ Usa CardThemeData
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: kRadius),
        margin: EdgeInsets.zero,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: Colors.white.withOpacity(.94),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), bottomLeft: Radius.circular(24),
          ),
        ),
      ),
      // ✅ Usa DialogThemeData
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: kRadius),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline.withOpacity(.18), thickness: 1),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: kRadius,
          side: BorderSide(color: scheme.outline.withOpacity(.18)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline.withOpacity(.3)),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: kRadius,
          borderSide: BorderSide(color: scheme.outline.withOpacity(.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: kRadius,
          borderSide: BorderSide(color: scheme.outline.withOpacity(.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: kRadius,
          borderSide: BorderSide(color: scheme.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surface.withOpacity(.98),
        contentTextStyle: TextStyle(color: scheme.onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: kRadius),
      ),
      chipTheme: ChipThemeData(
        shape: StadiumBorder(side: BorderSide(color: scheme.outline.withOpacity(.2))),
        backgroundColor: scheme.surface,
        labelStyle: TextStyle(color: scheme.onSurface),
        selectedColor: scheme.primary.withOpacity(.12),
        secondarySelectedColor: scheme.primary.withOpacity(.16),
      ),
    );
  }
}
