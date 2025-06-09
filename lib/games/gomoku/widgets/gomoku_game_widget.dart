import 'package:flutter/material.dart';
import '../models/gomoku_game_model.dart';

/// 五子棋游戏界面组件
/// 
/// 功能特性：
/// 1. 响应式棋盘绘制，支持不同屏幕尺寸
/// 2. 触摸交互，支持点击下棋
/// 3. 棋子动画效果
/// 4. 最后一步高亮显示
class GomokuGameWidget extends StatefulWidget {
  final GomokuGameModel gameModel;
  
  const GomokuGameWidget({
    super.key,
    required this.gameModel,
  });

  @override
  State<GomokuGameWidget> createState() => _GomokuGameWidgetState();
}

class _GomokuGameWidgetState extends State<GomokuGameWidget>
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
    return AspectRatio(
      aspectRatio: 1.0, // 正方形棋盘
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          // 木质棋盘背景
          color: const Color(0xFFD4A574),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomPaint(
            painter: GomokuBoardPainter(
              gameModel: widget.gameModel,
              pieceAnimation: _pieceScaleAnimation,
              animatingRow: _animatingRow,
              animatingCol: _animatingCol,
            ),
            child: GestureDetector(
              onTapDown: _handleTapDown,
              // 确保手势检测器能接收到事件
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
              ), // 填满整个区域以接收点击事件
            ),
          ),
        ),
      ),
    );
  }

  /// 处理棋盘点击事件
  void _handleTapDown(TapDownDetails details) {
    
    // 只在游戏进行中且轮到玩家时响应
    if (widget.gameModel.gameState != GomokuGameState.playing) {
      return;
    }
    
    if (!widget.gameModel.isPlayerTurn) {
      return;
    }

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }
    
    final size = renderBox.size;
    final localPosition = details.localPosition;
    
    // 计算点击位置对应的棋盘坐标
    final cellSize = size.width / GomokuGameModel.boardSize;
    final row = (localPosition.dy / cellSize).floor();
    final col = (localPosition.dx / cellSize).floor();
    
    // 确保坐标在有效范围内
    if (row >= 0 && row < GomokuGameModel.boardSize && 
        col >= 0 && col < GomokuGameModel.boardSize) {
      
      // 检查该位置是否已有棋子
      if (widget.gameModel.board[row][col] != PieceType.none) {
        return;
      }
      
      // 调用游戏模型的落子方法，处理玩家下棋
      widget.gameModel.makePlayerMove(row, col);
      
    }
  }
}

/// 五子棋棋盘绘制器
/// 
/// 负责绘制棋盘网格、棋子和各种视觉效果
class GomokuBoardPainter extends CustomPainter {
  final GomokuGameModel gameModel;
  final Animation<double> pieceAnimation;
  final int? animatingRow;
  final int? animatingCol;

  GomokuBoardPainter({
    required this.gameModel,
    required this.pieceAnimation,
    this.animatingRow,
    this.animatingCol,
  }) : super(repaint: pieceAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / GomokuGameModel.boardSize;
    
    _drawBoard(canvas, size, cellSize);
    _drawPieces(canvas, cellSize);
  }

  /// 绘制棋盘网格和装饰
  void _drawBoard(Canvas canvas, Size size, double cellSize) {
    final Paint gridPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 绘制网格线
    for (int i = 0; i < GomokuGameModel.boardSize; i++) {
      final offset = i * cellSize + cellSize / 2;
      
      // 水平线
      canvas.drawLine(
        Offset(cellSize / 2, offset),
        Offset(size.width - cellSize / 2, offset),
        gridPaint,
      );
      
      // 垂直线
      canvas.drawLine(
        Offset(offset, cellSize / 2),
        Offset(offset, size.height - cellSize / 2),
        gridPaint,
      );
    }
    
    // 绘制天元和星位点
    _drawStarPoints(canvas, cellSize);
  }

  /// 绘制棋盘星位点（天元等关键位置标记）
  void _drawStarPoints(Canvas canvas, double cellSize) {
    final Paint starPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.fill;

    // 标准五子棋星位：天元(7,7)和四个角星
    final starPoints = [
      [7, 7],   // 天元
      [3, 3],   // 左上星
      [3, 11],  // 右上星
      [11, 3],  // 左下星
      [11, 11], // 右下星
    ];

    for (final point in starPoints) {
      final row = point[0];
      final col = point[1];
      
      if (row < GomokuGameModel.boardSize && col < GomokuGameModel.boardSize) {
        final centerX = col * cellSize + cellSize / 2;
        final centerY = row * cellSize + cellSize / 2;
        
        canvas.drawCircle(
          Offset(centerX, centerY),
          3.0, // 星位点半径
          starPaint,
        );
      }
    }
  }

  /// 绘制所有棋子
  void _drawPieces(Canvas canvas, double cellSize) {
    for (int row = 0; row < GomokuGameModel.boardSize; row++) {
      for (int col = 0; col < GomokuGameModel.boardSize; col++) {
        final piece = gameModel.board[row][col];
        
        if (piece != PieceType.none) {
          final centerX = col * cellSize + cellSize / 2;
          final centerY = row * cellSize + cellSize / 2;
          
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
  /// 
  /// [canvas] 画布
  /// [centerX] 棋子中心X坐标
  /// [centerY] 棋子中心Y坐标  
  /// [piece] 棋子类型
  /// [cellSize] 格子大小
  /// [scale] 缩放比例（用于动画）
  void _drawPiece(Canvas canvas, double centerX, double centerY, PieceType piece, 
                  double cellSize, double scale) {
    final radius = (cellSize * 0.4) * scale;
    
    if (piece == PieceType.player) {
      // 玩家棋子：黑色，带渐变效果
      final Paint blackPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF2C2C2C),
            const Color(0xFF000000),
          ],
          stops: const [0.3, 1.0],
        ).createShader(
          Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        );
      
      // 绘制棋子阴影
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      canvas.drawCircle(
        Offset(centerX + 2, centerY + 2),
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
        ..color = Colors.white.withOpacity(0.3);
      
      canvas.drawCircle(
        Offset(centerX - radius * 0.3, centerY - radius * 0.3),
        radius * 0.2,
        highlightPaint,
      );
      
    } else if (piece == PieceType.ai) {
      // AI棋子：白色，带渐变效果
      final Paint whitePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFFFFF),
            const Color(0xFFE0E0E0),
          ],
          stops: const [0.3, 1.0],
        ).createShader(
          Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        );
      
      // 绘制棋子阴影
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      canvas.drawCircle(
        Offset(centerX + 2, centerY + 2),
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
        ..strokeWidth = 1.5;
      
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
      ..strokeWidth = 3.0;
    
    final radius = cellSize * 0.25;
    
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(GomokuBoardPainter oldDelegate) {
    return oldDelegate.gameModel != gameModel ||
           oldDelegate.animatingRow != animatingRow ||
           oldDelegate.animatingCol != animatingCol;
  }
}
