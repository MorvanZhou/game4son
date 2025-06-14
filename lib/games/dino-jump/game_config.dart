/// 恐龙跳跃游戏的全局配置文件
/// 通过调整这里的缩放因子可以整体缩放所有游戏元素
class DinoGameConfig {
  // ========== 环境定义层 - 全局缩放因子 ==========
  // 调整这个参数可以整体缩放所有游戏元素，解决相对位移问题
  static const double GLOBAL_SCALE_FACTOR = 0.3;
  
  // 游戏基础常量（未缩放的原始值）
  static const double BASE_SCREEN_WIDTH = 800.0;
  static const double BASE_SCREEN_HEIGHT = 400.0;
  static const double BASE_GAME_SPEED = 4.0;
  static const double BASE_GROUND_Y = 380.0;
  
  // 恐龙基础常量
  static const double BASE_DINO_X = 80.0;
  static const double BASE_DINO_Y = 310.0;
  static const double BASE_DINO_DUCK_Y = 340.0;
  static const double BASE_JUMP_VEL = 7.6;
  static const double BASE_GRAVITY = 13.3;
  
  // UI基础常量
  static const double BASE_FONT_SIZE_LARGE = 30.0;
  static const double BASE_FONT_SIZE_MEDIUM = 20.0;
  static const double BASE_SCORE_OFFSET_X = 150.0;
  static const double BASE_SCORE_OFFSET_Y = 50.0;
  
  // 障碍物基础尺寸
  static const double BASE_SMALL_CACTUS_1_WIDTH = 40.0;
  static const double BASE_SMALL_CACTUS_1_HEIGHT = 71.0;
  static const double BASE_SMALL_CACTUS_2_WIDTH = 68.0;
  static const double BASE_SMALL_CACTUS_2_HEIGHT = 71.0;
  static const double BASE_SMALL_CACTUS_3_WIDTH = 105.0;
  static const double BASE_SMALL_CACTUS_3_HEIGHT = 71.0;
  
  static const double BASE_LARGE_CACTUS_1_WIDTH = 48.0;
  static const double BASE_LARGE_CACTUS_1_HEIGHT = 95.0;
  static const double BASE_LARGE_CACTUS_2_WIDTH = 99.0;
  static const double BASE_LARGE_CACTUS_2_HEIGHT = 95.0;
  static const double BASE_LARGE_CACTUS_3_WIDTH = 102.0;
  static const double BASE_LARGE_CACTUS_3_HEIGHT = 95.0;
  
  static const double BASE_BIRD_1_WIDTH = 97.0;
  static const double BASE_BIRD_1_HEIGHT = 68.0;
  static const double BASE_BIRD_2_WIDTH = 93.0;
  static const double BASE_BIRD_2_HEIGHT = 62.0;
  
  // 飞鸟高度偏移
  static const double BASE_BIRD_HEIGHT_OFFSET_1 = 20.0;
  static const double BASE_BIRD_HEIGHT_OFFSET_2 = 70.0;
  static const double BASE_BIRD_HEIGHT_OFFSET_3 = 130.0;
// 碰撞检测偏移
  static const double BASE_COLLISION_SHRINK_X = 6.0;
  static const double BASE_COLLISION_SHRINK_Y = 4.0;
  static const double BASE_BIRD_COLLISION_SHRINK_X = 10.0;
  static const double BASE_BIRD_COLLISION_SHRINK_Y = 8.0;
  
  // 云朵基础常量
  static const double BASE_CLOUD_SIZE = 80.0;
  static const double BASE_CLOUD_MIN_Y = 50.0;
  static const double BASE_CLOUD_MAX_Y = 100.0;
  static const double BASE_CLOUD_SPAWN_MIN = 800.0;
  static const double BASE_CLOUD_SPAWN_MAX = 1000.0;
  static const double BASE_CLOUD_RESPAWN_MIN = 2500.0;
  static const double BASE_CLOUD_RESPAWN_MAX = 3000.0;
  
  // 地面轨道基础常量
  static const double BASE_TRACK_WIDTH = 2400.0;
  static const double BASE_TRACK_HEIGHT = 24.0;
  
  // ========== 缩放后的值获取方法 ==========
  
  // 游戏尺寸
  static double get screenWidth => BASE_SCREEN_WIDTH * GLOBAL_SCALE_FACTOR;
  static double get screenHeight => BASE_SCREEN_HEIGHT * GLOBAL_SCALE_FACTOR;
  static int get gameSpeed => (BASE_GAME_SPEED * GLOBAL_SCALE_FACTOR).round();
  static double get groundY => BASE_GROUND_Y * GLOBAL_SCALE_FACTOR;
  
  // 恐龙参数
  static double get dinoX => BASE_DINO_X * GLOBAL_SCALE_FACTOR;
  static double get dinoY => BASE_DINO_Y * GLOBAL_SCALE_FACTOR;
  static double get dinoDuckY => BASE_DINO_DUCK_Y * GLOBAL_SCALE_FACTOR;
  static double get jumpVel => BASE_JUMP_VEL * GLOBAL_SCALE_FACTOR;
  static double get gravity => BASE_GRAVITY * GLOBAL_SCALE_FACTOR;
  
