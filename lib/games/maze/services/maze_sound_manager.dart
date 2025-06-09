import '../../common/sound_manager.dart';

/// 迷宫游戏专用声音管理器
/// 继承通用声音管理器，提供迷宫游戏特定的音效方法
class MazeSoundManager {
  static final MazeSoundManager _instance = MazeSoundManager._internal();
  factory MazeSoundManager() => _instance;
  MazeSoundManager._internal();

  // 使用通用声音管理器实例
  final CommonSoundManager _soundManager = CommonSoundManager();

  // 代理基础功能
  bool get soundEnabled => _soundManager.soundEnabled;
  bool get musicEnabled => _soundManager.musicEnabled;
  bool get isBackgroundMusicPlaying => _soundManager.isBackgroundMusicPlaying;

  void toggleSound() => _soundManager.toggleSound();
  void toggleMusic() => _soundManager.toggleMusic();

  /// 开始播放迷宫背景音乐
  Future<void> startBackgroundMusic() async {
    await _soundManager.startBackgroundMusic('sounds/background.wav', volume: 0.3);
  }

  Future<void> stopBackgroundMusic() async {
    await _soundManager.stopBackgroundMusic();
  }

  Future<void> pauseBackgroundMusic() async {
    await _soundManager.pauseBackgroundMusic();
  }

  Future<void> resumeBackgroundMusic() async {
    await _soundManager.resumeBackgroundMusic();
  }

  /// 播放移动音效
  Future<void> playMoveSound() async {
    await _soundManager.playEffect('sounds/move.flac');
  }

  /// 播放关卡胜利音效
  Future<void> playWinSound() async {
    await _soundManager.playEffectExclusive('sounds/win.flac');
  }

  /// 播放游戏完成音效
  Future<void> playCompleteSound() async {
    await _soundManager.playEffectExclusive('sounds/complete.wav');
  }

  void dispose() {
    _soundManager.dispose();
  }
}
