import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;
import 'components/dino_player.dart';
import 'components/obstacle.dart';
import 'components/cloud_background.dart';
import 'components/ground_track.dart';

/// Chrome Dino Runner - 完全参考Python版本的逻辑和结构
class ChromeDinoGame extends FlameGame with TapDetector, HasKeyboardHandlerComponents {
  // 游戏常量 - 参考Python版本
  static const double screenWidth = 1100.0;
  static const double screenHeight = 600.0;
  static const int initialGameSpeed = 20; // 参考Python版本的game_speed = 20
  static const Color fontColor = Color(0xFF000000); // 参考Python版本的FONT_COLOR=(0,0,0)
  
  // 游戏状态
  bool isRunning = false;
  bool isPaused = false;
  int gameSpeed = initialGameSpeed;
  int points = 0;
  int deathCount = 0;
  double xPosBg = 0; // 背景X位置
  double yPosBg = 380; // 背景Y位置 - 参考Python版本
  
  // 游戏组件
  late DinoPlayer player;
  late CloudBackground cloud;
  late GroundTrack groundTrack;
  final List<Obstacle> obstacles = [];
  
  // UI组件
  late TextComponent scoreText;
  late TextComponent startText;
  late TextComponent pauseText;
  
  // 音效管理
  final AudioPlayer audioPlayer = AudioPlayer();
  bool soundEnabled = true;
  
  // 随机数生成器
  final math.Random random = math.Random();

  @override
  Future<void> onLoad() async {
    // 设置游戏世界大小 - 参考Python版本的屏幕尺寸
    camera.viewfinder.visibleGameSize = Vector2(screenWidth, screenHeight);
    
    // 初始化游戏组件 - 参考Python版本的main函数结构
    await _initializeGameComponents();
    
    // 初始化UI
    await _setupUI();
    
    // 显示开始菜单
    _showStartMenu();
  }

  /// 初始化游戏组件 - 参考Python版本的main函数
  Future<void> _initializeGameComponents() async {
    // 初始化地面轨道 - 参考Python版本的background函数
    groundTrack = GroundTrack();
    add(groundTrack);
    
    // 初始化恐龙玩家 - 参考Python版本的Dinosaur类
    player = DinoPlayer();
    add(player);
    
    // 初始化云朵背景 - 参考Python版本的Cloud类
    cloud = CloudBackground();
    add(cloud);
  }

