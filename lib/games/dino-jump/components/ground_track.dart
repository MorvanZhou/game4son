import 'package:flame/components.dart';
import 'dart:math' as math;

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
    final gameHeight = (parent as dynamic).gameHeight ?? 600.0;
    
    // 计算地面Y位置 - 距离底部约1/3的位置
    yPosBg = gameHeight * 0.63; // 大约在屏幕的2/3位置
    
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
    
    // 设置轨道大小，让轨道能够覆盖屏幕宽度
    final trackWidth = math.max(trackSprite.srcSize.x, gameWidth / 2);
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

  /// 更新游戏尺寸 - 当游戏尺寸改变时调用
  void updateGameSize(double newGameWidth, double newGameHeight) {
    gameWidth = newGameWidth;
    yPosBg = newGameHeight * 0.63;
    
    // 更新轨道位置和大小
    track1.position.y = yPosBg;
    track2.position.y = yPosBg;
    
    // 更新轨道宽度
    final trackWidth = math.max(track1.sprite!.srcSize.x, gameWidth / 2);
    track1.size = Vector2(trackWidth, track1.sprite!.srcSize.y);
    track2.size = Vector2(trackWidth, track2.sprite!.srcSize.y);
  }
}
