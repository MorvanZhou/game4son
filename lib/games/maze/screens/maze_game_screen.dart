import 'package:flutter/material.dart';
import '../models/maze_game_model.dart';
import '../widgets/maze_widget.dart';
import '../widgets/congratulations_dialog.dart';
import '../services/maze_sound_manager.dart';

class MazeGameScreen extends StatefulWidget {
  const MazeGameScreen({super.key});

  @override
  State<MazeGameScreen> createState() => _MazeGameScreenState();
}

class _MazeGameScreenState extends State<MazeGameScreen> with TickerProviderStateMixin {
  late GameModel gameModel;
  late MazeSoundManager soundManager;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerGlowAnimation;

  @override
  void initState() {
    super.initState();
    gameModel = GameModel();
    soundManager = MazeSoundManager();
    gameModel.addListener(_onGameModelChanged);
    
    // Start background music
    WidgetsBinding.instance.addPostFrameCallback((_) {
      soundManager.startBackgroundMusic();
    });
    
    // Header animation for subtle pulsing effects (reduced intensity)
    _headerAnimationController = AnimationController(
      duration: const Duration(seconds: 6), // Much slower animation
      vsync: this,
    )..repeat(reverse: true);
    
    _headerGlowAnimation = Tween<double>(
      begin: 0.7, // Smaller variation range
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    gameModel.removeListener(_onGameModelChanged);
    _headerAnimationController.dispose();
    soundManager.stopBackgroundMusic(); // Stop background music when disposing
    super.dispose();
  }

  void _onGameModelChanged() {
    
    // Play sound effects based on game state changes
    if (gameModel.gameState == GameState.levelComplete) {
      soundManager.playWinSound();
      // Also show the congratulations dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCongratulationsDialog();
      });
    } else if (gameModel.gameState == GameState.gameComplete) {
      soundManager.playCompleteSound();
      // Also show the congratulations dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCongratulationsDialog();
      });
    }
  }

  void _showCongratulationsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CongratulationsDialog(
        level: gameModel.currentLevel,
        isGameComplete: gameModel.gameState == GameState.gameComplete,
        onNextLevel: () {
          Navigator.of(context).pop();
          gameModel.nextLevel();
        },
        onRestart: () {
          Navigator.of(context).pop();
          gameModel.restartGame();
        },
      ),
    );
  }

  void _showPauseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0xFF00FFFF),
            width: 1,
          ),
        ),
        title: const ShaderMask(
          shaderCallback: _createNeonGradient,
          child: Text(
            '游戏暂停',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        content: const Text(
          '游戏已暂停，点击继续按钮恢复游戏。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          _buildCyberButton(
            text: '继续',
            onPressed: () {
              Navigator.of(context).pop();
              gameModel.resumeGame();
              // 音频在简化架构中自动管理，不需要手动恢复
            },
          ),
          _buildCyberButton(
            text: '重新开始',
            onPressed: () {
              Navigator.of(context).pop();
              gameModel.restartGame();
            },
          ),
        ],
      ),
    );
  }

  static Shader _createNeonGradient(Rect bounds) {
    return const LinearGradient(
      colors: [Color(0xFF00FFFF), Color(0xFFFF0080)],
    ).createShader(bounds);
  }

  Widget _buildCyberButton({required String text, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF00FFFF).withOpacity(0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FFFF).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFF2A2A2A).withOpacity(0.8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: ShaderMask(
          shaderCallback: _createNeonGradient,
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _headerAnimationController,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Color.lerp(
                    const Color(0xFF00FFFF),
                    const Color(0xFF0080FF),
                    _headerGlowAnimation.value,
                  )!,
                  Color.lerp(
                    const Color(0xFFFF0080),
                    const Color(0xFFFF4080),
                    _headerGlowAnimation.value,
                  )!,
                ],
              ).createShader(bounds),
              child: const Text(
                'CYBER MAZE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: 2,
                ),
              ),
            );
          },
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        flexibleSpace: AnimatedBuilder(
          animation: _headerAnimationController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1A1A),
                    Color.lerp(
                      const Color(0xFF2A2A2A),
                      const Color(0xFF3A2A3A),
                      _headerGlowAnimation.value * 0.5,
                    )!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.lerp(
                      const Color(0xFF00FFFF).withOpacity(0.3),
                      const Color(0xFFFF0080).withOpacity(0.5),
                      _headerGlowAnimation.value,
                    )!,
                    blurRadius: 10 + (5 * _headerGlowAnimation.value),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          _buildNeonButton(
            icon: soundManager.audioEnabled ? Icons.volume_up : Icons.volume_off,
            onPressed: () {
              setState(() {
                soundManager.toggleAudio();
              });
            },
          ),
          _buildNeonButton(
            icon: Icons.pause,
            onPressed: () {
              gameModel.pauseGame();
              // 音频在简化架构中自动管理，不需要手动暂停
              _showPauseDialog();
            },
          ),
          _buildNeonButton(
            icon: Icons.refresh,
            onPressed: () {
              gameModel.restartGame();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced game info header with animations
          AnimatedBuilder(
            animation: _headerAnimationController,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A1A1A),
                      Color.lerp(
                        const Color(0xFF2A2A2A),
                        const Color(0xFF2A3A2A),
                        _headerGlowAnimation.value * 0.3,
                      )!,
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Color.lerp(
                        const Color(0xFF00FFFF).withOpacity(0.3),
                        const Color(0xFFFF0080).withOpacity(0.5),
                        _headerGlowAnimation.value,
                      )!,
                      width: 1 + (_headerGlowAnimation.value * 0.5),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color.lerp(
                        const Color(0xFF00FFFF).withOpacity(0.1),
                        const Color(0xFFFF0080).withOpacity(0.2),
                        _headerGlowAnimation.value,
                      )!,
                      blurRadius: 10 + (5 * _headerGlowAnimation.value),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListenableBuilder(
                  listenable: gameModel,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoItem('LEVEL', '${gameModel.currentLevel}/${gameModel.totalLevels}'),
                        _buildInfoItem('SIZE', '${gameModel.mazeWidth}×${gameModel.mazeHeight}'),
                        Row(
                          children: [
                            Icon(
                              Icons.keyboard,
                              color: Color.lerp(
                                const Color(0xFF00FFFF),
                                const Color(0xFFFF0080),
                                _headerGlowAnimation.value,
                              ),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  Color.lerp(
                                    const Color(0xFF00FFFF),
                                    const Color(0xFF0080FF),
                                    _headerGlowAnimation.value,
                                  )!,
                                  Color.lerp(
                                    const Color(0xFFFF0080),
                                    const Color(0xFFFF4080),
                                    _headerGlowAnimation.value,
                                  )!,
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                '↑↓←→ / WASD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
          // Game area - now takes up much more space
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListenableBuilder(
                listenable: gameModel,
                builder: (context, child) {
                  return MazeWidget(
                    gameModel: gameModel,
                    onLevelComplete: () {}, // Empty callback - handled in _onGameModelChanged
                    onGameComplete: () {}, // Empty callback - handled in _onGameModelChanged
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF00FFFF),
            fontSize: 12,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 2),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00FFFF), Color(0xFFFFFFFF)],
          ).createShader(bounds),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNeonButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF00FFFF).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FFFF).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: const Color(0xFF00FFFF),
          size: 20,
        ),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A1A).withOpacity(0.8),
        ),
      ),
    );
  }
}