import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'obstacle.dart';

/// 飞鸟障碍物组件 - 独立的飞鸟实现，支持自适应游戏尺寸
/// 使用真实图片尺寸：Bird1.png (97x68), Bird2.png (93x62)
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
    
    // 加载飞鸟精灵图 - 使用实际图片尺寸
    birdSprites = [
      await Sprite.load('dino-jump.Bird1.png'), // 97x68
      await Sprite.load('dino-jump.Bird2.png'), // 93x62
    ];
    
    // 定义每个精灵的实际尺寸
    birdSizes = [
      Vector2(97, 68), // Bird1.png 尺寸
      Vector2(93, 62), // Bird2.png 尺寸
    ];
    
    // 设置初始精灵和尺寸
    sprite = birdSprites[0];
    size = birdSizes[0];
    
    // 更新碰撞矩形
    _updateCollisionRect();
  }

  /// 根据游戏高度动态计算飞鸟飞行高度
  List<double> _calculateBirdHeights() {
    // 飞鸟应该在地面上方一定距离飞行
    // 地面位置是gameHeight * 0.63，飞鸟在地面上方50-150像素的范围内飞行
    final baseHeight = groundY;
    return [
      baseHeight - 20,  // 地面上方20像素
      baseHeight - 70,  // 地面上方70像素
      baseHeight - 130, // 地面上方130像素
    ];
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // 更新飞鸟动画 - 更平滑的动画切换
    _updateBirdAnimation(dt);
  }

  /// 更新飞鸟动画 - 优化动画流畅度
  void _updateBirdAnimation(double dt) {
    animationTimer += dt;
    
    // 每0.15秒切换一次动画帧，让飞行更自然
    if (animationTimer >= 0.15) {
      animationIndex = (animationIndex + 1) % 2;
      sprite = birdSprites[animationIndex];
      size = birdSizes[animationIndex];
      animationTimer = 0.0;
      
      // 重新计算碰撞矩形（因为尺寸可能改变）
      _updateCollisionRect();
    }
  }

  /// 更新碰撞矩形 - 优化飞鸟碰撞检测，让边界比图片稍小
  void _updateCollisionRect() {
    // 飞鸟碰撞矩形收缩参数 - 飞鸟收缩更多，让躲避更容易
    const double shrinkX = 10.0; // 左右各收缩10像素
    const double shrinkY = 8.0; // 上下各收缩8像素
    
    obstacleRect = Rect.fromLTWH(
      position.x + shrinkX/2, // X坐标向右偏移收缩量的一半
      position.y - size.y + shrinkY/2, // Y坐标向下偏移收缩量的一半
      size.x - shrinkX, // 宽度减少收缩量
      size.y - shrinkY, // 高度减少收缩量
    );
  }

  /// 检查是否可以与蹲下的恐龙碰撞
  /// 飞鸟主要威胁跳跃或站立的恐龙，蹲下可以躲避
  bool canHitDuckingDino() {
    // 如果飞鸟飞行高度低于330，蹲下的恐龙仍可能被撞到
    return position.y > 330;
  }
}
