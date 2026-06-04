import 'package:flutter/material.dart';
import 'wechat_constants.dart';

/// 微信风格 ThemeData 生成器
/// 可以快速将 Material 主题切换为微信风格
class WeChatTheme {
  WeChatTheme._();

  /// 生成微信风格的 ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // ===== 颜色 =====
      colorScheme: ColorScheme.fromSeed(
        seedColor: WeChatConstants.primaryGreen,
        primary: WeChatConstants.primaryGreen,
        brightness: Brightness.light,
      ).copyWith(
        surface: Colors.white,
        onSurface: const Color(0xFF181818),
      ),

      // ===== Scaffold =====
      scaffoldBackgroundColor: WeChatConstants.chatBg,

      // ===== AppBar =====
      appBarTheme: const AppBarTheme(
        backgroundColor: WeChatConstants.appBarBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: WeChatConstants.appBarText,
        elevation: 0.5,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: WeChatConstants.appBarText,
          fontSize: WeChatConstants.fontSizeTitle,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: WeChatConstants.appBarText,
          size: 22,
        ),
        actionsIconTheme: IconThemeData(
          color: WeChatConstants.appBarText,
          size: 22,
        ),
      ),

      // ===== 分割线 =====
      dividerColor: WeChatConstants.dividerColor,
      dividerTheme: const DividerThemeData(
        color: WeChatConstants.dividerColor,
        thickness: 0.5,
        space: 0,
      ),

      // ===== 卡片 =====
      cardColor: Colors.white,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // ===== 按钮 =====
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WeChatConstants.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),

      // ===== 输入框 =====
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WeChatConstants.searchBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WeChatConstants.inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WeChatConstants.inputRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WeChatConstants.inputRadius),
          borderSide: const BorderSide(
            color: WeChatConstants.primaryGreen,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        hintStyle: TextStyle(
          fontSize: WeChatConstants.fontSizeHint,
          color: WeChatConstants.secondaryText,
        ),
      ),

      // ===== 列表 =====
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        dense: true,
      ),

      // ===== TabBar =====
      tabBarTheme: const TabBarThemeData(
        labelColor: WeChatConstants.primaryGreen,
        unselectedLabelColor: WeChatConstants.secondaryText,
        indicatorColor: WeChatConstants.primaryGreen,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      ),

      // ===== 底部导航栏 =====
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: WeChatConstants.primaryGreen,
        unselectedItemColor: WeChatConstants.secondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),

      // ===== 对话框 =====
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// 微信风格深色主题
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.fromSeed(
        seedColor: WeChatConstants.primaryGreen,
        primary: WeChatConstants.primaryGreen,
        brightness: Brightness.dark,
      ).copyWith(
        surface: const Color(0xFF1E1E1E),
        onSurface: Colors.white,
      ),

      scaffoldBackgroundColor: WeChatConstants.chatBgDark,

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: WeChatConstants.fontSizeTitle,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white70, size: 22),
        actionsIconTheme: IconThemeData(color: Colors.white70, size: 22),
      ),

      dividerColor: const Color(0xFF303030),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF303030),
        thickness: 0.5,
        space: 0,
      ),

      cardColor: const Color(0xFF262626),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WeChatConstants.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WeChatConstants.inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WeChatConstants.inputRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WeChatConstants.inputRadius),
          borderSide: const BorderSide(
            color: WeChatConstants.primaryGreen,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintStyle: TextStyle(
          fontSize: WeChatConstants.fontSizeHint,
          color: Colors.grey[500],
        ),
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        dense: true,
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: WeChatConstants.primaryGreen,
        unselectedLabelColor: Colors.grey,
        indicatorColor: WeChatConstants.primaryGreen,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: WeChatConstants.primaryGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF262626),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