  /// 设置UI界面 - 参考Python版本的score函数和文本显示
  Future<void> _setupUI() async {
    // 得分显示 - 参考Python版本的score函数
    scoreText = TextComponent(
      text: 'Points: 0',
      position: Vector2(screenWidth - 200, 40),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: fontColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(scoreText);
    
    // 开始游戏提示 - 参考Python版本的menu函数
    startText = TextComponent(
      text: 'Press any Key to Start',
      position: Vector2(screenWidth / 2, screenHeight / 2),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 30,
          color: fontColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(startText);
    
    // 暂停文本
    pauseText = TextComponent(
      text: "Game Paused, Press 'R' to Resume",
      position: Vector2(screenWidth / 2, screenHeight / 3),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 30,
          color: fontColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (!isRunning || isPaused) return;
    
    // 更新得分和游戏速度 - 参考Python版本的score函数
    _updateScore();
    
    // 更新用户输入 - 参考Python版本的用户输入检测
    _handleContinuousInput();
    
    // 生成障碍物 - 参考Python版本的障碍物生成逻辑
    _generateObstacles();
    
    // 更新所有障碍物
    _updateObstacles();
    
    // 检查碰撞 - 参考Python版本的碰撞检测
    _checkCollisions();
    
    // 更新背景位置 - 参考Python版本的background函数
    _updateBackground();
  }

  /// 处理连续输入 - 参考Python版本的连续按键检测
  void _handleContinuousInput() {
    // 这里会通过键盘事件处理，暂时保留此方法以备将来扩展
  }

  /// 更新得分 - 参考Python版本的score函数
  void _updateScore() {
    // 降低得分增长速度，避免过快
    points += (gameSpeed / 10).round();
    
    // 每100分提升游戏速度 - 参考Python版本的速度提升逻辑
    if (points % 100 == 0 && points > 0) {
      gameSpeed += 1;
    }
    
    scoreText.text = 'Points: $points';
  }

  /// 生成障碍物 - 参考Python版本的障碍物生成逻辑
  void _generateObstacles() {
    // 参考Python版本: if len(obstacles) == 0:
    if (obstacles.isEmpty) {
      // 随机选择障碍物类型 - 参考Python版本的random.randint(0, 2)
      final obstacleType = random.nextInt(3); // 0: 小仙人掌, 1: 大仙人掌, 2: 飞鸟
      
      Obstacle newObstacle;
      
      switch (obstacleType) {
        case 0:
          newObstacle = SmallCactus();
          print('生成小仙人掌障碍物');
          break;
        case 1:
          newObstacle = LargeCactus();
          print('生成大仙人掌障碍物');
          break;
        case 2:
        default:
          newObstacle = SmallCactus(); // 暂时使用小仙人掌，避免飞鸟的复杂性
          print('生成小仙人掌障碍物(默认)');
          break;
      }
      
      // 添加到游戏和障碍物列表
      add(newObstacle);
      obstacles.add(newObstacle);
      
      print('障碍物已添加: 类型=${newObstacle.runtimeType}, 初始位置=${newObstacle.position}');
    }
  }

  /// 更新所有障碍物 - 参考Python版本的obstacle.update()逻辑
  void _updateObstacles() {
    // 更新障碍物位置并移除超出屏幕的障碍物
    obstacles.removeWhere((obstacle) {
      // 在调用updateMovement前记录位置
      final beforePosition = Vector2.copy(obstacle.position);
      
      // 手动调用移动更新
      obstacle.updateMovement(gameSpeed);
      
      // 检查位置是否异常变化
      final afterPosition = Vector2.copy(obstacle.position);
      if ((beforePosition.y - afterPosition.y).abs() > 1.0) {
        print('警告: 障碍物Y坐标异常变化! ${beforePosition} -> ${afterPosition}');
      }
      
      // 添加调试信息
      print('障碍物位置更新: position=${obstacle.position}, isOffScreen=${obstacle.isOffScreen()}');
      
      if (obstacle.isOffScreen()) {
        print('障碍物超出屏幕，将被移除');
        obstacle.removeFromParent();
        return true;
      }
      return false;
    });
  }

  /// 检查碰撞 - 参考Python版本的player.dino_rect.colliderect(obstacle.rect)
  void _checkCollisions() {
    for (final obstacle in obstacles) {
      // 添加调试信息 - 显示恐龙和障碍物的位置
      if (obstacles.length == 1) { // 只在有障碍物时显示一次
        final dinoRect = player.getCollisionRect();
        final obstacleRect = obstacle.getCollisionRect();
        print('恐龙位置: ${player.position}, 碰撞框: ${dinoRect}');
        print('障碍物位置: ${obstacle.position}, 碰撞框: ${obstacleRect}');
      }
      
      if (player.checkCollision(obstacle)) {
        print('碰撞检测到！游戏结束');
        _gameOver();
        break;
      }
    }
  }

  /// 更新背景位置 - 参考Python版本的background函数
  void _updateBackground() {
    // 地面轨道和云朵会自动更新，这里主要处理全局背景移动
    groundTrack.updateMovement(gameSpeed);
    cloud.updateMovement(gameSpeed);
  }

  /// 游戏结束 - 参考Python版本的游戏结束逻辑
  void _gameOver() {
    isRunning = false;
    deathCount += 1;
    
    // 清理障碍物
    for (final obstacle in obstacles) {
      obstacle.removeFromParent();
    }
    obstacles.clear();
    
    // 停止背景音乐
    _stopBackgroundMusic();
    
    // 播放游戏结束音效
    _playGameOverSound();
    
    // 显示游戏结束菜单
    _showGameOverMenu();
  }

  /// 显示开始菜单 - 参考Python版本的menu函数
  void _showStartMenu() {
    isRunning = false;
    startText.text = 'Press any Key to Start';
    
    if (!startText.isMounted) {
      add(startText);
    }
  }

  /// 显示游戏结束菜单 - 参考Python版本的menu函数游戏结束状态
  void _showGameOverMenu() {
    startText.text = 'Press any Key to Restart';
    
    // 显示最终得分
    final scoreDisplay = TextComponent(
      text: 'Your Score: $points',
      position: Vector2(screenWidth / 2, screenHeight / 2 + 50),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 30,
          color: fontColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(scoreDisplay);
    
    if (!startText.isMounted) {
      add(startText);
    }
  }

  /// 开始游戏 - 参考Python版本的main函数游戏开始逻辑
  void _startGame() {
    isRunning = true;
    isPaused = false;
    gameSpeed = initialGameSpeed;
    points = 0;
    
    // 隐藏开始文本
    if (startText.isMounted) {
      startText.removeFromParent();
    }
    
    // 清理上次游戏的组件
    children.whereType<TextComponent>().where((component) => 
      component != scoreText && component != startText && component != pauseText
    ).forEach((component) => component.removeFromParent());
    
    // 重置游戏组件
    player.reset();
    cloud.reset();
    groundTrack.reset();
    
    // 清理障碍物
    for (final obstacle in obstacles) {
      obstacle.removeFromParent();
    }
    obstacles.clear();
    
    // 播放背景音乐
    _playBackgroundMusic();
  }

  /// 暂停游戏 - 参考Python版本的paused函数
  void _pauseGame() {
    isPaused = true;
    if (!pauseText.isMounted) {
      add(pauseText);
    }
  }

  /// 恢复游戏 - 参考Python版本的unpause函数
  void _resumeGame() {
    isPaused = false;
    if (pauseText.isMounted) {
      pauseText.removeFromParent();
    }
  }

  // 控制输入处理 - 参考Python版本的输入处理逻辑
  @override
  bool onTapDown(TapDownInfo info) {
    _handleInput();
    return true;
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    super.onKeyEvent(event, keysPressed);
    
    if (event is KeyDownEvent) {
      if (keysPressed.contains(LogicalKeyboardKey.space) || 
          keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
        _handleInput();
        if (isRunning && !isPaused) {
          player.jump();
        }
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
        if (isRunning && !isPaused) {
          player.duck();
        }
      } else if (keysPressed.contains(LogicalKeyboardKey.keyP)) {
        if (isRunning && !isPaused) {
          _pauseGame();
        }
      } else if (keysPressed.contains(LogicalKeyboardKey.keyR)) {
        if (isPaused) {
          _resumeGame();
        }
      } else {
        _handleInput();
      }
      return KeyEventResult.handled;
    }
    
    return KeyEventResult.ignored;
  }

  /// 处理通用输入 - 开始游戏或重新开始
  void _handleInput() {
    if (!isRunning && !isPaused) {
      _startGame();
    }
  }

  // 音效管理方法
  Future<void> _playBackgroundMusic() async {
    if (!soundEnabled) return;
    try {
      await audioPlayer.play(AssetSource('sounds/dina-bg-loop.wav'));
      await audioPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      print('播放背景音乐失败: $e');
    }
  }

  Future<void> _stopBackgroundMusic() async {
    try {
      await audioPlayer.stop();
    } catch (e) {
      print('停止背景音乐失败: $e');
    }
  }

  Future<void> _playGameOverSound() async {
    if (!soundEnabled) return;
    try {
      final gameOverPlayer = AudioPlayer();
      await gameOverPlayer.play(AssetSource('sounds/life-lost-game-over.wav'));
    } catch (e) {
      print('播放游戏结束音效失败: $e');
    }
  }

  /// 切换音效开关
  void toggleSound() {
    soundEnabled = !soundEnabled;
    if (!soundEnabled) {
      _stopBackgroundMusic();
    } else if (isRunning && !isPaused) {
      _playBackgroundMusic();
    }
  }

  @override
  void onRemove() {
    audioPlayer.dispose();
    super.onRemove();
  }
}
