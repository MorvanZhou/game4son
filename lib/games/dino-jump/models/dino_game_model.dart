import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/dino_sound_manager.dart';
import 'game_entities.dart';
import 'physics_engine.dart';
import 'difficulty_system.dart';
import 'obstacle_system.dart';
import 'ai_intelligence_system.dart';

/// 重构后的恐龙游戏模型
/// 采用模块化设计，将复杂的游戏逻辑拆分为多个专门的系统
class DinoGameModel extends ChangeNotifier {
  // 游戏状态
  DinoGameState _gameState = DinoGameState.ready;
  DinoGameState get gameState => _gameState;

  // 游戏区域尺寸
  static const double gameWidth = 800;
  static const double gameHeight = 200;
  static const double groundHeight = 20;

  // 游戏分数
  int score = 0;               // 得分
  int highScore = 0;           // 最高分
  
  // 核心系统模块
  final PhysicsEngine _physicsEngine = PhysicsEngine();           // 物理引擎
  final DifficultySystem _difficultySystem = DifficultySystem();  // 难度系统
  final ObstacleSystem _obstacleSystem = ObstacleSystem();        // 障碍物系统
  final AIIntelligenceSystem _aiSystem = AIIntelligenceSystem();  // AI智能系统
  
  // 随机数生成器
  final math.Random _random = math.Random();
  
  // 音效管理器
  final DinoSoundManager _soundManager = DinoSoundManager();
  
  /// 开始游戏
  void startGame() {
    _gameState = DinoGameState.playing;
    score = 0;
    
    // 重置所有系统
    _physicsEngine.reset();
    _difficultySystem.reset();
    _obstacleSystem.reset(gameWidth);
    _aiSystem.reset();
    
    // 开始播放背景音乐
    _soundManager.startGameMusic();
    
    notifyListeners();
  }

  /// 恐龙跳跃
  void jump() {
    // 如果游戏还未开始，点击开始游戏
    if (_gameState == DinoGameState.ready) {
      startGame();
      return;
    }
    
    // 如果游戏结束，点击重新开始游戏
    if (_gameState == DinoGameState.gameOver) {
      restart();
      return;
    }
    
    // 游戏进行中，尝试跳跃
    if (_gameState == DinoGameState.playing) {
      bool jumpSuccessful = _physicsEngine.jump();
      if (jumpSuccessful) {
        // 播放跳跃音效
        _soundManager.playJumpSound();
        // 记录跳跃时机用于AI分析
        _aiSystem.recordJumpTiming(
          _obstacleSystem.obstacles, 
          _physicsEngine.dinoX, 
          _difficultySystem.gameSpeed
        );
      }
    }
  }

  /// 恐龙蹲下
  void duck() {
    // 只有在游戏进行中才能蹲下
    if (_gameState == DinoGameState.playing) {
      _physicsEngine.duck();
      // 播放蹲下音效（如果有的话）
      // _soundManager.playDuckSound();
    }
  }
  
  /// 停止蹲下
  void stopDucking() {
    _physicsEngine.stopDucking();
  }

  /// 重新开始游戏
  void restart() {
    startGame();
  }

  /// 游戏主循环更新
  void update(double deltaTime) {
    if (_gameState != DinoGameState.playing) return;

    // 更新物理系统
    _physicsEngine.update(deltaTime);
    
    // 更新难度系统
    _difficultySystem.updateSpeed(score);
    
    // 更新障碍物系统
    _obstacleSystem.updateObstacles(deltaTime, _difficultySystem.gameSpeed);
    _obstacleSystem.updateClouds(deltaTime);
    
    // 生成新的障碍物和云朵
    _generateObstacles(deltaTime);
    _obstacleSystem.generateClouds(deltaTime, gameWidth);
    
    // 检查碰撞
    _checkCollisions();
    
    // 更新得分
    _updateScore();
    
    notifyListeners();
  }

  /// 生成障碍物 - 使用智能系统
  void _generateObstacles(double deltaTime) {
    // 计算当前阶段的基础障碍物间距
    double baseDistance = _difficultySystem.calculateObstacleDistance(score, _random);
    
    // 使用AI系统计算智能间距
    double smartDistance = _aiSystem.calculateSmartObstacleDistance(score, baseDistance);
    
    // 检查是否需要生成新的障碍物
    if (_obstacleSystem.shouldGenerateObstacle(gameWidth, smartDistance)) {
      // 使用AI系统选择障碍物模式
      List<PatternWeight> weights = _aiSystem.calculatePatternWeights(score);
      ObstaclePattern pattern = _aiSystem.selectObstaclePattern(weights);
      
      // 根据模式生成具体障碍物
      _generateObstacleByPattern(pattern);
      
      // 更新AI系统状态
      _aiSystem.updateObstacleGenerationState(pattern);
    }
  }
  
