import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  // Separate players for background music and sound effects
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  final AudioPlayer _effectsPlayer = AudioPlayer();
  
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _isBackgroundMusicPlaying = false;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get isBackgroundMusicPlaying => _isBackgroundMusicPlaying;


  void toggleMusic() {
    _musicEnabled = !_musicEnabled;
    _soundEnabled = !_soundEnabled;
    if (_musicEnabled) {
      startBackgroundMusic();
    } else {
      stopBackgroundMusic();
    }
  }

  Future<void> startBackgroundMusic() async {
    if (!_musicEnabled || _isBackgroundMusicPlaying) return;
    
    try {
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop); // Loop the music
      await _backgroundPlayer.setVolume(0.3); // Lower volume for background music
      await _backgroundPlayer.play(AssetSource('sounds/background.wav'), volume: 0.3);
      _isBackgroundMusicPlaying = true;
    } catch (e) {
      print('Error starting background music: $e');
      _isBackgroundMusicPlaying = false;
    }
  }

  Future<void> stopBackgroundMusic() async {
    try {
      await _backgroundPlayer.stop();
      _isBackgroundMusicPlaying = false;
    } catch (e) {
      print('Error stopping background music: $e');
    }
  }

  Future<void> pauseBackgroundMusic() async {
    try {
      await _backgroundPlayer.pause();
      print('Background music paused');
    } catch (e) {
      print('Error pausing background music: $e');
    }
  }

  Future<void> resumeBackgroundMusic() async {
    if (!_musicEnabled) return;
    
    try {
      await _backgroundPlayer.resume();
      print('Background music resumed');
    } catch (e) {
      print('Error resuming background music: $e');
    }
  }

  Future<void> playMoveSound() async {
    if (!_soundEnabled) return;
    
    try {
      // Use effects player for sound effects
      await _effectsPlayer.play(AssetSource('sounds/move.flac'));
    } catch (e) {
      print('Error playing move sound: $e');
    }
  }

  Future<void> playWinSound() async {
    if (!_soundEnabled) {
      return;
    }
    
    try {
      // Stop any currently playing effect first
      await _effectsPlayer.stop();
      await _effectsPlayer.play(AssetSource('sounds/win.flac'));
    } catch (e) {
      print('Error playing win sound: $e');
    }
  }

  Future<void> playCompleteSound() async {
    if (!_soundEnabled) {
      return;
    }
    
    try {
      // Stop any currently playing effect first
      await _effectsPlayer.stop();
      await _effectsPlayer.play(AssetSource('sounds/complete.wav'));
    } catch (e) {
      print('Error playing complete sound: $e');
    }
  }

  void dispose() {
    _backgroundPlayer.dispose();
    _effectsPlayer.dispose();
  }
}
