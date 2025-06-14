import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

/// 玩家飞机组件
/// 
/// 功能特性：
/// 1. 飞机移动控制
/// 2. 碰撞检测
/// 3. 飞机倾斜动画
/// 4. 推进器效果
class Player extends PositionComponent with HasGameRef, CollisionCallbacks {
  
  // 移动相关
  Vector2 velocity = Vector2.zero();
  Vector2 gameSize;
  
  // 动画相关
  double tiltAngle = 0.0;
  static const double maxTiltAngle = 0.3; // 最大倾斜角度
  static const double tiltSpeed = 5.0; // 倾斜速度
  
  // 推进器效果
  double thrusterTimer = 0.0;
  static const double thrusterCycle = 0.1; // 推进器闪烁周期
  
  // 闪烁效果（被撞击时）
  bool isStunned = false; // 是否处于晕眩状态
  double stunTimer = 0.0; // 晕眩计时器
  double flashTimer = 0.0; // 闪烁计时器
  bool isVisible = true; // 是否可见（用于闪烁效果）
  static const double stunDuration = 2.0; // 晕眩持续时间（秒）
  static const double flashInterval = 0.1; // 闪烁间隔（秒）
  
  // Sprite相关
  Sprite? playerSprite;
  
  Player({
    required Vector2 position,
    required this.gameSize,
  }) : super(
    position: position,
    size: Vector2(50, 50), // 飞机大小 - 基于8x8图片放大4倍
  );
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 尝试加载飞机图片
    try {
      playerSprite = await gameRef.loadSprite('raiden.plane.png');
    } catch (e) {
      // 如果图片加载失败，使用默认绘制
      print('无法加载飞机图片: $e，将使用默认绘制');
      playerSprite = null;
    }
    
    // 设置锚点为中心
    anchor = Anchor.center;
    
    // 添加碰撞检测 - 精确的碰撞区域，锚点与主体一致
    add(RectangleHitbox(
      size: Vector2(size.x * 0.6, size.y * 0.6), // 更小的碰撞盒，提高精确度
      position: Vector2.zero(), // 相对于玩家中心的位置偏移
      anchor: Anchor.center, // 碰撞盒的锚点也是中心
    ));
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // 更新晕眩状态
    _updateStunState(dt);
    
    // 更新推进器效果计时器
    thrusterTimer += dt;
    if (thrusterTimer > thrusterCycle) {
      thrusterTimer = 0.0;
    }
    
    // 如果处于晕眩状态，减少控制能力
    if (!isStunned) {
      // 根据速度更新倾斜角度
      final targetTiltAngle = velocity.x * 0.01; // 根据水平速度倾斜
      tiltAngle = _lerpAngle(tiltAngle, targetTiltAngle.clamp(-maxTiltAngle, maxTiltAngle), dt * tiltSpeed);
      
      // 应用倾斜
      angle = tiltAngle;
      
      // 更新位置
      position += velocity * dt;
    } else {
      // 晕眩状态下，飞机轻微摇摆
      angle = tiltAngle + math.sin(stunTimer * 10) * 0.1;
      
      // 晕眩状态下移动速度减半
      position += velocity * dt * 0.5;
    }
    
    // 限制在游戏区域内
    position.x = position.x.clamp(size.x / 2, gameSize.x - size.x / 2);
    position.y = position.y.clamp(size.y / 2, gameSize.y - size.y / 2);
    
