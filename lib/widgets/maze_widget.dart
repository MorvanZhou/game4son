import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/maze_generator.dart';
import '../models/game_model.dart';
import '../services/sound_manager.dart';

class MazeWidget extends StatefulWidget {
  final GameModel gameModel;
  final VoidCallback onLevelComplete;
  final VoidCallback onGameComplete;

  const MazeWidget({
    super.key,
    required this.gameModel,
    required this.onLevelComplete,
    required this.onGameComplete,
  });

  @override
  State<MazeWidget> createState() => _MazeWidgetState();
}

class _MazeWidgetState extends State<MazeWidget> with TickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  final SoundManager _soundManager = SoundManager();
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    widget.gameModel.addListener(_onGameStateChanged);
    
    // Animation controllers for subtle visual effects (reduced intensity)
    _animationController = AnimationController(
      duration: const Duration(seconds: 8), // Slower rotation
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4), // Much slower pulse
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.9, // Less variation in pulse
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Ensure the widget can receive focus and keyboard events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    widget.gameModel.removeListener(_onGameStateChanged);
    _focusNode.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onGameStateChanged() {
    // This listener is now only used for any additional widget-specific state handling
    // Dialog display is handled in GameScreen to avoid duplication
  }

  KeyEventResult _handleKeyPress(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      bool handled = false;
      bool moved = false;
      
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        moved = widget.gameModel.movePlayer(Direction.up);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        moved = widget.gameModel.movePlayer(Direction.down);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        moved = widget.gameModel.movePlayer(Direction.left);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        moved = widget.gameModel.movePlayer(Direction.right);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyW) {
        moved = widget.gameModel.movePlayer(Direction.up);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
        moved = widget.gameModel.movePlayer(Direction.down);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyA) {
        moved = widget.gameModel.movePlayer(Direction.left);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
        moved = widget.gameModel.movePlayer(Direction.right);
        handled = true;
      }
      
      // Play sound effect if movement was successful
      if (moved) {
        _soundManager.playMoveSound();
      }
      
      return handled ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyPress,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A0A0A),
                const Color(0xFF1A1A1A),
              ],
            ),
            border: Border.all(
              color: _focusNode.hasFocus 
                  ? const Color(0xFF00FFFF)
                  : const Color(0xFF00FFFF).withOpacity(0.3),
              width: _focusNode.hasFocus ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _focusNode.hasFocus 
                    ? const Color(0xFF00FFFF).withOpacity(0.5)
                    : Colors.black.withOpacity(0.3),
                blurRadius: _focusNode.hasFocus ? 20 : 8,
                offset: const Offset(0, 4),
              ),
              if (_focusNode.hasFocus)
                BoxShadow(
                  color: const Color(0xFF00FFFF).withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 1.0,            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: CyberMazePainter(
                    maze: widget.gameModel.maze,
                    player: widget.gameModel.player,
                    mazeWidth: widget.gameModel.mazeWidth,
                    mazeHeight: widget.gameModel.mazeHeight,
                    animationValue: _animationController.value,
                    pulseValue: _pulseAnimation.value,
                  ),
                );
              },
            ),
            ),
          ),
        ),
      ),
    );
  }
}

class CyberMazePainter extends CustomPainter {
  final List<List<Cell>> maze;
  final Player player;
  final int mazeWidth;
  final int mazeHeight;
  final double animationValue;
  final double pulseValue;

  CyberMazePainter({
    required this.maze,
    required this.player,
    required this.mazeWidth,
    required this.mazeHeight,
    required this.animationValue,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / mazeWidth;
    final cellHeight = size.height / mazeHeight;

    // Cyberpunk color palette with subtle animation (reduced intensity)
    final wallPaint = Paint()
      ..color = Color.lerp(
        const Color(0xFF00FFFF),
        const Color(0xFF0080FF),
        (animationValue * 0.3) % 1.0, // Much slower color change
      )!
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final wallGlowPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.3 + 0.1 * pulseValue) // Minimal glow variation
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, 2 + (1 * pulseValue)); // Reduced blur variation

