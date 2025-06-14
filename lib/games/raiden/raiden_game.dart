import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'components/player.dart';
import 'components/enemy.dart';
import 'components/bullet.dart';
import 'components/background.dart';
import 'components/explosion.dart';
import 'models/game_state.dart';

/// 雷电游戏核心引擎
/// 
/// 功能特性：
/// 1. 基于 Flame 游戏引擎构建
/// 2. 玩家飞机控制（键盘/触摸）
/// 3. 自动射击系统
/// 4. 敌机生成和AI
/// 5. 碰撞检测
/// 6. 爆炸效果
/// 7. 分数和生命系统
class RaidenGame extends FlameGame 
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  
  // 游戏状态
  late RaidenGameState gameState;
  
  // 游戏组件
  late Player player;
  late GameBackground background;
  
  // 敌机生成器
  Timer? enemySpawnTimer;
  
  // 子弹生成器
  Timer? bulletTimer;
  
  // 键盘控制状态
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  double _shootTimer = 0.0; // 手动射击计时器
  
  // 游戏设置
  static const double enemySpawnInterval = 2.0; // 敌机生成间隔（秒）
  static const double bulletInterval = 0.2; // 子弹发射间隔（秒）
  static const int maxEnemies = 8; // 最大敌机数量
  static const int maxBullets = 20; // 最大子弹数量
  
  // 游戏回调
  Function(int score, int lives, bool gameOver)? onGameStateChanged;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 初始化游戏状态
    gameState = RaidenGameState();
    
    // 加载背景
    background = GameBackground();
    add(background);
    
    // 创建玩家飞机
    player = Player(
      position: Vector2(size.x / 2, size.y * 0.8),
      gameSize: size,
    );
    add(player);
    
    // 启动定时器
    _startGameTimers();
    
    // 通知状态变化
    _notifyStateChanged();
  }
  
  /// 启动游戏定时器
  void _startGameTimers() {
    // 敌机生成定时器
    enemySpawnTimer = Timer(
      enemySpawnInterval,
      onTick: _spawnEnemy,
      repeat: true,
    );
    
    // 子弹发射定时器
    bulletTimer = Timer(
      bulletInterval,
      onTick: _fireBullet,
      repeat: true,
    );
  }
  
  /// 生成敌机
  void _spawnEnemy() {
    if (!gameState.isPlaying) return;
    
    // 检查当前敌机数量
    final currentEnemies = children.whereType<Enemy>().length;
    if (currentEnemies >= maxEnemies) return;
    
    // 随机生成敌机位置和类型
    final x = _random.nextDouble() * (size.x - 60) + 30;
    
    // 根据游戏难度和随机数选择敌机类型
    EnemyType enemyType;
    final typeRandom = _random.nextDouble();
    final difficultyLevel = gameState.level;
    
    if (difficultyLevel <= 2) {
      // 初期以基础敌机为主
      enemyType = typeRandom < 0.8 ? EnemyType.basic : EnemyType.fast;
    } else if (difficultyLevel <= 5) {
      // 中期混合出现
      if (typeRandom < 0.5) {
        enemyType = EnemyType.basic;
      } else if (typeRandom < 0.8) {
        enemyType = EnemyType.fast;
      } else {
        enemyType = EnemyType.zigzag;
      }
    } else {
      // 后期更多高级敌机
      if (typeRandom < 0.3) {
        enemyType = EnemyType.basic;
      } else if (typeRandom < 0.6) {
        enemyType = EnemyType.fast;
      } else {
        enemyType = EnemyType.zigzag;
      }
    }
    
    final enemy = Enemy(
      position: Vector2(x, -50),
      gameSize: size,
      type: enemyType,
    );
    
    add(enemy);
  }
  
  /// 发射子弹
  void _fireBullet() {
    if (!gameState.isPlaying) return;
    
    // 检查当前子弹数量
    final currentBullets = children.whereType<Bullet>().where((bullet) => bullet.isPlayerBullet).length;
    if (currentBullets >= maxBullets) return;
    
    // 从玩家位置发射子弹
    final bullet = Bullet(
      position: Vector2(player.position.x, player.position.y - 20),
      velocity: Vector2(0, -300), // 向上移动
      gameSize: size,
      type: BulletType.playerNormal,
      isPlayerBullet: true,
    );
    
    add(bullet);
  }
  
  // 随机数生成器
  static final _random = math.Random();
  
  /// 创建爆炸效果 - 公开方法供组件调用
  void createExplosion(Vector2 position) {
    
    try {
      final explosion = Explosion(
        position: position,
        type: ExplosionType.normal,
      );
      
      add(explosion);
    } catch (e) {
      print('❌ RaidenGame 创建爆炸效果时出错: $e');
    }
  }
  
  /// 添加分数 - 公开方法供组件调用
  void addScore(int points) {
    if (!gameState.isPlaying) return;
    
    gameState.addScore(points);
    _notifyStateChanged();
  }
  
  /// 减少生命 - 公开方法供组件调用
  void loseLife() {
    if (!gameState.isPlaying) return;
    
    gameState.loseLife();
    _notifyStateChanged();
    
    // 检查游戏结束
    if (gameState.lives <= 0) {
      gameState.setGameOver();
      _pauseGame();
      _notifyStateChanged();
    }
  }
  
  /// 记录射击 - 公开方法供组件调用
  void recordShot() {
    gameState.recordShot();
  }
  
  /// 暂停游戏
  void _pauseGame() {
    enemySpawnTimer?.stop();
    bulletTimer?.stop();
  }
  
  /// 恢复游戏
  void resumeGame() {
    if (gameState.isPlaying) {
      _startGameTimers();
    }
  }
  
  /// 重新开始游戏
  void restartGame() {
    // 重置游戏状态
    gameState.reset();
    
    // 清除按键状态
    _pressedKeys.clear();
    _shootTimer = 0.0;
    
    // 清除所有敌机、子弹、爆炸
    children.whereType<Enemy>().toList().forEach((enemy) => enemy.removeFromParent());
    children.whereType<Bullet>().toList().forEach((bullet) => bullet.removeFromParent());
    children.whereType<Explosion>().toList().forEach((explosion) => explosion.removeFromParent());
    
    // 重置玩家位置
    player.position = Vector2(size.x / 2, size.y * 0.8);
    
    // 重新启动定时器
    _startGameTimers();
    
    // 通知状态变化
    _notifyStateChanged();
  }
  
  /// 更新游戏逻辑
  @override
  void update(double dt) {
    super.update(dt);
    
    // 处理连续键盘输入（在这里处理提供更丝滑的体验）
    _handleContinuousKeyboardInput(dt);
    
    // 更新定时器
    enemySpawnTimer?.update(dt);
    bulletTimer?.update(dt);
    
    // 清理超出屏幕的组件
    _cleanupOutOfBounds();
  }
  
  /// 处理连续键盘输入
  void _handleContinuousKeyboardInput(double dt) {
    if (!gameState.isPlaying) return;
    
    // 提高移动速度，使用实际的dt时间
    const moveSpeed = 600.0; // 进一步增加移动速度
    
    // 支持对角线移动（同时按下两个方向键）
    Vector2 moveDirection = Vector2.zero();
    
    // 计算移动方向
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyA)) {
      moveDirection.x -= 1;
    }
    
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyD)) {
      moveDirection.x += 1;
    }
    
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyW)) {
      moveDirection.y -= 1;
    }
    
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowDown) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyS)) {
      moveDirection.y += 1;
    }
    
    // 应用移动（标准化向量以保持恒定速度）
    if (moveDirection.length > 0) {
      moveDirection.normalize(); // 确保对角线移动速度一致
      final movement = moveDirection * moveSpeed * dt;
      
      final newX = (player.position.x + movement.x).clamp(30.0, size.x - 30.0);
      final newY = (player.position.y + movement.y).clamp(50.0, size.y - 50.0);
      
      player.position.x = newX;
      player.position.y = newY;
    }
    
    // 连续射击
    if (_pressedKeys.contains(LogicalKeyboardKey.space)) {
      // 手动射击的频率比自动射击稍高
      _shootTimer += dt;
      if (_shootTimer >= 0.12) { // 更快的射击频率
        _fireBullet();
        _shootTimer = 0.0;
      }
    } else {
      _shootTimer = 0.0; // 重置射击计时器
    }
  }
  
  /// 清理超出屏幕边界的组件
  void _cleanupOutOfBounds() {
    // 清理超出屏幕的敌机
    children.whereType<Enemy>().where((enemy) => 
      enemy.position.y > size.y + 100
    ).toList().forEach((enemy) => enemy.removeFromParent());
    
    // 清理超出屏幕的子弹
    children.whereType<Bullet>().where((bullet) => 
      bullet.position.y < -50
    ).toList().forEach((bullet) => bullet.removeFromParent());
  }
  
  /// 处理触摸输入
  void movePlayerTo(Vector2 position) {
    if (!gameState.isPlaying) return;
    
    // 限制玩家移动范围
    player.position.x = position.x.clamp(30, size.x - 30);
    player.position.y = position.y.clamp(50, size.y - 50);
  }
  
  /// 通知游戏状态变化
  void _notifyStateChanged() {
    onGameStateChanged?.call(
      gameState.score,
      gameState.lives,
      gameState.isGameOver,
    );
  }
  
  /// 处理键盘输入事件
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    super.onKeyEvent(event, keysPressed);
    
    if (!gameState.isPlaying) return KeyEventResult.ignored;
    
    // 更新按键状态 - 这种方式提供更好的响应性
    _pressedKeys.clear();
    _pressedKeys.addAll(keysPressed);
    
    // 立即响应按键（提供即时反馈）
    if (event is KeyDownEvent) {
      // 处理按键按下事件，提供即时响应
      if (keysPressed.contains(LogicalKeyboardKey.space)) {
        _fireBullet(); // 空格键立即射击
        return KeyEventResult.handled;
      }
    }
    
    return keysPressed.isNotEmpty ? KeyEventResult.handled : KeyEventResult.ignored;
  }
  
  @override
  void onRemove() {
    enemySpawnTimer?.stop();
    bulletTimer?.stop();
    super.onRemove();
  }
}
