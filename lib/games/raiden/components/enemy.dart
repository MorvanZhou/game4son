import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

/// 敌机组件
/// 
/// 功能特性：
/// 1. 多种敌机类型
/// 2. 不同移动模式
/// 3. 碰撞检测
/// 4. 简单AI行为
class Enemy extends PositionComponent with HasGameRef, CollisionCallbacks {
  
  // 敌机类型
  final EnemyType type;
  
  // 移动相关
  Vector2 velocity;
  Vector2 gameSize;
  
  // AI行为
  double behaviorTimer = 0.0;
  double behaviorInterval;
  EnemyBehavior currentBehavior;
  
  // 动画相关
  double rotationSpeed = 0.0;
  
  Enemy({
    required Vector2 position,
    required this.gameSize,
    this.type = EnemyType.basic,
  }) : 
    velocity = Vector2(0, 100), // 默认向下移动
    behaviorInterval = 2.0 + math.Random().nextDouble() * 3.0, // 2-5秒行为切换
    currentBehavior = EnemyBehavior.moveDown,
    super(
      position: position,
      size: _getSizeForType(type),
    );
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 根据类型设置属性
    _setupForType();
    
    // 设置锚点为中心
    anchor = Anchor.center;
    
    // 添加圆形碰撞检测 - 不受旋转影响，中心对齐敌机中心
    add(CircleHitbox(
      radius: (size.x * 0.4), // 使用圆形碰撞盒，半径为敌机宽度的40%
      position: Vector2.zero(), // 圆心位于敌机中心
      anchor: Anchor.center, // 碰撞盒的锚点也是中心
    ));
  }
  
  /// 根据类型设置敌机属性
  void _setupForType() {
    switch (type) {
      case EnemyType.basic:
        velocity = Vector2(0, 80 + math.Random().nextDouble() * 40);
        rotationSpeed = 0.0;
        break;
      case EnemyType.fast:
        // 修复快速敌机碰撞问题：降低速度和旋转速度
        velocity = Vector2(0, 100 + math.Random().nextDouble() * 40); // 减少速度：120-180 → 100-140
        rotationSpeed = math.pi * 0.2; // 减慢旋转：0.5 → 0.2，避免碰撞检测失效
        break;
      case EnemyType.zigzag:
        velocity = Vector2(100, 60);
        rotationSpeed = 0.0;
        currentBehavior = EnemyBehavior.zigzag;
        break;
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // 更新行为计时器
    behaviorTimer += dt;
    
    // 更新AI行为
    _updateBehavior(dt);
    
    // 更新旋转
    if (rotationSpeed != 0) {
      angle += rotationSpeed * dt;
    }
    
    // 更新位置
    position += velocity * dt;
  }
  
  /// 更新AI行为
  void _updateBehavior(double dt) {
    switch (currentBehavior) {
      case EnemyBehavior.moveDown:
        // 直线向下移动（默认行为）
        break;
        
      case EnemyBehavior.zigzag:
        // 之字形移动 - 修复碰撞检测问题
        final zigzagSpeed = 100.0; // 降低速度避免碰撞检测失效
        velocity.x = math.sin(behaviorTimer * 2.5) * zigzagSpeed; // 减慢频率
        break;
        
      case EnemyBehavior.circle:
        // 圆形运动 - 使用速度而非直接设置位置，避免碰撞检测失效
        final radius = 50.0;
        final centerX = gameSize.x / 2;
        final circleSpeed = 2.0;
        
        // 计算目标位置
        final targetX = centerX + math.cos(behaviorTimer * circleSpeed) * radius;
        
        // 使用速度移动到目标位置，而不是直接设置位置
        final deltaX = targetX - position.x;
        velocity.x = deltaX * 3.0; // 平滑移动到目标位置
        break;
        
      case EnemyBehavior.followPlayer:
        // 跟随玩家（简单实现）
        // 这里需要获取玩家位置，暂时省略
        break;
    }
    
    // 随机切换行为（仅对特定类型）
    if (type == EnemyType.zigzag && behaviorTimer > behaviorInterval) {
      _switchBehavior();
      behaviorTimer = 0.0;
    }
  }
  
  /// 切换行为模式
  void _switchBehavior() {
    final behaviors = [
      EnemyBehavior.moveDown,
      EnemyBehavior.zigzag,
      EnemyBehavior.circle,
    ];
    
    // 选择不同于当前行为的行为
    EnemyBehavior newBehavior;
    do {
      newBehavior = behaviors[math.Random().nextInt(behaviors.length)];
    } while (newBehavior == currentBehavior);
    
    currentBehavior = newBehavior;
  }
  
  @override
  void render(Canvas canvas) {
    // 自定义绘制敌机
    _renderCustomEnemy(canvas);
  }
  
  /// 自定义绘制敌机
  void _renderCustomEnemy(Canvas canvas) {
    Color enemyColor;
    
    switch (type) {
      case EnemyType.basic:
        enemyColor = Colors.red; // 红色 - 基础敌机
        break;
      case EnemyType.fast:
        enemyColor = Colors.orange; // 橙色 - 快速敌机
        break;
      case EnemyType.zigzag:
        enemyColor = Colors.purple; // 紫色 - 之字形敌机
        break;
    }
    
    final enemyPaint = Paint()
      ..color = enemyColor
      ..style = PaintingStyle.fill;
    
    // 绘制敌机主体
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.x * 0.8,
        height: size.y * 0.6,
      ),
      enemyPaint,
    );
    
    // 绘制机翼
    final wingPaint = Paint()
      ..color = enemyColor.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, -5),
        width: size.x * 0.6,
        height: size.y * 0.3,
      ),
      wingPaint,
    );
    
    // 绘制标识点
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset.zero,
      size.x * 0.1,
      dotPaint,
    );
  }
  
  /// 根据类型获取大小
  static Vector2 _getSizeForType(EnemyType type) {
    switch (type) {
      case EnemyType.basic:
        return Vector2(40, 40); // 基础敌机
      case EnemyType.fast:
        return Vector2(36, 36); // 快速敌机
      case EnemyType.zigzag:
        return Vector2(36, 36); // 之字形敌机
    }
  }
  
  /// 检查是否超出屏幕
  bool isOutOfBounds() {
    return position.y > gameSize.y + 100 ||
           position.x < -100 ||
           position.x > gameSize.x + 100;
  }
  
  @override
  bool onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
            
    // 处理敌机碰撞
    if (other.runtimeType.toString().contains('Bullet')) {
      final bullet = other as dynamic;
            
      // 如果是玩家子弹
      if (bullet.isPlayerBullet == true) {
        
        
        // 移除敌机和子弹
        removeFromParent();
        other.removeFromParent();
        
        // 创建爆炸效果
        _createExplosionAt(position);
        
        // 根据敌机类型增加分数
        int points = _getScoreForEnemyType();
        _addScore(points);
      }
    }
    // 注意：不再处理敌机撞击玩家的逻辑，因为玩家组件会处理这种碰撞
    
    return true;
  }
  
  /// 根据敌机类型获取分数
  int _getScoreForEnemyType() {
    switch (type) {
      case EnemyType.basic:
        return 10; // 基础敌机 10分
      case EnemyType.fast:
        return 20; // 快速敌机 20分
      case EnemyType.zigzag:
        return 30; // 之字形敌机 30分
    }
  }
  
  /// 创建爆炸效果
  void _createExplosionAt(Vector2 pos) {
    try {
      // 通过gameRef访问游戏引擎创建爆炸 - 使用公开方法
      (gameRef as dynamic).createExplosion?.call(pos);
    } catch (e) {
      print('❌ 敌机创建爆炸效果时出错: $e');
    }
  }
  
  /// 增加分数
  void _addScore(int points) {
    try {
      (gameRef as dynamic).addScore?.call(points);
    } catch (e) {
      print('❌ 增加分数时出错: $e');
    }
  }
}

/// 敌机类型枚举
enum EnemyType {
  basic,    // 基础敌机
  fast,     // 快速敌机
  zigzag,   // 之字形敌机
}

/// 敌机行为枚举
enum EnemyBehavior {
  moveDown,     // 直线向下
  zigzag,       // 之字形移动
  circle,       // 圆形运动
  followPlayer, // 跟随玩家
}
