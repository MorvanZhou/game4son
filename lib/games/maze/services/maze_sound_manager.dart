import '../../common/sound_manager.dart';
import '../../../games/common/game_audio_config.dart';

/// 🌟 迷宫游戏音频管理器 - 简化版
/// 只负责调用简化音频管理器，提供游戏特定的便捷方法
class MazeSoundManager {
  static final MazeSoundManager _instance = MazeSoundManager._internal();
  factory MazeSoundManager() => _instance;
  MazeSoundManager._internal();

  // 使用简化音频管理器
  final SimpleSoundManager _audioManager = SimpleSoundManager();

  /// 全局音频开关状态
  bool get audioEnabled => _audioManager.audioEnabled;

  /// 切换全局音频开关
  void toggleAudio() => _audioManager.toggleAudio();

  /// 开始迷宫背景音乐
  Future<void> startBackgroundMusic() async {
    await _audioManager.playBackgroundMusic(GameAudioConfig.mazeBackgroundMusic);
  }

  /// 停止背景音乐
  Future<void> stopBackgroundMusic() async {
    await _audioManager.stopBackgroundMusic();
  }

  /// 播放移动音效
  Future<void> playMoveSound() async {
    await _audioManager.playEffect(GameAudioConfig.mazeMoveSound);
  }

  /// 播放关卡胜利音效
  Future<void> playWinSound() async {
    await _audioManager.playEffect(GameAudioConfig.mazeWinSound);
  }

  /// 播放游戏完成音效
  Future<void> playCompleteSound() async {
    await _audioManager.playEffect(GameAudioConfig.mazeCompleteSound);
  }

  /// 释放资源
  void dispose() {
    // 不需要释放，由简化音频管理器统一管理
  }
}
