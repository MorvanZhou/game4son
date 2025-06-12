import 'package:flutter/material.dart';
import '../games/maze/screens/maze_game_screen.dart';
import '../games/dino-jump/screens/chrome_dino_game_screen.dart';
import '../games/gomoku/screens/gomoku_game_screen.dart';

class GameCollectionHome extends StatefulWidget {
  const GameCollectionHome({super.key});

  @override
  State<GameCollectionHome> createState() => _GameCollectionHomeState();
}

class _GameCollectionHomeState extends State<GameCollectionHome>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // 淡入动画
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // 卡片动画
    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    ));

    // 启动动画
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _cardController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e), // 深蓝紫色
              Color(0xFF16213e), // 深蓝色
              Color(0xFF0f3460), // 蓝色
              Color(0xFF533483), // 紫色
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // 标题区域
                _buildHeader(),
                
                // 游戏卡片区域
                Expanded(
                  child: _buildGameGrid(),
                ),
                
                // 底部信息
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), // 减少padding
      child: Column(
        children: [
          // 主标题 - 减少字体大小
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
                Color(0xFFEC4899),
              ],
            ).createShader(bounds),
            child: const Text(
              'Game4son',
              style: TextStyle(
                fontSize: 32, // 从48减少到32
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15), // 减少水平padding
            child: GridView.count(
              crossAxisCount: 3, // 3列布局
              crossAxisSpacing: 12, // 减少间距
              mainAxisSpacing: 12, // 减少间距
              childAspectRatio: 1.0, // 正方形卡片
              physics: const BouncingScrollPhysics(), // 添加滚动物理效果
              children: [
                // 迷宫游戏卡片
                _buildGameCard(
                  title: '迷宫探险',
                  icon: Icons.route,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MazeGameScreen(),
                      ),
                    );
                  },
                ),
                
                // 恐龙跳跃游戏卡片
                _buildGameCard(
                  title: '恐龙跳跳',
                  icon: Icons.directions_run,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4CAF50),
                      Color(0xFF66BB6A),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChromeDinoGameScreen(),
                      ),
                    );
                  },
                ),
                
                // 五子棋游戏卡片
                _buildGameCard(
                  title: '五子棋',
                  icon: Icons.grid_on,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF6B6B),
                      Color(0xFFFF8E8E),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GomokuGameScreen(),
                      ),
                    );
                  },
                ),
                
                _buildComingSoonCard(
                  title: '记忆翻牌',
                  icon: Icons.memory,
                ),
                
                _buildComingSoonCard(
                  title: '数字拼图',
                  icon: Icons.grid_3x3,
                ),
                
                _buildComingSoonCard(
                  title: '扫雷游戏',
                  icon: Icons.flag,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameCard({
    required String title,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据可用空间动态计算元素大小
        final cardSize = constraints.maxWidth;
        final iconSize = (cardSize * 0.2).clamp(24.0, 45.0); // 图标大小为卡片宽度的20%，限制在24-45px之间
        final iconPadding = (cardSize * 0.08).clamp(6.0, 12.0); // 图标内边距
        final spacing = (cardSize * 0.06).clamp(4.0, 8.0); // 元素间距
        final fontSize = (cardSize * 0.12).clamp(10.0, 14.0); // 字体大小
        final cardPadding = (cardSize * 0.08).clamp(6.0, 12.0); // 卡片内边距
        
        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, // 重要：使用最小尺寸
                    children: [
                      // 游戏图标 - 自适应大小
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.all(iconPadding),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            size: iconSize,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: spacing),
                      
                      // 游戏标题 - 自适应字体大小
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildComingSoonCard({
    required String title,
    required IconData icon,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据可用空间动态计算元素大小
        final cardSize = constraints.maxWidth;
        final iconSize = (cardSize * 0.28).clamp(20.0, 32.0); // 即将推出的卡片图标稍小
        final iconPadding = (cardSize * 0.08).clamp(6.0, 12.0);
        final spacing = (cardSize * 0.06).clamp(3.0, 8.0);
        final fontSize = (cardSize * 0.12).clamp(10.0, 14.0);
        final cardPadding = (cardSize * 0.08).clamp(6.0, 12.0);
        final tagFontSize = (cardSize * 0.08).clamp(8.0, 10.0);
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.withOpacity(0.3),
                Colors.grey.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // 使用最小尺寸
              children: [
                // 游戏图标 - 自适应大小
                Flexible(
                  child: Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
                
                SizedBox(height: spacing),
                
                // 游戏标题 - 自适应字体
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                SizedBox(height: spacing * 0.5),
                
                // 即将推出标签 - 自适应大小
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: cardPadding * 0.7, 
                      vertical: cardPadding * 0.3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '即将推出',
                      style: TextStyle(
                        fontSize: tagFontSize,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Text(
        '© 2025 游戏合集 - 更多精彩游戏即将推出',
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withOpacity(0.6),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
