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
    // 获取当前时间决定主题
    final currentHour = DateTime.now().hour;
    final isDayTime = currentHour >= 6 && currentHour < 19;
    
    // 定义配色
    final backgroundColor = isDayTime ? const Color(0xFFF7F7F7) : const Color(0xFF121212);
    final cardBackground = isDayTime ? Colors.white : const Color(0xFF1E1E1E);
    final textColor = isDayTime ? const Color(0xFF202124) : const Color(0xFFE8EAED);
    final secondaryTextColor = isDayTime ? const Color(0xFF5F6368) : const Color(0xFF9AA0A6);
    final accentColor = isDayTime ? const Color(0xFF1A73E8) : const Color(0xFF8AB4F8);
    final borderColor = isDayTime ? const Color(0xFFDADCE0) : const Color(0xFF3C4043);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Chrome Dino Runner',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        systemOverlayStyle: isDayTime 
            ? SystemUiOverlayStyle.dark 
            : SystemUiOverlayStyle.light,
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
      body: Column(
        children: [
          // 游戏统计信息栏
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDayTime ? 0.1 : 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: borderColor, width: 0.5),
            ),
            child: Row(
              children: [
                // 得分
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.star,
                    iconColor: const Color(0xFF1A73E8),
                    label: '得分',
                    value: game.points.toString(),
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: borderColor,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                // 速度
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.speed,
                    iconColor: const Color(0xFF34A853),
                    label: '速度',
                    value: game.gameSpeed.toString(),
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: borderColor,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                // 状态
                Expanded(
                  child: _buildStatItem(
                    icon: game.isRunning 
                        ? (game.isPaused ? Icons.pause : Icons.play_arrow)
                        : Icons.play_arrow,
                    iconColor: game.isRunning && !game.isPaused 
                        ? const Color(0xFF34A853) 
                        : const Color(0xFFEA4335),
                    label: '状态',
                    value: game.isRunning 
                        ? (game.isPaused ? '暂停' : '运行')
                        : '等待',
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          
          // 游戏区域
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDayTime ? 0.1 : 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: borderColor, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GameWidget<ChromeDinoGame>.controlled(
                  gameFactory: () => game,
                ),
              ),
            ),
          ),
          
          // 控制说明
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDayTime ? 0.1 : 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: borderColor, width: 0.5),
            ),
            child: Column(
              children: [
                Text(
                  '🎮 控制说明',
                  style: TextStyle(
                    fontSize: 18,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlItem(
                      icon: Icons.keyboard_arrow_up,
                      label: '跳跃',
                      color: accentColor,
                      textColor: secondaryTextColor,
                    ),
                    _buildControlItem(
                      icon: Icons.keyboard_arrow_down,
                      label: '蹲下',
                      color: const Color(0xFF34A853),
                      textColor: secondaryTextColor,
                    ),
                    _buildControlItem(
                      icon: Icons.pause,
                      label: '暂停 (P)',
                      color: const Color(0xFFEA4335),
                      textColor: secondaryTextColor,
                    ),
                    _buildControlItem(
                      icon: Icons.play_arrow,
                      label: '继续 (R)',
                      color: const Color(0xFF34A853),
                      textColor: secondaryTextColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildControlItem({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
