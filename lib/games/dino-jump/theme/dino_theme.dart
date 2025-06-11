import 'package:flutter/material.dart';

/// Chrome Dino游戏统一配色方案
/// 参考Chrome浏览器离线页面的配色风格
class DinoGameColors {
  // === 主色调定义 ===
  
  // 日间模式配色 - 清爽明亮
  static const Color dayBackground = Color(0xFFF7F7F7);        // 浅灰白背景
  static const Color dayCardBackground = Color(0xFFFFFFFF);     // 纯白卡片背景
  static const Color dayPrimary = Color(0xFF5F6368);           // Chrome灰主色
  static const Color daySecondary = Color(0xFF80868B);         // 次要文本灰
  static const Color dayText = Color(0xFF202124);              // 主文本深灰
  static const Color dayTextSecondary = Color(0xFF5F6368);     // 次要文本
  static const Color dayAccent = Color(0xFF1A73E8);            // Google蓝强调色
  static const Color daySuccess = Color(0xFF34A853);           // Google绿
  static const Color dayWarning = Color(0xFFEA4335);           // Google红

  // 夜间模式配色 - 深色舒适
  static const Color nightBackground = Color(0xFF121212);       // 深黑背景
  static const Color nightCardBackground = Color(0xFF1E1E1E);   // 深灰卡片背景
  static const Color nightPrimary = Color(0xFFE8EAED);         // 浅灰主色
  static const Color nightSecondary = Color(0xFF9AA0A6);       // 次要文本灰
  static const Color nightText = Color(0xFFE8EAED);            // 主文本浅灰
  static const Color nightTextSecondary = Color(0xFF9AA0A6);   // 次要文本
  static const Color nightAccent = Color(0xFF8AB4F8);          // 夜间蓝
  static const Color nightSuccess = Color(0xFF81C995);         // 夜间绿
  static const Color nightWarning = Color(0xFFF28B82);         // 夜间红

  // === 游戏特定颜色 ===
  static const Color gameGround = Color(0xFF535353);           // 地面颜色（Chrome恐龙原色）
  static const Color gameObstacle = Color(0xFF535353);         // 障碍物颜色
  static const Color gameDino = Color(0xFF535353);             // 恐龙颜色
  static const Color gameCloud = Color(0xFFBDC1C6);            // 云朵颜色
  static const Color gameSuccess = Color(0xFF34A853);          // 游戏成功状态颜色
  
  // === 状态颜色 ===
  static const Color scoreColor = Color(0xFF1A73E8);           // 得分颜色
  static const Color speedColor = Color(0xFF34A853);           // 速度颜色
  static const Color pausedColor = Color(0xFFEA4335);          // 暂停颜色

  // === 阴影和边框 ===
  static const Color shadowLight = Color(0x1A000000);          // 浅色阴影
  static const Color shadowDark = Color(0x33000000);           // 深色阴影
  static const Color borderLight = Color(0xFFDADCE0);          // 浅色边框
  static const Color borderDark = Color(0xFF3C4043);           // 深色边框

  /// 获取当前主题配色
  static DinoThemeData getTheme(bool isDayTime) {
    return isDayTime ? dayTheme : nightTheme;
  }

  /// 日间主题
  static DinoThemeData get dayTheme => DinoThemeData(
    background: dayBackground,
    cardBackground: dayCardBackground,
    primary: dayPrimary,
    secondary: daySecondary,
    text: dayText,
    textSecondary: dayTextSecondary,
    accent: dayAccent,
    success: daySuccess,
    warning: dayWarning,
    shadow: shadowLight,
    border: borderLight,
    isDark: false,
  );

  /// 夜间主题
  static DinoThemeData get nightTheme => DinoThemeData(
    background: nightBackground,
    cardBackground: nightCardBackground,
    primary: nightPrimary,
    secondary: nightSecondary,
    text: nightText,
    textSecondary: nightTextSecondary,
    accent: nightAccent,
    success: nightSuccess,
    warning: nightWarning,
    shadow: shadowDark,
    border: borderDark,
    isDark: true,
  );
}

/// 主题数据类
class DinoThemeData {
  final Color background;
  final Color cardBackground;
  final Color primary;
  final Color secondary;
  final Color text;
  final Color textSecondary;
  final Color accent;
  final Color success;
  final Color warning;
  final Color shadow;
  final Color border;
  final bool isDark;

  const DinoThemeData({
    required this.background,
    required this.cardBackground,
    required this.primary,
    required this.secondary,
    required this.text,
    required this.textSecondary,
    required this.accent,
    required this.success,
    required this.warning,
    required this.shadow,
    required this.border,
    required this.isDark,
  });

  /// 获取游戏区域阴影
  List<BoxShadow> get gameAreaShadow => [
    BoxShadow(
      color: shadow,
      blurRadius: isDark ? 8 : 12,
      offset: const Offset(0, 4),
      spreadRadius: isDark ? 0 : 1,
    ),
  ];

  /// 获取卡片阴影
  List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: shadow,
      blurRadius: isDark ? 4 : 8,
      offset: const Offset(0, 2),
    ),
  ];
}
