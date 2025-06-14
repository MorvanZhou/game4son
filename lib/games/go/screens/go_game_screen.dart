import 'package:flutter/material.dart';
import '../models/go_game_model.dart';
import '../widgets/go_game_widget.dart';

/// 围棋游戏主界面
///
/// 功能特性：
/// 1. 统一游戏界面，直接开始游戏而无需设置页面
/// 2. 内联设置控件（执黑/执白选择、难度调节）位于游戏界面顶部
/// 3. 简化的比分显示（玩家胜局 : AI胜局）
/// 4. 应用栏重新开始按钮，便于快速重新开始
/// 5. 响应式布局，适配不同屏幕尺寸
/// 6. 围棋特有功能：Pass按钮、提子数显示
class GoGameScreen extends StatefulWidget {
  const GoGameScreen({super.key});

  @override
  State<GoGameScreen> createState() => _GoGameScreenState();
}

class _GoGameScreenState extends State<GoGameScreen>
    with TickerProviderStateMixin {
  
  late GoGameModel gameModel;
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  
  // 鼠标悬停状态
  int? _hoverRow;
  int? _hoverCol;

  @override
  void initState() {
    super.initState();
    
    gameModel = GoGameModel();
    gameModel.addListener(_onGameStateChanged);
    
    // 背景动画控制器
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundController);
  }

  @override
  void dispose() {
    gameModel.removeListener(_onGameStateChanged);
    _backgroundController.dispose();
    super.dispose();
  }

  /// 游戏状态变化监听器
  void _onGameStateChanged() {
    setState(() {});

    // 游戏结束时显示结果对话框
    if (gameModel.gameState == GoGameState.playerWin ||
        gameModel.gameState == GoGameState.aiWin ||
        gameModel.gameState == GoGameState.draw) {
      // 延迟显示，避免动画冲突
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showGameResultDialog();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
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
                    const Color(0xFF3A2A2A),
                    (_backgroundAnimation.value * 0.5) % 1.0,
                  )!,
                  const Color(0xFF1A1A1A),
                ],
                stops: [0.0, (_backgroundAnimation.value * 0.8) % 1.0, 1.0],
              ),
            ),
            child: SafeArea(
              child: _buildGameScreen(),
            ),
          );
        },
      ),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: ShaderMask(
        shaderCallback:
            (bounds) => const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ).createShader(bounds),
        child: const Text(
          '围棋',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.5,
          ),
        ),
      ),
      backgroundColor: const Color(0xFF2A2A2A),
      elevation: 0,
      actions: [
        // 重新配置按钮
        IconButton(
          onPressed: () {
            gameModel.resetGame();
          },
          icon: const Icon(
            Icons.settings_backup_restore,
            color: Color(0xFF8B5CF6),
            size: 24,
          ),
          tooltip: '重新配置',
        ),

        // 开始游戏按钮
        IconButton(
          onPressed:
              (gameModel.gameState == GoGameState.playing)
                  ? null
                  : () {
                    gameModel.startNewGame();
                  },
          icon: Icon(
            gameModel.gameState == GoGameState.playing
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline,
            color:
                gameModel.gameState == GoGameState.playing
                    ? Colors.grey
                    : const Color(0xFF4CAF50),
            size: 28,
          ),
          tooltip:
              gameModel.gameState == GoGameState.playing ? '游戏进行中' : '开始游戏',
        ),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A2A2A), Color(0xFF3A3A3A)],
          ),
        ),
      ),
    );
  }

  /// 构建游戏主界面
  Widget _buildGameScreen() {
    return Column(
      children: [
        // 设置和状态栏
        _buildGameSettingsBar(),

        // 棋盘区域
        Expanded(
          child: _buildBoardSection(),
        ),
      ],
    );
  }

  /// 构建棋盘区域
  Widget _buildBoardSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GoGameWidget(
        gameModel: gameModel,
        hoverRow: _hoverRow,
        hoverCol: _hoverCol,
        onHover: _handleMouseHover,
        onTap: _handleTapDown,
        onMouseExit: _handleMouseExit,
      ),
    );
  }

  /// 构建游戏设置栏（参考 gomoku 设计）
  Widget _buildGameSettingsBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A3A3A), Color(0xFF2A2A2A)],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF6366F1).withValues(alpha: 100),
            width: 1,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 判断屏幕宽度，决定使用单行还是多行布局
          final isNarrowScreen = constraints.maxWidth < 450;
          final isVeryNarrowScreen = constraints.maxWidth < 280;
          
          if (isNarrowScreen) {
            // 窄屏幕：使用两行布局
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 第一行：游戏状态和比分
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 游戏状态
                    Flexible(
                      child: Text(
                        gameModel.getGameStateText(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getGameStateColor(),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // 比分显示
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${gameModel.playerWins} : ${gameModel.aiWins}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                // 第二行：设置选项
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 执子选择
                    Flexible(
                      flex: 1,
                      child: _buildCompactSettingsGroup(
                        label: isVeryNarrowScreen ? '执' : '执子',
                        options: [
                          ('黑', gameModel.playerPlaysBlack, () => gameModel.setPlayerPlaysBlack(true)),
                          ('白', !gameModel.playerPlaysBlack, () => gameModel.setPlayerPlaysBlack(false)),
                        ],
                      ),
                    ),
                    
                    SizedBox(width: isVeryNarrowScreen ? 4 : 8),
                    
                    // 难度选择
                    Flexible(
                      flex: 1,
                      child: _buildCompactSettingsGroup(
                        label: isVeryNarrowScreen ? '难' : '难度',
                        options: [
                          ('易', gameModel.difficulty == DifficultyLevel.easy, () => gameModel.setDifficulty(DifficultyLevel.easy)),
                          ('中', gameModel.difficulty == DifficultyLevel.medium, () => gameModel.setDifficulty(DifficultyLevel.medium)),
                          ('难', gameModel.difficulty == DifficultyLevel.hard, () => gameModel.setDifficulty(DifficultyLevel.hard)),
                        ],
                      ),
                    ),
                    
                    SizedBox(width: isVeryNarrowScreen ? 4 : 8),
                    
                    // Pass按钮和提子数
                    Flexible(
                      flex: 1,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCompactPassButton(),
                          if (!isVeryNarrowScreen) ...[
                            const SizedBox(width: 4),
                            _buildCaptureIndicator(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                // 超窄屏时，提子数单独一行
                if (isVeryNarrowScreen) ...[
                  const SizedBox(height: 4),
                  _buildCaptureIndicator(),
                ],
              ],
            );
          } else {
            // 宽屏幕：使用单行布局
            return Row(
              children: [
                // 游戏状态
                Flexible(
                  flex: 2,
                  child: Text(
                    gameModel.getGameStateText(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getGameStateColor(),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: 8),

                // 比分显示
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${gameModel.playerWins} : ${gameModel.aiWins}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const Spacer(),

                // 执子选择
                _buildCompactSettingsGroup(
                  label: '执子',
                  options: [
                    ('黑', gameModel.playerPlaysBlack, () => gameModel.setPlayerPlaysBlack(true)),
                    ('白', !gameModel.playerPlaysBlack, () => gameModel.setPlayerPlaysBlack(false)),
                  ],
                ),

                const SizedBox(width: 12),

                // 难度选择
                _buildCompactSettingsGroup(
                  label: '难度',
                  options: [
                    ('易', gameModel.difficulty == DifficultyLevel.easy, () => gameModel.setDifficulty(DifficultyLevel.easy)),
                    ('中', gameModel.difficulty == DifficultyLevel.medium, () => gameModel.setDifficulty(DifficultyLevel.medium)),
                    ('难', gameModel.difficulty == DifficultyLevel.hard, () => gameModel.setDifficulty(DifficultyLevel.hard)),
                  ],
                ),

                const SizedBox(width: 12),

                // Pass按钮
                _buildCompactPassButton(),

                const SizedBox(width: 12),

                // 提子数显示
                _buildCaptureIndicator(),
              ],
            );
          }
        },
      ),
    );
  }

  /// 构建紧凑设置组
  Widget _buildCompactSettingsGroup({
    required String label,
    required List<(String, bool, VoidCallback)> options,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标签
        Flexible(
          child: Text(
            '$label：',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 200),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        // 选项按钮
        ...options.map((option) {
          final (text, isSelected, onTap) = option;
          return Flexible(
            child: Padding(
              padding: const EdgeInsets.only(right: 2),
              child: _buildQuickToggle(
                text: text,
                isSelected: isSelected,
                onTap: onTap,
              ),
            ),
          );
        }),
      ],
    );
  }

  /// 构建快速切换按钮（参考 gomoku 风格）
  Widget _buildQuickToggle({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withOpacity(0.8)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  /// 构建紧凑版Pass按钮
  Widget _buildCompactPassButton() {
    final canPass = gameModel.gameState == GoGameState.playing && gameModel.isPlayerTurn;
    
    return GestureDetector(
      onTap: canPass ? gameModel.playerPass : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        decoration: BoxDecoration(
          color: canPass
              ? const Color(0xFFFF9800).withOpacity(0.8)
              : Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: canPass
                ? const Color(0xFFFF9800)
                : Colors.grey.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Text(
          'Pass',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: canPass ? Colors.white : Colors.white.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  /// 构建提子数指示器
  Widget _buildCaptureIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.black.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            '黑:${gameModel.blackCaptured}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Text(
            '白:${gameModel.whiteCaptured}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  /// 获取游戏状态对应的颜色
  Color _getGameStateColor() {
    switch (gameModel.gameState) {
      case GoGameState.playing:
        return gameModel.isPlayerTurn
            ? const Color(0xFF4CAF50)
            : const Color(0xFFFF9800);
      case GoGameState.playerWin:
        return const Color(0xFF4CAF50);
      case GoGameState.aiWin:
        return const Color(0xFFF44336);
      case GoGameState.draw:
        return const Color(0xFFFF9800);
      default:
        return Colors.white;
    }
  }

  /// 显示游戏结果对话框
  void _showGameResultDialog() {
    String title;
    String message;
    Color titleColor;
    IconData icon;

    switch (gameModel.gameState) {
      case GoGameState.playerWin:
        title = '恭喜获胜！';
        message = '您在围棋对弈中战胜了AI，展现了出色的棋艺！';
        titleColor = const Color(0xFF4CAF50);
        icon = Icons.emoji_events;
        break;
      case GoGameState.aiWin:
        title = 'AI获胜';
        message = '这是一局精彩的对弈，继续练习提高棋艺！';
        titleColor = const Color(0xFFF44336);
        icon = Icons.psychology;
        break;
      case GoGameState.draw:
        title = '平局';
        message = '势均力敌的精彩对局！';
        titleColor = const Color(0xFFFF9800);
        icon = Icons.handshake;
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: titleColor.withValues(alpha: 125), width: 2),
        ),
        title: Column(
          children: [
            Icon(icon, size: 48, color: titleColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 225),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildGameResultStats(),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    gameModel.enterAnalysisMode();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 25),
                  ),
                  child: const Text(
                    '查看复盘',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    gameModel.startNewGame();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: titleColor,
                  ),
                  child: const Text(
                    '再来一局',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建游戏结果统计
  Widget _buildGameResultStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 50),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            '本局统计',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 175),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '黑棋被提',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 175),
                      ),
                    ),
                    Text(
                      gameModel.blackCaptured.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 75),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '白棋被提',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 175),
                      ),
                    ),
                    Text(
                      gameModel.whiteCaptured.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 处理鼠标悬停事件 - 屏幕级别坐标处理
  void _handleMouseHover(PointerEvent event) {
    // 只在游戏进行中且轮到玩家时显示悬停效果
    if (gameModel.gameState != GoGameState.playing ||
        !gameModel.isPlayerTurn) {
      return;
    }

    // 使用与点击事件完全相同的坐标计算逻辑
    final localPosition = event.localPosition;
    final gridCoords = _calculateGridCoordinates(localPosition);
    
    if (gridCoords != null) {
      final (row, col) = gridCoords;
      
      // 检查是否为有效位置（空位置）
      if (gameModel.board[row][col] == PieceType.none) {
        if (_hoverRow != row || _hoverCol != col) {
          setState(() {
            _hoverRow = row;
            _hoverCol = col;
          });
        }
      } else {
        _clearHoverState();
      }
    } else {
      _clearHoverState();
    }
  }

  /// 处理点击事件
  void _handleTapDown(TapDownDetails details) {
    // 只在游戏进行中且轮到玩家时响应
    if (gameModel.gameState != GoGameState.playing ||
        !gameModel.isPlayerTurn) {
      return;
    }

    // 获取鼠标点击的坐标并计算对应的网格位置
    // 使用与悬停事件完全相同的坐标计算逻辑
    final localPosition = details.localPosition;
    final gridCoords = _calculateGridCoordinates(localPosition);
    
    if (gridCoords != null) {
      final (row, col) = gridCoords;
      
      // 检查该位置是否已有棋子
      if (gameModel.board[row][col] == PieceType.none) {
        // 调用游戏模型的落子方法
        gameModel.makePlayerMove(row, col);
      }
    }
  }

  /// 处理鼠标离开事件
  void _handleMouseExit(PointerEvent event) {
    _clearHoverState();
  }

  /// 清除悬停状态
  void _clearHoverState() {
    if (_hoverRow != null || _hoverCol != null) {
      setState(() {
        _hoverRow = null;
        _hoverCol = null;
      });
    }
  }

  /// 计算网格坐标 - 基于Widget坐标系
  (int, int)? _calculateGridCoordinates(Offset localPosition) {
    // 现在 localPosition 是相对于 GoGameWidget 内部的 MouseRegion 的
    // 这意味着坐标系与 CustomPaint 的 Canvas 完全一致
    
    // 首先获取当前的 GoGameWidget 的尺寸信息
    // 由于我们无法直接获取 Widget 内部的尺寸，我们需要基于屏幕信息推算
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return null;
    }

    final screenSize = renderBox.size;
    final availableWidth = screenSize.width;
    final availableHeight = screenSize.height - 60; // 减去设置栏高度（大约）
    
    // 计算棋盘实际尺寸（与 GoGameWidget 内部逻辑一致）
    final boardSize = availableWidth < availableHeight ? availableWidth : availableHeight;
    final containerMargin = 8.0;
    final actualCanvasSize = boardSize - containerMargin * 2;
    
    // 检查坐标是否在 Canvas 区域内
    if (localPosition.dx < 0 || localPosition.dy < 0 || 
        localPosition.dx > actualCanvasSize || localPosition.dy > actualCanvasSize) {
      return null;
    }
    
    // 使用与 Canvas 绘制完全相同的坐标计算
    final cellSize = actualCanvasSize / GoGameModel.boardSize;
    final double margin = cellSize * 0.5;
    final double boardDrawSize = actualCanvasSize - margin * 2;
    final double actualCellSize = boardDrawSize / (GoGameModel.boardSize +1);   // 减去一行或一列的偏移量

    // 计算到最近交点的距离
    final adjustedX = localPosition.dx - margin;
    final adjustedY = localPosition.dy - margin;
    
    // 使用网格交点布局计算行列
    final col = (adjustedX / actualCellSize + 0.5).floor();
    final row = (adjustedY / actualCellSize + 0.5).floor();
    
    // 检查是否为有效位置
    if (row >= 0 && row < GoGameModel.boardSize && 
        col >= 0 && col < GoGameModel.boardSize) {
      return (row, col);
    }

    return null;
  }
}
