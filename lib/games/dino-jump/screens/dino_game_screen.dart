import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/dino_game_model.dart';
import '../models/game_entities.dart'; // 导入游戏实体
import '../widgets/dino_game_widget.dart';
import '../services/dino_sound_manager.dart';

class DinoGameScreen extends StatefulWidget {
  const DinoGameScreen({super.key});

  @override
  State<DinoGameScreen> createState() => _DinoGameScreenState();
}

class _DinoGameScreenState extends State<DinoGameScreen> 
    with TickerProviderStateMixin {
  late DinoGameModel gameModel;
  late DinoSoundManager soundManager;
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  
  // 游戏循环定时器
  DateTime? _lastUpdateTime;
  
  // 键盘焦点节点 - 避免重复创建，直接初始化避免LateInitializationError
  final FocusNode _keyboardFocusNode = FocusNode();
  
  // 防止重复按键处理
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};

  @override
  void initState() {
    super.initState();
    
    // 初始化游戏模型和声音管理器
    gameModel = DinoGameModel();
    soundManager = DinoSoundManager();
    
    // 监听游戏状态变化
    gameModel.addListener(_onGameStateChanged);
    
    // 背景动画控制器（用于地面滚动效果）
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundController);
    
    // 启动游戏循环
    _startGameLoop();
  }

  @override
  void dispose() {
    gameModel.removeListener(_onGameStateChanged);
    _backgroundController.dispose();
    _keyboardFocusNode.dispose(); // 释放焦点节点
    soundManager.dispose();
    super.dispose();
  }

  // 游戏状态变化监听器
  void _onGameStateChanged() {
    if (gameModel.gameState == DinoGameState.gameOver) {
      // 游戏结束音效 - 使用通用音效管理器的现有方法
      // soundManager.playEffect('game_over');
    }
  }

  // 启动游戏循环
  void _startGameLoop() {
    _lastUpdateTime = DateTime.now();
    _gameLoop();
  }

  // 游戏循环
  void _gameLoop() {
    if (!mounted) return;
    
    final now = DateTime.now();
    if (_lastUpdateTime != null) {
      final deltaTime = now.difference(_lastUpdateTime!).inMicroseconds / 1000000.0;
      gameModel.update(deltaTime);
    }
    _lastUpdateTime = now;
    
    // 使用WidgetsBinding确保在下一帧调用
    WidgetsBinding.instance.addPostFrameCallback((_) => _gameLoop());
  }

  // 处理键盘输入 - 阻止系统默认按键音效和重复按键
  KeyEventResult _handleKeyEvent(KeyEvent event) {
    final key = event.logicalKey;
    
    if (event is KeyDownEvent) {
      // 检查是否为跳跃按键
      if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.arrowUp) {
        // 防止重复按键处理
        if (_pressedKeys.contains(key)) {
          return KeyEventResult.handled;
        }
        
        _pressedKeys.add(key);
        gameModel.jump();
        
        // 返回handled告诉系统我们已经处理了这个按键，阻止系统默认行为
        return KeyEventResult.handled;
      }
    } else if (event is KeyUpEvent) {
      // 按键释放时从集合中移除
      _pressedKeys.remove(key);
    }
    
    // 对于其他按键，让系统继续处理
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7), // 浅灰色背景模拟白天
      appBar: AppBar(
        title: const Text(
          '恐龙跳跃',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF535353),
          ),
        ),
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF535353)),
        actions: [
          // 全局音频控制按钮 - 一键控制所有声音
          IconButton(
            icon: Icon(
              (soundManager.musicEnabled || soundManager.effectsEnabled) 
                ? Icons.volume_up 
                : Icons.volume_off,
              color: const Color(0xFF535353),
            ),
            onPressed: () {
              setState(() {
                // 如果有任何音频开启，则全部静音；如果全部静音，则全部开启
                if (soundManager.musicEnabled || soundManager.effectsEnabled) {
                  soundManager.muteAll();
                } else {
                  soundManager.unmuteAll();
                }
              });
            },
          ),
          // 重新开始按钮
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: const Color(0xFF535353),
            ),
            onPressed: () {
              gameModel.restart();
            },
          ),
        ],
      ),
      body: KeyboardListener(
        focusNode: _keyboardFocusNode..requestFocus(),
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          onTap: () => gameModel.jump(), // 点击屏幕跳跃
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFF7F7F7),
            child: Column(
              children: [
                // 得分显示区域
                _buildScoreArea(),
                
                // 游戏区域
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ListenableBuilder(
                        listenable: gameModel,
                        builder: (context, child) {
                          return DinoGameWidget(
                            gameModel: gameModel,
                            backgroundAnimation: _backgroundAnimation,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                
                // 控制说明区域
                _buildControlsInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建得分显示区域
  Widget _buildScoreArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ListenableBuilder(
        listenable: gameModel,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 当前得分和难度
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '得分',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF888888),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${gameModel.score}',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // 显示当前难度等级
                  if (gameModel.gameState == DinoGameState.playing)
                    Text(
                      '难度: Lv.${gameModel.difficultyLevel}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getDifficultyColor(gameModel.difficultyLevel),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              
              // 最高分和速度指示
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '最高分',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF888888),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${gameModel.highScore}',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // 显示当前速度百分比
                  if (gameModel.gameState == DinoGameState.playing)
                    Text(
                      '速度: ${(gameModel.speedPercentage * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
  
  // 根据难度等级获取颜色
  Color _getDifficultyColor(int level) {
    switch (level) {
      case 1: return const Color(0xFF4CAF50); // 绿色 - 简单
      case 2: return const Color(0xFF2196F3); // 蓝色 - 普通
      case 3: return const Color(0xFFFF9800); // 橙色 - 困难
      case 4: return const Color(0xFFFF5722); // 红色 - 专家
      case 5: return const Color(0xFF9C27B0); // 紫色 - 大师
      default: return const Color(0xFF666666);
    }
  }

  // 构建控制说明区域
  Widget _buildControlsInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 游戏状态提示
          ListenableBuilder(
            listenable: gameModel,
            builder: (context, child) {
              String statusText;
              Color statusColor;
              
              switch (gameModel.gameState) {
                case DinoGameState.ready:
                  statusText = '点击屏幕或按空格键开始游戏';
                  statusColor = const Color(0xFF666666);
                  break;
                case DinoGameState.playing:
                  statusText = '游戏进行中 - 避开障碍物！';
                  statusColor = const Color(0xFF4CAF50);
                  break;
                case DinoGameState.gameOver:
                  statusText = '游戏结束 - 点击屏幕直接开始新游戏';
                  statusColor = const Color(0xFFFF5722);
                  break;
              }
              
              return Text(
                statusText,
                style: TextStyle(
                  fontSize: 16,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
          
          const SizedBox(height: 10),
          
          // 控制说明
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app,
                color: Color(0xFF888888),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '点击屏幕',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                ),
              ),
              SizedBox(width: 20),
              Icon(
                Icons.keyboard,
                color: Color(0xFF888888),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '空格键 / ↑',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
