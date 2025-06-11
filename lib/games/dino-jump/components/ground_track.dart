import 'package:flame/components.dart';

/// 地面轨道组件 - 参考Python版本的background函数逻辑
class GroundTrack extends Component {
  // 屏幕常量
  static const double screenWidth = 1100.0;
  static const double yPosBg = 380.0; // 参考Python版本的y_pos_bg = 380
  
  // 背景位置 - 参考Python版本的x_pos_bg
  double xPosBg = 0.0;
  
  // 地面轨道精灵组件
  late SpriteComponent track1;
  late SpriteComponent track2;

  @override
  Future<void> onLoad() async {
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
    
    // 设置轨道大小以覆盖整个屏幕宽度
    final trackWidth = trackSprite.srcSize.x;
    track1.size = Vector2(trackWidth, trackSprite.srcSize.y);
    track2.size = Vector2(trackWidth, trackSprite.srcSize.y);
  }

  /// 更新地面轨道移动 - 参考Python版本的background函数
  void updateMovement(int gameSpeed) {
    // 参考Python版本的移动逻辑: x_pos_bg -= game_speed
    xPosBg -= gameSpeed;
    
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
}
