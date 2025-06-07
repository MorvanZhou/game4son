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

  // Add method to handle player movement with sound effect
  void _movePlayer(Direction direction) {
    bool moved = widget.gameModel.movePlayer(direction);
    if (moved) {
      _soundManager.playMoveSound();
    }
  }

  // Handle keyboard input for desktop platforms
  KeyEventResult _handleKeyPress(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      bool handled = false;
      
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _movePlayer(Direction.up);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _movePlayer(Direction.down);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _movePlayer(Direction.left);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _movePlayer(Direction.right);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyW) {
        _movePlayer(Direction.up);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
        _movePlayer(Direction.down);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyA) {
        _movePlayer(Direction.left);
        handled = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
        _movePlayer(Direction.right);
        handled = true;
      }
      
      return handled ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  // Handle swipe gestures for mobile devices with improved sensitivity
  double _totalDeltaX = 0.0;
  double _totalDeltaY = 0.0;
  bool _hasMovedInCurrentGesture = false;

  void _handlePanStart(DragStartDetails details) {
    // Reset gesture tracking
    _totalDeltaX = 0.0;
    _totalDeltaY = 0.0;
    _hasMovedInCurrentGesture = false;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    // Accumulate total movement for better gesture recognition
    _totalDeltaX += details.delta.dx;
    _totalDeltaY += details.delta.dy;
    
    // Increase threshold for better small screen experience and avoid accidental triggers
    const double threshold = 35.0;
    
    // Only trigger movement once per gesture to avoid rapid repeated movements
    if (!_hasMovedInCurrentGesture) {
      if (_totalDeltaX.abs() > _totalDeltaY.abs()) {
        // Horizontal movement
        if (_totalDeltaX > threshold) {
          _movePlayer(Direction.right);
          _hasMovedInCurrentGesture = true;
        } else if (_totalDeltaX < -threshold) {
          _movePlayer(Direction.left);
          _hasMovedInCurrentGesture = true;
        }
      } else {
        // Vertical movement
        if (_totalDeltaY > threshold) {
          _movePlayer(Direction.down);
          _hasMovedInCurrentGesture = true;
        } else if (_totalDeltaY < -threshold) {
          _movePlayer(Direction.up);
          _hasMovedInCurrentGesture = true;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main maze area with touch controls
        Expanded(
          child: Focus(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: _handleKeyPress,
            child: GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              onPanStart: _handlePanStart, // Add pan start handler
              onPanUpdate: _handlePanUpdate, // Add swipe gesture support with improved tracking
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
                    aspectRatio: 1.0,
                    child: AnimatedBuilder(
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
          ),
        ),
        // Virtual D-pad for mobile devices
        _buildVirtualControls(),
      ],
    );
  }

  // Build virtual directional controls for mobile platforms
  Widget _buildVirtualControls() {
    // Only show virtual controls on mobile platforms
    bool isMobile = Theme.of(context).platform == TargetPlatform.android || 
                   Theme.of(context).platform == TargetPlatform.iOS;
    
    if (!isMobile) {
      return const SizedBox.shrink(); // Hide on desktop
    }

    // Get screen size for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    // Adjust sizes based on screen size
    final controlAreaSize = isSmallScreen ? 180.0 : 200.0;
    final buttonSize = isSmallScreen ? 65.0 : 75.0;
    final buttonIconSize = isSmallScreen ? 28.0 : 32.0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Instructions for mobile users
          Text(
            'Swipe on maze or use buttons below',
            style: TextStyle(
              color: const Color(0xFF00FFFF).withOpacity(0.7),
              fontSize: isSmallScreen ? 11 : 12,
            ),
          ),
          const SizedBox(height: 8),
          // Virtual D-pad with improved layout
          Container(
            width: controlAreaSize,
            height: controlAreaSize,
            child: Stack(
              children: [
                // Center circle for visual guidance
                Positioned(
                  left: (controlAreaSize - 40) / 2,
                  top: (controlAreaSize - 40) / 2,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF00FFFF).withAlpha(60),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                // Up button
                Positioned(
                  top: 0,
                  left: (controlAreaSize - buttonSize) / 2,
                  child: _buildDirectionButton(
                    icon: Icons.keyboard_arrow_up,
                    direction: Direction.up,
                    size: buttonSize,
                    iconSize: buttonIconSize,
                  ),
                ),
                // Down button
                Positioned(
                  bottom: 0,
                  left: (controlAreaSize - buttonSize) / 2,
                  child: _buildDirectionButton(
                    icon: Icons.keyboard_arrow_down,
                    direction: Direction.down,
                    size: buttonSize,
                    iconSize: buttonIconSize,
                  ),
                ),
                // Left button
                Positioned(
                  left: 0,
                  top: (controlAreaSize - buttonSize) / 2,
                  child: _buildDirectionButton(
                    icon: Icons.keyboard_arrow_left,
                    direction: Direction.left,
                    size: buttonSize,
                    iconSize: buttonIconSize,
                  ),
                ),
                // Right button
                Positioned(
                  right: 0,
                  top: (controlAreaSize - buttonSize) / 2,
                  child: _buildDirectionButton(
                    icon: Icons.keyboard_arrow_right,
                    direction: Direction.right,
                    size: buttonSize,
                    iconSize: buttonIconSize,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build individual direction button with adjustable size for better mobile experience
  Widget _buildDirectionButton({
    required IconData icon,
    required Direction direction,
    double size = 60.0,
    double iconSize = 24.0,
  }) {
    return GestureDetector(
      onTap: () => _movePlayer(direction),
      // Add larger touch area for easier tapping
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2A2A2A),
              const Color(0xFF1A1A1A),
            ],
          ),
          border: Border.all(
            color: const Color(0xFF00FFFF).withAlpha(125),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FFFF).withAlpha(80),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: const Color(0xFF00FFFF),
          size: iconSize,
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
