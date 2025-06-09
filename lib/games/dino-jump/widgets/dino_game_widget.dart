import 'package:flutter/material.dart';
import '../models/dino_game_model.dart';
import '../models/game_entities.dart'; // 导入游戏实体
import 'dart:math' as math;

class DinoGameWidget extends StatelessWidget {
  final DinoGameModel gameModel;
  final Animation<double> backgroundAnimation;

  const DinoGameWidget({
    super.key,
    required this.gameModel,
    required this.backgroundAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF7F7F7), // 浅灰色背景
      child: CustomPaint(
        painter: DinoGamePainter(
          gameModel: gameModel,
          backgroundAnimation: backgroundAnimation,
        ),
        child: Container(), // 空容器用于接收点击事件
      ),
    );
  }
}

class DinoGamePainter extends CustomPainter {
  final DinoGameModel gameModel;
  final Animation<double> backgroundAnimation;

  DinoGamePainter({
    required this.gameModel,
    required this.backgroundAnimation,
  }) : super(repaint: backgroundAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景云朵
    _drawClouds(canvas, size);
    
    // 绘制地面
    _drawGround(canvas, size);
    
    // 绘制障碍物
    _drawObstacles(canvas, size);
    
    // 绘制恐龙
    _drawDino(canvas, size);
    
    // 绘制游戏状态提示
    _drawGameStateOverlay(canvas, size);
  }

  // 绘制云朵
  void _drawClouds(Canvas canvas, Size size) {
    final Paint cloudPaint = Paint()
      ..color = const Color(0xFFDDDDDD)
      ..style = PaintingStyle.fill;

    for (Cloud cloud in gameModel.clouds) {
      // 绘制简单的云朵形状
      _drawCloud(canvas, cloud.x, cloud.y, cloudPaint);
    }
  }

  // 绘制单个云朵
  void _drawCloud(Canvas canvas, double x, double y, Paint paint) {
    final Path cloudPath = Path();
    
    // 创建云朵形状（多个圆形组合）
    cloudPath.addOval(Rect.fromCenter(center: Offset(x, y), width: 30, height: 20));
    cloudPath.addOval(Rect.fromCenter(center: Offset(x + 15, y), width: 25, height: 18));
    cloudPath.addOval(Rect.fromCenter(center: Offset(x - 10, y + 5), width: 20, height: 15));
    cloudPath.addOval(Rect.fromCenter(center: Offset(x + 10, y + 8), width: 22, height: 16));
    
    canvas.drawPath(cloudPath, paint);
  }

  // 绘制地面
  void _drawGround(Canvas canvas, Size size) {
    final Paint groundPaint = Paint()
      ..color = const Color(0xFF535353)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    double groundY = gameModel.groundY;
    
    // 绘制地面线条
    canvas.drawLine(
      Offset(0, groundY),
      Offset(size.width, groundY),
      groundPaint,
    );

    // 绘制滚动的地面纹理（小点点）
    final Paint dotPaint = Paint()
      ..color = const Color(0xFF535353)
      ..style = PaintingStyle.fill;

    double offset = (backgroundAnimation.value * 20) % 20;
    for (double x = -offset; x < size.width + 20; x += 20) {
      if (x > 0) {
        canvas.drawCircle(
          Offset(x, groundY + 5),
          1,
          dotPaint,
        );
      }
    }
  }

  // 绘制障碍物
  void _drawObstacles(Canvas canvas, Size size) {
    for (Obstacle obstacle in gameModel.obstacles) {
      switch (obstacle.type) {
        case ObstacleType.cactus:
          _drawCactus(canvas, obstacle);
          break;
        case ObstacleType.bird:
          _drawBird(canvas, obstacle);
          break;
      }
    }
  }

