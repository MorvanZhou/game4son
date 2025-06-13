import 'package:flutter/material.dart';
import '../models/gomoku_game_model.dart';
import '../widgets/gomoku_game_widget.dart';

/// 五子棋游戏主界面 - 统一单页面设计
///
/// 功能特性：
/// 1. 统一游戏界面，直接开始游戏而无需设置页面
/// 2. 内联设置控件（先后手选择、难度调节）位于游戏界面顶部
/// 3. 简化的比分显示（玩家胜局 : AI胜局）
/// 4. 应用栏重新开始按钮，便于快速重新开始
/// 5. 响应式布局，适配不同屏幕尺寸
class GomokuGameScreen extends StatefulWidget {
  const GomokuGameScreen({super.key});

  @override
  State<GomokuGameScreen> createState() => _GomokuGameScreenState();
}

class _GomokuGameScreenState extends State<GomokuGameScreen>
    with TickerProviderStateMixin {
  late GomokuGameModel gameModel;
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  
  // 鼠标悬停位置追踪 - 用于显示落子预览效果
  int? _hoverRow;
  int? _hoverCol;

  @override
  void initState() {
    super.initState();

    // 初始化游戏模型
    gameModel = GomokuGameModel();
    gameModel.addListener(_onGameStateChanged);

    // 背景动画控制器
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
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
    if (gameModel.gameState == GomokuGameState.playerWin ||
        gameModel.gameState == GomokuGameState.aiWin ||
        gameModel.gameState == GomokuGameState.draw) {
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
              child: _buildGameScreen(), // 直接显示游戏界面
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
          '五子棋',
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
        // 重新配置按钮 - 重置设置但不开始游戏
        IconButton(
          onPressed: () {
            gameModel.resetGame(); // 重置游戏状态和比分
          },
          icon: const Icon(
            Icons.settings_backup_restore,
            color: Color(0xFF8B5CF6),
            size: 24,
          ),
          tooltip: '重新配置',
        ),

        // 开始游戏按钮 - 根据当前设置开始新游戏
        IconButton(
          onPressed:
              (gameModel.gameState == GomokuGameState.playing)
                  ? null // 游戏进行中时禁用
                  : () {
                    gameModel.startNewGame(); // 开始新游戏
                  },
          icon: Icon(
            gameModel.gameState == GomokuGameState.playing
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline,
            color:
                gameModel.gameState == GomokuGameState.playing
                    ? Colors.grey
                    : const Color(0xFF4CAF50),
            size: 28,
          ),
          tooltip:
              gameModel.gameState == GomokuGameState.playing ? '游戏进行中' : '开始游戏',
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

  /// 构建游戏进行界面
  Widget _buildGameScreen() {
    return Column(
      children: [
        // 设置和状态栏
        _buildGameSettingsBar(),

        // 棋盘区域 - 直接使用GomokuGameWidget，交互处理移到Widget内部
        Expanded(
          child: GomokuGameWidget(
            gameModel: gameModel,
            hoverRow: _hoverRow,
            hoverCol: _hoverCol,
            onHover: _handleMouseHover,
            onTap: _handleTapDown,
            onMouseExit: _handleMouseExit,
          ),
        ),
      ],
    );
  }

  /// 构建游戏设置栏（包含设置和状态信息）
  /// 使用响应式布局，在小屏幕上自动换行避免溢出
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
            color: const Color(0xFF6366F1).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 判断屏幕宽度，决定使用单行还是多行布局
          final isNarrowScreen = constraints.maxWidth < 400;
          final isVeryNarrowScreen = constraints.maxWidth < 250; // 超窄屏幕特殊处理
          
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
                
                const SizedBox(height: 6), // 行间距
                
                // 第二行：设置选项 - 使用Flexible防止溢出
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 先后手选择 - 使用Flexible防止溢出
                    Flexible(
                      flex: 1,
                      child: _buildCompactSettingsGroup(
                        label: isVeryNarrowScreen ? '先' : '先手', // 超窄屏使用简化标签
                        options: [
                          ('我', gameModel.playerGoesFirst, () => gameModel.setPlayerGoesFirst(true)),
                          ('AI', !gameModel.playerGoesFirst, () => gameModel.setPlayerGoesFirst(false)),
                        ],
                      ),
                    ),
                    
                    SizedBox(width: isVeryNarrowScreen ? 4 : 8), // 超窄屏减少间距
                    
                    // 难度选择 - 使用Flexible防止溢出
                    Flexible(
                      flex: 1,
                      child: _buildCompactSettingsGroup(
                        label: isVeryNarrowScreen ? '难' : '难度', // 超窄屏使用简化标签
                        options: [
                          ('易', gameModel.difficulty == DifficultyLevel.easy, () => gameModel.setDifficulty(DifficultyLevel.easy)),
                          ('中', gameModel.difficulty == DifficultyLevel.medium, () => gameModel.setDifficulty(DifficultyLevel.medium)),
                          ('难', gameModel.difficulty == DifficultyLevel.hard, () => gameModel.setDifficulty(DifficultyLevel.hard)),
                        ],
                      ),
                    ),
                  ],
                ),
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

                // 先后手选择
                _buildCompactSettingsGroup(
                  label: '先手',
                  options: [
                    ('我', gameModel.playerGoesFirst, () => gameModel.setPlayerGoesFirst(true)),
                    ('AI', !gameModel.playerGoesFirst, () => gameModel.setPlayerGoesFirst(false)),
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
              ],
            );
          }
        },
      ),
    );
  }

  /// 构建紧凑的设置组件，减少代码重复，支持自适应宽度
  Widget _buildCompactSettingsGroup({
    required String label,
    required List<(String, bool, VoidCallback)> options,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标签 - 使用Flexible确保不会溢出
        Flexible(
          child: Text(
            '$label：',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.7),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        // 选项按钮 - 使用Flexible包装
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
        }).toList(),
      ],
    );
  }

  /// 构建快速切换按钮
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
        ), // 减少按钮内边距
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF6366F1).withOpacity(0.8)
                  : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6), // 减少圆角
          border: Border.all(
            color:
                isSelected
                    ? const Color(0xFF6366F1)
                    : Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10, // 缩小按钮文字
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  /// 获取游戏状态对应的颜色
  Color _getGameStateColor() {
    switch (gameModel.gameState) {
      case GomokuGameState.playing:
        return gameModel.isPlayerTurn
            ? const Color(0xFF4CAF50)
            : const Color(0xFFFF9800);
      case GomokuGameState.playerWin:
        return const Color(0xFF4CAF50);
      case GomokuGameState.aiWin:
        return const Color(0xFFF44336);
      case GomokuGameState.draw:
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
      case GomokuGameState.playerWin:
        title = '恭喜获胜！';
        message = '你成功击败了AI，棋艺精湛！';
        titleColor = const Color(0xFF4CAF50);
        icon = Icons.emoji_events;
        break;
      case GomokuGameState.aiWin:
        title = 'AI获胜';
        message = '再接再厉，挑战更高难度吧！';
        titleColor = const Color(0xFFF44336);
        icon = Icons.psychology;
        break;
      case GomokuGameState.draw:
        title = '平局';
        message = '棋力相当，这是一场精彩的对弈！';
        titleColor = const Color(0xFFFF9800);
        icon = Icons.handshake;
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: titleColor.withOpacity(0.5), width: 2),
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
                    color: Colors.white.withOpacity(0.9),
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
                        gameModel.enterAnalysisMode(); // 进入分析模式，保留棋局
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.white.withOpacity(0.1),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF3A3A3A), Color(0xFF4A4A4A)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildResultStatItem(
            '胜利',
            gameModel.playerWins,
            const Color(0xFF4CAF50),
          ),
          _buildResultStatItem('失败', gameModel.aiWins, const Color(0xFFF44336)),
          _buildResultStatItem('平局', gameModel.draws, const Color(0xFFFF9800)),
        ],
      ),
    );
  }

  /// 构建结果统计项目
  Widget _buildResultStatItem(String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
        ),
      ],
    );
  }

  /// 处理点击事件 - 与悬停事件使用完全相同的坐标计算
  void _handleTapDown(TapDownDetails details) {
    // 只在游戏进行中且轮到玩家时响应
    if (gameModel.gameState != GomokuGameState.playing ||
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
        
        print('=== 点击落子调试 ===');
        print('点击坐标: (${localPosition.dx.toStringAsFixed(1)}, ${localPosition.dy.toStringAsFixed(1)})');
        print('网格坐标: ($row, $col)');
      }
    }
  }

  /// 计算给定坐标对应的网格坐标 - 直接基于Widget坐标系
  /// 返回 (row, col) 或 null（如果坐标无效）
  (int, int)? _calculateGridCoordinates(Offset localPosition) {
    // 现在 localPosition 是相对于 GomokuGameWidget 内部的 MouseRegion 的
    // 这意味着坐标系与 CustomPaint 的 Canvas 完全一致
    
    // 首先获取当前的 GomokuGameWidget 的尺寸信息
    // 由于我们无法直接获取 Widget 内部的尺寸，我们需要基于屏幕信息推算
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return null;
    }

    final screenSize = renderBox.size;
    final availableWidth = screenSize.width;
    final availableHeight = screenSize.height - 60; // 减去设置栏高度（大约）
    
    // 计算棋盘实际尺寸（与 GomokuGameWidget 内部逻辑一致）
    final boardSize = availableWidth < availableHeight ? availableWidth : availableHeight;
    final containerMargin = 8.0;
    final actualCanvasSize = boardSize - containerMargin * 2;
    
    // 检查坐标是否在 Canvas 区域内
    if (localPosition.dx < 0 || localPosition.dy < 0 || 
        localPosition.dx > actualCanvasSize || localPosition.dy > actualCanvasSize) {
      return null;
    }
    
    // 使用与 Canvas 绘制完全相同的坐标计算
    final cellSize = actualCanvasSize / GomokuGameModel.boardSize;
    final double margin = cellSize * 0.5;
    final double boardDrawSize = actualCanvasSize - margin * 2;
    final double actualCellSize = boardDrawSize / (GomokuGameModel.boardSize - (availableWidth < availableHeight ? 1 : 0));
    
    // 计算到最近交点的距离
    final adjustedX = localPosition.dx - margin;
    final adjustedY = localPosition.dy - margin;
    
    // 使用网格交点布局计算行列
    final col = (adjustedX / actualCellSize + 0.5).floor();
    final row = (adjustedY / actualCellSize + 0.5).floor();
    
    // 检查是否为有效位置
    if (row >= 0 && row < GomokuGameModel.boardSize &&
        col >= 0 && col < GomokuGameModel.boardSize) {
      return (row, col);
    }
    
    return null;
  }

  /// 处理鼠标悬停事件 - 屏幕级别坐标处理
  void _handleMouseHover(PointerEvent event) {
    // 只在游戏进行中且轮到玩家时显示悬停效果
    if (gameModel.gameState != GomokuGameState.playing ||
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
          
          print('=== 悬停调试（统一坐标系）===');
          print('屏幕坐标: (${localPosition.dx.toStringAsFixed(1)}, ${localPosition.dy.toStringAsFixed(1)})');
          print('网格坐标: ($row, $col)');
        }
      } else {
        _clearHoverState();
      }
    } else {
      _clearHoverState();
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
}
