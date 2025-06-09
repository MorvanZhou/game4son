import 'package:flutter/material.dart';
import '../games/maze/screens/maze_game_screen.dart';

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
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          // 主标题
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
                Color(0xFFEC4899),
              ],
            ).createShader(bounds),
            child: const Text(
              '游戏合集',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          
          // 副标题
          Text(
            '选择你喜欢的游戏开始挑战',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w300,
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.85,
              children: [
                // 迷宫游戏卡片
                _buildGameCard(
                  title: '迷宫探险',
                  description: '在迷宫中寻找出路\n挑战你的空间感知力',
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
                
                // 即将推出的游戏卡片
                _buildComingSoonCard(
                  title: '数字拼图',
                  description: '经典的滑动拼图游戏\n锻炼逻辑思维能力',
                  icon: Icons.grid_3x3,
                ),
                
                _buildComingSoonCard(
                  title: '记忆翻牌',
                  description: '测试记忆力的翻牌游戏\n提升专注力和记忆力',
                  icon: Icons.memory,
                ),
                
                _buildComingSoonCard(
                  title: '俄罗斯方块',
                  description: '经典的方块消除游戏\n享受经典的游戏乐趣',
                  icon: Icons.apps,
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
    required String description,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 游戏图标
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 游戏标题
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 游戏描述
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonCard({
    required String title,
    required String description,
    required IconData icon,
  }) {
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 游戏图标
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 40,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 游戏标题
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // 游戏描述
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // 即将推出标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '即将推出',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
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
