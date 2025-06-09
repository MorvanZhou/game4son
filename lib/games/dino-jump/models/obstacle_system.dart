import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'game_entities.dart';

/// 障碍物系统
/// 负责障碍物的生成、更新、移除和碰撞检测
class ObstacleSystem {
  // 障碍物和装饰
  List<Obstacle> obstacles = [];
  List<Cloud> clouds = [];
  
  // 随机数生成器
  final math.Random _random = math.Random();
  
  // 生成障碍物的距离控制
  double _lastObstacleX = 0; // 记录最后一个障碍物的X坐标
  
  // 云朵生成计时器
  double _cloudTimer = 0;
  double _cloudInterval = 3.0; // 云朵生成间隔（秒）
  
  /// 重置障碍物系统
  void reset(double gameWidth) {
    obstacles.clear();
    clouds.clear();
    _cloudTimer = 0;
    _lastObstacleX = 0;
  }
  
  /// 更新障碍物位置，移除屏幕外的障碍物
  void updateObstacles(double deltaTime, double gameSpeed) {
    obstacles.removeWhere((obstacle) {
      obstacle.x -= gameSpeed * deltaTime;
      return obstacle.x + obstacle.width < 0; // 移除屏幕外的障碍物
    });
  }
  
  /// 更新云朵位置，移除屏幕外的云朵
  void updateClouds(double deltaTime) {
    clouds.removeWhere((cloud) {
      cloud.x -= cloud.speed * deltaTime;
      return cloud.x < -100; // 移除屏幕外的云朵
    });
  }
  
  /// 生成云朵装饰
  void generateClouds(double deltaTime, double gameWidth) {
    _cloudTimer += deltaTime;
    
    if (_cloudTimer >= _cloudInterval) {
      _cloudTimer = 0;
      
      clouds.add(Cloud(
        x: gameWidth + 100,
        y: 30 + _random.nextDouble() * 50, // 随机高度
        speed: 50 + _random.nextDouble() * 30, // 随机速度
      ));
      
      _cloudInterval = 2.0 + _random.nextDouble() * 4.0; // 2-6秒随机间隔
    }
  }
  
  /// 检查是否需要生成新的障碍物
  bool shouldGenerateObstacle(double gameWidth, double currentDistance) {
    if (obstacles.isEmpty) {
      // 没有障碍物时，立即生成第一个
      _lastObstacleX = gameWidth + 100; // 设置初始位置
      return true;
    } else {
      // 找到最右边（最新）的障碍物
      double rightmostX = obstacles.map((o) => o.x + o.width).reduce(math.max);
      
      // 如果最右边的障碍物离屏幕右边缘足够远，生成新的障碍物
      if (gameWidth - rightmostX >= currentDistance) {
        _lastObstacleX = gameWidth + 50; // 从屏幕右边缘稍微外面开始
        return true;
      }
    }
    return false;
  }
  
  /// 生成单个仙人掌
  void generateSingleCactus(double x, int score, double groundHeight) {
    // 根据分数阶段调整仙人掌大小
    double width, height;
    if (score < 200) {
      width = 12 + _random.nextDouble() * 8; // 12-20
      height = 30 + _random.nextDouble() * 15; // 30-45
    } else if (score < 600) {
      width = 15 + _random.nextDouble() * 10; // 15-25
      height = 35 + _random.nextDouble() * 20; // 35-55
    } else {
      width = 18 + _random.nextDouble() * 12; // 18-30
      height = 40 + _random.nextDouble() * 25; // 40-65
    }
    
    obstacles.add(Obstacle(
      x: x,
      y: groundHeight,
      width: width,
      height: height,
      type: ObstacleType.cactus,
    ));
  }
  
  /// 生成单个飞鸟
  void generateSingleBird(double x, int score, double groundHeight) {
    // 根据分数阶段调整飞鸟属性
    double width, height, y;
    if (score < 300) {
      // 低分阶段：相对固定的低空飞行
      width = 20 + _random.nextDouble() * 8; // 20-28
      height = 12 + _random.nextDouble() * 8; // 12-20
      y = groundHeight + 40 + _random.nextDouble() * 20; // 相对固定高度
    } else if (score < 700) {
      // 中分阶段：高度开始随机化
      width = 25 + _random.nextDouble() * 10; // 25-35
      height = 15 + _random.nextDouble() * 10; // 15-25
      y = groundHeight + 30 + _random.nextDouble() * 40; // 更大高度范围
    } else {
      // 高分阶段：完全随机化高度，挑战极限反应
      width = 30 + _random.nextDouble() * 15; // 30-45
      height = 18 + _random.nextDouble() * 12; // 18-30
      y = groundHeight + 20 + _random.nextDouble() * 80; // 极大高度范围
    }
    
    obstacles.add(Obstacle(
      x: x,
      y: y,
      width: width,
      height: height,
      type: ObstacleType.bird,
    ));
  }
  
