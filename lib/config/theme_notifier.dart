import 'package:flutter/material.dart';
import 'theme.dart';

/// Accent colors available in the app.
enum AccentColor { popcorn, siege, ocean, forest, lavender }

/// Singleton [ValueNotifier] that provides reactive [ThemeData].
///
/// Call [toggleDark] to switch dark/light and [setAccent] to change the
/// accent colour. Listeners are notified automatically.
class ThemeNotifier extends ValueNotifier<ThemeData> {
  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------
  static final ThemeNotifier instance = ThemeNotifier._();

  ThemeNotifier._() : super(_buildTheme(true, AccentColor.popcorn));

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------
  bool _isDark = true;
  AccentColor _accent = AccentColor.popcorn;

  bool get isDark => _isDark;
  AccentColor get accent => _accent;

  /// Toggle between dark and light mode.
  void toggleDark() {
    _isDark = !_isDark;
    value = _buildTheme(_isDark, _accent);
    notifyListeners();
  }

  /// Change the accent colour.
  void setAccent(AccentColor c) {
    _accent = c;
    value = _buildTheme(_isDark, c);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Theme builder
  // ---------------------------------------------------------------------------
  static ThemeData _buildTheme(bool dark, AccentColor accent) {
    final Color primary = _accentColor(accent);
    final Color secondary = accent == AccentColor.popcorn ? siege : popcorn;

    final Color bg = dark ? onyx : ecran;
    final Color surface = dark ? projecteur : Colors.white;
    final Color onSurface = dark ? ecran : onyx;
    final Color onSurfaceSecondary = ticket; // keep ticket for both

    final ColorScheme colorScheme = dark
        ? ColorScheme.dark(
            primary: primary,
            secondary: secondary,
            surface: surface,
            onPrimary: dark ? onyx : ecran,
            onSecondary: dark ? onyx : ecran,
            onSurface: onSurface,
          )
        : ColorScheme.light(
            primary: primary,
            secondary: secondary,
            surface: surface,
            onPrimary: dark ? onyx : ecran,
            onSecondary: dark ? onyx : ecran,
            onSurface: onSurface,
          );

    return ThemeData(
      brightness: dark ? Brightness.dark : Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      cardColor: surface,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(color: primary, fontSize: 12);
          }
          return TextStyle(color: onSurfaceSecondary, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary);
          }
          return const IconThemeData(color: ticket);
        }),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: onSurface),
        titleMedium: TextStyle(color: onSurface),
        bodyMedium: TextStyle(color: onSurface),
        bodySmall: TextStyle(color: onSurfaceSecondary),
        labelLarge: TextStyle(color: onSurface),
      ),
    );
  }

  /// Map [AccentColor] to its [Color] value.
  static Color _accentColor(AccentColor accent) {
    switch (accent) {
      case AccentColor.popcorn:
        return popcorn;
      case AccentColor.siege:
        return siege;
      case AccentColor.ocean:
        return ocean;
      case AccentColor.forest:
        return forest;
      case AccentColor.lavender:
        return lavender;
    }
  }
}
