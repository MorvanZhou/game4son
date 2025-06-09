import 'package:audioplayers/audioplayers.dart';

/// 通用声音管理器 - 可供所有游戏使用
/// 支持背景音乐和音效的播放、暂停、停止等功能
class CommonSoundManager {
  static final CommonSoundManager _instance = CommonSoundManager._internal();
  factory CommonSoundManager() => _instance;
  CommonSoundManager._internal();

  // 背景音乐播放器 - 用于循环播放背景音乐
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  // 音效播放器 - 用于播放游戏音效
  final AudioPlayer _effectsPlayer = AudioPlayer();
  
  bool _soundEnabled = true;    // 音效开关
  bool _musicEnabled = true;    // 背景音乐开关 
  bool _isBackgroundMusicPlaying = false;  // 背景音乐播放状态
  String? _currentBackgroundMusic;         // 当前播放的背景音乐

  // 公共属性访问器
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get isBackgroundMusicPlaying => _isBackgroundMusicPlaying;

  /// 切换音效开关
  void toggleSound() {
    _soundEnabled = !_soundEnabled;
  }

  /// 切换背景音乐开关
  void toggleMusic() {
    _musicEnabled = !_musicEnabled;
    if (_musicEnabled) {
      // 如果有正在播放的背景音乐，恢复播放
      if (_currentBackgroundMusic != null) {
        startBackgroundMusic(_currentBackgroundMusic!);
      }
    } else {
      stopBackgroundMusic();
    }
  }

  /// 开始播放背景音乐
  /// [musicPath] 音乐文件路径，如 'sounds/background.wav'
  /// [volume] 音量，范围0.0-1.0，默认0.3
  Future<void> startBackgroundMusic(String musicPath, {double volume = 0.3}) async {
    if (!_musicEnabled) return;
    
    // 如果正在播放相同的音乐，则不重复播放
    if (_isBackgroundMusicPlaying && _currentBackgroundMusic == musicPath) return;
    
    try {
      // 先停止当前播放的音乐
      await _backgroundPlayer.stop();
      
      // 设置新的背景音乐
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundPlayer.setVolume(volume);
      await _backgroundPlayer.play(AssetSource(musicPath), volume: volume);
      
      _isBackgroundMusicPlaying = true;
      _currentBackgroundMusic = musicPath;
    } catch (e) {
      print('播放背景音乐时出错: $e');
      _isBackgroundMusicPlaying = false;
      _currentBackgroundMusic = null;
    }
  }

  /// 停止背景音乐
  Future<void> stopBackgroundMusic() async {
    try {
      await _backgroundPlayer.stop();
      _isBackgroundMusicPlaying = false;
      _currentBackgroundMusic = null;
    } catch (e) {
      print('停止背景音乐时出错: $e');
    }
  }

  /// 暂停背景音乐
  Future<void> pauseBackgroundMusic() async {
    try {
      await _backgroundPlayer.pause();
    } catch (e) {
      print('暂停背景音乐时出错: $e');
    }
  }

  /// 恢复播放背景音乐
  Future<void> resumeBackgroundMusic() async {
    if (!_musicEnabled) return;
    
    try {
      await _backgroundPlayer.resume();
    } catch (e) {
      print('恢复背景音乐时出错: $e');
    }
  }

  /// 播放音效
  /// [effectPath] 音效文件路径，如 'sounds/move.flac'
  /// [volume] 音量，范围0.0-1.0，默认1.0
  Future<void> playEffect(String effectPath, {double volume = 1.0}) async {
    if (!_soundEnabled) return;
    
    try {
      await _effectsPlayer.play(AssetSource(effectPath), volume: volume);
    } catch (e) {
      print('播放音效时出错: $e');
    }
  }

  /// 播放音效（停止当前音效后播放新音效）
  /// 用于播放重要音效，如胜利音效
  Future<void> playEffectExclusive(String effectPath, {double volume = 1.0}) async {
    if (!_soundEnabled) return;
    
    try {
      await _effectsPlayer.stop();
      await _effectsPlayer.play(AssetSource(effectPath), volume: volume);
    } catch (e) {
      print('播放独占音效时出错: $e');
    }
  }

  /// 设置背景音乐音量
  Future<void> setBackgroundVolume(double volume) async {
    try {
      await _backgroundPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      print('设置背景音乐音量时出错: $e');
    }
  }

  /// 释放资源
  void dispose() {
    _backgroundPlayer.dispose();
    _effectsPlayer.dispose();
  }
}
