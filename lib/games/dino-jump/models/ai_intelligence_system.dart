import 'dart:math' as math;
import 'game_entities.dart';

/// AI智能系统
/// 负责玩家行为分析、智能障碍物生成、自适应难度调节
class AIIntelligenceSystem {
  // 智能障碍物生成系统状态
  int _consecutiveCactusCount = 0;    // 连续仙人掌计数
  int _consecutiveBirdCount = 0;      // 连续飞鸟计数
  bool _isInComboChain = false;       // 是否在组合链中
  int _comboChainLength = 0;          // 组合链长度
  double _playerStressLevel = 0.0;    // 玩家压力等级(0.0-1.0)
  int _recentMissCount = 0;           // 最近的险过计数
  final List<double> _recentJumpTimings = []; // 最近的跳跃时机记录
  
  final math.Random _random = math.Random();
  
  /// 重置AI智能系统
  void reset() {
    _consecutiveCactusCount = 0;
    _consecutiveBirdCount = 0;
    _isInComboChain = false;
    _comboChainLength = 0;
    _playerStressLevel = 0.0;
    _recentMissCount = 0;
    _recentJumpTimings.clear();
  }
  
  /// 智能障碍物间距计算
  /// 根据玩家状态和游戏阶段动态调整间距
  double calculateSmartObstacleDistance(int score, double baseDistance) {
    double adjustedDistance = baseDistance;
    
    // 根据玩家压力等级调整间距
    if (_playerStressLevel > 0.7) {
      // 高压力时增加间距，给玩家喘息机会
      adjustedDistance *= (1.0 + _playerStressLevel * 0.5);
    } else if (_playerStressLevel < 0.3) {
      // 低压力时减少间距，增加挑战
      adjustedDistance *= (1.0 - (0.3 - _playerStressLevel) * 0.3);
    }
    
    // 根据连续障碍物类型调整
    if (_consecutiveCactusCount >= 3) {
      // 连续仙人掌过多，增加间距或引入飞鸟
      adjustedDistance *= 1.2;
    }
    
    if (_consecutiveBirdCount >= 2) {
      // 连续飞鸟过多，增加间距
      adjustedDistance *= 1.3;
    }
    
    // 组合链中保持紧密间距
    if (_isInComboChain) {
      adjustedDistance *= 0.8;
    }
    
    return adjustedDistance;
  }
  
  /// 智能模式选择系统
  /// 根据玩家状态和游戏进度选择最合适的障碍物模式
  List<PatternWeight> calculatePatternWeights(int score) {
    List<PatternWeight> weights = [];
    
    // 计算玩家跳跃质量评分
    double jumpQualityScore = getJumpQualityScore();
    
    // 基础权重
    double cactusWeight = 1.0;
    double birdWeight = 0.0; // 初始时飞鸟概率为0
    
    // 根据分数阶段调整飞鸟出现概率
    if (score >= 50) {
      birdWeight = 0.2; // 50分后开始出现飞鸟
    }
    if (score >= 200) {
      birdWeight = 0.4; // 200分后增加飞鸟概率
    }
    if (score >= 400) {
      birdWeight = 0.6; // 400分后进一步增加
    }
    if (score >= 1000) {
      birdWeight = 0.8; // 1000分后高概率飞鸟
    }
    
    // 根据连续计数调整权重（避免单调）
    if (_consecutiveCactusCount >= 3) {
      cactusWeight *= 0.5; // 减少仙人掌概率
      birdWeight *= 1.5;   // 增加飞鸟概率
    }
    
    if (_consecutiveBirdCount >= 2) {
      birdWeight *= 0.3;   // 减少飞鸟概率
      cactusWeight *= 1.2; // 增加仙人掌概率
    }
    
    // 根据玩家压力等级和表现调整
    if (_playerStressLevel > 0.6) {
      // 高压力时降低难度
      birdWeight *= 0.7;
      cactusWeight *= 1.1;
    } else if (_playerStressLevel < 0.2 && jumpQualityScore > 0.8) {
      // 低压力且表现优秀时增加挑战
      birdWeight *= 1.3;
    }
    
    // 添加基础模式
    weights.add(PatternWeight(ObstaclePattern.singleCactus, cactusWeight));
    weights.add(PatternWeight(ObstaclePattern.singleBird, birdWeight));
    
    // 高级组合模式（更高分数才解锁）
    if (score >= 300) {
      double comboWeight = 0.3;
      if (_playerStressLevel < 0.5 && jumpQualityScore > 0.7) {
        comboWeight = 0.6; // 表现好时增加组合挑战
      }
      
      weights.add(PatternWeight(ObstaclePattern.jumpThenDuck, comboWeight));
      weights.add(PatternWeight(ObstaclePattern.duckThenJump, comboWeight));
    }
    
    // 节奏破坏者（高分才有）
    if (score >= 500) {
      double rhythmWeight = 0.2;
      if (_recentMissCount < 2) {
        rhythmWeight = 0.4; // 表现稳定时增加节奏破坏
      }
      weights.add(PatternWeight(ObstaclePattern.rhythmBreaker, rhythmWeight));
    }
    
    // 压力测试（极高分且表现优秀时）
    if (score >= 800 && jumpQualityScore > 0.8 && _playerStressLevel < 0.4) {
      weights.add(PatternWeight(ObstaclePattern.stressTest, 0.3));
    }
    
    return weights;
  }
  
