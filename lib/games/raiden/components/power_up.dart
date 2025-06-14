import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

/// 道具组件
/// 
/// 功能特性：
/// 1. 多种道具类型
/// 2. 飘落动画
/// 3. 闪烁效果
/// 4. 碰撞检测
class PowerUp extends PositionComponent with HasGameRef, CollisionCallbacks {
  
  // 道具类型
  final PowerUpType type;
  
  // 移动相关
  Vector2 velocity;
  Vector2 gameSize;
  
  // 动画相关
  double animationTimer = 0.0;
  double blinkTimer = 0.0;
  bool isVisible = true;
  double opacity = 1.0; // 添加opacity属性
  
  // 道具属性
  final int value;
  final double lifeTime;
  double currentLifeTime = 0.0;
  
  PowerUp({
    required Vector2 position,
    required this.gameSize,
    this.type = PowerUpType.weaponUpgrade,
  }) : 
    velocity = Vector2(0, 50 + math.Random().nextDouble() * 30),
    value = _getValueForType(type),
    lifeTime = _getLifeTimeForType(type),
    super(
      position: position,
      size: _getSizeForType(type),
    );
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 设置锚点为中心
    anchor = Anchor.center;
    
    // 添加碰撞检测
    add(RectangleHitbox(
      size: Vector2(size.x * 0.8, size.y * 0.8),
    ));
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // 更新动画计时器
    animationTimer += dt;
    blinkTimer += dt;
    currentLifeTime += dt;
    
    // 飘落移动
    position += velocity * dt;
    
    // 轻微的水平摆动
    position.x += math.sin(animationTimer * 2) * 20 * dt;
    
    // 快过期时闪烁
    if (currentLifeTime > lifeTime * 0.8) {
      if (blinkTimer > 0.2) {
        isVisible = !isVisible;
        blinkTimer = 0.0;
      }
      opacity = isVisible ? 1.0 : 0.3;
    }
    
    // 生命周期结束或超出边界时移除
    if (currentLifeTime >= lifeTime || isOutOfBounds()) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    // 自定义绘制道具
    _renderCustomPowerUp(canvas);
    
