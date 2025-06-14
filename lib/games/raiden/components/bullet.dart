import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

/// 子弹组件
/// 
/// 功能特性：
/// 1. 玩家子弹和敌机子弹
/// 2. 不同类型的子弹效果
/// 3. 碰撞检测
/// 4. 自动清理超出边界的子弹
class Bullet extends PositionComponent with HasGameRef, CollisionCallbacks {
  
  // 子弹类型
  final BulletType type;
  
  // 移动相关
  Vector2 velocity;
  Vector2 gameSize;
  
  // 子弹属性
  final double damage;
  final bool isPlayerBullet;
  
  Bullet({
    required Vector2 position,
    required this.velocity,
    required this.gameSize,
    this.type = BulletType.playerNormal,
    this.damage = 1.0,
    this.isPlayerBullet = true,
  }) : super(
    position: position,
    size: _getSizeForType(type),
  );
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 设置锚点为中心
    anchor = Anchor.center;
    
    // 添加碰撞检测 - 精确的子弹碰撞区域
    add(RectangleHitbox(
      size: Vector2(size.x * 0.6, size.y * 0.8), // 子弹使用更精确的碰撞盒
      position: Vector2.zero(), // 相对于子弹中心的位置偏移
      anchor: Anchor.center, // 碰撞盒的锚点也是中心
    ));
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // 更新位置
    position += velocity * dt;
    
    // 检查是否超出边界，如果是则移除
    if (isOutOfBounds()) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    // 自定义绘制子弹
    _renderCustomBullet(canvas);
  }
  
  /// 自定义绘制子弹
  void _renderCustomBullet(Canvas canvas) {
    Color bulletColor;
    
    switch (type) {
      case BulletType.playerNormal:
        bulletColor = Colors.yellow;
        break;
      case BulletType.playerPower:
        bulletColor = Colors.blue;
        break;
      case BulletType.enemyNormal:
        bulletColor = Colors.red;
        break;
      case BulletType.enemyPower:
        bulletColor = Colors.purple;
        break;
    }
    
    final bulletPaint = Paint()
      ..color = bulletColor
      ..style = PaintingStyle.fill;
    
    // 绘制子弹主体
    if (isPlayerBullet) {
      // 玩家子弹 - 向上的尖角形状
      final path = Path();
      path.moveTo(0, -size.y / 2); // 顶部尖角
      path.lineTo(-size.x / 3, size.y / 2); // 左下
      path.lineTo(size.x / 3, size.y / 2); // 右下
      path.close();
      canvas.drawPath(path, bulletPaint);
    } else {
      // 敌机子弹 - 圆形
      canvas.drawCircle(
        Offset.zero,
        size.x / 2,
        bulletPaint,
      );
    }
    
    // 添加发光效果
    if (type == BulletType.playerPower || type == BulletType.enemyPower) {
      final glowPaint = Paint()
        ..color = bulletColor.withOpacity(0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      canvas.drawCircle(
        Offset.zero,
        size.x / 2 + 2,
        glowPaint,
      );
    }
  }
  
  /// 根据类型获取大小
  static Vector2 _getSizeForType(BulletType type) {
    switch (type) {
      case BulletType.playerNormal:
        return Vector2(8, 16);
      case BulletType.playerPower:
        return Vector2(12, 20);
      case BulletType.enemyNormal:
        return Vector2(6, 6);
      case BulletType.enemyPower:
        return Vector2(10, 10);
    }
  }
  
  /// 检查是否超出屏幕边界
  bool isOutOfBounds() {
    return position.y < -50 ||
           position.y > gameSize.y + 50 ||
           position.x < -50 ||
           position.x > gameSize.x + 50;
  }
   @override
  bool onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    // 处理子弹碰撞
    if (isPlayerBullet) {
      // 玩家子弹击中其他目标
      _handlePlayerBulletCollision(other);
    } else {
      // 敌机子弹击中玩家
      _handleEnemyBulletCollision(other);
    }
    
    return true;
  }
  
  /// 处理玩家子弹碰撞
  void _handlePlayerBulletCollision(PositionComponent other) {    
    if (other.runtimeType.toString().contains('Enemy')) {
      // 移除子弹和敌机
      removeFromParent();
      other.removeFromParent();
      
      // 创建爆炸效果
      _createExplosionAt(other.position);
      
      // 根据敌机类型增加不同分数
      int points = _getScoreForEnemy(other);
      _addScore(points);
    } 
  }
  
  /// 处理敌机子弹碰撞
  void _handleEnemyBulletCollision(PositionComponent other) {
    // 检查是否击中玩家
    if (other.runtimeType.toString().contains('Player')) {
      // 移除子弹
      removeFromParent();
      
      // 创建爆炸效果
      _createExplosionAt(other.position);
      
      // 减少生命
      _loseLife();
    }
  }
  
  /// 根据敌机类型获取分数
  int _getScoreForEnemy(PositionComponent enemy) {
    try {
      // 尝试获取敌机类型
      final enemyType = (enemy as dynamic).type;
      
      switch (enemyType.toString()) {
        case 'EnemyType.basic':
          return 10; // 基础敌机 10分
        case 'EnemyType.fast':
          return 20; // 快速敌机 20分
        case 'EnemyType.zigzag':
          return 30; // 之字形敌机 30分
        default:
          return 10; // 默认 10分
      }
    } catch (e) {
      // 如果无法获取类型，返回默认分数
      return 10;
    }
  }
  
  /// 创建爆炸效果
  void _createExplosionAt(Vector2 pos) {
    try {
      // 通过gameRef访问游戏引擎创建爆炸 - 使用公开方法
      (gameRef as dynamic).createExplosion?.call(pos);
    } catch (e) {
      print('❌ 创建爆炸效果时出错: $e');
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
  
  /// 减少生命
  void _loseLife() {
    try {
      (gameRef as dynamic).loseLife?.call();
    } catch (e) {
      print('❌ 减少生命时出错: $e');
    }
  }
}

/// 子弹类型枚举
enum BulletType {
  playerNormal,  // 玩家普通子弹
  playerPower,   // 玩家威力子弹
  enemyNormal,   // 敌机普通子弹
  enemyPower,    // 敌机威力子弹
}