  // 绘制仙人掌
  void _drawCactus(Canvas canvas, Obstacle obstacle) {
    final Paint cactusPaint = Paint()
      ..color = const Color(0xFF535353)
      ..style = PaintingStyle.fill;

    double x = obstacle.x;
    double y = DinoGameModel.gameHeight - obstacle.y - obstacle.height;
    double width = obstacle.width;
    double height = obstacle.height;

    // 主体
    final Rect mainBody = Rect.fromLTWH(x + width * 0.3, y, width * 0.4, height);
    canvas.drawRect(mainBody, cactusPaint);

    // 左臂
    final Rect leftArm = Rect.fromLTWH(x, y + height * 0.3, width * 0.5, width * 0.2);
    canvas.drawRect(leftArm, cactusPaint);

    // 右臂
    final Rect rightArm = Rect.fromLTWH(x + width * 0.5, y + height * 0.5, width * 0.5, width * 0.2);
    canvas.drawRect(rightArm, cactusPaint);

    // 添加一些刺（小线条）
    final Paint spinePaint = Paint()
      ..color = const Color(0xFF535353)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      double spineY = y + height * 0.2 + i * (height * 0.6 / 4);
      canvas.drawLine(
        Offset(x + width * 0.5, spineY),
        Offset(x + width * 0.5 - 3, spineY - 2),
        spinePaint,
      );
      canvas.drawLine(
        Offset(x + width * 0.5, spineY),
        Offset(x + width * 0.5 + 3, spineY - 2),
        spinePaint,
      );
    }
  }

  // 绘制飞鸟
  void _drawBird(Canvas canvas, Obstacle obstacle) {
    final Paint birdPaint = Paint()
      ..color = const Color(0xFF535353)
      ..style = PaintingStyle.fill;

    double x = obstacle.x;
    double y = DinoGameModel.gameHeight - obstacle.y - obstacle.height;
    double width = obstacle.width;
    double height = obstacle.height;

    // 鸟身体（椭圆）
    final Rect bodyRect = Rect.fromLTWH(x + width * 0.2, y + height * 0.3, width * 0.6, height * 0.4);
    canvas.drawOval(bodyRect, birdPaint);

    // 翅膀（使用动画效果模拟扇动）
    double wingOffset = math.sin(DateTime.now().millisecondsSinceEpoch / 100) * 3;
    
    // 左翅膀
    final Path leftWing = Path();
    leftWing.moveTo(x + width * 0.2, y + height * 0.5);
    leftWing.quadraticBezierTo(
      x - 5 + wingOffset, y + height * 0.2,
      x + width * 0.1, y + height * 0.8,
    );
    canvas.drawPath(leftWing, birdPaint);

    // 右翅膀
    final Path rightWing = Path();
    rightWing.moveTo(x + width * 0.8, y + height * 0.5);
    rightWing.quadraticBezierTo(
      x + width + 5 - wingOffset, y + height * 0.2,
      x + width * 0.9, y + height * 0.8,
    );
    canvas.drawPath(rightWing, birdPaint);

    // 鸟嘴
    final Path beak = Path();
    beak.moveTo(x + width * 0.8, y + height * 0.5);
    beak.lineTo(x + width, y + height * 0.4);
    beak.lineTo(x + width * 0.8, y + height * 0.6);
    beak.close();
    canvas.drawPath(beak, birdPaint);
  }

  // 绘制恐龙
  void _drawDino(Canvas canvas, Size size) {
    final Paint dinoPaint = Paint()
      ..color = const Color(0xFF535353)
      ..style = PaintingStyle.fill;

    double x = gameModel.dinoX;
    double y = gameModel.dinoScreenY;
    double width = gameModel.dinoWidth;
    double height = gameModel.dinoHeight;

    // 根据蹲下状态调整恐龙形状
    if (gameModel.dinoDucking) {
      // 蹲下状态：恐龙高度减半，形状压缩
      height = height * 0.5;
      
      // 恐龙身体（更宽更扁）
      final Rect body = Rect.fromLTWH(x + width * 0.1, y + height * 0.2, width * 0.8, height * 0.6);
      canvas.drawRect(body, dinoPaint);

      // 恐龙头部（椭圆形，更扁）
      final Rect head = Rect.fromLTWH(x + width * 0.05, y, width * 0.6, height * 0.5);
      canvas.drawOval(head, dinoPaint);

      // 恐龙尾巴（更低）
      final Path tail = Path();
      tail.moveTo(x + width * 0.1, y + height * 0.5);
      tail.quadraticBezierTo(
        x - width * 0.2, y + height * 0.3,
        x - width * 0.05, y + height * 0.8,
      );
      tail.lineTo(x, y + height);
      tail.lineTo(x + width * 0.15, y + height * 0.7);
      tail.close();
      canvas.drawPath(tail, dinoPaint);

      // 蹲下状态的腿部（贴地）
      final Rect leftLeg = Rect.fromLTWH(x + width * 0.25, y + height * 0.7, width * 0.2, height * 0.3);
      canvas.drawRect(leftLeg, dinoPaint);
      
      final Rect rightLeg = Rect.fromLTWH(x + width * 0.55, y + height * 0.7, width * 0.2, height * 0.3);
      canvas.drawRect(rightLeg, dinoPaint);

      // 恐龙眼睛（位置调整）
      final Paint eyePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(x + width * 0.35, y + height * 0.15),
        2.5,
        eyePaint,
      );

      // 眼珠
      final Paint pupilPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(x + width * 0.37, y + height * 0.15),
        1.2,
        pupilPaint,
      );
    } else {
      // 正常状态：保持原来的绘制逻辑
      // 恐龙身体（矩形）
      final Rect body = Rect.fromLTWH(x + width * 0.2, y + height * 0.3, width * 0.6, height * 0.5);
      canvas.drawRect(body, dinoPaint);

      // 恐龙头部（圆形）
      final Rect head = Rect.fromLTWH(x + width * 0.1, y, width * 0.5, height * 0.4);
      canvas.drawOval(head, dinoPaint);

      // 恐龙尾巴
      final Path tail = Path();
      tail.moveTo(x + width * 0.2, y + height * 0.5);
      tail.quadraticBezierTo(
        x - width * 0.3, y + height * 0.3,
        x - width * 0.1, y + height * 0.7,
      );
      tail.lineTo(x, y + height * 0.8);
      tail.lineTo(x + width * 0.2, y + height * 0.6);
      tail.close();
      canvas.drawPath(tail, dinoPaint);

      // 恐龙腿部（根据是否在地面调整）
      if (gameModel.dinoOnGround) {
        // 左腿
        final Rect leftLeg = Rect.fromLTWH(x + width * 0.3, y + height * 0.7, width * 0.15, height * 0.3);
        canvas.drawRect(leftLeg, dinoPaint);
        
        // 右腿
        final Rect rightLeg = Rect.fromLTWH(x + width * 0.55, y + height * 0.7, width * 0.15, height * 0.3);
        canvas.drawRect(rightLeg, dinoPaint);
      } else {
        // 跳跃状态：腿部收起
        final Rect leftLeg = Rect.fromLTWH(x + width * 0.35, y + height * 0.8, width * 0.12, height * 0.2);
        canvas.drawRect(leftLeg, dinoPaint);
        
        final Rect rightLeg = Rect.fromLTWH(x + width * 0.53, y + height * 0.8, width * 0.12, height * 0.2);
        canvas.drawRect(rightLeg, dinoPaint);
      }

      // 恐龙眼睛
      final Paint eyePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(x + width * 0.45, y + height * 0.15),
        3,
        eyePaint,
      );

      // 眼珠
      final Paint pupilPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(x + width * 0.47, y + height * 0.15),
        1.5,
        pupilPaint,
      );
    }
  }

  // 绘制游戏状态覆盖层
  void _drawGameStateOverlay(Canvas canvas, Size size) {
    if (gameModel.gameState == DinoGameState.ready) {
      _drawReadyOverlay(canvas, size);
    } else if (gameModel.gameState == DinoGameState.gameOver) {
      _drawGameOverOverlay(canvas, size);
    }
  }

  // 绘制准备开始覆盖层
  void _drawReadyOverlay(Canvas canvas, Size size) {
    // 半透明背景
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.3);
    canvas.drawRect(Offset.zero & size, overlayPaint);

    // 开始提示文字
    _drawCenteredText(
      canvas,
      size,
      '↑跳跃 ↓蹲下 | 点击上半屏跳跃，下半屏蹲下',
      const TextStyle(
        fontSize: 20,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // 绘制游戏结束覆盖层
  void _drawGameOverOverlay(Canvas canvas, Size size) {
    // 半透明背景
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5);
    canvas.drawRect(Offset.zero & size, overlayPaint);

    // 游戏结束文字
    _drawCenteredText(
      canvas,
      size,
      'GAME OVER',
      const TextStyle(
        fontSize: 32,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      offsetY: -30,
    );

    // 重新开始提示
    _drawCenteredText(
      canvas,
      size,
      '↑跳跃 ↓蹲下 | 点击重新开始',
      const TextStyle(
        fontSize: 18,
        color: Colors.white70,
        fontWeight: FontWeight.w500,
      ),
      offsetY: 10,
    );
  }

  // 绘制居中文字
  void _drawCenteredText(Canvas canvas, Size size, String text, TextStyle style, {double offsetY = 0}) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final Offset offset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2 + offsetY,
    );

    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // 总是重绘以保持游戏流畅
  }
}
