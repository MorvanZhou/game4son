import 'package:flutter/material.dart';
import '../models/go_game_model.dart';

/// 围棋游戏界面组件
/// 
/// 功能特性：
/// 1. 响应式棋盘绘制，支持不同屏幕尺寸
/// 2. 触摸交互，支持点击下棋
/// 3. 棋子动画效果
/// 4. 最后一步高亮显示
/// 5. 19x19标准围棋棋盘
class GoGameWidget extends StatefulWidget {
  final GoGameModel gameModel;
  final int? hoverRow;      // 外部传入的悬停行
  final int? hoverCol;      // 外部传入的悬停列
  final Function(PointerEvent)? onHover;      // 鼠标悬停回调
  final Function(TapDownDetails)? onTap;      // 点击回调
  final Function(PointerEvent)? onMouseExit;  // 鼠标离开回调
  
  const GoGameWidget({
    super.key,
    required this.gameModel,
    this.hoverRow,
    this.hoverCol,
    this.onHover,
    this.onTap,
    this.onMouseExit,
  });

  @override
  State<GoGameWidget> createState() => _GoGameWidgetState();
}

class _GoGameWidgetState extends State<GoGameWidget>
    with TickerProviderStateMixin {
  late AnimationController _pieceAnimationController;
  late Animation<double> _pieceScaleAnimation;
  
  // 最新下棋的动画位置
  int? _animatingRow;
  int? _animatingCol;

  @override
  void initState() {
    super.initState();
    
    // 棋子放置动画控制器
    _pieceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pieceScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pieceAnimationController,
      curve: Curves.elasticOut,
    ));
    
    // 监听游戏模型变化以触发动画
    widget.gameModel.addListener(_onGameModelChanged);
  }

  @override
  void dispose() {
    widget.gameModel.removeListener(_onGameModelChanged);
    _pieceAnimationController.dispose();
    super.dispose();
  }

  /// 游戏状态变化监听器
  void _onGameModelChanged() {
    // 如果有新的棋子被放置，播放动画
    if (widget.gameModel.lastMoveRow != null && 
        widget.gameModel.lastMoveCol != null) {
      setState(() {
        _animatingRow = widget.gameModel.lastMoveRow;
        _animatingCol = widget.gameModel.lastMoveCol;
      });
      
      // 重置并开始动画
      _pieceAnimationController.reset();
      _pieceAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用LayoutBuilder来获取可用空间，确保棋盘在任何屏幕尺寸下都能正确显示
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算可用的最大尺寸，选择宽度和高度中较小的值来保持正方形
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        final boardSize = (availableWidth < availableHeight ? availableWidth : availableHeight); 
        
        return Center(
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                // 榧木棋盘背景
                color: const Color(0xFFE6C794),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 100),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: MouseRegion(
                    onHover: widget.onHover,
                    onExit: widget.onMouseExit,
                    child: GestureDetector(
                      onTapDown: widget.onTap,
                      behavior: HitTestBehavior.opaque,
                      child: CustomPaint(
                        painter: GoBoardPainter(
                          gameModel: widget.gameModel,
                          pieceAnimation: _pieceScaleAnimation,
                          animatingRow: _animatingRow,
                          animatingCol: _animatingCol,
                          hoverRow: widget.hoverRow,  // 使用外部传入的悬停位置
                          hoverCol: widget.hoverCol,  // 使用外部传入的悬停位置
                        ),
                        child: const SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ),
            ),
          ),
        );
      },
    );
  }
}

/// 围棋棋盘绘制器
/// 
/// 负责绘制棋盘网格、棋子和各种视觉效果
class GoBoardPainter extends CustomPainter {
  final GoGameModel gameModel;
  final Animation<double> pieceAnimation;
  final int? animatingRow;
  final int? animatingCol;
  final int? hoverRow; // 鼠标悬停行位置
  final int? hoverCol; // 鼠标悬停列位置

  GoBoardPainter({
    required this.gameModel,
    required this.pieceAnimation,
    this.animatingRow,
    this.animatingCol,
    this.hoverRow,
    this.hoverCol,
  }) : super(repaint: pieceAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / GoGameModel.boardSize;
    
    _drawBoard(canvas, size, cellSize);
    _drawPieces(canvas, cellSize);
    _drawHoverEffect(canvas, size);
  }

  /// 绘制围棋棋盘
  void _drawBoard(Canvas canvas, Size size, double cellSize) {
    final Paint gridPaint = Paint()
      ..color = const Color(0xFF4A4A4A)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 计算实际可用的绘制区域
    final double margin = cellSize * 0.5;
    final double boardSize = size.width - margin * 2;
    final double actualCellSize = boardSize / (GoGameModel.boardSize - 1);

    // 绘制网格线
    for (int i = 0; i < GoGameModel.boardSize; i++) {
      final double lineOffset = margin + i * actualCellSize;
      
      // 水平线
      canvas.drawLine(
        Offset(margin, lineOffset),
        Offset(size.width - margin, lineOffset),
        gridPaint,
      );
      
      // 垂直线
      canvas.drawLine(
        Offset(lineOffset, margin),
        Offset(lineOffset, size.height - margin),
        gridPaint,
      );
    }
    
    // 绘制星位点
    _drawStarPoints(canvas, cellSize);
  }

