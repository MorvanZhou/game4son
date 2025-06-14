import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 爆炸效果组件
/// 
/// 功能特性：
/// 1. 粒子爆炸动画
/// 2. 缩放和透明度变化
/// 3. 自动清理
/// 4. 不同类型的爆炸效果
class Explosion extends Component with HasGameRef {
  
  // 爆炸类型
  final ExplosionType type;
  
  // 动画相关
  double animationTimer = 0.0;
  final double animationDuration;
  late List<ExplosionParticle> particles;
  
  // 位置和大小
  Vector2 position;
  Vector2 size;
  
  Explosion({
    required this.position,
    this.type = ExplosionType.normal,
  }) : 
    animationDuration = _getDurationForType(type),
    size = _getSizeForType(type) {
    
    
    // 创建粒子
    _createParticles();
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    animationTimer += dt;
    
    // 更新所有粒子
    for (final particle in particles) {
      particle.update(dt);
    }
    
    // 动画完成后移除组件
    if (animationTimer >= animationDuration) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(position.x, position.y);
    
    // 绘制所有粒子
    for (final particle in particles) {
      particle.render(canvas);
    }
    
    canvas.restore();
  }
  
  /// 创建爆炸粒子
  void _createParticles() {
    particles = [];
    final particleCount = _getParticleCountForType(type);
    final random = math.Random();
    
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi + random.nextDouble() * 0.5;
      final speed = 50 + random.nextDouble() * 100;
      final lifeTime = animationDuration * (0.8 + random.nextDouble() * 0.4);
      
      particles.add(ExplosionParticle(
        position: Vector2.zero(),
        velocity: Vector2(math.cos(angle), math.sin(angle)) * speed,
        lifeTime: lifeTime,
        color: _getColorForType(type),
        size: 2 + random.nextDouble() * 4,
      ));
    }
  }
  
  /// 根据类型获取持续时间
  static double _getDurationForType(ExplosionType type) {
    switch (type) {
      case ExplosionType.small:
        return 0.3;
      case ExplosionType.normal:
        return 0.5;
      case ExplosionType.large:
        return 0.8;
    }
  }
  
  /// 根据类型获取大小
  static Vector2 _getSizeForType(ExplosionType type) {
    switch (type) {
      case ExplosionType.small:
        return Vector2(30, 30);
      case ExplosionType.normal:
        return Vector2(50, 50);
      case ExplosionType.large:
        return Vector2(80, 80);
    }
  }
  
  /// 根据类型获取粒子数量
  int _getParticleCountForType(ExplosionType type) {
    switch (type) {
      case ExplosionType.small:
        return 8;
      case ExplosionType.normal:
        return 12;
      case ExplosionType.large:
        return 20;
    }
  }
  
  /// 根据类型获取颜色
  Color _getColorForType(ExplosionType type) {
    switch (type) {
      case ExplosionType.small:
        return Colors.orange;
      case ExplosionType.normal:
        return Colors.red;
      case ExplosionType.large:
        return Colors.yellow;
    }
  }
}

/// 爆炸粒子
class ExplosionParticle {
  Vector2 position;
  Vector2 velocity;
  double lifeTime;
  double currentTime = 0.0;
  Color color;
  double size;
  
  ExplosionParticle({
    required this.position,
    required this.velocity,
    required this.lifeTime,
    required this.color,
    required this.size,
  });
  
  void update(double dt) {
    currentTime += dt;
    position += velocity * dt;
    
    // 减速
    velocity *= 0.98;
  }
  
  void render(Canvas canvas) {
    if (currentTime >= lifeTime) return;
    
    final progress = currentTime / lifeTime;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);
    final currentSize = size * (1.0 - progress * 0.5);
    
    final paint = Paint()
      ..color = color.withOpacity(alpha)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(position.x, position.y),
      currentSize,
      paint,
    );
  }
}

/// 爆炸类型枚举
enum ExplosionType {
  small,   // 小爆炸
  normal,  // 普通爆炸
  large,   // 大爆炸
}
