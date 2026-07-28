import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors — sama di light & dark
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color accent = Color(0xFF42A5F5);
  static const Color success = Color(0xFF66BB6A);
  static const Color danger = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);

  // Light mode
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);

  // Dark mode - MIDNIGHT INDIGO
  static const Color darkBackground = Color(0xFF13111C); // Hitam dengan aura ungu gelap
  static const Color darkCard = Color(0xFF1E1C2A); // Kartu ungu keabu-abuan
  static const Color darkTextPrimary = Color(0xFFF8F9FA); // Putih salju
  static const Color darkTextSecondary = Color(0xFFAFAEC2); // Abu-abu lavender
  static const Color darkDivider = Color(0xFF2D2B3B); // Garis pemisah ungu gelap

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? darkBackground : background;
    final card = isDark ? darkCard : cardBg;
    final txtPrimary = isDark ? darkTextPrimary : textPrimary;
    final txtSecondary = isDark ? darkTextSecondary : textSecondary;
    final inputFill = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE0E0E0);
    final navBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final navIndicator = isDark ? const Color(0xFF1E3A5F) : primaryLight;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        secondary: accent,
        surface: card,
      ),
      scaffoldBackgroundColor: bg,
      dividerColor: isDark ? darkDivider : const Color(0xFFE0E0E0),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isDark
              ? const BorderSide(color: Color(0xFF334155), width: 1)
              : BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        labelStyle: TextStyle(color: txtSecondary),
        hintStyle: TextStyle(color: txtSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBg,
        indicatorColor: navIndicator,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
                color: primary, fontWeight: FontWeight.w600, fontSize: 12);
          }
          return TextStyle(color: txtSecondary, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary);
          }
          return IconThemeData(color: txtSecondary);
        }),
      ),
      listTileTheme: ListTileThemeData(
        textColor: txtPrimary,
        subtitleTextStyle: TextStyle(color: txtSecondary, fontSize: 12),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        titleTextStyle: TextStyle(
            color: txtPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        contentTextStyle: TextStyle(color: txtSecondary, fontSize: 14),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: txtPrimary),
        bodyMedium: TextStyle(color: txtPrimary),
        bodySmall: TextStyle(color: txtSecondary),
        titleLarge: TextStyle(color: txtPrimary, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: txtPrimary, fontWeight: FontWeight.w600),
      ),
      iconTheme: IconThemeData(color: txtSecondary),
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        textStyle: TextStyle(color: txtPrimary),
      ),
    );
  }
}