  /// 生成跳跃+下蹲组合
  void generateJumpThenDuckCombo(double x, double groundHeight) {
    // 先是一个高空飞鸟（需要下蹲）
    obstacles.add(Obstacle(
      x: x,
      y: groundHeight + 25 + _random.nextDouble() * 15, // 低空飞行
      width: 25 + _random.nextDouble() * 10,
      height: 15 + _random.nextDouble() * 8,
      type: ObstacleType.bird,
    ));
    
    // 然后是一个仙人掌（需要跳跃）
    obstacles.add(Obstacle(
      x: x + 100 + _random.nextDouble() * 50, // 适当间距
      y: groundHeight,
      width: 15 + _random.nextDouble() * 10,
      height: 35 + _random.nextDouble() * 20,
      type: ObstacleType.cactus,
    ));
  }
  
  /// 生成下蹲+跳跃组合
  void generateDuckThenJumpCombo(double x, double groundHeight) {
    // 先是一个仙人掌（需要跳跃）
    obstacles.add(Obstacle(
      x: x,
      y: groundHeight,
      width: 15 + _random.nextDouble() * 10,
      height: 35 + _random.nextDouble() * 20,
      type: ObstacleType.cactus,
    ));
    
    // 然后是一个低空飞鸟（需要下蹲）
    obstacles.add(Obstacle(
      x: x + 120 + _random.nextDouble() * 60, // 稍大间距
      y: groundHeight + 25 + _random.nextDouble() * 15,
      width: 25 + _random.nextDouble() * 10,
      height: 15 + _random.nextDouble() * 8,
      type: ObstacleType.bird,
    ));
  }
  
  /// 生成节奏破坏者（超近距离或异常高度）
  void generateRhythmBreaker(double x, double groundHeight) {
    if (_random.nextBool()) {
      // 超近距离双仙人掌
      obstacles.add(Obstacle(
        x: x,
        y: groundHeight,
        width: 12 + _random.nextDouble() * 8,
        height: 30 + _random.nextDouble() * 15,
        type: ObstacleType.cactus,
      ));
      
      obstacles.add(Obstacle(
        x: x + 60 + _random.nextDouble() * 30, // 很近距离
        y: groundHeight,
        width: 12 + _random.nextDouble() * 8,
        height: 30 + _random.nextDouble() * 15,
        type: ObstacleType.cactus,
      ));
    } else {
      // 异常高度飞鸟（非常高或非常低）
      double extremeY;
      if (_random.nextBool()) {
        extremeY = groundHeight + 80 + _random.nextDouble() * 30; // 极高
      } else {
        extremeY = groundHeight + 15 + _random.nextDouble() * 10; // 极低
      }
      
      obstacles.add(Obstacle(
        x: x,
        y: extremeY,
        width: 20 + _random.nextDouble() * 15,
        height: 12 + _random.nextDouble() * 10,
        type: ObstacleType.bird,
      ));
    }
  }
  
  /// 生成压力测试（连续3个高难度障碍物）
  void generateStressTest(double x, double groundHeight) {
    double currentX = x;
    
    for (int i = 0; i < 3; i++) {
      if (_random.nextBool()) {
        // 仙人掌
        obstacles.add(Obstacle(
          x: currentX,
          y: groundHeight,
          width: 18 + _random.nextDouble() * 12,
          height: 40 + _random.nextDouble() * 25,
          type: ObstacleType.cactus,
        ));
      } else {
        // 飞鸟
        obstacles.add(Obstacle(
          x: currentX,
          y: groundHeight + 45 + _random.nextDouble() * 30,
          width: 22 + _random.nextDouble() * 8,
          height: 15 + _random.nextDouble() * 8,
          type: ObstacleType.bird,
        ));
      }
      
      currentX += 80 + _random.nextDouble() * 40; // 较紧密间距
    }
  }
  
  /// 检查碰撞
  /// 返回true表示发生碰撞
  bool checkCollision(Rect dinoRect) {
    for (Obstacle obstacle in obstacles) {
      // 障碍物的碰撞矩形（需要根据屏幕坐标系转换）
      Rect obstacleRect = Rect.fromLTWH(
        obstacle.x,
        obstacle.y, // 注意：这里需要调用方提供正确的屏幕坐标
        obstacle.width,
        obstacle.height,
      );
      
      if (dinoRect.overlaps(obstacleRect)) {
        return true; // 发生碰撞
      }
    }
    return false; // 没有碰撞
  }
  
  /// 更新得分 - 检查哪些障碍物被成功通过
  int updateScore(double dinoX) {
    int scoreIncrement = 0;
    
    for (Obstacle obstacle in obstacles) {
      if (!obstacle.passed && obstacle.x + obstacle.width < dinoX) {
        obstacle.passed = true;
        scoreIncrement += 1; // 每通过一个障碍物得1分
      }
    }
    
    return scoreIncrement;
  }
  
  /// 获取最后一个障碍物的X坐标（用于外部系统）
  double get lastObstacleX => _lastObstacleX;
  
  /// 设置最后一个障碍物的X坐标（用于外部系统）
  set lastObstacleX(double value) => _lastObstacleX = value;
}
