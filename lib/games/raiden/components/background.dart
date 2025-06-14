import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 雷电游戏背景组件
/// 
/// 功能特性：
/// 1. 滚动星空背景
/// 2. 动态星星效果
/// 3. 渐变色背景
class GameBackground extends Component with HasGameRef {
  
  // 星星列表
  final List<Star> stars = [];
  static const int starCount = 100;
  
  // 背景滚动
  double scrollOffset = 0.0;
  static const double scrollSpeed = 50.0;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 生成随机星星
    _generateStars();
  }
  
  /// 生成星星
  void _generateStars() {
    final gameSize = gameRef.size;
    
    for (int i = 0; i < starCount; i++) {
      stars.add(Star(
        position: Vector2(
          _random.nextDouble() * gameSize.x,
          _random.nextDouble() * gameSize.y,
        ),
        brightness: _random.nextDouble(),
        speed: _random.nextDouble() * 30 + 10,
      ));
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    final gameSize = gameRef.size;
    
    // 更新星星位置
    for (final star in stars) {
      star.position.y += star.speed * dt;
      
      // 重置超出屏幕的星星
      if (star.position.y > gameSize.y) {
        star.position.y = -10;
        star.position.x = _random.nextDouble() * gameSize.x;
        star.brightness = _random.nextDouble();
        star.speed = _random.nextDouble() * 30 + 10;
      }
    }
    
    // 更新背景滚动
    scrollOffset += scrollSpeed * dt;
    if (scrollOffset > gameSize.y) {
      scrollOffset = 0;
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final gameSize = gameRef.size;
    
    // 绘制渐变背景
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0A0A2E), // 深蓝紫
          Color(0xFF1A1A4E), // 蓝紫
          Color(0xFF2A2A6E), // 亮蓝紫
        ],
      ).createShader(Rect.fromLTWH(0, 0, gameSize.x, gameSize.y));
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameSize.x, gameSize.y),
      backgroundPaint,
    );
    
    // 绘制星星
    for (final star in stars) {
      final starPaint = Paint()
        ..color = Colors.white.withOpacity(star.brightness)
        ..style = PaintingStyle.fill;
      
      // 根据亮度决定星星大小
      final starSize = star.brightness * 2 + 0.5;
      
      canvas.drawCircle(
        Offset(star.position.x, star.position.y),
        starSize,
        starPaint,
      );
    }
  }
  
  static final _random = math.Random();
}

/// 星星数据类
class Star {
  Vector2 position;
  double brightness;
  double speed;
  
  Star({
    required this.position,
    required this.brightness,
    required this.speed,
  });
}
