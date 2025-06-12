import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'obstacle.dart';

/// 恐龙玩家组件 - 完全参考Python版本的Dinosaur类
class DinoPlayer extends SpriteAnimationComponent {
  // 恐龙常量 - 根据Python分析脚本优化的物理参数
  static const double xPos = 80.0;        // X_POS = 80
  static const double yPos = 310.0;       // Y_POS = 310
  static const double yPosDuck = 340.0;   // Y_POS_DUCK = 340
  static const double jumpVel = 7.6;      // 优化后的初始跳跃速度 (px/frame)
  static const double gravity = 13.3;     // 重力加速度 (px/s)
  
  // 恐龙尺寸常量 - 基于实际图片尺寸
  static final Vector2 runSize1 = Vector2(87, 94);        // DinoRun1 实际尺寸
  static final Vector2 runSize2 = Vector2(88, 94);        // DinoRun2 实际尺寸  
  static final Vector2 jumpSize = Vector2(88, 94);        // DinoJump 实际尺寸
  static final Vector2 duckSize1 = Vector2(108, 60);      // DinoDuck1 实际尺寸
  static final Vector2 duckSize2 = Vector2(116, 60);      // DinoDuck2 实际尺寸
  static final Vector2 startSize = Vector2(97, 101);      // DinoStart 实际尺寸
  static final Vector2 deadSize = Vector2(86, 101);       // DinoDead 实际尺寸
  
  // 统一使用的游戏尺寸 - 为了保持游戏平衡，使用平均尺寸
  static final Vector2 gameRunSize = Vector2(88, 94);     // 跑步和跳跃统一尺寸
  static final Vector2 gameDuckSize = Vector2(112, 60);   // 蹲下统一尺寸（取平均值）
  static const double groundY = 380.0;                    // 地面Y坐标
  
  // 恐龙状态 - 参考Python版本的状态变量
  bool dinoDuck = false;    // dino_duck
  bool dinoRun = true;      // dino_run
  bool dinoJump = false;    // dino_jump
  
  int stepIndex = 0;        // step_index
  double jumpVelocity = jumpVel;  // jump_vel
  
  // 精灵动画组件
  late SpriteAnimationComponent runAnimation;
  late SpriteAnimationComponent duckAnimation;
  late SpriteComponent jumpSprite;
  
  // 碰撞矩形
  late Rect dinoRect;
  
  // 音效系统 - 用于跳跃音效
  bool soundEnabled = true;

  // 动态地面Y坐标 - 支持自适应屏幕高度
  double dynamicGroundY = groundY;

  @override
  Future<void> onLoad() async {
    // 获取游戏引擎中的地面位置
    final gameHeight = (parent as dynamic).gameHeight ?? 600.0;
    dynamicGroundY = gameHeight * 0.63; // 与地面轨道保持一致
    
    // 设置恐龙位置和大小 - 统一使用bottomLeft锚点，Y坐标设为动态地面位置
    position = Vector2(xPos, dynamicGroundY); // 恐龙底部对齐地面
    size = gameRunSize; // 使用预定义的游戏跑步尺寸
    anchor = Anchor.bottomLeft;
    
    // 加载恐龙精灵图 - 参考Python版本的图片加载
    await _loadDinoSprites();
    
    // 设置初始状态为跑步
    _setRunningState();
    
    // 初始化碰撞矩形
    _updateCollisionRect();
  }