    // 重置速度（每帧都需要重新设置）
    velocity = Vector2.zero();
  }
  
  @override
  void render(Canvas canvas) {
    // 如果处于闪烁状态且当前不可见，则不绘制
    if (isStunned && !isVisible) {
      return;
    }
    
    // 如果有sprite就用sprite渲染，否则自定义绘制
    if (playerSprite != null) {
      playerSprite!.render(canvas, size: size);
    } else {
      _renderCustomPlane(canvas);
    }
    
    // 绘制推进器效果
    _renderThruster(canvas);
    
    // 如果处于晕眩状态，绘制晕眩效果
    if (isStunned) {
      _renderStunEffect(canvas);
    }
  }
  
  /// 更新晕眩状态
  void _updateStunState(double dt) {
    if (!isStunned) return;
    
    // 更新晕眩计时器
    stunTimer += dt;
    
    // 更新闪烁计时器
    flashTimer += dt;
    
    // 控制闪烁
    if (flashTimer >= flashInterval) {
      isVisible = !isVisible; // 切换可见性
      flashTimer = 0.0;
    }
    
    // 检查晕眩是否结束
    if (stunTimer >= stunDuration) {
      _endStun();
    }
  }
  
  /// 开始晕眩状态
  void startStun() {
    isStunned = true;
    stunTimer = 0.0;
    flashTimer = 0.0;
    isVisible = true;
  }
  
  /// 结束晕眩状态
  void _endStun() {
    isStunned = false;
    stunTimer = 0.0;
    flashTimer = 0.0;
    isVisible = true;
    angle = 0.0; // 重置角度
  }
  
  /// 绘制晕眩效果（星星特效）
  void _renderStunEffect(Canvas canvas) {
    final starPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    // 在飞机周围绘制旋转的星星
    final starCount = 3;
    final radius = size.x * 0.8;
    
    for (int i = 0; i < starCount; i++) {
      final angle = (stunTimer * 3 + i * (2 * math.pi / starCount));
      final starX = math.cos(angle) * radius;
      final starY = math.sin(angle) * radius;
      
      // 绘制星星形状
      _drawStar(canvas, Offset(starX, starY), 8.0, starPaint);
    }
  }
  
  /// 绘制星星
  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const spikes = 5;
    const outerRadius = 1.0;
    const innerRadius = 0.5;
    
    for (int i = 0; i < spikes * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * math.pi) / spikes;
      final x = center.dx + math.cos(angle) * radius * size;
      final y = center.dy + math.sin(angle) * radius * size;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  /// 自定义绘制飞机（当图片加载失败时使用）
  void _renderCustomPlane(Canvas canvas) {
    final planePaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;
    
    final wingPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    
    // 绘制机身
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.x * 0.3,
        height: size.y * 0.8,
      ),
      planePaint,
    );
    
    // 绘制机翼
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, 5),
        width: size.x * 0.8,
        height: size.y * 0.3,
      ),
      wingPaint,
    );
    
    // 绘制机头
    final nosePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(0, -size.y * 0.3),
      size.x * 0.1,
      nosePaint,
    );
  }
  
  /// 绘制推进器效果
  void _renderThruster(Canvas canvas) {
    if (thrusterTimer < thrusterCycle * 0.5) {
      final thrusterPaint = Paint()
        ..color = Colors.orange.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      // 绘制推进器火焰
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, size.y * 0.35),
          width: size.x * 0.2,
          height: size.y * 0.3,
        ),
        thrusterPaint,
      );
      
      // 内部火焰
      final innerThrusterPaint = Paint()
        ..color = Colors.yellow.withOpacity(0.9)
        ..style = PaintingStyle.fill;
      
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, size.y * 0.35),
          width: size.x * 0.1,
          height: size.y * 0.2,
        ),
        innerThrusterPaint,
      );
    }
  }
  
  /// 移动飞机
  void moveBy(Vector2 delta) {
    velocity += delta;
  }
  
  /// 移动到指定位置
  void moveTo(Vector2 target) {
    const moveSpeed = 300.0;
    final direction = (target - position).normalized();
    velocity = direction * moveSpeed;
  }
  
  /// 线性插值角度
  double _lerpAngle(double from, double to, double t) {
    final difference = to - from;
    return from + difference * t.clamp(0.0, 1.0);
  }
  
  /// 获取飞机前方位置（用于发射子弹）
  Vector2 get frontPosition {
    return Vector2(position.x, position.y - size.y / 2);
  }
  
  @override
  bool onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    // 如果已经处于晕眩状态，忽略新的碰撞
    if (isStunned) {
      return true;
    }
    
    // 处理玩家碰撞
    if (other.runtimeType.toString().contains('Enemy')) {
      // 玩家撞击敌机 - 移除敌机
      other.removeFromParent();

      // 创建爆炸效果
      _createExplosionAt(position);

      // 开始晕眩状态
      startStun();

      // 减少生命
      _loseLife();
    } else if (other.runtimeType.toString().contains('Bullet')) {
      final bullet = other as dynamic;
      // 如果是敌机子弹
      if (bullet.isPlayerBullet == false) {
        other.removeFromParent(); // 移除子弹

        // 创建爆炸效果
        _createExplosionAt(position);
        
        // 开始晕眩状态
        startStun();
        
        // 减少生命
        _loseLife();
      }
    }
    
    return true;
  }
  
  /// 创建爆炸效果
  void _createExplosionAt(Vector2 pos) {
    try {
      // 通过gameRef访问游戏引擎创建爆炸
      (gameRef as dynamic).createExplosion?.call(pos);
    } catch (e) {
      print('❌ 创建爆炸效果时出错: $e');
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
