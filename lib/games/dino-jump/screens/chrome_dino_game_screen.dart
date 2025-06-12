import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import '../chrome_dino_game.dart';

/// Chrome Dino 游戏界面 - 优化配色方案
class ChromeDinoGameScreen extends StatefulWidget {
  const ChromeDinoGameScreen({super.key});

  @override
  State<ChromeDinoGameScreen> createState() => _ChromeDinoGameScreenState();
}

class _ChromeDinoGameScreenState extends State<ChromeDinoGameScreen> {
  late ChromeDinoGame game;

  @override
  void initState() {
    super.initState();
    game = ChromeDinoGame();
  }

  @override
  Widget build(BuildContext context) {
    // Chrome Dino原版明亮风格配色 - 简洁清爽
    const backgroundColor = Color(0xFFF7F7F7);        // 浅灰背景，类似Chrome离线页面
    const cardBackground = Colors.white;              // 纯白卡片背景
    const textColor = Color(0xFF535353);              // Chrome Dino原版灰色
    const secondaryTextColor = Color(0xFF9E9E9E);     // 浅灰次要文字
    const accentColor = Color(0xFF4285F4);            // Google蓝色
    const borderColor = Color(0xFFE0E0E0);            // 浅灰边框
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          '🦕 Dino Runner',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 22,
            color: textColor,
            letterSpacing: 0.25,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          // 音效按钮
          IconButton(
            icon: Icon(
              game.soundEnabled ? Icons.volume_up : Icons.volume_off,
              color: secondaryTextColor,
            ),
            onPressed: () {
              setState(() {
                game.toggleSound();
              });
            },
          ),
          // 重新开始按钮
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: accentColor,
            ),
            onPressed: () {
              setState(() {
                game = ChromeDinoGame();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(8), // 减少边距从16到8
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(12), // 减少圆角从20到12
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 8, // 减少模糊半径
                offset: const Offset(0, 2), // 减少偏移
              ),
            ],
            border: Border.all(color: borderColor, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12), // 保持一致的圆角
            child: GameWidget<ChromeDinoGame>.controlled(
              gameFactory: () => game,
            ),
          ),
        ),
      ),
    );
  }
}
