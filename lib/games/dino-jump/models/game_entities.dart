import 'package:flutter/material.dart';

// 游戏状态枚举
enum DinoGameState {
  ready,     // 准备开始
  playing,   // 游戏中
  gameOver,  // 游戏结束
  gameOverWithDialog,  // 游戏结束显示对话框状态
}

// 障碍物类型
enum ObstacleType {
  cactus,    // 仙人掌
  bird,      // 飞鸟
}

// 障碍物模型
class Obstacle {
  double x;                    // X坐标
  double y;                    // Y坐标
  double width;                // 宽度
  double height;               // 高度
  ObstacleType type;           // 类型
  bool passed;                 // 是否已通过（用于计分）

  Obstacle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.type,
    this.passed = false,
  });

  // 获取碰撞矩形
  Rect get rect => Rect.fromLTWH(x, y, width, height);
}

// 云朵装饰
class Cloud {
  double x;
  double y;
  double speed;

  Cloud({
    required this.x,
    required this.y,
    required this.speed,
  });
}

// 障碍物模式枚举 - 用于智能生成系统
enum ObstaclePattern {
  singleCactus,     // 单个仙人掌
  singleBird,       // 单个飞鸟
  jumpThenDuck,     // 跳跃然后下蹲组合
  duckThenJump,     // 下蹲然后跳跃组合  
  rhythmBreaker,    // 节奏破坏者
  stressTest,       // 压力测试
}

// 模式权重类 - 用于智能生成系统的加权选择
class PatternWeight {
  final ObstaclePattern pattern;
  final double weight;
  
  PatternWeight(this.pattern, this.weight);
}
