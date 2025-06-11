import 'package:flame/components.dart';
import 'dart:math' as math;

/// 云朵背景组件 - 参考Python版本的Cloud类
class CloudBackground extends SpriteComponent {
  // 屏幕常量
  static const double screenWidth = 1100.0;
  
  final math.Random random = math.Random();

  @override
  Future<void> onLoad() async {
    // 加载云朵精灵图 - 参考Python版本的CLOUD图片
    sprite = await Sprite.load('dino-jump.Cloud.png');
    
    // 设置初始位置和大小 - 参考Python版本的Cloud.__init__方法
    _resetPosition();
    
    size = Vector2(80, 40); // 根据图片调整大小
    anchor = Anchor.topLeft;
  }

  /// 重置云朵位置 - 参考Python版本的初始化逻辑
  void _resetPosition() {
    // 参考Python版本: self.x = SCREEN_WIDTH + random.randint(800, 1000)
    position.x = screenWidth + random.nextInt(200) + 800;
    
    // 参考Python版本: self.y = random.randint(50, 100)
    position.y = random.nextInt(50) + 50.0;
  }

  /// 更新云朵移动 - 参考Python版本的update方法
  void updateMovement(int gameSpeed) {
    // 参考Python版本: self.x -= game_speed
    position.x -= gameSpeed;
    
    // 检查是否需要重置位置 - 参考Python版本的重置逻辑
    // if self.x < -self.width:
    if (position.x < -size.x) {
      // 参考Python版本的重置逻辑
      // self.x = SCREEN_WIDTH + random.randint(2500, 3000)
      // self.y = random.randint(50, 100)
      position.x = screenWidth + random.nextInt(500) + 2500;
      position.y = random.nextInt(50) + 50.0;
    }
  }

  /// 重置云朵 - 游戏重新开始时调用
  void reset() {
    _resetPosition();
  }
}