  /// 加权随机选择障碍物模式
  ObstaclePattern selectObstaclePattern(List<PatternWeight> weights) {
    if (weights.isEmpty) {
      return ObstaclePattern.singleCactus; // 默认返回仙人掌
    }
    
    // 计算总权重
    double totalWeight = weights.fold(0.0, (sum, item) => sum + item.weight);
    
    if (totalWeight <= 0) {
      return ObstaclePattern.singleCactus; // 权重为0时返回默认
    }
    
    // 随机选择
    double randomValue = _random.nextDouble() * totalWeight;
    double currentWeight = 0.0;
    
    for (PatternWeight weight in weights) {
      currentWeight += weight.weight;
      if (randomValue <= currentWeight) {
        return weight.pattern;
      }
    }
    
    return weights.last.pattern; // 备选返回最后一个
  }
  
  /// 更新障碍物生成状态
  void updateObstacleGenerationState(ObstaclePattern pattern) {
    // 更新连续计数
    if (pattern == ObstaclePattern.singleCactus) {
      _consecutiveCactusCount++;
      _consecutiveBirdCount = 0;
    } else if (pattern == ObstaclePattern.singleBird) {
      _consecutiveBirdCount++;
      _consecutiveCactusCount = 0;
    } else {
      // 组合模式重置连续计数
      _consecutiveCactusCount = 0;
      _consecutiveBirdCount = 0;
    }
    
    // 限制连续计数上限
    if (_consecutiveCactusCount > 5) _consecutiveCactusCount = 5;
    if (_consecutiveBirdCount > 3) _consecutiveBirdCount = 3;
    
    // 组合链状态管理
    if (!_isInComboChain && (pattern == ObstaclePattern.jumpThenDuck || 
                             pattern == ObstaclePattern.duckThenJump ||
                             pattern == ObstaclePattern.stressTest)) {
      _isInComboChain = true;
    }
    
    // 组合链长度递减
    if (_isInComboChain) {
      _comboChainLength--;
      if (_comboChainLength <= 0) {
        _isInComboChain = false;
        _comboChainLength = 0;
      }
    }
  }
  
