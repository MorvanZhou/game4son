import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'obstacle.dart';
import '../game_config.dart';

/// 飞鸟障碍物组件 - 独立的飞鸟实现，支持自适应游戏尺寸
/// 使用真实图片尺寸：Bird1.png (97x68), Bird2.png (93x62)，使用配置系统应用缩放
class BirdObstacle extends Obstacle {
  
  final math.Random random = math.Random();
  int animationIndex = 0;
  double animationTimer = 0.0;
  
  // 飞鸟动画精灵
  late List<Sprite> birdSprites;
  late List<Vector2> birdSizes; // 存储每个精灵的实际尺寸

  BirdObstacle() : super();

  @override
  Future<void> onLoad() async {
    await super.onLoad(); // 先调用父类的onLoad获取游戏尺寸
    
    // 根据游戏高度动态计算飞鸟飞行高度
    final List<double> birdHeights = _calculateBirdHeights();
    
    // 随机选择飞行高度
    final selectedHeight = birdHeights[random.nextInt(birdHeights.length)];
    position = Vector2(gameWidth, selectedHeight);
    
    // 加载飞鸟精灵并设置初始尺寸
    await loadSprite();
    
    // 初始化碰撞矩形
    updateCollisionRect();
  }

  @override
  Future<void> loadSprite() async {
    // 加载飞鸟动画精灵 - 参考Python版本的BIRD数组
    birdSprites = [
      await Sprite.load('dino-jump.Bird1.png'),
      await Sprite.load('dino-jump.Bird2.png'),
    ];
    
    // 设置每个精灵的实际尺寸，使用配置系统
    birdSizes = [
      Vector2(DinoGameConfig.bird1Width, DinoGameConfig.bird1Height), // Bird1: 97x68
      Vector2(DinoGameConfig.bird2Width, DinoGameConfig.bird2Height), // Bird2: 93x62  
    ];
    
    // 设置初始精灵和尺寸
    sprite = birdSprites[0];
    size = birdSizes[0];
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // 更新动画 - 飞鸟翅膀拍动效果
    _updateBirdAnimation(dt);
  }

  /// 更新飞鸟动画 - 在两个精灵之间切换模拟翅膀拍动
  void _updateBirdAnimation(double dt) {
    animationTimer += dt;
    
    // 每0.2秒切换一次精灵，模拟翅膀拍动
    if (animationTimer >= 0.2) {
      animationIndex = (animationIndex + 1) % birdSprites.length;
      sprite = birdSprites[animationIndex];
      size = birdSizes[animationIndex]; // 更新尺寸以匹配当前精灵
      animationTimer = 0.0;
    }
  }

  /// 计算飞鸟的可能飞行高度 - 基于屏幕高度动态计算，使用配置系统
  List<double> _calculateBirdHeights() {
    // 参考Python版本的飞鸟高度计算逻辑，使用配置系统的高度偏移
    // 飞鸟应该在恐龙跳跃范围内，但不会太低或太高
    return [
      groundY - DinoGameConfig.birdHeightOffset1, // 较低的飞行高度
      groundY - DinoGameConfig.birdHeightOffset2, // 中等的飞行高度  
      groundY - DinoGameConfig.birdHeightOffset3, // 较高的飞行高度
    ];
  }

  /// 更新碰撞矩形 - 针对飞鸟的特殊碰撞检测优化
  @override
  void updateCollisionRect() {
    // 飞鸟碰撞矩形收缩参数 - 比仙人掌更宽松，使用配置系统
    final double shrinkX = DinoGameConfig.birdCollisionShrinkX; // 左右各收缩
    final double shrinkY = DinoGameConfig.birdCollisionShrinkY; // 上下各收缩
    
    obstacleRect = Rect.fromLTWH(
      position.x + shrinkX/2, // X坐标向右偏移收缩量的一半
      position.y - size.y + shrinkY/2, // Y坐标向下偏移收缩量的一半
      size.x - shrinkX, // 宽度减少收缩量
      size.y - shrinkY, // 高度减少收缩量
    );
  }

  /// 重置飞鸟到屏幕右侧 - 重新随机选择飞行高度
  @override
  void reset() {
    position.x = gameWidth + random.nextInt(200);
    
    // 重新随机选择飞行高度
    final List<double> birdHeights = _calculateBirdHeights();
    position.y = birdHeights[random.nextInt(birdHeights.length)];
    
    // 重置动画状态
    animationIndex = 0;
    animationTimer = 0.0;
    sprite = birdSprites[0];
    size = birdSizes[0];
    
    updateCollisionRect();
  }
}
