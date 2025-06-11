import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 障碍物基类 - 参考Python版本的Obstacle类
abstract class Obstacle extends SpriteComponent {
  // 屏幕常量
  static const double screenWidth = 1100.0;
  static const double groundY = 380.0; // 地面Y坐标
  
  // 障碍物类型
  int type = 0;
  
  // 碰撞矩形
  late Rect obstacleRect;

  Obstacle() {
    // 设置初始位置为屏幕右侧地面上
    position = Vector2(screenWidth, groundY);
    anchor = Anchor.bottomLeft;
  }

  /// 更新移动 - 参考Python版本的update方法
  void updateMovement(int gameSpeed) {
    // 记录更新前的位置
    final oldPosition = Vector2.copy(position);
    
    // 参考Python版本: self.rect.x -= game_speed
    position.x -= gameSpeed.toDouble();
    
    // 添加调试信息
    print('障碍物移动: ${oldPosition} -> ${position}, gameSpeed=${gameSpeed}');
    
    _updateCollisionRect();
  }

  /// 检查是否超出屏幕 - 参考Python版本的清理逻辑
  bool isOffScreen() {
    // 参考Python版本: if self.rect.x < -self.rect.width
    return position.x < -size.x;
  }

  /// 更新碰撞矩形
  void _updateCollisionRect() {
    obstacleRect = Rect.fromLTWH(
      position.x,
      position.y - size.y, // 因为anchor是bottomLeft，所以要减去高度
      size.x,
      size.y,
    );
  }

  /// 获取碰撞矩形
  Rect getCollisionRect() {
    return obstacleRect;
  }
}

/// 小仙人掌 - 参考Python版本的SmallCactus类
class SmallCactus extends Obstacle {
  final math.Random random = math.Random();

  @override
  Future<void> onLoad() async {
    // 随机选择小仙人掌类型 - 参考Python版本: self.type = random.randint(0, 2)
    type = random.nextInt(3); // 0, 1, 2
    
    // 加载对应的精灵图
    final spriteNames = [
      'dino-jump.SmallCactus1.png',
      'dino-jump.SmallCactus2.png',
      'dino-jump.SmallCactus3.png',
    ];
    
    sprite = await Sprite.load(spriteNames[type]);
    
    // 设置大小 - 根据图片调整大小
    size = Vector2(34, 70);
    
    // 不要重新设置位置，使用父类构造函数中设置的初始位置
    _updateCollisionRect();
    
    // 添加调试信息
    print('小仙人掌加载完成: position=${position}, size=${size}, sprite loaded: ${sprite != null}');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // 添加调试渲染 - 绘制一个红色矩形来确保组件在正确位置
    if (sprite != null) {
      final debugPaint = Paint()
        ..color = const Color(0x80FF0000) // 半透明红色
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      canvas.drawRect(
        Rect.fromLTWH(0, -size.y, size.x, size.y),
        debugPaint,
      );
    }
  }
}

/// 大仙人掌 - 参考Python版本的LargeCactus类
class LargeCactus extends Obstacle {
  final math.Random random = math.Random();

  @override
  Future<void> onLoad() async {
    // 随机选择大仙人掌类型 - 参考Python版本: self.type = random.randint(0, 2)
    type = random.nextInt(3); // 0, 1, 2
    
    // 加载对应的精灵图
    final spriteNames = [
      'dino-jump.LargeCactus1.png',
      'dino-jump.LargeCactus2.png',
      'dino-jump.LargeCactus3.png',
    ];
    
    sprite = await Sprite.load(spriteNames[type]);
    
    // 设置大小 - 根据图片调整大小
    size = Vector2(50, 100);
    
    // 不要重新设置位置，使用父类构造函数中设置的初始位置
    _updateCollisionRect();
    
    // 添加调试信息
    print('大仙人掌加载完成: position=${position}, size=${size}');
  }
}

/// 飞鸟障碍物 - 参考Python版本的Bird类
class BirdObstacle extends Obstacle {
  // 参考Python版本的BIRD_HEIGHTS = [250, 290, 320]
  static const List<double> birdHeights = [250.0, 290.0, 320.0];
  
  final math.Random random = math.Random();
  int animationIndex = 0; // 参考Python版本的self.index = 0
  
  // 鸟类动画精灵
  late List<Sprite> birdSprites;

  BirdObstacle() : super() {
    // 为飞鸟设置特殊的Y位置（在空中）
    final selectedHeight = birdHeights[random.nextInt(birdHeights.length)];
    position = Vector2(Obstacle.screenWidth, selectedHeight);
  }

  @override
  Future<void> onLoad() async {
    // 加载鸟类精灵图 - 参考Python版本的BIRD数组
    birdSprites = [
      await Sprite.load('dino-jump.Bird1.png'),
      await Sprite.load('dino-jump.Bird2.png'),
    ];
    
    // 设置初始精灵
    sprite = birdSprites[0];
    
    // 设置大小
    size = Vector2(60, 50); // 根据图片调整大小
    
    // 不要重新设置位置，使用构造函数中设置的位置
    _updateCollisionRect();
    
    // 添加调试信息
    print('飞鸟加载完成: position=${position}, size=${size}');
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // 鸟类飞行动画 - 参考Python版本的draw方法动画逻辑
    _updateBirdAnimation();
  }

  /// 更新鸟类动画 - 参考Python版本的Bird.draw方法
  void _updateBirdAnimation() {
    // 参考Python版本: if self.index >= 9: self.index = 0
    if (animationIndex >= 9) {
      animationIndex = 0;
    }
    
    // 参考Python版本: SCREEN.blit(self.image[self.index // 5], self.rect)
    sprite = birdSprites[animationIndex ~/ 5];
    animationIndex += 1;
  }
}
