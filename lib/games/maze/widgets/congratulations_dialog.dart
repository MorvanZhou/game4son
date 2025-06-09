import 'package:flutter/material.dart';
import 'dart:math' as math;

class CongratulationsDialog extends StatefulWidget {
  final int level;
  final bool isGameComplete;
  final VoidCallback onNextLevel;
  final VoidCallback onRestart;

  const CongratulationsDialog({
    super.key,
    required this.level,
    required this.isGameComplete,
    required this.onNextLevel,
    required this.onRestart,
  });

  @override
  State<CongratulationsDialog> createState() => _CongratulationsDialogState();
}

class _CongratulationsDialogState extends State<CongratulationsDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
    _particleController.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isGameComplete
                      ? [
                          const Color(0xFF0A0A0A),
                          const Color(0xFF2A1A2A),
                          const Color(0xFF1A0A1A),
                        ]
                      : [
                          const Color(0xFF0A0A0A),
                          const Color(0xFF1A2A2A),
                          const Color(0xFF0A1A1A),
                        ],
                ),
                border: Border.all(
                  color: widget.isGameComplete 
                      ? const Color(0xFFFF0080)
                      : const Color(0xFF00FFFF),
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.isGameComplete
                        ? const Color(0xFFFF0080).withOpacity(0.5)
                        : const Color(0xFF00FFFF).withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.8),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isGameComplete) ...[
                    // Enhanced particle effects for game completion
                    AnimatedBuilder(
                      animation: _particleController,
                      builder: (context, child) {
                        return                        CustomPaint(
                          size: const Size(250, 120),
                          painter: ParticlePainter(_particleController.value),
                        );
                      },
                    ),
                  ],
                  // Enhanced rotating trophy/star with glow
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.isGameComplete
                              ? const Color(0xFFFF0080).withOpacity(0.8)
                              : const Color(0xFF00FFFF).withOpacity(0.8),
                          blurRadius: 25,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: ShaderMask(
                        shaderCallback: (bounds) => RadialGradient(
                          colors: widget.isGameComplete
                              ? [
                                  const Color(0xFFFFFFFF),
                                  const Color(0xFFFF0080),
                                  const Color(0xFFFFD700),
                                ]
                              : [
                                  const Color(0xFFFFFFFF),
                                  const Color(0xFF00FFFF),
                                  const Color(0xFFFFD700),
                                ],
                        ).createShader(bounds),
                        child: Icon(
                          widget.isGameComplete ? Icons.emoji_events : Icons.star,
                          size: widget.isGameComplete ? 90 : 70,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Enhanced title with cyberpunk styling
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: widget.isGameComplete
                          ? [
                              const Color(0xFF00FFFF),
                              const Color(0xFFFF0080),
                              const Color(0xFFFFD700),
                            ]
                          : [
                              const Color(0xFF00FFFF),
                              const Color(0xFF80FF80),
                              const Color(0xFFFFFFFF),
                            ],
                    ).createShader(bounds),
                    child: Text(
                      widget.isGameComplete ? '🎉 MISSION COMPLETE! 🎉' : '🌟 LEVEL CLEARED! 🌟',
                      style: TextStyle(
                        fontSize: widget.isGameComplete ? 28 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Enhanced subtitle with glow effect
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: widget.isGameComplete
                            ? const Color(0xFFFF0080).withOpacity(0.5)
                            : const Color(0xFF00FFFF).withOpacity(0.5),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: widget.isGameComplete
                              ? const Color(0xFFFF0080).withOpacity(0.3)
                              : const Color(0xFF00FFFF).withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.isGameComplete
                          ? 'You conquered all 15 levels!\nTrue Cyber Maze Master!'
                          : 'Level ${widget.level} Complete!',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (widget.isGameComplete) ...[
                    // Enhanced game complete button
                    _buildCyberButton(
                      text: 'RESTART MISSION',
                      onPressed: widget.onRestart,
                      isPrimary: true,
                      color: const Color(0xFFFF0080),
                    ),
                  ] else ...[
                    // Enhanced level complete button
                    _buildCyberButton(
                      text: 'NEXT LEVEL',
                      onPressed: widget.onNextLevel,
                      isPrimary: true,
                      color: const Color(0xFF00FFFF),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCyberButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: color.withOpacity(0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A0A0A).withOpacity(0.9),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
        ),
        child: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Colors.white,
              color,
            ],
          ).createShader(bounds),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double animation;
  final List<CyberParticle> particles;

  ParticlePainter(this.animation) : particles = _generateCyberParticles();

  static List<CyberParticle> _generateCyberParticles() {
    final random = math.Random();
    return List.generate(30, (index) {
      return CyberParticle(
        x: random.nextDouble() * 250,
        y: random.nextDouble() * 120,
        size: random.nextDouble() * 4 + 1,
        color: [
          const Color(0xFF00FFFF),
          const Color(0xFFFF0080),
          const Color(0xFFFFD700),
          const Color(0xFF80FF80),
        ][random.nextInt(4)],
        speed: random.nextDouble() * 3 + 1,
        phase: random.nextDouble() * 2 * math.pi,
        type: random.nextInt(3), // Different particle types
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final animatedY = particle.y + (animation * particle.speed * 60) % (size.height + 20);
      final animatedX = particle.x + math.sin(animation * 2 + particle.phase) * 10;
      final pulseFactor = 0.5 + 0.5 * math.sin(animation * 4 + particle.phase);
      
      final paint = Paint()
        ..color = particle.color.withOpacity(0.8 * pulseFactor)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * pulseFactor);

      switch (particle.type) {
        case 0: // Circle particles
          canvas.drawCircle(
            Offset(animatedX, animatedY),
            particle.size * pulseFactor,
            paint,
          );
          break;
        case 1: // Diamond particles
          final path = Path();
          final centerX = animatedX;
          final centerY = animatedY;
          final radius = particle.size * pulseFactor;
          
          path.moveTo(centerX, centerY - radius);
          path.lineTo(centerX + radius, centerY);
          path.lineTo(centerX, centerY + radius);
          path.lineTo(centerX - radius, centerY);
          path.close();
          
          canvas.drawPath(path, paint);
          break;
        case 2: // Star particles
          canvas.save();
          canvas.translate(animatedX, animatedY);
          canvas.rotate(animation * 2 + particle.phase);
          
          final starPath = Path();
          final outerRadius = particle.size * pulseFactor;
          final innerRadius = outerRadius * 0.5;
          
          for (int i = 0; i < 5; i++) {
            final outerAngle = (i * 2 * math.pi / 5) - math.pi / 2;
            final innerAngle = ((i + 0.5) * 2 * math.pi / 5) - math.pi / 2;
            
            if (i == 0) {
              starPath.moveTo(
                outerRadius * math.cos(outerAngle),
                outerRadius * math.sin(outerAngle),
              );
            } else {
              starPath.lineTo(
                outerRadius * math.cos(outerAngle),
                outerRadius * math.sin(outerAngle),
              );
            }
            
            starPath.lineTo(
              innerRadius * math.cos(innerAngle),
              innerRadius * math.sin(innerAngle),
            );
          }
          starPath.close();
          
          canvas.drawPath(starPath, paint);
          canvas.restore();
          break;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class CyberParticle {
  final double x, y, size, speed, phase;
  final Color color;
  final int type;

  CyberParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
    required this.phase,
    required this.type,
  });
}