    // Animated background with flowing energy patterns
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF0A0A0A),
          Color.lerp(
            const Color(0xFF1A1A1A),
            const Color(0xFF2A1A2A),
            (animationValue * 0.5) % 1.0,
          )!,
          const Color(0xFF0A0A0A),
        ],
        stops: [
          0.0,
          (animationValue * 0.8) % 1.0,
          1.0,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Enhanced player paint with subtle effects
    final playerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFFFFF),
          const Color(0xFF00FFFF), // Stable cyan color
          const Color(0xFF0080FF),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(
          player.x * cellWidth + cellWidth / 2,
          player.y * cellHeight + cellHeight / 2,
        ),
        radius: cellWidth * 0.35 * pulseValue,
      ));

    final playerGlowPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.6 + 0.2 * pulseValue) // Reduced glow variation
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + (4 * pulseValue)); // Reduced blur variation

    // Start/end positions with stable colors
    final startPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFFFFF),
          const Color(0xFF00FF00), // Stable green
          const Color(0xFF00FF00), // Stable green
          const Color(0xFF80FF80),
        ],
      ).createShader(Rect.fromLTWH(0, 0, cellWidth, cellHeight));

    final startGlowPaint = Paint()
      ..color = const Color(0xFF00FF00).withOpacity(0.4 + 0.2 * pulseValue) // Reduced glow variation
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + (2 * pulseValue)); // Reduced blur

    final endPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFFFFF),
          const Color(0xFFFF0080), // Stable magenta
          const Color(0xFFFF4040),
        ],
      ).createShader(Rect.fromLTWH(
        (mazeWidth - 1) * cellWidth,
        (mazeHeight - 1) * cellHeight,
        cellWidth,
        cellHeight,
      ));

    final endGlowPaint = Paint()
      ..color = const Color(0xFFFF0080).withOpacity(0.4 + 0.2 * pulseValue) // Reduced glow variation
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + (2 * pulseValue)); // Reduced blur

    // Draw animated maze background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Draw enhanced grid pattern with flowing energy
    final gridPaint = Paint()
      ..color = Color.lerp(
        const Color(0xFF00FFFF).withOpacity(0.05),
        const Color(0xFFFF0080).withOpacity(0.1),
        (animationValue * 0.8) % 1.0,
      )!
      ..strokeWidth = 0.5;

    for (int i = 0; i <= mazeWidth; i++) {
      canvas.drawLine(
        Offset(i * cellWidth, 0),
        Offset(i * cellWidth, size.height),
        gridPaint,
      );
    }
    for (int i = 0; i <= mazeHeight; i++) {
      canvas.drawLine(
        Offset(0, i * cellHeight),
        Offset(size.width, i * cellHeight),
        gridPaint,
      );
    }

    // Draw walls with glow effect
    for (int y = 0; y < mazeHeight; y++) {
      for (int x = 0; x < mazeWidth; x++) {
        final cell = maze[y][x];
        final left = x * cellWidth;
        final top = y * cellHeight;
        final right = left + cellWidth;
        final bottom = top + cellHeight;

        wallPaint.strokeCap = StrokeCap.round;
        wallGlowPaint.strokeCap = StrokeCap.round;
        
        if (cell.topWall) {
          // Draw glow first
          canvas.drawLine(
            Offset(left, top),
            Offset(right, top),
            wallGlowPaint,
          );
          // Draw main wall
          canvas.drawLine(
            Offset(left, top),
            Offset(right, top),
            wallPaint,
          );
        }
        if (cell.rightWall) {
          canvas.drawLine(
            Offset(right, top),
            Offset(right, bottom),
            wallGlowPaint,
          );
          canvas.drawLine(
            Offset(right, top),
            Offset(right, bottom),
            wallPaint,
          );
        }
        if (cell.bottomWall) {
          canvas.drawLine(
            Offset(left, bottom),
            Offset(right, bottom),
            wallGlowPaint,
          );
          canvas.drawLine(
            Offset(left, bottom),
            Offset(right, bottom),
            wallPaint,
          );
        }
        if (cell.leftWall) {
          canvas.drawLine(
            Offset(left, top),
            Offset(left, bottom),
            wallGlowPaint,
          );
          canvas.drawLine(
            Offset(left, top),
            Offset(left, bottom),
            wallPaint,
          );
        }
      }
    }

    // Draw start position with pulsing glow
    final startRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        6,
        6,
        cellWidth - 12,
        cellHeight - 12,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(startRect, startGlowPaint);
    canvas.drawRRect(startRect, startPaint);

    // Draw end position with pulsing glow
    final endRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        (mazeWidth - 1) * cellWidth + 6,
        (mazeHeight - 1) * cellHeight + 6,
        cellWidth - 12,
        cellHeight - 12,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(endRect, endGlowPaint);
    canvas.drawRRect(endRect, endPaint);

    // Draw player with subtle effects (reduced animation intensity)
    final playerX = player.x * cellWidth + cellWidth / 2;
    final playerY = player.y * cellHeight + cellHeight / 2;
    final playerRadius = (cellWidth.clamp(0, cellHeight) * 0.4).clamp(8.0, 20.0);

    // Player outer energy field (reduced intensity)
    canvas.drawCircle(
      Offset(playerX, playerY),
      playerRadius + 3 + (2 * pulseValue), // Reduced field size variation
      Paint()
        ..color = const Color(0xFF00FFFF).withOpacity(0.2 + 0.1 * pulseValue) // Stable color with minimal variation
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + (4 * pulseValue)), // Reduced blur variation
    );

    // Player glow ring
    canvas.drawCircle(
      Offset(playerX, playerY),
      playerRadius + 4,
      playerGlowPaint,
    );

    // Player body with gradient
    canvas.drawCircle(
      Offset(playerX, playerY),
      playerRadius,
      playerPaint,
    );

    // Player inner core with subtle pulse
    final corePaint = Paint()
      ..color = const Color(0xFFFFFFFF) // Stable white core
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(playerX, playerY),
      playerRadius * 0.3,
      corePaint,
    );

    // Static energy rings (no rotation)
    final ringPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.6 + 0.2 * pulseValue) // Subtle pulse
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Inner ring
    canvas.drawCircle(
      Offset(playerX, playerY),
      playerRadius * 0.7,
      ringPaint,
    );

    // Outer ring
    canvas.drawCircle(
      Offset(playerX, playerY),
      playerRadius * 1.1 + (0.1 * pulseValue), // Minimal size variation
      Paint()
        ..color = const Color(0xFF00FFFF).withOpacity(0.3 + 0.1 * pulseValue) // Subtle variation
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
