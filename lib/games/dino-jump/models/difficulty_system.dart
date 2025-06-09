import 'dart:math' as math;

/// 恐龙游戏难度系统
/// 负责管理游戏速度递进、阶段划分、难度调节等
class DifficultySystem {
  // 游戏参数
  double gameSpeed = 200;      // 当前游戏速度
  static const double baseSpeed = 200;      // 基础速度
  static const double maxSpeed = 600;       // 最大速度限制（提高上限以匹配原版）
  
  /// 重置难度系统
  void reset() {
    gameSpeed = baseSpeed;
  }
  
  /// 根据分数更新游戏速度
  /// 🚀 现代化速度递进：平滑增长 + 关键节点突破
  void updateSpeed(int score) {
    // 基于新得分系统的速度递进
    double stageSpeedMultiplier;
    
    if (score < 30) {
      // 新手引导(0-30分): 1.0x → 1.2x 速度倍数
      double progress = score / 30.0;
      stageSpeedMultiplier = 1.0 + progress * 0.2;
    } else if (score < 80) {
      // 入门熟悉(30-80分): 1.2x → 1.5x 速度倍数
      double progress = (score - 30) / 50.0;
      stageSpeedMultiplier = 1.2 + progress * 0.3;
    } else if (score < 150) {
      // 基础掌握(80-150分): 1.5x → 1.8x 速度倍数
      double progress = (score - 80) / 70.0;
      stageSpeedMultiplier = 1.5 + progress * 0.3;
    } else if (score < 250) {
      // 技能提升(150-250分): 1.8x → 2.2x 速度倍数
      double progress = (score - 150) / 100.0;
      stageSpeedMultiplier = 1.8 + progress * 0.4;
    } else if (score < 400) {
      // 高手进阶(250-400分): 2.2x → 2.6x 速度倍数
      double progress = (score - 250) / 150.0;
      stageSpeedMultiplier = 2.2 + progress * 0.4;
    } else if (score < 600) {
      // 专家级别(400-600分): 2.6x → 2.9x 速度倍数
      double progress = (score - 400) / 200.0;
      stageSpeedMultiplier = 2.6 + progress * 0.3;
    } else {
      // 大师以上(600分+): 2.9x → 3.0x 速度倍数
      double progress = math.min(1.0, (score - 600) / 400.0);
      stageSpeedMultiplier = 2.9 + progress * 0.1;
    }
    
    // 应用速度倍数，确保不超过最大速度
    gameSpeed = math.min(maxSpeed, baseSpeed * stageSpeedMultiplier);
    
    // 🎯 关键等级突破点的额外加速
    List<int> levelBreakpoints = [30, 80, 150, 250, 400, 600, 900, 1300];
    
    for (int point in levelBreakpoints) {
      if (score == point) {
        // 在等级突破点额外加速8%，制造明显的升级感
        gameSpeed = math.min(maxSpeed, gameSpeed * 1.08);
        break;
      }
    }
  }
  
  /// 获取当前游戏难度等级（用于UI显示）
  /// 🎮 现代游戏设计：快速递进，给玩家持续的成就感
  int getDifficultyLevel(int score) {
    if (score < 30) return 1;        // 新手引导：6个障碍物即升级
    if (score < 80) return 2;        // 入门熟悉：16个障碍物
    if (score < 150) return 3;       // 基础掌握：30个障碍物
    if (score < 250) return 4;       // 技能提升：50个障碍物
    if (score < 400) return 5;       // 高手进阶：80个障碍物
    if (score < 600) return 6;       // 专家级别：120个障碍物
    if (score < 900) return 7;       // 大师水准：180个障碍物
    if (score < 1300) return 8;      // 传奇玩家：260个障碍物
    if (score < 1800) return 9;      // 超凡境界：360个障碍物
    return 10;                       // 神话级别：无限挑战
  }
  
  /// 获取当前游戏阶段名称
  String getGameStageText(int score) {
    if (score < 30) return "新手引导";
    if (score < 80) return "入门熟悉";
    if (score < 150) return "基础掌握";
    if (score < 250) return "技能提升";
    if (score < 400) return "高手进阶";
    if (score < 600) return "专家级别";
    if (score < 900) return "大师水准";
    if (score < 1300) return "传奇玩家";
    if (score < 1800) return "超凡境界";
    return "神话级别";
  }
  
  /// 获取当前速度百分比（相对于最大速度）
  double get speedPercentage => (gameSpeed - baseSpeed) / (maxSpeed - baseSpeed);
  
  /// 计算当前阶段的障碍物间距
  /// 根据分数阶段调整障碍物间距，分数越高间距越小
  double calculateObstacleDistance(int score, math.Random random) {
    if (score < 30) {
      // 新手引导：超宽松间距，让新手有足够时间适应
      return 450 + random.nextDouble() * 200; // 450-650像素
    } else if (score < 80) {
      // 入门熟悉：开始收紧间距
      return 380 + random.nextDouble() * 160; // 380-540像素
    } else if (score < 150) {
      // 基础掌握：进一步收紧
      return 320 + random.nextDouble() * 140; // 320-460像素
    } else if (score < 250) {
      // 技能提升：开始有压迫感
      return 280 + random.nextDouble() * 120; // 280-400像素
    } else if (score < 400) {
      // 高手进阶：高密度挑战
      return 240 + random.nextDouble() * 100; // 240-340像素
    } else if (score < 600) {
      // 专家级别：极高密度
      return 200 + random.nextDouble() * 80;  // 200-280像素
    } else {
      // 大师以上：极限密度，完美操控
      return 160 + random.nextDouble() * 60;  // 160-220像素
    }
  }
  
  /// 获取障碍物密度百分比（相对于基础密度）
  double getObstacleDensityPercentage(int score, math.Random random) {
    double currentDistance = calculateObstacleDistance(score, random);
    double maxDistance = 500; // 最大间距（适应阶段）
    double minDistance = 80; // 最小间距（极限阶段）
    return 1.0 - ((currentDistance - minDistance) / (maxDistance - minDistance));
  }
}
