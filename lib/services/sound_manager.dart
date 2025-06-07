import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _soundEnabled = true;

  bool get soundEnabled => _soundEnabled;

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
  }

  Future<void> playMoveSound() async {
    if (!_soundEnabled) return;
    
    try {
      // Using a simple beep sound for movement
      // In a real app, you would add actual sound files to assets
      await _audioPlayer.play(AssetSource('sounds/move.flac'));
    } catch (e) {
      // Silently handle missing sound files for better user experience
      // print('Sound file not found: $e');
    }
  }

  Future<void> playWinSound() async {
    if (!_soundEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource('sounds/win.flac'));
    } catch (e) {
      // print('Sound file not found: $e');
    }
  }

  Future<void> playCompleteSound() async {
    if (!_soundEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource('sounds/complete.wav'));
    } catch (e) {
      // print('Sound file not found: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
