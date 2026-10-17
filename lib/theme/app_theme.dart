import 'package:flutter/material.dart';

class AppTheme {
  // Rich Espresso & Gold Color Palette
  static const Color bgDark = Color(0xFF110E0C);
  static const Color surfaceCard = Color(0xFF1B1512);
  static const Color surfaceElevated = Color(0xFF261E1A);
  static const Color surfaceInput = Color(0xFF161210);
  static const Color borderSubtle = Color(0xFF382C24);
  static const Color borderFocused = Color(0xFFD4AF37);

  // Accents
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF3D270);
  static const Color crema = Color(0xFFFDFBF7);
  static const Color textMuted = Color(0xFF9E8E85);
  static const Color textSecondary = Color(0xFFD1C7BD);

  // Functional Status Colors
  static const Color cyanCold = Color(0xFF38BDF8);
  static const Color amberHeat = Color(0xFFF97316);
  static const Color rubyEmergency = Color(0xFFEF4444);
  static const Color emeraldSuccess = Color(0xFF10B981);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: goldPrimary,
      colorScheme: const ColorScheme.dark(
        primary: goldPrimary,
        secondary: goldLight,
        surface: surfaceCard,
        background: bgDark,
        error: rubyEmergency,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: crema,
        onBackground: crema,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceCard,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: crema,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: goldPrimary),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldPrimary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: goldPrimary,
          side: const BorderSide(color: goldPrimary, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        selectedColor: goldPrimary.withOpacity(0.2),
        secondarySelectedColor: goldPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: goldPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: goldPrimary,
        inactiveTrackColor: surfaceElevated,
        thumbColor: goldLight,
        overlayColor: goldPrimary.withOpacity(0.2),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceCard,
        indicatorColor: goldPrimary.withOpacity(0.25),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(
              color: goldPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            );
          }
          return const TextStyle(
            color: textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: goldPrimary, size: 24);
          }
          return const IconThemeData(color: textMuted, size: 24);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaceCard,
        indicatorColor: goldPrimary.withOpacity(0.25),
        selectedIconTheme: const IconThemeData(color: goldPrimary, size: 26),
        unselectedIconTheme: const IconThemeData(color: textMuted, size: 24),
        selectedLabelTextStyle: const TextStyle(
          color: goldPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: const TextStyle(color: crema),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderSubtle),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
