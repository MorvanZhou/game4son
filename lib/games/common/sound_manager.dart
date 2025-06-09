import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 🎵 简化音频管理器 - 全局唯一音频控制
/// 
/// 设计原则：
/// 1. 整个应用只有一个全局静音开关
/// 2. 每个游戏只需要提供音频文件路径配置
/// 3. 简单易用，避免复杂的状态管理
class SimpleSoundManager {
  static final SimpleSoundManager _instance = SimpleSoundManager._internal();
  factory SimpleSoundManager() => _instance;
  SimpleSoundManager._internal();

  // 音频播放器
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();
  bool _isEffectPlaying = false;
  
  // 全局音频开关 - 整个应用只有这一个控制
  bool _audioEnabled = true;
  
  // 当前背景音乐信息 - 用于静音恢复
  String? _currentBackgroundMusic;
  bool _isBackgroundPlaying = false;

  /// 全局音频开关状态
  bool get audioEnabled => _audioEnabled;

  /// 切换全局音频开关
  void toggleAudio() {
    _audioEnabled = !_audioEnabled;
    
    if (_audioEnabled) {
      // 开启音频：恢复背景音乐
      if (_currentBackgroundMusic != null) {
        _playBackgroundMusic(_currentBackgroundMusic!);
      }
    } else {
      // 关闭音频：停止所有声音
      _stopAllAudio();
    }
  }

  /// 播放背景音乐
  /// [musicPath] 音乐文件路径，如 'sounds/dina-bg-loop.wav'
  Future<void> playBackgroundMusic(String musicPath) async {
    _currentBackgroundMusic = musicPath;
    
    if (_audioEnabled) {
      await _playBackgroundMusic(musicPath);
    }
  }

  /// 内部播放背景音乐方法
  Future<void> _playBackgroundMusic(String musicPath) async {
    try {
      // 如果已经在播放相同音乐，不重复播放
      if (_isBackgroundPlaying && _currentBackgroundMusic == musicPath) {
        return;
      }

      await _backgroundPlayer.stop();
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundPlayer.play(AssetSource(musicPath), volume: 0.3);
      _isBackgroundPlaying = true;
    } catch (e) {
      debugPrint('播放背景音乐错误: $e');
    }
  }

  /// 停止背景音乐
  Future<void> stopBackgroundMusic() async {
    try {
      await _backgroundPlayer.stop();
      _isBackgroundPlaying = false;
      _currentBackgroundMusic = null;
    } catch (e) {
      debugPrint('停止背景音乐错误: $e');
    }
  }

  /// 播放音效 - 带防抖控制
  /// [effectPath] 音效文件路径，如 'sounds/jump.wav'
  Future<void> playEffect(String effectPath) async {
    if (!_audioEnabled) return;

    // 防抖检查：如果音效正在播放，避免重复触发
    if (_isEffectPlaying) return;
    
    try {
      _isEffectPlaying = true; // 设置播放状态标志，防止重复触发
      await _effectPlayer.stop(); // 停止当前可能播放的音效
      await _effectPlayer.play(AssetSource(effectPath)); // 播放新音效
      
      // 设置防抖延时：播放后延迟200ms再允许下次播放
      // 这样可以避免快速连续点击导致的音效重叠
      Future.delayed(const Duration(milliseconds: 200), () {
        _isEffectPlaying = false; // 重置播放状态，允许下次音效播放
      });
      
    } catch (e) {
      debugPrint('播放音效错误: $e');
      _isEffectPlaying = false; // 异常时立即重置状态，确保不会卡住
    }
  }

  /// 停止所有音频
  void _stopAllAudio() {
    try {
      _backgroundPlayer.stop();
      _effectPlayer.stop();
      _isBackgroundPlaying = false;
    } catch (e) {
      debugPrint('停止音频错误: $e');
    }
  }

  /// 释放资源
  void dispose() {
    _backgroundPlayer.dispose();
    _effectPlayer.dispose();
  }
}
