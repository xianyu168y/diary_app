import 'package:flutter/material.dart';

class AppTheme {
  // ═══════════════════════════════════════════════
  //  Design Tokens — Color Palette
  // ═══════════════════════════════════════════════

  // ── 语义角色 ──
  // surface  : 页面背景（浅色 #FFFDF5 / 深色 #1F1C18）
  // card     : 卡片背景（浅色 #FFFFFF / 深色 #2E2A26）
  // ink      : 主要文字（浅色 #5D4037 / 深色 #F2EAD3）
  // ink-muted: 次要文字（浅色 #7D6B5A / 深色 #8F7F6E）
  // accent   : 强调色（浅色 #FFA500 / 深色 #FFAA33）
  // divider  : 分割线（浅色 #FFE4B5 / 深色 #3D3833）

  // ── 浅色配色 ──
  static const Color primaryYellow = Color(0xFFFFE4B5);
  static const Color primaryDark = Color(0xFFF5D89A);
  static const Color accentOrange = Color(0xFFFFA500);
  static const Color bgColor = Color(0xFFFFFDF5);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textBrown = Color(0xFF5D4037);
  static const Color textLight = Color(0xFF7D6B5A); // 调暗 ↑ 从 #9E8E7E 提升至 WCAG AA 4.5:1
  static const Color doneGreen = Color(0xFF81C784);
  static const Color deleteRed = Color(0xFFE57373);

  // ── 深色配色 ──
  static const Color darkBg = Color(0xFF1F1C18);
  static const Color darkCard = Color(0xFF2E2A26);
  static const Color darkText = Color(0xFFF2EAD3);
  static const Color darkTextLight = Color(0xFF8F7F6E); // 调暗 ↑ 从 #A89F91
  static const Color darkDivider = Color(0xFF3D3833);
  static const Color darkAccent = Color(0xFFFFAA33);

  // ═══════════════════════════════════════════════
  //  Spacing & Radius Tokens
  // ═══════════════════════════════════════════════
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 20;
  static const double space2xl = 28;
  static const double space3xl = 40;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radius2xl = 24;

  static const double touchMin = 44.0; // 最小触摸目标 WCAG

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
