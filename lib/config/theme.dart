import 'package:flutter/material.dart';

const Color onyx = Color(0xFF121214);
const Color projecteur = Color(0xFF1A1A1E);
const Color popcorn = Color(0xFFFFC107);
const Color siege = Color(0xFFE53935);
const Color ecran = Color(0xFFF5F5F7);
const Color ticket = Color(0xFF9E9E9E);

class AppTheme {
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: onyx,
    cardColor: projecteur,

    colorScheme: const ColorScheme.dark(
      primary: popcorn,
      secondary: siege,
      surface: projecteur,
      onPrimary: onyx,
      onSecondary: ecran,
      onSurface: ecran,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: onyx,
      foregroundColor: ecran,
      surfaceTintColor: Colors.transparent,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: projecteur,
      indicatorColor: popcorn.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: popcorn, fontSize: 12);
        }
        return TextStyle(color: ticket, fontSize: 12);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: popcorn);
        }
        return const IconThemeData(color: ticket);
      }),
    ),

    textTheme: const TextTheme(
      titleLarge: TextStyle(color: ecran),
      titleMedium: TextStyle(color: ecran),
      bodyMedium: TextStyle(color: ecran),
      bodySmall: TextStyle(color: ticket),
      labelLarge: TextStyle(color: ecran),
    ),
  );
}
