import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../game_config.dart';

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
    // 获取游戏尺寸（从父组件获取），使用配置系统
    gameWidth = (parent as dynamic).gameWidth ?? 1100.0;
    gameHeight = (parent as dynamic).gameHeight ?? 600.0;
    groundY = DinoGameConfig.groundY; // 使用配置系统的地面位置
    
    // 设置初始位置
    position = Vector2(gameWidth, groundY);
    
    // 子类将设置具体的精灵和尺寸
    await loadSprite();
    
    // 初始化碰撞矩形
    updateCollisionRect();
  }
  
  /// 抽象方法 - 子类实现具体的精灵加载
  Future<void> loadSprite();

  @override
  void update(double dt) {
    super.update(dt);
    
    // 更新碰撞矩形
    updateCollisionRect();
  }

  /// 更新障碍物移动 - 参考Python版本的update方法
  void updateMovement(int gameSpeed) {
    // 向左移动，使用配置系统的缩放
    position.x -= gameSpeed * DinoGameConfig.GLOBAL_SCALE_FACTOR;
  }

  /// 更新碰撞矩形 - 优化碰撞体验，让边界比图片稍小
  void updateCollisionRect() {
    // 障碍物碰撞矩形收缩参数 - 让碰撞检测更宽松，使用配置系统
    final double shrinkX = DinoGameConfig.collisionShrinkX; // 左右各收缩
    final double shrinkY = DinoGameConfig.collisionShrinkY; // 上下各收缩
    
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

  /// 检查是否超出屏幕左边界
  bool isOffScreen() {
    return position.x < -size.x;
  }

  /// 重置障碍物到屏幕右侧
  void reset() {
    position.x = gameWidth + math.Random().nextInt(200);
    position.y = groundY;
    updateCollisionRect();
  }
}

/// 小仙人掌障碍物 - 参考Python版本的SmallCactus类
class SmallCactus extends Obstacle {
  
  @override
  Future<void> loadSprite() async {
    // 随机选择小仙人掌类型 - 参考Python版本的random.randint(0, 2)
    type = math.Random().nextInt(3);
    
    switch (type) {
      case 0: // SmallCactus1: 使用配置系统的尺寸
        sprite = await Sprite.load('dino-jump.SmallCactus1.png');
        size = Vector2(DinoGameConfig.smallCactus1Width, DinoGameConfig.smallCactus1Height);
        break;
      case 1: // SmallCactus2: 使用配置系统的尺寸
        sprite = await Sprite.load('dino-jump.SmallCactus2.png');
        size = Vector2(DinoGameConfig.smallCactus2Width, DinoGameConfig.smallCactus2Height);
        break;
      case 2: // SmallCactus3: 使用配置系统的尺寸
        sprite = await Sprite.load('dino-jump.SmallCactus3.png');
        size = Vector2(DinoGameConfig.smallCactus3Width, DinoGameConfig.smallCactus3Height);
        break;
      default:
        sprite = await Sprite.load('dino-jump.SmallCactus1.png');
        size = Vector2(DinoGameConfig.smallCactus1Width, DinoGameConfig.smallCactus1Height);
    }
  }
}

/// 大仙人掌障碍物 - 参考Python版本的LargeCactus类
class LargeCactus extends Obstacle {
  
  @override
  Future<void> loadSprite() async {
    // 随机选择大仙人掌类型 - 参考Python版本的random.randint(0, 2)
    type = math.Random().nextInt(3);
    
    switch (type) {
      case 0: // LargeCactus1: 使用配置系统的尺寸
        sprite = await Sprite.load('dino-jump.LargeCactus1.png');
        size = Vector2(DinoGameConfig.largeCactus1Width, DinoGameConfig.largeCactus1Height);
        break;
      case 1: // LargeCactus2: 使用配置系统的尺寸
        sprite = await Sprite.load('dino-jump.LargeCactus2.png');
        size = Vector2(DinoGameConfig.largeCactus2Width, DinoGameConfig.largeCactus2Height);
        break;
      case 2: // LargeCactus3: 使用配置系统的尺寸
        sprite = await Sprite.load('dino-jump.LargeCactus3.png');
        size = Vector2(DinoGameConfig.largeCactus3Width, DinoGameConfig.largeCactus3Height);
        break;
      default:
        sprite = await Sprite.load('dino-jump.LargeCactus1.png');
        size = Vector2(DinoGameConfig.largeCactus1Width, DinoGameConfig.largeCactus1Height);
    }
  }
}
