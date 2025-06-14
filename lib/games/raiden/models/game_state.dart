/// 雷电游戏状态管理
/// 
/// 负责管理：
/// 1. 分数系统
/// 2. 生命值系统
/// 3. 游戏状态（进行中/结束）
/// 4. 难度等级
class RaidenGameState {
  // 游戏数据
  int _score = 0;
  int _lives = 3;
  bool _isGameOver = false;
  bool _isPlaying = true;
  
  // 统计数据
  int _enemiesDestroyed = 0;
  int _bulletsShot = 0;
  
  // 游戏设置
  double _difficultyMultiplier = 1.0;
  
  // Getters
  int get score => _score;
  int get lives => _lives;
  bool get isGameOver => _isGameOver;
  bool get isPlaying => _isPlaying && !_isGameOver;
  int get enemiesDestroyed => _enemiesDestroyed;
  int get bulletsShot => _bulletsShot;
  double get difficultyMultiplier => _difficultyMultiplier;
  
  /// 增加分数
  void addScore(int points) {
    if (!isPlaying) return;
    
    _score += (points * _difficultyMultiplier).round();
    _enemiesDestroyed++;
    
    // 每销毁10个敌机增加难度
    if (_enemiesDestroyed % 10 == 0) {
      _difficultyMultiplier += 0.1;
    }
  }
  
  /// 减少生命
  void loseLife() {
    if (!isPlaying) return;
    
    _lives--;
    if (_lives <= 0) {
      _isGameOver = true;
      _isPlaying = false;
    }
  }
  
  /// 增加生命（奖励道具）
  void gainLife() {
    if (!isPlaying) return;
    
    _lives++;
  }
  
  /// 记录射击
  void recordShot() {
    _bulletsShot++;
  }
  
  /// 设置游戏结束
  void setGameOver() {
    _isGameOver = true;
    _isPlaying = false;
  }
  
  /// 暂停游戏
  void pauseGame() {
    _isPlaying = false;
  }
  
  /// 恢复游戏
  void resumeGame() {
    if (!_isGameOver) {
      _isPlaying = true;
    }
  }
  
  /// 重置游戏状态
  void reset() {
    _score = 0;
    _lives = 3;
    _isGameOver = false;
    _isPlaying = true;
    _enemiesDestroyed = 0;
    _bulletsShot = 0;
    _difficultyMultiplier = 1.0;
  }
  
  /// 获取命中率
  double get accuracy {
    if (_bulletsShot == 0) return 0.0;
    return (_enemiesDestroyed / _bulletsShot).clamp(0.0, 1.0);
  }
  
  /// 获取等级（基于分数）
  int get level {
    return (_score / 100).floor() + 1;
  }
  
  /// 获取游戏结果文本
  String getGameResultText() {
    if (!_isGameOver) return '';
    
    if (_score >= 1000) {
      return '王牌飞行员！';
    } else if (_score >= 500) {
      return '优秀表现！';
    } else if (_score >= 200) {
      return '不错的成绩！';
    } else {
      return '继续努力！';
    }
  }
  
  /// 获取统计信息
  Map<String, dynamic> getStatistics() {
    return {
      'score': _score,
      'lives': _lives,
      'enemiesDestroyed': _enemiesDestroyed,
      'bulletsShot': _bulletsShot,
      'accuracy': (accuracy * 100).toStringAsFixed(1),
      'level': level,
      'difficultyMultiplier': _difficultyMultiplier.toStringAsFixed(1),
    };
  }
}