  /// 加载恐龙精灵图 - 参考Python版本的图片定义
  Future<void> _loadDinoSprites() async {
    // 跑步动画 - 参考Python版本的RUNNING数组
    final runSprites = [
      await Sprite.load('dino-jump.DinoRun1.png'),
      await Sprite.load('dino-jump.DinoRun2.png'),
    ];
    
    runAnimation = SpriteAnimationComponent(
      animation: SpriteAnimation.spriteList(runSprites, stepTime: 0.1),
      size: size,
    );
    
    // 蹲下动画 - 参考Python版本的DUCKING数组
    final duckSprites = [
      await Sprite.load('dino-jump.DinoDuck1.png'),
      await Sprite.load('dino-jump.DinoDuck2.png'),
    ];
    
    duckAnimation = SpriteAnimationComponent(
      animation: SpriteAnimation.spriteList(duckSprites, stepTime: 0.1),
      size: gameDuckSize, // 使用预定义的游戏蹲下尺寸
    );
    
    // 跳跃精灵 - 参考Python版本的JUMPING
    jumpSprite = SpriteComponent(
      sprite: await Sprite.load('dino-jump.DinoJump.png'),
      size: size,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // 更新恐龙状态 - 参考Python版本的update方法
    _updateDinoState(dt);
    
    // 更新碰撞矩形
    _updateCollisionRect();
    
    // 更新步进索引 - 参考Python版本的step_index逻辑
    stepIndex += 1;
    if (stepIndex >= 10) {
      stepIndex = 0;
    }
  }

  /// 更新恐龙状态 - 参考Python版本的update方法逻辑
  void _updateDinoState(double dt) {
    if (dinoDuck) {
      _duck();
    } else if (dinoRun) {
      _run();
    } else if (dinoJump) {
      _jump(dt);
    }
  }

  /// 恐龙蹲下 - 使用正确的坐标和尺寸计算
  void _duck() {
    removeAll(children);
    add(duckAnimation);
    position.y = dynamicGroundY; // 底部对齐动态地面
    size = gameDuckSize; // 使用预定义的游戏蹲下尺寸
  }

  /// 恐龙跑步 - 使用正确的坐标和尺寸计算
  void _run() {
    removeAll(children);
    add(runAnimation);
    position.y = dynamicGroundY; // 底部对齐动态地面
    size = gameRunSize; // 使用预定义的游戏跑步尺寸
  }

  /// 恐龙跳跃 - 使用优化后的物理参数
  void _jump(double dt) {
    removeAll(children);
    add(jumpSprite);
    
    if (dinoJump) {
      // 使用优化后的跳跃物理参数：每帧更新位置和速度
      position.y -= jumpVelocity * dt * 60; // 位置更新：速度*时间
      jumpVelocity -= gravity * dt;         // 速度更新：重力加速度*时间
      
      // 检查是否着陆 - 当速度反向且达到初始跳跃速度的负值时着陆
      if (jumpVelocity < -jumpVel) {
        dinoJump = false;
        dinoRun = true;
        dinoDuck = false;
        jumpVelocity = jumpVel;
        position.y = dynamicGroundY; // 着陆时底部对齐动态地面
      }
    }
  }

  /// 开始跳跃 - 参考Python版本的跳跃触发逻辑，添加音效支持
  void jump() {
    if (!dinoJump) {
      dinoDuck = false;
      dinoRun = false;
      dinoJump = true;
      jumpVelocity = jumpVel;
      
    }
  }
  
  /// 设置音效开关
  void setSoundEnabled(bool enabled) {
    soundEnabled = enabled;
  }

  /// 开始蹲下 - 参考Python版本的蹲下触发逻辑
  void duck() {
    if (!dinoJump) {
      dinoDuck = true;
      dinoRun = false;
      dinoJump = false;
    }
  }

  /// 停止蹲下 - 恢复跑步状态
  void stopDucking() {
    if (!dinoJump) {
      dinoDuck = false;
      dinoRun = true;
      dinoJump = false;
    }
  }

  /// 设置跑步状态
  void _setRunningState() {
    dinoDuck = false;
    dinoRun = true;
    dinoJump = false;
    jumpVelocity = jumpVel;
    position.y = dynamicGroundY; // 底部对齐动态地面
  }

  /// 更新碰撞矩形 - 优化碰撞体验，让边界比图片稍小
  void _updateCollisionRect() {
    // 碰撞矩形收缩参数 - 让碰撞检测更宽松，提升游戏体验
    const double shrinkX = 8.0; // 左右各收缩8像素
    const double shrinkY = 6.0; // 上下各收缩6像素
    
    dinoRect = Rect.fromLTWH(
      position.x + shrinkX/2, // X坐标向右偏移收缩量的一半
      position.y - size.y + shrinkY/2, // Y坐标向下偏移收缩量的一半
      size.x - shrinkX, // 宽度减少收缩量
      size.y - shrinkY, // 高度减少收缩量
    );
  }

  /// 检查与障碍物的碰撞 - 参考Python版本的colliderect方法
  bool checkCollision(Obstacle obstacle) {
    final obstacleRect = obstacle.getCollisionRect();
    // 添加调试信息
    // print('Dino rect: ${dinoRect}, Obstacle rect: ${obstacleRect}');
    return dinoRect.overlaps(obstacleRect);
  }

  /// 重置恐龙状态 - 游戏重新开始时调用
  void reset() {
    _setRunningState();
    stepIndex = 0;
    _updateCollisionRect();
  }

  /// 获取碰撞矩形
  Rect getCollisionRect() {
    return dinoRect;
  }

  /// 更新地面位置 - 当屏幕尺寸改变时调用
  void updateGroundPosition(double newGroundY) {
    dynamicGroundY = newGroundY;
    
    // 更新恐龙位置以匹配新的地面位置
    if (!dinoJump) {
      // 只有在不跳跃时才调整位置
      position = Vector2(xPos, dynamicGroundY);
    }
  }
}
