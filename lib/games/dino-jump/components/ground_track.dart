import 'package:flame/components.dart';
import 'dart:math' as math;
import '../game_config.dart';

/// 地面轨道组件 - 参考Python版本的background函数逻辑，支持自适应游戏尺寸
class GroundTrack extends Component {
  
  // 背景位置 - 参考Python版本的x_pos_bg
  double xPosBg = 0.0;
  late double yPosBg; // 自适应Y位置
  late double gameWidth; // 自适应游戏宽度
  
  // 地面轨道精灵组件
  late SpriteComponent track1;
  late SpriteComponent track2;

  @override
  Future<void> onLoad() async {
    // 获取游戏尺寸（从父组件获取）
    gameWidth = (parent as dynamic).gameWidth ?? 1100.0;
    
    // 使用配置系统的地面Y位置 - 保持相对位置关系
    yPosBg = DinoGameConfig.groundY + 20; // 地面轨道在地面位置下方一点
    
    // 加载地面轨道精灵图 - 参考Python版本的BG图片
    final trackSprite = await Sprite.load('dino-jump.Track.png');
    
    // 创建第一个轨道 - 参考Python版本的background函数逻辑
    track1 = SpriteComponent(
      sprite: trackSprite,
      position: Vector2(xPosBg, yPosBg),
      anchor: Anchor.topLeft,
    );
    add(track1);
    
    // 创建第二个轨道用于无缝滚动
    track2 = SpriteComponent(
      sprite: trackSprite,
      position: Vector2(trackSprite.srcSize.x + xPosBg, yPosBg),
      anchor: Anchor.topLeft,
    );
    add(track2);
    
    // 设置轨道大小，应用配置系统的缩放，让轨道能够覆盖屏幕宽度
    final trackWidth = math.max(DinoGameConfig.trackWidth, gameWidth / 2);
    final trackHeight = DinoGameConfig.trackHeight;
    track1.size = Vector2(trackWidth, trackHeight);
    track2.size = Vector2(trackWidth, trackHeight);
  }

  /// 更新地面轨道移动 - 参考Python版本的background函数，使用配置系统应用缩放
  void updateMovement(int gameSpeed) {
    // 参考Python版本的移动逻辑: x_pos_bg -= game_speed，使用配置系统应用缩放
    xPosBg -= gameSpeed * DinoGameConfig.GLOBAL_SCALE_FACTOR;
    
    // 更新两个轨道的位置
    track1.position.x = xPosBg;
    track2.position.x = track1.size.x + xPosBg;
    
    // 无缝循环逻辑 - 参考Python版本的重置逻辑
    // if x_pos_bg <= -image_width:
    if (xPosBg <= -track1.size.x) {
      // SCREEN.blit(BG, (image_width + x_pos_bg, y_pos_bg))
      // x_pos_bg = 0
      xPosBg = 0;
    }
  }

  /// 重置地面轨道 - 游戏重新开始时调用
  void reset() {
    xPosBg = 0.0;
    track1.position.x = xPosBg;
    track2.position.x = track1.size.x + xPosBg;
  }

  /// 更新游戏尺寸 - 当游戏尺寸改变时调用，使用配置系统
  void updateGameSize(double newGameWidth, double newGameHeight) {
    gameWidth = newGameWidth;
    yPosBg = DinoGameConfig.groundY + 20; // 使用配置系统的地面位置
    
    // 更新轨道位置和大小
    track1.position.y = yPosBg;
    track2.position.y = yPosBg;
    
    // 更新轨道宽度，使用配置系统的缩放
    final trackWidth = math.max(DinoGameConfig.trackWidth, gameWidth / 2);
    final trackHeight = DinoGameConfig.trackHeight;
    track1.size = Vector2(trackWidth, trackHeight);
    track2.size = Vector2(trackWidth, trackHeight);
  }
}
