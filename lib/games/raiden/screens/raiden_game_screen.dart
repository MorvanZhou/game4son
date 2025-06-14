import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../raiden_game.dart';

/// 雷电游戏界面
/// 
/// 功能特性：
/// 1. 游戏引擎集成
/// 2. 触摸控制支持
/// 3. 游戏状态显示
/// 4. 暂停/重新开始功能
/// 5. 自适应布局
class RaidenGameScreen extends StatefulWidget {
  const RaidenGameScreen({super.key});

  @override
  State<RaidenGameScreen> createState() => _RaidenGameScreenState();
}

class _RaidenGameScreenState extends State<RaidenGameScreen> {
  late RaidenGame game;
  bool isPaused = false;
  int score = 0;
  int lives = 3;
  bool isGameOver = false;

  @override
  void initState() {
    super.initState();
    
    // 创建游戏实例
    game = RaidenGame();
    
    // 设置游戏状态回调
    game.onGameStateChanged = (newScore, newLives, gameOver) {
      setState(() {
        score = newScore;
        lives = newLives;
        isGameOver = gameOver;
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // 游戏主体 - 添加焦点和键盘监听
          Focus(
            autofocus: true,
            child: GameWidget<RaidenGame>.controlled(
              gameFactory: () => game,
            ),
          ),
          
          // 游戏状态HUD
          _buildGameHUD(),
          
          // 游戏结束覆盖层
          if (isGameOver) _buildGameOverOverlay(),
          
          // 暂停覆盖层
          if (isPaused && !isGameOver) _buildPauseOverlay(),
        ],
      ),
      floatingActionButton: _buildControlButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
        ).createShader(bounds),
        child: const Text(
          '雷电射击',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.5,
          ),
        ),
      ),
      backgroundColor: Colors.black87,
      elevation: 0,
      actions: [
        // 暂停按钮
        IconButton(
          onPressed: _togglePause,
          icon: Icon(
            isPaused ? Icons.play_arrow : Icons.pause,
            color: const Color(0xFF4ECDC4),
            size: 28,
          ),
          tooltip: isPaused ? '继续' : '暂停',
        ),
        // 重新开始按钮
        IconButton(
          onPressed: _restartGame,
          icon: const Icon(
            Icons.refresh,
            color: Color(0xFFFF6B6B),
            size: 28,
          ),
          tooltip: '重新开始',
        ),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a1a), Color(0xFF2a2a2a)],
          ),
        ),
      ),
    );
  }

  /// 构建游戏HUD
  Widget _buildGameHUD() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF4ECDC4).withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 分数显示
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '分数',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                Text(
                  score.toString().padLeft(6, '0'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4ECDC4),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            
            // 生命值显示
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '生命',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    return Icon(
                      index < lives ? Icons.favorite : Icons.favorite_border,
                      color: index < lives 
                          ? const Color(0xFFFF6B6B) 
                          : Colors.grey.withOpacity(0.3),
                      size: 20,
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建控制按钮
  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 移动控制区域提示
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF4ECDC4).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '触摸屏幕移动飞机\n方向键或WASD控制',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // 射击提示
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFF6B6B).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '自动射击\n空格键手动射击',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建游戏结束覆盖层
  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2a2a2a),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFF6B6B),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B6B).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 游戏结束图标
              const Icon(
                Icons.military_tech,
                size: 64,
                color: Color(0xFFFF6B6B),
              ),
              
              const SizedBox(height: 16),
              
              // 游戏结束文本
              const Text(
                '游戏结束',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B6B),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 最终分数
              Text(
                '最终分数: $score',
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFF4ECDC4),
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 返回按钮
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.home, color: Colors.white),
                    label: const Text(
                      '返回',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                  
                  // 重新开始按钮
                  ElevatedButton.icon(
                    onPressed: _restartGame,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      '再来一局',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B6B),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建暂停覆盖层
  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2a2a2a),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF4ECDC4),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pause_circle_outline,
                size: 64,
                color: Color(0xFF4ECDC4),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                '游戏暂停',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4ECDC4),
                ),
              ),
              
              const SizedBox(height: 24),
              
              ElevatedButton.icon(
                onPressed: _togglePause,
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text(
                  '继续游戏',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 切换暂停状态
  void _togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
    
    if (isPaused) {
      game.pauseEngine();
    } else {
      game.resumeEngine();
    }
  }

  /// 重新开始游戏
  void _restartGame() {
    setState(() {
      isPaused = false;
      isGameOver = false;
      score = 0;
      lives = 3;
    });
    
    game.restartGame();
    game.resumeEngine();
  }

  @override
  void dispose() {
    game.detach();
    super.dispose();
  }
}
