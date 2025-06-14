import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;
import 'components/dino_player.dart';
import 'components/obstacle.dart';
import 'components/bird_obstacle.dart';
import 'components/cloud_background.dart';
import 'components/ground_track.dart';
import 'game_config.dart';

/// Chrome Dino Runner - 完全参考Python版本的逻辑和结构，支持自适应界面和移动端触控
class ChromeDinoGame extends FlameGame 
    with TapDetector, HasKeyboardHandlerComponents, PanDetector {
  
  // 游戏常量 - 自适应尺寸替代固定尺寸，使用配置系统的全局缩放
  static double get minScreenWidth => DinoGameConfig.screenWidth;     // 最小游戏宽度
  static double get minScreenHeight => DinoGameConfig.screenHeight;    // 最小游戏高度
  static const double aspectRatio = 16 / 9;       // 首选宽高比
  
  // 获取缩放后的初始游戏速度
  static int get initialGameSpeed => DinoGameConfig.gameSpeed;

  // 实际游戏尺寸 - 运行时根据屏幕计算
  late double gameWidth;
  late double gameHeight;
  
  // UI初始化标志 - 防止在UI组件初始化前调用重新布局
  bool _uiInitialized = false;

  static const Color fontColor = Color(0xFF535353); // Chrome Dino风格的灰色文字
  static const Color gameBackgroundColor = Color.fromARGB(255, 215, 215, 215); // 明亮的浅灰背景
  
  // 游戏状态
  bool isRunning = false;
  bool isPaused = false;
  int gameSpeed = initialGameSpeed;
  int points = 0;
  int deathCount = 0;
  double xPosBg = 0; // 背景X位置
  double yPosBg = DinoGameConfig.groundY; // 背景Y位置 - 使用配置系统，应用缩放
  
  // 难度阶段系统 - 平滑的难度递进，参考真实Chrome Dino游戏
  int currentStage = 1; // 当前难度阶段
  int birdAppearanceChance = 0; // 飞鸟出现概率（百分比）
  
  // 难度配置 - 更平滑的递进
  static const Map<int, Map<String, dynamic>> stageConfig = {
    1: {'name': '初级', 'speedBonus': 0, 'birdChance': 0, 'minScore': 0},
    2: {'name': '中级', 'speedBonus': 2, 'birdChance': 15, 'minScore': 300}, // 300分开始出现飞鸟
    3: {'name': '高级', 'speedBonus': 4, 'birdChance': 25, 'minScore': 800}, // 800分飞鸟概率增加
    4: {'name': '专家', 'speedBonus': 6, 'birdChance': 35, 'minScore': 1500}, // 1500分更高难度
    5: {'name': '大师', 'speedBonus': 8, 'birdChance': 45, 'minScore': 2500}, // 2500分最高难度
  };
  
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

  // 移动端触控状态管理
  bool _isDucking = false; // 是否正在蹲下
  bool _isLongPressing = false; // 是否正在长按
  DateTime? _touchStartTime; // 触摸开始时间
  static const int _longPressDuration = 150; // 长按判定时间（毫秒）

  @override
  Future<void> onLoad() async {
    // 初始化游戏尺寸 - 自适应屏幕大小
    _initializeGameSize();
    
    // 设置游戏世界大小 - 使用自适应尺寸，完全填充可用空间
    camera.viewfinder.visibleGameSize = Vector2(gameWidth, gameHeight);
    
    // 设置相机视图适配策略，确保游戏内容能够完全填充屏幕
    camera.viewfinder.anchor = Anchor.topLeft;
    
    // 设置明亮的背景颜色 - Chrome Dino风格
    await add(RectangleComponent(
      size: Vector2(gameWidth, gameHeight),
      paint: Paint()..color = gameBackgroundColor,
      position: Vector2.zero(),
      priority: -10, // 设置最低优先级，确保在所有组件后面
    ));
    
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
    // 设置初始音效状态
    player.setSoundEnabled(soundEnabled);
    add(player);
    
    // 初始化云朵背景 - 参考Python版本的Cloud类
    cloud = CloudBackground();
    add(cloud);
  }

  /// 设置UI界面 - 参考Python版本的score函数和文本显示，使用自适应布局
  Future<void> _setupUI() async {
    // 得分显示 - 参考Python版本的score函数，使用配置系统应用缩放
    scoreText = TextComponent(
      text: 'Points: 0',
      position: Vector2(gameWidth - DinoGameConfig.scoreOffsetX, DinoGameConfig.scoreOffsetY),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: DinoGameConfig.fontSizeMedium, // 使用配置系统的缩放
          color: fontColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(scoreText);
    
    // 开始游戏提示 - 参考Python版本的menu函数，使用配置系统应用缩放
    startText = TextComponent(
      text: 'Press any Key to Start',
      position: Vector2(gameWidth / 2, gameHeight / 2),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: DinoGameConfig.fontSizeLarge, // 使用配置系统的缩放
          color: fontColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(startText);
    
    // 暂停文本，使用配置系统应用缩放
    pauseText = TextComponent(
      text: "Game Paused, Press 'R' to Resume",
      position: Vector2(gameWidth / 2, gameHeight / 3),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: DinoGameConfig.fontSizeLarge, // 使用配置系统的缩放
          color: fontColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    
    // 标记UI组件已初始化
    _uiInitialized = true;
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

  /// 处理连续输入 - 参考Python版本的连续按键检测，增加移动端长按检测
  void _handleContinuousInput() {
    // 检查移动端长按蹲下状态
    if (_touchStartTime != null && _isDucking && isRunning && !isPaused) {
      final touchDuration = DateTime.now().difference(_touchStartTime!).inMilliseconds;
      
      // 长按超过阈值时，保持蹲下状态
      if (touchDuration >= _longPressDuration && !_isLongPressing) {
        _isLongPressing = true;
        // 确保持续蹲下
        player.duck();
      }
    }
  }

  /// 更新得分 - 参考Python版本的score函数，添加难度阶段管理
  void _updateScore() {
    // 大幅降低得分增长速度，让难度递进更平滑
    points += (gameSpeed / 20).round(); 
    
    // 更新难度阶段和游戏速度
    _updateDifficultyStage();
    
    scoreText.text = 'Points: $points';
  }
  
  /// 更新难度阶段 - 平滑的7阶段难度系统，减缓递进速度
  void _updateDifficultyStage() {
    int newStage = currentStage;
    int newBirdChance = birdAppearanceChance;
    
    if (points >= 2000) {
      // 阶段7 (2000分+): 大师级别，最终挑战
      newStage = 7;
      newBirdChance = 50; // 50%飞鸟概率，不要太高
    } else if (points >= 1500) {
      // 阶段6 (1500-2000分): 高级挑战
      newStage = 6;
      newBirdChance = 45; // 45%飞鸟概率  
    } else if (points >= 1000) {
      // 阶段5 (1000-1500分): 平衡挑战
      newStage = 5;
      newBirdChance = 40; // 40%飞鸟概率
    } else if (points >= 700) {
      // 阶段4 (700-1000分): 能力巩固
      newStage = 4;
      newBirdChance = 35; // 35%飞鸟概率
    } else if (points >= 500) {
      // 阶段3 (500-700分): 技能建立
      newStage = 3;
      newBirdChance = 30; // 30%飞鸟概率
    } else if (points >= 300) {
      // 阶段2 (300-500分): 初步学习
      newStage = 2;
      newBirdChance = 20; // 20%飞鸟概率，温和开始
    } else if (points >= 150) {
      // 阶段1 (150-300分): 认知阶段，飞鸟开始出现
      newStage = 1;
      newBirdChance = 10; // 10%飞鸟概率，非常温和
    } else {
      // 阶段0 (0-150分): 学习阶段，只有仙人掌
      newStage = 0;
      newBirdChance = 0; // 无飞鸟
    }
    
    // 更新状态
    currentStage = newStage;
    birdAppearanceChance = newBirdChance;
    gameSpeed = gameSpeed * (1 + newStage * 0.05).round(); // 每个阶段增加5%的速度
  }

  /// 生成障碍物 - 基于难度阶段的智能障碍物系统
  void _generateObstacles() {
    // 参考Python版本: if len(obstacles) == 0:
    if (obstacles.isEmpty) {
      Obstacle newObstacle;
      
      // 根据难度阶段决定是否生成飞鸟
      if (currentStage > 0 && random.nextInt(100) < birdAppearanceChance) {
        // 生成飞鸟障碍物
        newObstacle = BirdObstacle();
      } else {
        // 生成仙人掌障碍物 - 根据难度阶段调整大小仙人掌比例
        final cactusRatio = _getCactusRatio();
        if (random.nextInt(100) < cactusRatio) {
          newObstacle = LargeCactus(); // 大仙人掌
        } else {
          newObstacle = SmallCactus(); // 小仙人掌
        }
      }
      
      // 添加到游戏和障碍物列表
      add(newObstacle);
      obstacles.add(newObstacle);
    }
  }
  
  /// 根据难度阶段获取大仙人掌比例
  int _getCactusRatio() {
    switch (currentStage) {
      case 0: return 20; // 20%大仙人掌
      case 1: return 30; // 30%大仙人掌
      case 2: return 35; // 35%大仙人掌
      case 3: return 40; // 40%大仙人掌
      case 4: return 45; // 45%大仙人掌
      case 5: return 50; // 50%大仙人掌
      case 6: return 55; // 55%大仙人掌
      case 7: return 60; // 60%大仙人掌
      default: return 25; // 默认25%大仙人掌
    }
  }
  
  /// 获取当前难度阶段名称
  String get currentStageName {
    switch (currentStage) {
      case 0: return '学习';
      case 1: return '认知';
      case 2: return '初学';
      case 3: return '技能';
      case 4: return '巩固';
      case 5: return '平衡';
      case 6: return '高级';
      case 7: return '大师';
      default: return '未知';
    }
  }

  /// 更新所有障碍物 - 参考Python版本的obstacle.update()逻辑
  void _updateObstacles() {
    // 更新障碍物位置并移除超出屏幕的障碍物
    obstacles.removeWhere((obstacle) {
      // 更新障碍物移动
      obstacle.updateMovement(gameSpeed);
      
      // 检查是否超出屏幕
      if (obstacle.isOffScreen()) {
        obstacle.removeFromParent();
        return true;
      }
      return false;
    });
  }

  /// 检查碰撞 - 参考Python版本的player.dino_rect.colliderect(obstacle.rect)
  void _checkCollisions() {
    for (final obstacle in obstacles) {
      if (player.checkCollision(obstacle)) {
        // 碰撞检测成功，游戏结束
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
    
    // 重置移动端触摸状态
    _isDucking = false;
    _isLongPressing = false;
    _touchStartTime = null;
    
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
    
    // 显示最终得分，使用配置系统应用缩放
    final scoreDisplay = TextComponent(
      text: 'Your Score: $points',
      position: Vector2(gameWidth / 2, gameHeight / 2 + DinoGameConfig.scoreOffsetY),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: DinoGameConfig.fontSizeLarge, // 使用配置系统的缩放
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
    
    // 重置难度阶段
    currentStage = 0;
    birdAppearanceChance = 0;
    
    // 重置移动端触摸状态
    _isDucking = false;
    _isLongPressing = false;
    _touchStartTime = null;
    
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

  /// 初始化游戏尺寸 - 根据容器大小自适应，完全填充可用空间
  void _initializeGameSize() {
    // 尝试获取容器尺寸，如果无法获取则使用默认值
    if (camera.viewport.size.x > 0 && camera.viewport.size.y > 0) {
      final containerWidth = camera.viewport.size.x;
      final containerHeight = camera.viewport.size.y;
      
      // 直接使用容器的实际尺寸，不强制固定宽高比
      gameWidth = math.max(containerWidth, minScreenWidth);
      gameHeight = math.max(containerHeight, minScreenHeight);
      
      // 确保游戏尺寸不会太小影响游戏体验
      if (gameWidth < minScreenWidth) {
        gameWidth = minScreenWidth;
      }
      if (gameHeight < minScreenHeight) {
        gameHeight = minScreenHeight;
      }
    } else {
      // 使用默认尺寸
      gameWidth = minScreenWidth;
      gameHeight = minScreenHeight;
    }
  }

  /// 处理游戏尺寸变化 - 支持窗口缩放
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    
    // 重新计算游戏尺寸
    _initializeGameSize();
    
    // 更新相机视图
    camera.viewfinder.visibleGameSize = Vector2(gameWidth, gameHeight);
    
    // 更新背景组件尺寸
    final bgComponent = children.whereType<RectangleComponent>().firstOrNull;
    if (bgComponent != null) {
      bgComponent.size = Vector2(gameWidth, gameHeight);
    }
    
    // 只有在UI组件已经初始化后才重新布局
    if (_uiInitialized) {
      _repositionUIComponents();
    }
  }

  /// 重新定位UI组件 - 适应新的游戏尺寸
  void _repositionUIComponents() {
    // 确保UI组件已经初始化
    if (!_uiInitialized) return;
    
    // 更新分数显示位置，使用配置系统应用缩放
    scoreText.position = Vector2(gameWidth - DinoGameConfig.scoreOffsetX, DinoGameConfig.scoreOffsetY);
    
    // 更新开始提示位置
    startText.position = Vector2(gameWidth / 2, gameHeight / 2);
    
    // 更新暂停提示位置
    pauseText.position = Vector2(gameWidth / 2, gameHeight / 2);
    
    // 更新云朵组件的游戏宽度
    cloud.updateGameWidth(gameWidth);
    
    // 更新地面轨道的游戏尺寸
    groundTrack.updateGameSize(gameWidth, gameHeight);
    
    // 更新游戏中使用的地面Y坐标
    yPosBg = groundTrack.yPosBg;
    
    // 更新恐龙的地面位置
    player.updateGroundPosition(yPosBg);
  }

  // 控制输入处理 - 参考Python版本的输入处理逻辑，增强移动端触摸支持
  @override
  bool onTapDown(TapDownInfo info) {
    // 记录触摸开始时间，用于长按检测
    _touchStartTime = DateTime.now();
    _isLongPressing = false;
    
    // 判断触摸位置：屏幕上半部分跳跃，下半部分蹲下
    final touchY = info.eventPosition.global.y;
    final screenHeight = gameHeight;
    final isUpperHalf = touchY < screenHeight / 2;
    
    if (isUpperHalf) {
      // 上半部分触摸：跳跃或开始游戏
      _handleInput();
      if (isRunning && !isPaused) {
        player.jump();
      }
    } else {
      // 下半部分触摸：开始蹲下
      _handleInput();
      if (isRunning && !isPaused) {
        _isDucking = true;
        player.duck();
      }
    }
    
    return true;
  }

  @override
  bool onTapUp(TapUpInfo info) {
    // 处理触摸释放事件
    final touchDuration = DateTime.now().difference(_touchStartTime ?? DateTime.now()).inMilliseconds;
    final touchY = info.eventPosition.global.y;
    final isUpperHalf = touchY < gameHeight / 2;
    
    // 只有下半部分触摸且时间较短才停止蹲下（短按）
    if (!isUpperHalf && touchDuration < _longPressDuration) {
      if (isRunning && !isPaused && _isDucking) {
        _isDucking = false;
        player.stopDucking();
      }
    }
    
    _isLongPressing = false;
    return true;
  }

  @override
  bool onTapCancel() {
    // 触摸取消时停止蹲下
    if (isRunning && !isPaused && _isDucking) {
      _isDucking = false;
      player.stopDucking();
    }
    _isLongPressing = false;
    return true;
  }

  @override
  bool onPanStart(DragStartInfo info) {
    // 开始拖拽，记录触摸开始时间
    _touchStartTime = DateTime.now();
    _isLongPressing = false;
    
    final touchY = info.eventPosition.global.y;
    final isUpperHalf = touchY < gameHeight / 2;
    
    if (!isUpperHalf) {
      // 下半部分触摸开始蹲下
      _handleInput();
      if (isRunning && !isPaused) {
        _isDucking = true;
        player.duck();
      }
    }
    
    return true;
  }

  @override
  bool onPanUpdate(DragUpdateInfo info) {
    // 检查是否为长按
    if (_touchStartTime != null && !_isLongPressing) {
      final touchDuration = DateTime.now().difference(_touchStartTime!).inMilliseconds;
      if (touchDuration >= _longPressDuration) {
        _isLongPressing = true;
      }
    }
    
    // 持续检查触摸位置
    final touchY = info.eventPosition.global.y;
    final isUpperHalf = touchY < gameHeight / 2;
    
    if (!isUpperHalf && isRunning && !isPaused) {
      // 在下半部分持续蹲下
      if (!_isDucking) {
        _isDucking = true;
        player.duck();
      }
    }
    
    return true;
  }

  @override
  bool onPanEnd(DragEndInfo info) {
    // 拖拽结束，停止蹲下
    if (isRunning && !isPaused && _isDucking) {
      _isDucking = false;
      player.stopDucking();
    }
    _isLongPressing = false;
    return true;
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    super.onKeyEvent(event, keysPressed);
    
    // 处理按键按下事件
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space || 
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _handleInput();
        if (isRunning && !isPaused) {
          player.jump();
        }
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // 按下下键开始蹲下
        if (isRunning && !isPaused) {
          player.duck();
        }
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyP) {
        if (isRunning && !isPaused) {
          _pauseGame();
        }
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
        if (isPaused) {
          _resumeGame();
        }
        return KeyEventResult.handled;
      } else {
        _handleInput();
        return KeyEventResult.handled;
      }
    }
    
    // 处理按键释放事件 - 关键改进：实现持续按住下键保持蹲下的机制
    if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // 释放下键时停止蹲下，恢复跑步状态
        if (isRunning && !isPaused) {
          player.stopDucking();
        }
        return KeyEventResult.handled;
      }
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
    
    // 同步音效设置到恐龙玩家
    player.setSoundEnabled(soundEnabled);
    
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
