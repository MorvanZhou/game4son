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
  /// 实现非线性速度增长机制，提供明显的阶段性递进感
  void updateSpeed(int score) {
    // 分阶段的非线性速度增长
    double stageSpeedMultiplier;
    
    if (score < 50) {
      // 适应阶段(0-50分): 1.0x → 1.3x 速度倍数
      double progress = score / 50.0;
      stageSpeedMultiplier = 1.0 + progress * 0.3;
    } else if (score < 200) {
      // 入门阶段(50-200分): 1.3x → 1.7x 速度倍数
      double progress = (score - 50) / 150.0;
      stageSpeedMultiplier = 1.3 + progress * 0.4;
    } else if (score < 400) {
      // 基础阶段(200-400分): 1.7x → 2.2x 速度倍数
      double progress = (score - 200) / 200.0;
      stageSpeedMultiplier = 1.7 + progress * 0.5;
    } else if (score < 1000) {
      // 进阶阶段(400-1000分): 2.2x → 2.8x 速度倍数
      double progress = (score - 400) / 600.0;
      stageSpeedMultiplier = 2.2 + progress * 0.6;
    } else {
      // 极限阶段(1000分以上): 2.8x → 3.0x 速度倍数
      double progress = math.min(1.0, (score - 1000) / 1000.0);
      stageSpeedMultiplier = 2.8 + progress * 0.2;
    }
    
    // 应用速度倍数，确保不超过最大速度
    gameSpeed = math.min(maxSpeed, baseSpeed * stageSpeedMultiplier);
    
    // 关键分数节点的跳跃式加速，增加明显的递进感
    List<int> majorAccelerationPoints = [50, 200, 400, 1000, 1500];
    
    for (int point in majorAccelerationPoints) {
      if (score == point) {
        // 在关键节点额外加速10%，制造明显的递进感
        gameSpeed = math.min(maxSpeed, gameSpeed * 1.1);
        break;
      }
    }
  }
  
  /// 获取当前游戏难度等级（用于UI显示）
  int getDifficultyLevel(int score) {
    if (score < 50) return 1;       // 初始阶段早期
    if (score < 200) return 2;      // 初始阶段后期  
    if (score < 400) return 3;      // 基础阶段
    if (score < 1000) return 4;     // 进阶阶段
    return 5;                       // 极限阶段
  }
  
  /// 获取当前游戏阶段名称
  String getGameStageText(int score) {
    if (score < 50) return "适应阶段";
    if (score < 200) return "入门阶段";
    if (score < 400) return "基础阶段";
    if (score < 1000) return "进阶阶段";
    return "极限阶段";
  }
  
  /// 获取当前速度百分比（相对于最大速度）
  double get speedPercentage => (gameSpeed - baseSpeed) / (maxSpeed - baseSpeed);
  
  /// 计算当前阶段的障碍物间距
  /// 根据分数阶段调整障碍物间距，分数越高间距越小
  double calculateObstacleDistance(int score, math.Random random) {
    if (score < 50) {
      // 适应阶段：宽松间距，给新手足够反应时间
      return 400 + random.nextDouble() * 200; // 400-600像素
    } else if (score < 200) {
      // 入门阶段：开始收紧间距
      return 320 + random.nextDouble() * 160; // 320-480像素
    } else if (score < 400) {
      // 基础阶段：明显收紧，开始有压迫感
      return 280 + random.nextDouble() * 120; // 280-400像素
    } else if (score < 1000) {
      // 进阶阶段：高密度，考验反应速度
      return 240 + random.nextDouble() * 80;  // 240-320像素
    } else {
      // 极限阶段：极限密度，需要完美操控
      return 200 + random.nextDouble() * 60;  // 200-260像素
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
