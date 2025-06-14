import 'package:flame/components.dart';
import 'dart:math' as math;
import '../game_config.dart';

/// 云朵背景组件 - 参考Python版本的Cloud类，支持自适应游戏尺寸
class CloudBackground extends SpriteComponent {
  
  late double gameWidth; // 从游戏主类获取的游戏宽度
  final math.Random random = math.Random();

  @override
  Future<void> onLoad() async {
    // 加载云朵精灵图 - 参考Python版本的CLOUD图片
    sprite = await Sprite.load('dino-jump.Cloud.png');
    
    // 获取游戏宽度（从父组件获取）
    gameWidth = (parent as dynamic).gameWidth ?? 1100.0;
    
    // 设置初始位置和大小 - 参考Python版本的Cloud.__init__方法，使用配置系统
    _resetPosition();
    
    size = Vector2(DinoGameConfig.cloudSize, DinoGameConfig.cloudSize); // 使用配置系统的缩放值
    anchor = Anchor.topLeft;
  }

  /// 重置云朵位置 - 参考Python版本的初始化逻辑，使用配置系统应用缩放
  void _resetPosition() {
    // 参考Python版本: self.x = SCREEN_WIDTH + random.randint(800, 1000)，使用配置系统
    double spawnRange = DinoGameConfig.cloudSpawnMax - DinoGameConfig.cloudSpawnMin;
    position.x = gameWidth + DinoGameConfig.cloudSpawnMin + random.nextDouble() * spawnRange;
    
    // 参考Python版本: self.y = random.randint(50, 100)，使用配置系统应用缩放
    double yRange = DinoGameConfig.cloudMaxY - DinoGameConfig.cloudMinY;
    position.y = DinoGameConfig.cloudMinY + random.nextDouble() * yRange;
  }

  /// 更新云朵移动 - 参考Python版本的update方法，使用配置系统
  void updateMovement(int gameSpeed) {
    // 参考Python版本: self.x -= game_speed，使用配置系统应用缩放
    position.x -= gameSpeed * DinoGameConfig.GLOBAL_SCALE_FACTOR;
    
    // 检查是否需要重置位置 - 参考Python版本的重置逻辑
    // if self.x < -self.width:
    if (position.x < -size.x) {
      // 参考Python版本的重置逻辑，使用配置系统应用缩放
      // self.x = SCREEN_WIDTH + random.randint(2500, 3000)
      // self.y = random.randint(50, 100)
      double respawnRange = DinoGameConfig.cloudRespawnMax - DinoGameConfig.cloudRespawnMin;
      position.x = gameWidth + DinoGameConfig.cloudRespawnMin + random.nextDouble() * respawnRange;
      
      double yRange = DinoGameConfig.cloudMaxY - DinoGameConfig.cloudMinY;
      position.y = DinoGameConfig.cloudMinY + random.nextDouble() * yRange;
    }
  }

  /// 重置云朵 - 游戏重新开始时调用
  void reset() {
    _resetPosition();
  }

  /// 更新游戏宽度 - 当游戏尺寸改变时调用
  void updateGameWidth(double newGameWidth) {
    gameWidth = newGameWidth;
  }
}