  // UI参数
  static double get fontSizeLarge => BASE_FONT_SIZE_LARGE * GLOBAL_SCALE_FACTOR;
  static double get fontSizeMedium => BASE_FONT_SIZE_MEDIUM * GLOBAL_SCALE_FACTOR;
  static double get scoreOffsetX => BASE_SCORE_OFFSET_X * GLOBAL_SCALE_FACTOR;
  static double get scoreOffsetY => BASE_SCORE_OFFSET_Y * GLOBAL_SCALE_FACTOR;
  
  // 障碍物尺寸
  static double get smallCactus1Width => BASE_SMALL_CACTUS_1_WIDTH * GLOBAL_SCALE_FACTOR;
  static double get smallCactus1Height => BASE_SMALL_CACTUS_1_HEIGHT * GLOBAL_SCALE_FACTOR;
  static double get smallCactus2Width => BASE_SMALL_CACTUS_2_WIDTH * GLOBAL_SCALE_FACTOR;
  static double get smallCactus2Height => BASE_SMALL_CACTUS_2_HEIGHT * GLOBAL_SCALE_FACTOR;
  static double get smallCactus3Width => BASE_SMALL_CACTUS_3_WIDTH * GLOBAL_SCALE_FACTOR;
  static double get smallCactus3Height => BASE_SMALL_CACTUS_3_HEIGHT * GLOBAL_SCALE_FACTOR;
  
  static double get largeCactus1Width => BASE_LARGE_CACTUS_1_WIDTH * GLOBAL_SCALE_FACTOR;
  static double get largeCactus1Height => BASE_LARGE_CACTUS_1_HEIGHT * GLOBAL_SCALE_FACTOR;
  static double get largeCactus2Width => BASE_LARGE_CACTUS_2_WIDTH * GLOBAL_SCALE_FACTOR;
  static double get largeCactus2Height => BASE_LARGE_CACTUS_2_HEIGHT * GLOBAL_SCALE_FACTOR;
  static double get largeCactus3Width => BASE_LARGE_CACTUS_3_WIDTH * GLOBAL_SCALE_FACTOR;
  static double get largeCactus3Height => BASE_LARGE_CACTUS_3_HEIGHT * GLOBAL_SCALE_FACTOR;
  
  static double get bird1Width => BASE_BIRD_1_WIDTH * GLOBAL_SCALE_FACTOR;
  static double get bird1Height => BASE_BIRD_1_HEIGHT * GLOBAL_SCALE_FACTOR;
  static double get bird2Width => BASE_BIRD_2_WIDTH * GLOBAL_SCALE_FACTOR;
  static double get bird2Height => BASE_BIRD_2_HEIGHT * GLOBAL_SCALE_FACTOR;
  
  // 飞鸟高度偏移
  static double get birdHeightOffset1 => BASE_BIRD_HEIGHT_OFFSET_1 * GLOBAL_SCALE_FACTOR;
  static double get birdHeightOffset2 => BASE_BIRD_HEIGHT_OFFSET_2 * GLOBAL_SCALE_FACTOR;
  static double get birdHeightOffset3 => BASE_BIRD_HEIGHT_OFFSET_3 * GLOBAL_SCALE_FACTOR;
  
  // 云朵参数
  static double get cloudSize => BASE_CLOUD_SIZE * GLOBAL_SCALE_FACTOR;
  static double get cloudMinY => BASE_CLOUD_MIN_Y * GLOBAL_SCALE_FACTOR;
  static double get cloudMaxY => BASE_CLOUD_MAX_Y * GLOBAL_SCALE_FACTOR;
  static double get cloudSpawnMin => BASE_CLOUD_SPAWN_MIN * GLOBAL_SCALE_FACTOR;
  static double get cloudSpawnMax => BASE_CLOUD_SPAWN_MAX * GLOBAL_SCALE_FACTOR;
  static double get cloudRespawnMin => BASE_CLOUD_RESPAWN_MIN * GLOBAL_SCALE_FACTOR;
  static double get cloudRespawnMax => BASE_CLOUD_RESPAWN_MAX * GLOBAL_SCALE_FACTOR;
  
  // 地面轨道参数
  static double get trackWidth => BASE_TRACK_WIDTH * GLOBAL_SCALE_FACTOR;
  static double get trackHeight => BASE_TRACK_HEIGHT * GLOBAL_SCALE_FACTOR;
  
  // 碰撞检测偏移
  static double get collisionShrinkX => BASE_COLLISION_SHRINK_X * GLOBAL_SCALE_FACTOR;
  static double get collisionShrinkY => BASE_COLLISION_SHRINK_Y * GLOBAL_SCALE_FACTOR;
  static double get birdCollisionShrinkX => BASE_BIRD_COLLISION_SHRINK_X * GLOBAL_SCALE_FACTOR;
  static double get birdCollisionShrinkY => BASE_BIRD_COLLISION_SHRINK_Y * GLOBAL_SCALE_FACTOR;
}
