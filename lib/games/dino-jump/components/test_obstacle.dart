import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 简单测试障碍物 - 用于调试渲染问题
class TestObstacle extends RectangleComponent {
  final int gameSpeed = 20;
  
  TestObstacle({required Vector2 startPosition}) {
    position = startPosition;
    size = Vector2(34, 70);
    paint = Paint()..color = Colors.red;
    anchor = Anchor.bottomLeft;
    
    print('测试障碍物创建: position=${position}, size=${size}');
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // 简单向左移动
    position.x -= gameSpeed;
    
    // 添加调试信息
    print('测试障碍物更新: position=${position}');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // 额外绘制一个绿色边框
    final borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawRect(
      Rect.fromLTWH(0, -size.y, size.x, size.y),
      borderPaint,
    );
    
    // 绘制位置信息
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );
    
    final textSpan = TextSpan(
      text: '(${position.x.toInt()}, ${position.y.toInt()})',
      style: textStyle,
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, Offset(5, -size.y + 5));
  }

  bool isOffScreen() {
    return position.x < -size.x;
  }
}
