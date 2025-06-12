import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 障碍物基类 - 参考Python版本的Obstacle类，支持自适应游戏尺寸
abstract class Obstacle extends SpriteComponent {
  // 自适应游戏尺寸
  late double gameWidth;
  late double gameHeight;
  late double groundY; // 动态地面Y坐标
  
  // 障碍物类型
  int type = 0;
  
  // 碰撞矩形
  late Rect obstacleRect;

  Obstacle() {
    // 初始位置会在onLoad中设置
    anchor = Anchor.bottomLeft;
  }

  @override
  Future<void> onLoad() async {
    // 获取游戏尺寸（从父组件获取）
    gameWidth = (parent as dynamic).gameWidth ?? 1100.0;
    gameHeight = (parent as dynamic).gameHeight ?? 600.0;
    groundY = gameHeight * 0.63; // 与地面轨道保持一致
    
    // 设置初始位置为屏幕右侧地面上
    position = Vector2(gameWidth, groundY);
    
    await super.onLoad();
  }

  /// 更新移动 - 参考Python版本的update方法
  void updateMovement(int gameSpeed) {
    // 参考Python版本: self.rect.x -= game_speed
    position.x -= gameSpeed.toDouble();
    _updateCollisionRect();
  }

  /// 检查是否超出屏幕 - 参考Python版本的清理逻辑
  bool isOffScreen() {
    // 参考Python版本: if self.rect.x < -self.rect.width
    return position.x < -size.x;
  }

  /// 更新碰撞矩形 - 优化碰撞体验，让边界比图片稍小
  void _updateCollisionRect() {
    // 障碍物碰撞矩形收缩参数 - 让碰撞检测更宽松
    const double shrinkX = 6.0; // 左右各收缩6像素
    const double shrinkY = 4.0; // 上下各收缩4像素
    
    obstacleRect = Rect.fromLTWH(
      position.x + shrinkX/2, // X坐标向右偏移收缩量的一半
      position.y - size.y + shrinkY/2, // Y坐标向下偏移收缩量的一半
      size.x - shrinkX, // 宽度减少收缩量
      size.y - shrinkY, // 高度减少收缩量
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
    await super.onLoad(); // 调用父类onLoad获取游戏尺寸
    
    // 随机选择小仙人掌类型 - 参考Python版本: self.type = random.randint(0, 2)
    type = random.nextInt(3); // 0, 1, 2
    
    // 加载对应的精灵图
    final spriteNames = [
      'dino-jump.SmallCactus1.png',
      'dino-jump.SmallCactus2.png',
      'dino-jump.SmallCactus3.png',
    ];
    
    sprite = await Sprite.load(spriteNames[type]);
    
    // 根据实际图片尺寸设置大小
    switch (type) {
      case 0: // SmallCactus1: 40x71
        size = Vector2(40, 71);
        break;
      case 1: // SmallCactus2: 68x71  
        size = Vector2(68, 71);
        break;
      case 2: // SmallCactus3: 105x71
        size = Vector2(105, 71);
        break;
      default:
        size = Vector2(40, 71); // 默认使用第一个尺寸
        break;
    }
    
    // 更新碰撞矩形
    _updateCollisionRect();
  }
}

/// 大仙人掌 - 参考Python版本的LargeCactus类
class LargeCactus extends Obstacle {
  final math.Random random = math.Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad(); // 调用父类onLoad获取游戏尺寸
    
    // 随机选择大仙人掌类型 - 参考Python版本: self.type = random.randint(0, 2)
    type = random.nextInt(3); // 0, 1, 2
    
    // 加载对应的精灵图
    final spriteNames = [
      'dino-jump.LargeCactus1.png',
      'dino-jump.LargeCactus2.png',
      'dino-jump.LargeCactus3.png',
    ];
    
    sprite = await Sprite.load(spriteNames[type]);
    
    // 根据实际图片尺寸设置大小
    switch (type) {
      case 0: // LargeCactus1: 48x95
        size = Vector2(48, 95);
        break;
      case 1: // LargeCactus2: 99x95
        size = Vector2(99, 95);
        break;
      case 2: // LargeCactus3: 102x95
        size = Vector2(102, 95);
        break;
      default:
        size = Vector2(48, 95); // 默认使用第一个尺寸
        break;
    }
    
    // 更新碰撞矩形
    _updateCollisionRect();
  }
}