  /// 绘制围棋星位点
  void _drawStarPoints(Canvas canvas, double cellSize) {
    final Paint starPaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.fill;

    // 计算与网格线相同的精确坐标
    final double margin = cellSize * 0.5;
    final double boardSize = cellSize * GoGameModel.boardSize - margin * 2;
    final double actualCellSize = boardSize / (GoGameModel.boardSize - 1);

    // 19路围棋标准星位
    final starPoints = [
      [3, 3], [3, 9], [3, 15],    // 上方星位
      [9, 3], [9, 9], [9, 15],    // 中间星位（包含天元）
      [15, 3], [15, 9], [15, 15], // 下方星位
    ];

    for (final point in starPoints) {
      final row = point[0];
      final col = point[1];
      
      if (row < GoGameModel.boardSize && col < GoGameModel.boardSize) {
        final centerX = margin + col * actualCellSize;
        final centerY = margin + row * actualCellSize;
        
        canvas.drawCircle(
          Offset(centerX, centerY),
          4.0, // 星位点半径
          starPaint,
        );
      }
    }
  }

  /// 绘制所有棋子
  void _drawPieces(Canvas canvas, double cellSize) {
    // 计算与网格线相同的精确坐标
    final double margin = cellSize * 0.5;
    final double boardSize = cellSize * GoGameModel.boardSize - margin * 2;
    final double actualCellSize = boardSize / (GoGameModel.boardSize - 1);

    for (int row = 0; row < GoGameModel.boardSize; row++) {
      for (int col = 0; col < GoGameModel.boardSize; col++) {
        final piece = gameModel.board[row][col];
        
        if (piece != PieceType.none) {
          final centerX = margin + col * actualCellSize;
          final centerY = margin + row * actualCellSize;
          
          // 检查是否为正在动画的棋子
          double scale = 1.0;
          if (animatingRow == row && animatingCol == col) {
            scale = pieceAnimation.value;
          }
          
          _drawPiece(canvas, centerX, centerY, piece, cellSize, scale);
          
          // 如果是最后一步，绘制高亮标记
          if (gameModel.lastMoveRow == row && gameModel.lastMoveCol == col) {
            _drawLastMoveHighlight(canvas, centerX, centerY, cellSize);
          }
        }
      }
    }
  }

  /// 绘制单个棋子
  void _drawPiece(Canvas canvas, double centerX, double centerY, PieceType piece, 
                  double cellSize, double scale) {
    final radius = (cellSize * 0.45) * scale;
    
    if (piece == PieceType.black) {
      // 黑棋：黑色，带渐变效果
      final Paint blackPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF404040),
            const Color(0xFF000000),
          ],
          stops: const [0.3, 1.0],
        ).createShader(
          Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        );
      
      // 绘制阴影
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 150)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      canvas.drawCircle(
        Offset(centerX + 1.5, centerY + 1.5),
        radius,
        shadowPaint,
      );
      
      // 绘制黑棋
      canvas.drawCircle(
        Offset(centerX, centerY),
        radius,
        blackPaint,
      );
      
      // 绘制高光
      final Paint highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 80);
      
      canvas.drawCircle(
        Offset(centerX - radius * 0.3, centerY - radius * 0.3),
        radius * 0.2,
        highlightPaint,
      );
      
    } else if (piece == PieceType.white) {
      // 白棋：白色，带渐变效果
      final Paint whitePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFFFFF),
            const Color(0xFFE8E8E8),
          ],
          stops: const [0.3, 1.0],
        ).createShader(
          Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        );
      
      // 绘制阴影
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 100)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      canvas.drawCircle(
        Offset(centerX + 1.5, centerY + 1.5),
        radius,
        shadowPaint,
      );
      
      // 绘制白棋
      canvas.drawCircle(
        Offset(centerX, centerY),
        radius,
        whitePaint,
      );
      
      // 绘制边框
      final Paint borderPaint = Paint()
        ..color = const Color(0xFFCCCCCC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawCircle(
        Offset(centerX, centerY),
        radius,
        borderPaint,
      );
    }
  }

  /// 绘制最后一步的高亮标记
  void _drawLastMoveHighlight(Canvas canvas, double centerX, double centerY, double cellSize) {
    final Paint highlightPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    
    final radius = cellSize * 0.3;
    
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      highlightPaint,
    );
  }

  /// 绘制鼠标悬停效果
  void _drawHoverEffect(Canvas canvas, Size size) {
    // 只有在有悬停位置且游戏进行中时才绘制
    if (hoverRow == null || hoverCol == null) return;
    if (gameModel.gameState != GoGameState.playing) return;
    if (!gameModel.isPlayerTurn) return;

    final cellSize = size.width / GoGameModel.boardSize;
    final double margin = cellSize * 0.5;
    final double boardSize = size.width - margin * 2;
    final double actualCellSize = boardSize / (GoGameModel.boardSize - 1);

    final centerX = margin + hoverCol! * actualCellSize;
    final centerY = margin + hoverRow! * actualCellSize;
    final radius = cellSize * 0.4;

    // 绘制半透明的悬停提示
    final Paint hoverPaint = Paint()
      ..color = gameModel.isBlackTurn 
          ? Colors.black.withValues(alpha: 100) 
          : Colors.white.withValues(alpha: 150)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      hoverPaint,
    );

    // 绘制边框
    final Paint borderPaint = Paint()
      ..color = gameModel.isBlackTurn 
          ? const Color(0xFF4CAF50)
          : const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(GoBoardPainter oldDelegate) {
    return oldDelegate.gameModel != gameModel ||
           oldDelegate.animatingRow != animatingRow ||
           oldDelegate.animatingCol != animatingCol ||
           oldDelegate.hoverRow != hoverRow ||
           oldDelegate.hoverCol != hoverCol ||
           oldDelegate.pieceAnimation.value != pieceAnimation.value;
  }
}
