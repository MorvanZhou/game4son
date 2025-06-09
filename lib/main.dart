import 'package:flutter/material.dart';
import 'screens/game_collection_home.dart';

void main() {
  runApp(const GameCollection());
}

class GameCollection extends StatelessWidget {
  const GameCollection({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '游戏合集',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 使用更加中性的主题，不被特定游戏风格影响
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1), // 现代紫色
          secondary: Color(0xFF8B5CF6), // 淡紫色
          surface: Color(0xFF1F2937), // 深灰色
          onPrimary: Color(0xFFFFFFFF),
          onSecondary: Color(0xFFFFFFFF),
          onSurface: Color(0xFFE5E7EB),
        ),
        useMaterial3: true,
        fontFamily: 'System', // 使用系统字体，更加通用
      ),
      home: const GameCollectionHome(), // 使用游戏集合首页
    );
  }
}