  /// 根据模式生成具体障碍物
  void _generateObstacleByPattern(ObstaclePattern pattern) {
    double obstacleX = _obstacleSystem.lastObstacleX;
    
    switch (pattern) {
      case ObstaclePattern.singleCactus:
        _obstacleSystem.generateSingleCactus(obstacleX, score, groundHeight);
        break;
      case ObstaclePattern.singleBird:
        _obstacleSystem.generateSingleBird(obstacleX, score, groundHeight);
        break;
      case ObstaclePattern.jumpThenDuck:
        _obstacleSystem.generateJumpThenDuckCombo(obstacleX, groundHeight);
        break;
      case ObstaclePattern.duckThenJump:
        _obstacleSystem.generateDuckThenJumpCombo(obstacleX, groundHeight);
        break;
      case ObstaclePattern.rhythmBreaker:
        _obstacleSystem.generateRhythmBreaker(obstacleX, groundHeight);
        break;
      case ObstaclePattern.stressTest:
        _obstacleSystem.generateStressTest(obstacleX, groundHeight);
        break;
    }
  }

  /// 检查碰撞
  void _checkCollisions() {
    // 获取恐龙的碰撞矩形
    Rect dinoRect = _physicsEngine.getCollisionRect(gameHeight, groundHeight);
    
    // 检查与所有障碍物的碰撞
    bool hasCollision = false;
    
    for (Obstacle obstacle in _obstacleSystem.obstacles) {
      // 障碍物的碰撞矩形
      Rect obstacleRect = Rect.fromLTWH(
        obstacle.x,
        gameHeight - obstacle.y - obstacle.height,
        obstacle.width,
        obstacle.height,
      );
      
      if (dinoRect.overlaps(obstacleRect)) {
        hasCollision = true;
        break;
      }
    }
    
    if (hasCollision) {
      // 发生碰撞，游戏结束
      _gameState = DinoGameState.gameOver;
      if (score > highScore) {
        highScore = score;
      }
      
      // 停止背景音乐并播放游戏结束音效
      _soundManager.stopGameMusic();
      _soundManager.playGameOverSound();
    }
  }

  /// 更新得分
  void _updateScore() {
    int scoreIncrement = _obstacleSystem.updateScore(
      _physicsEngine.dinoX, 
      score, 
      _difficultySystem.gameSpeed
    );
    score += scoreIncrement;
  }

  // === 公共访问器方法 ===
  
  /// 获取障碍物列表
  List<Obstacle> get obstacles => _obstacleSystem.obstacles;
  
  /// 获取云朵列表
  List<Cloud> get clouds => _obstacleSystem.clouds;
  
  /// 获取当前游戏速度
  double get gameSpeed => _difficultySystem.gameSpeed;
  
  /// 获取恐龙X坐标
  double get dinoX => _physicsEngine.dinoX;
  
  /// 获取恐龙Y坐标（相对于地面）
  double get dinoY => _physicsEngine.dinoY;
  
  /// 获取恐龙宽度
  double get dinoWidth => _physicsEngine.dinoWidth;
  
  /// 获取恐龙高度
  double get dinoHeight => _physicsEngine.dinoHeight;
  
  /// 获取恐龙是否在地面
  bool get dinoOnGround => _physicsEngine.dinoOnGround;
  
  /// 获取恐龙是否在蹲下
  bool get dinoDucking => _physicsEngine.dinoDucking;
  
  /// 获取地面Y坐标（屏幕坐标系）
  double get groundY => gameHeight - groundHeight;
  
  /// 获取恐龙在屏幕中的Y坐标（屏幕坐标系）
  double get dinoScreenY => _physicsEngine.getScreenY(gameHeight, groundHeight);
  
  /// 获取当前游戏难度等级
  int get difficultyLevel => _difficultySystem.getDifficultyLevel(score);
  
  /// 获取当前游戏阶段名称
  String get gameStageText => _difficultySystem.getGameStageText(score);
  
  /// 获取当前速度百分比（相对于最大速度）
  double get speedPercentage => _difficultySystem.speedPercentage;
  
  /// 获取当前障碍物密度信息
  double get currentObstacleDistance => _difficultySystem.calculateObstacleDistance(score, _random);
  
  /// 获取障碍物密度百分比（相对于基础密度）
  double get obstacleDensityPercentage => _difficultySystem.getObstacleDensityPercentage(score, _random);
  
  /// 获取玩家当前压力等级（0.0-1.0）
  double get playerStressLevel => _aiSystem.playerStressLevel;
  
  /// 获取最近险过次数
  int get recentNearMissCount => _aiSystem.recentNearMissCount;
  
  /// 获取玩家跳跃质量评分 (0.0-1.0)
  double get jumpQualityScore => _aiSystem.getJumpQualityScore();
  
  /// 获取险过次数
  int get nearMissCount => _aiSystem.nearMissCount;
  
  /// 计算平均跳跃质量（用于评估玩家技能水平）
  double get averageJumpQuality => _aiSystem.averageJumpQuality;
  
  /// 释放资源
  @override
  void dispose() {
    _soundManager.dispose();
    super.dispose();
  }
}
