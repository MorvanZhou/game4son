/// 🎮 游戏音频配置
/// 定义每个游戏的音频文件路径，使用简化音频管理器
class GameAudioConfig {
  // 恐龙游戏音频配置
  static const String dinoBackgroundMusic = 'sounds/dina-bg-loop.wav';
  static const String dinoJumpSound = 'sounds/jump.wav';
  static const String dinoGameOverSound = 'sounds/life-lost-game-over.wav';
  
  // 迷宫游戏音频配置
  static const String mazeBackgroundMusic = 'sounds/maze-bg-loop.wav';
  static const String mazeMoveSound = 'sounds/move.flac';
  static const String mazeWinSound = 'sounds/win.flac';
  static const String mazeCompleteSound = 'sounds/complete.wav';
  
  // 通用音频配置
  static const String generalBackgroundMusic = 'sounds/background.wav';
}
