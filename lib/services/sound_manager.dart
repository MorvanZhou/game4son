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
      // Don't stop previous sounds for move - they should be short
      await _audioPlayer.play(AssetSource('sounds/move.flac'));
    } catch (e) {
      print('Error playing move sound: $e');
    }
  }

  Future<void> playWinSound() async {
    if (!_soundEnabled) {
      print('Sound disabled, not playing win sound');
      return;
    }
    
    try {
      print('Attempting to play win sound...');
      // Stop any currently playing sound first
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/win.flac'));
      print('Win sound playback started successfully');
    } catch (e) {
      print('Error playing win sound: $e');
    }
  }

  Future<void> playCompleteSound() async {
    if (!_soundEnabled) {
      print('Sound disabled, not playing complete sound');
      return;
    }
    
    try {
      print('Attempting to play complete sound...');
      // Stop any currently playing sound first
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/complete.wav'));
      print('Complete sound playback started successfully');
    } catch (e) {
      print('Error playing complete sound: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
