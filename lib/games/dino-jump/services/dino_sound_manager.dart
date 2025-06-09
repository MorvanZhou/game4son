import '../../common/sound_manager.dart';

/// 恐龙游戏专用声音管理器
/// 包装通用声音管理器，添加恐龙游戏特定的音效支持
class DinoSoundManager {
  static final DinoSoundManager _instance = DinoSoundManager._internal();
  factory DinoSoundManager() => _instance;
  DinoSoundManager._internal();

  // 内部使用通用声音管理器
  final CommonSoundManager _soundManager = CommonSoundManager();

  // 代理属性访问器
  bool get effectsEnabled => _soundManager.effectsEnabled;
  bool get musicEnabled => _soundManager.musicEnabled;

  // 代理方法
  void toggleEffects() => _soundManager.toggleEffects();
  void toggleMusic() => _soundManager.toggleMusic();
  
  /// 全局静音 - 停止所有音频
  void muteAll() => _soundManager.muteAll();
  
  /// 恢复所有音频
  void unmuteAll() => _soundManager.unmuteAll();

  /// 播放跳跃音效
  Future<void> playJumpSound() async {
    // 播放跳跃音效 - 使用非阻塞方式避免重复响应错误
    if (_soundManager.effectsEnabled) {
      _soundManager.playEffect('sounds/jump.wav');
    }
  }

  /// 播放得分音效
  Future<void> playScoreSound() async {
    // 播放得分音效 - 使用完成音效作为得分音效
    // await _soundManager.playEffectExclusive('sounds/complete.wav');
  }

  /// 播放游戏结束音效
  Future<void> playGameOverSound() async {
    // 播放游戏结束音效 - 使用非阻塞方式
    if (_soundManager.effectsEnabled) {
      _soundManager.playEffectExclusive('sounds/life-lost-game-over.wav');
    }
  }

  /// 开始游戏背景音乐
  Future<void> startGameMusic() async {
    // 开始播放恐龙游戏背景音乐 - 使用非阻塞方式
    if (_soundManager.musicEnabled) {
      _soundManager.startBackgroundMusic('sounds/dina-bg-loop.wav');
    }
  }

  /// 停止游戏背景音乐
  void stopGameMusic() {
    _soundManager.stopBackgroundMusic();
  }

  /// 暂停游戏背景音乐
  void pauseGameMusic() {
    _soundManager.pauseBackgroundMusic();
  }

  /// 恢复游戏背景音乐
  void resumeGameMusic() {
    _soundManager.resumeBackgroundMusic();
  }

  /// 释放资源
  void dispose() {
    stopGameMusic();
    _soundManager.dispose();
  }
}
