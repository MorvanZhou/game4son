import '../../common/sound_manager.dart';
import '../../../games/common/game_audio_config.dart';

/// 🦕 恐龙游戏音频管理器 - 简化版
/// 只负责调用简化音频管理器，提供游戏特定的便捷方法
class DinoSoundManager {
  static final DinoSoundManager _instance = DinoSoundManager._internal();
  factory DinoSoundManager() => _instance;
  DinoSoundManager._internal();

  // 使用简化音频管理器
  final SimpleSoundManager _audioManager = SimpleSoundManager();

  /// 全局音频开关状态
  bool get audioEnabled => _audioManager.audioEnabled;

  /// 切换全局音频开关
  void toggleAudio() => _audioManager.toggleAudio();

  /// 开始游戏背景音乐
  Future<void> startGameMusic() async {
    await _audioManager.playBackgroundMusic(GameAudioConfig.dinoBackgroundMusic);
  }

  /// 停止游戏背景音乐
  Future<void> stopGameMusic() async {
    await _audioManager.stopBackgroundMusic();
  }

  /// 播放跳跃音效
  Future<void> playJumpSound() async {
    await _audioManager.playEffect(GameAudioConfig.dinoJumpSound);
  }

  /// 播放游戏结束音效
  Future<void> playGameOverSound() async {
    await _audioManager.playEffect(GameAudioConfig.dinoGameOverSound);
  }

  /// 释放资源
  void dispose() {
    // 不需要释放，由简化音频管理器统一管理
  }
}