    // 绘制光环效果
    if (opacity > 0.5) {
      _renderGlowEffect(canvas);
    }
  }
  
  /// 自定义绘制道具
  void _renderCustomPowerUp(Canvas canvas) {
    Color powerUpColor;
    
    switch (type) {
      case PowerUpType.weaponUpgrade:
        powerUpColor = Colors.blue;
        break;
      case PowerUpType.health:
        powerUpColor = Colors.green;
        break;
      case PowerUpType.score:
        powerUpColor = Colors.yellow;
        break;
      case PowerUpType.shield:
        powerUpColor = Colors.purple;
        break;
    }
    
    // 绘制道具背景
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.x,
          height: size.y,
        ),
        const Radius.circular(8),
      ),
      bgPaint,
    );
    
    // 绘制道具边框
    final borderPaint = Paint()
      ..color = powerUpColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.x,
          height: size.y,
        ),
        const Radius.circular(8),
      ),
      borderPaint,
    );
    
    // 绘制图标（简化版本）
    final iconPaint = Paint()
      ..color = powerUpColor
      ..style = PaintingStyle.fill;
    
    switch (type) {
      case PowerUpType.weaponUpgrade:
        // 绘制上箭头
        final path = Path();
        path.moveTo(0, -size.y * 0.2);
        path.lineTo(-size.x * 0.2, size.y * 0.1);
        path.lineTo(-size.x * 0.1, size.y * 0.1);
        path.lineTo(-size.x * 0.1, size.y * 0.2);
        path.lineTo(size.x * 0.1, size.y * 0.2);
        path.lineTo(size.x * 0.1, size.y * 0.1);
        path.lineTo(size.x * 0.2, size.y * 0.1);
        path.close();
        canvas.drawPath(path, iconPaint);
        break;
        
      case PowerUpType.health:
        // 绘制十字
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: size.x * 0.1,
            height: size.y * 0.4,
          ),
          iconPaint,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: size.x * 0.4,
            height: size.y * 0.1,
          ),
          iconPaint,
        );
        break;
        
      case PowerUpType.score:
        // 绘制星形（简化版）
        final starPath = Path();
        for (int i = 0; i < 5; i++) {
          final angle = (i * 2 * math.pi / 5) - math.pi / 2;
          final x = math.cos(angle) * size.x * 0.2;
          final y = math.sin(angle) * size.y * 0.2;
          if (i == 0) {
            starPath.moveTo(x, y);
          } else {
            starPath.lineTo(x, y);
          }
        }
        starPath.close();
        canvas.drawPath(starPath, iconPaint);
        break;
        
      case PowerUpType.shield:
        // 绘制盾牌形状
        final shieldPath = Path();
        shieldPath.moveTo(0, -size.y * 0.2);
        shieldPath.quadraticBezierTo(
          size.x * 0.2, -size.y * 0.1,
          size.x * 0.2, 0,
        );
        shieldPath.quadraticBezierTo(
          size.x * 0.2, size.y * 0.1,
          0, size.y * 0.2,
        );
        shieldPath.quadraticBezierTo(
          -size.x * 0.2, size.y * 0.1,
          -size.x * 0.2, 0,
        );
        shieldPath.quadraticBezierTo(
          -size.x * 0.2, -size.y * 0.1,
          0, -size.y * 0.2,
        );
        canvas.drawPath(shieldPath, iconPaint);
        break;
    }
  }
  
  /// 绘制光环效果
  void _renderGlowEffect(Canvas canvas) {
    final glowRadius = size.x * 0.8 + math.sin(animationTimer * 4) * 5;
    final glowPaint = Paint()
      ..color = _getColorForType(type).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    
    canvas.drawCircle(
      Offset.zero,
      glowRadius,
      glowPaint,
    );
  }
  
  /// 根据类型获取大小
  static Vector2 _getSizeForType(PowerUpType type) {
    switch (type) {
      case PowerUpType.weaponUpgrade:
        return Vector2(25, 25);
      case PowerUpType.health:
        return Vector2(20, 20);
      case PowerUpType.score:
        return Vector2(22, 22);
      case PowerUpType.shield:
        return Vector2(28, 28);
    }
  }
  
  /// 根据类型获取数值
  static int _getValueForType(PowerUpType type) {
    switch (type) {
      case PowerUpType.weaponUpgrade:
        return 1;
      case PowerUpType.health:
        return 1;
      case PowerUpType.score:
        return 100;
      case PowerUpType.shield:
        return 1;
    }
  }
  
  /// 根据类型获取生命周期
  static double _getLifeTimeForType(PowerUpType type) {
    switch (type) {
      case PowerUpType.weaponUpgrade:
        return 10.0;
      case PowerUpType.health:
        return 8.0;
      case PowerUpType.score:
        return 6.0;
      case PowerUpType.shield:
        return 12.0;
    }
  }
  
  /// 根据类型获取颜色
  Color _getColorForType(PowerUpType type) {
    switch (type) {
      case PowerUpType.weaponUpgrade:
        return Colors.blue;
      case PowerUpType.health:
        return Colors.green;
      case PowerUpType.score:
        return Colors.yellow;
      case PowerUpType.shield:
        return Colors.purple;
    }
  }
  
  /// 检查是否超出边界
  bool isOutOfBounds() {
    return position.y > gameSize.y + 50 ||
           position.x < -50 ||
           position.x > gameSize.x + 50;
  }
  
  /// 应用道具效果
  void applyEffect(dynamic target) {
    switch (type) {
      case PowerUpType.weaponUpgrade:
        // 升级武器
        if (target.hasMethod('upgradeWeapon')) {
          target.upgradeWeapon();
        }
        break;
      case PowerUpType.health:
        // 恢复血量
        if (target.hasMethod('heal')) {
          target.heal(value);
        }
        break;
      case PowerUpType.score:
        // 增加分数
        if (target.hasMethod('addScore')) {
          target.addScore(value);
        }
        break;
      case PowerUpType.shield:
        // 激活护盾
        if (target.hasMethod('activateShield')) {
          target.activateShield();
        }
        break;
    }
  }
}

/// 道具类型枚举
enum PowerUpType {
  weaponUpgrade,  // 武器升级
  health,         // 血量恢复
  score,          // 分数奖励
  shield,         // 护盾
}