  /// 记录跳跃时机（智能系统用于分析玩家行为）
  void recordJumpTiming(List<Obstacle> obstacles, double dinoX, double gameSpeed) {
    // 寻找距离恐龙最近的障碍物
    Obstacle? nearestObstacle;
    double minDistance = double.infinity;
    
    for (Obstacle obstacle in obstacles) {
      // 只考虑前方的障碍物
      if (obstacle.x > dinoX) {
        double distance = obstacle.x - dinoX;
        if (distance < minDistance) {
          minDistance = distance;
          nearestObstacle = obstacle;
        }
      }
    }
    
    if (nearestObstacle != null) {
      // 记录跳跃时机 - 距离障碍物的相对位置
      double jumpTiming = minDistance / gameSpeed; // 转换为时间（秒）
      _recentJumpTimings.add(jumpTiming);
      
      // 只保留最近10次跳跃记录
      if (_recentJumpTimings.length > 10) {
        _recentJumpTimings.removeAt(0);
      }
      
      // 分析跳跃质量并更新玩家压力等级
      _analyzeJumpQuality(jumpTiming, nearestObstacle);
    }
  }
  
  /// 分析跳跃质量和玩家压力等级
  void _analyzeJumpQuality(double jumpTiming, Obstacle obstacle) {
    // 定义理想跳跃时机区间（根据障碍物类型）
    double idealTiming;
    double toleranceRange;
    
    if (obstacle.type == ObstacleType.cactus) {
      // 仙人掌：需要更早跳跃
      idealTiming = 0.8; // 理想提前0.8秒跳跃
      toleranceRange = 0.3; // 容忍±0.3秒
    } else {
      // 飞鸟：跳跃时机更灵活
      idealTiming = 0.6; // 理想提前0.6秒跳跃
      toleranceRange = 0.4; // 容忍±0.4秒
    }
    
    // 计算跳跃质量
    double timingError = (jumpTiming - idealTiming).abs();
    bool isNearMiss = timingError < toleranceRange * 1.5 && timingError > toleranceRange;
    bool isEarlyJump = jumpTiming > idealTiming + toleranceRange;
    
    // 更新险过次数
    if (isNearMiss) {
      _recentMissCount++;
      if (_recentMissCount > 10) _recentMissCount = 10; // 限制上限
    } else if (timingError < toleranceRange * 0.5) {
      // 完美跳跃，减少险过计数
      _recentMissCount = math.max(0, _recentMissCount - 1);
    }
    
    // 更新压力等级
    if (isNearMiss) {
      _playerStressLevel = math.min(1.0, _playerStressLevel + 0.15);
    }
    
    // 基于跳跃时机模式调整
    if (isEarlyJump && _recentMissCount > 2) {
      // 连续提前跳跃表示紧张
      _playerStressLevel = math.min(1.0, _playerStressLevel + 0.1);
    }
    
    // 自然衰减压力等级（时间会缓解压力）
    _playerStressLevel = math.max(0.0, _playerStressLevel - 0.02);
  }
  
  /// 获取玩家当前压力等级（0.0-1.0）
  double get playerStressLevel => _playerStressLevel;
  
  /// 获取最近险过次数
  int get recentNearMissCount => _recentMissCount;
  
  /// 获取玩家跳跃质量评分 (0.0-1.0)
  double getJumpQualityScore() {
    if (_recentJumpTimings.isEmpty) return 0.5;
    
    // 计算最近跳跃的平均质量
    double totalQuality = 0.0;
    for (double timing in _recentJumpTimings) {
      // 简化的质量评估：接近0.7秒的跳跃质量最高
      double error = (timing - 0.7).abs();
      double quality = math.max(0.0, 1.0 - error * 2.0);
      totalQuality += quality;
    }
    
    return totalQuality / _recentJumpTimings.length;
  }
  
  /// 获取险过次数
  int get nearMissCount => _recentMissCount;
  
  /// 计算平均跳跃质量（用于评估玩家技能水平）
  double get averageJumpQuality {
    if (_recentJumpTimings.isEmpty) return 0.0;
    return _recentJumpTimings.reduce((a, b) => a + b) / _recentJumpTimings.length;
  }
}
