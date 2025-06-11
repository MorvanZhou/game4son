import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'obstacle.dart';

/// 恐龙玩家组件 - 完全参考Python版本的Dinosaur类
class DinoPlayer extends SpriteAnimationComponent {
  // 恐龙常量 - 参考Python版本的Dinosaur类常量
  static const double xPos = 80.0;        // X_POS = 80
  static const double yPos = 310.0;       // Y_POS = 310
  static const double yPosDuck = 340.0;   // Y_POS_DUCK = 340
  static const double jumpVel = 8.5;      // JUMP_VEL = 8.5
  
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

  @override
  Future<void> onLoad() async {
    // 设置恐龙位置和大小 - 统一使用bottomLeft锚点，Y坐标设为地面位置
    position = Vector2(xPos, 380.0); // 恐龙底部对齐地面Y=380
    size = Vector2(60, 68); // 根据图片调整大小
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
      size: Vector2(size.x, size.y * 0.6), // 蹲下时高度减少
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

  /// 恐龙蹲下 - 参考Python版本的duck方法
  void _duck() {
    removeAll(children);
    add(duckAnimation);
    position.y = 380.0; // 底部对齐地面
    size = Vector2(size.x, size.y * 0.6);
  }

  /// 恐龙跑步 - 参考Python版本的run方法
  void _run() {
    removeAll(children);
    add(runAnimation);
    position.y = 380.0; // 底部对齐地面
    size = Vector2(60, 68);
  }

  /// 恐龙跳跃 - 参考Python版本的jump方法
  void _jump(double dt) {
    removeAll(children);
    add(jumpSprite);
    
    if (dinoJump) {
      // 参考Python版本的跳跃物理: self.dino_rect.y -= self.jump_vel * 4
      position.y -= jumpVelocity * 4 * dt * 60; // 调整为适合Flame的帧率
      jumpVelocity -= 0.8 * dt * 60; // 重力效果
      
      // 检查是否着陆 - 参考Python版本的着陆逻辑
      if (jumpVelocity < -jumpVel) {
        dinoJump = false;
        dinoRun = true;
        dinoDuck = false;
        jumpVelocity = jumpVel;
        position.y = 380.0; // 着陆时底部对齐地面
      }
    }
  }

  /// 开始跳跃 - 参考Python版本的跳跃触发逻辑
  void jump() {
    if (!dinoJump) {
      dinoDuck = false;
      dinoRun = false;
      dinoJump = true;
      jumpVelocity = jumpVel;
    }
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
    position.y = 380.0; // 底部对齐地面
  }

  /// 更新碰撞矩形 - 参考Python版本的self.dino_rect
  void _updateCollisionRect() {
    dinoRect = Rect.fromLTWH(
      position.x,
      position.y - size.y, // 因为anchor是bottomLeft，所以要减去高度
      size.x,
      size.y,
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
}
