/// Visual identity in the game's colour mood: evening-sky blues, gold,
/// grass-green buttons and elixir pink. No logos or marks are reused.
library;

import 'package:flutter/material.dart';

class Palette {
  Palette._();

  static const night = Color(0xFF0F1E3A);
  static const stone = Color(0xFF1A2D52);
  static const stoneHigh = Color(0xFF24406E);
  static const line = Color(0xFF34528A);
  static const sky = Color(0xFF3FA9F5);
  static const gold = Color(0xFFFFC82E);
  static const goldDeep = Color(0xFFE09A14);
  static const elixir = Color(0xFFD94FD6);
  static const darkElixir = Color(0xFF5A35A8);
  static const grass = Color(0xFF7BD13A);
  static const grassDeep = Color(0xFF4E9A1E);
  static const ember = Color(0xFFF2552C);
  static const ink = Color(0xFFFFFBF2);
  static const inkSoft = Color(0xFFC3D3EE);
  static const inkFaint = Color(0xFF8299C2);
}

const displayFont = 'LilitaOne';
const bodyFont = 'Nunito';

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.gold,
    brightness: Brightness.dark,
  ).copyWith(
    primary: Palette.gold,
    onPrimary: Palette.night,
    secondary: Palette.elixir,
    surface: Palette.stone,
    onSurface: Palette.ink,
    error: Palette.ember,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.night,
    fontFamily: bodyFont,
  );

  TextStyle display(double size) => TextStyle(
        fontFamily: displayFont,
        fontSize: size,
        color: Palette.ink,
        letterSpacing: 0.4,
        height: 1.1,
        shadows: const [Shadow(offset: Offset(0, 2), blurRadius: 0, color: Color(0x99000000))],
      );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displaySmall: display(34),
      headlineMedium: display(28),
      headlineSmall: display(22),
      titleLarge: display(20),
      titleMedium: const TextStyle(
          fontWeight: FontWeight.w800, fontSize: 16, color: Palette.ink),
      bodyLarge: const TextStyle(fontSize: 16, color: Palette.ink, height: 1.4),
      bodyMedium:
          const TextStyle(fontSize: 14, color: Palette.inkSoft, height: 1.4),
      labelLarge: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Palette.night,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: display(24),
    ),
    cardTheme: CardThemeData(
      color: Palette.stone,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Palette.line),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Palette.stone,
      indicatorColor: Palette.gold.withValues(alpha: 0.18),
      height: 66,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: s.contains(WidgetState.selected)
              ? Palette.gold
              : Palette.inkFaint,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? Palette.gold
              : Palette.inkFaint,
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: Palette.stone,
      selectedColor: Palette.gold,
      side: const BorderSide(color: Palette.line),
      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
      shape: const StadiumBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.grass,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Palette.grassDeep.withValues(alpha: 0.5),
        side: const BorderSide(color: Palette.grassDeep, width: 2),
        textStyle: const TextStyle(
            fontFamily: displayFont,
            fontSize: 18,
            letterSpacing: 0.4,
            shadows: [Shadow(offset: Offset(0, 1.5), color: Color(0x99000000))]),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.stone,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Palette.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Palette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Palette.gold, width: 1.6),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Palette.line, thickness: 1),
  );
}
