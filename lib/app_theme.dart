import 'package:flutter/material.dart';

class AppTheme {
  // ── 浅色配色 ──
  static const Color primaryYellow = Color(0xFFFFE4B5);
  static const Color primaryDark = Color(0xFFF5D89A);
  static const Color accentOrange = Color(0xFFFFA500);
  static const Color bgColor = Color(0xFFFFFDF5);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textBrown = Color(0xFF5D4037);
  static const Color textLight = Color(0xFF9E8E7E);
  static const Color doneGreen = Color(0xFF81C784);
  static const Color deleteRed = Color(0xFFE57373);

  // ── 深色配色 ──
  static const Color darkBg = Color(0xFF1F1C18);       // 柔和深米灰
  static const Color darkCard = Color(0xFF2E2A26);      // 浅灰棕卡片
  static const Color darkText = Color(0xFFF2EAD3);      // 浅米白主文字
  static const Color darkTextLight = Color(0xFFA89F91); // 浅灰次要文字
  static const Color darkDivider = Color(0xFF3D3833);   // 分割线
  static const Color darkAccent = Color(0xFFFFAA33);    // 暖橙强调色

  static ThemeData get theme => lightTheme;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      // 整体背景
      scaffoldBackgroundColor: bgColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentOrange,
        primary: accentOrange,
        secondary: primaryYellow,
        surface: bgColor,
        onPrimary: Colors.white,
        onSecondary: textBrown,
        onSurface: textBrown,
      ),
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryYellow,
        foregroundColor: textBrown,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textBrown,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      // 卡片
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shadowColor: primaryYellow.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      // 按钮
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentOrange,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: accentOrange.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // 输入框
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryYellow),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryYellow.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentOrange, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        hintStyle: const TextStyle(color: textLight),
      ),
      // 浮动按钮
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentOrange,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      // 文字主题
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textBrown,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textBrown,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textBrown,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: textBrown, fontSize: 16),
        bodyMedium: TextStyle(color: textBrown, fontSize: 14),
        bodySmall: TextStyle(color: textLight, fontSize: 12),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkAccent,
        primary: darkAccent,
        secondary: darkCard,
        surface: darkBg,
        brightness: Brightness.dark,
        onPrimary: Colors.white,
        onSecondary: darkText,
        onSurface: darkText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF252522),
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: darkText, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 1,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 0.5,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: darkCard)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: darkCard)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: darkAccent, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        hintStyle: const TextStyle(color: darkTextLight),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: darkText, fontSize: 28, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: darkText, fontSize: 22, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: darkText, fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: darkText, fontSize: 16),
        bodyMedium: TextStyle(color: darkText, fontSize: 14),
        bodySmall: TextStyle(color: darkTextLight, fontSize: 12),
      ),
    );
  }
}
