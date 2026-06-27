import 'package:flutter/material.dart';

/// A dark theme that lets the strip's actual color be the visual accent,
/// rather than imposing a fixed brand color. The app's background stays
/// near-black so color previews and presets read as glowing light.
class AppTheme {
  static const background = Color.fromARGB(255, 0, 0, 0);
  static const surface = Color(0xFF0E0E12);
  static const surfaceHigh = Color(0xFF1A1A20);
  static const textPrimary = Color(0xFFF2F2F5);
  static const textSecondary = Color(0xFF9A9AA5);
  static const divider = Color(0xFF2E2E38);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: Color(0xFF7FD8C4),
        secondary: Color(0xFFE8A87C),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: textSecondary),
        labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
    );
  }
}
