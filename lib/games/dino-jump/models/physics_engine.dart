import 'package:flutter/material.dart';

/// 恐龙游戏物理引擎
/// 负责处理恐龙的物理状态、重力、跳跃逻辑等
class PhysicsEngine {
  // 恐龙物理属性
  double dinoX = 50;           // 恐龙X坐标（固定）
  double dinoY = 0;            // 恐龙Y坐标（相对于地面，0=地面，正值=向上）
  double dinoWidth = 40;       // 恐龙宽度
  double dinoHeight = 40;      // 恐龙高度
  double dinoVelocityY = 0;    // 恐龙垂直速度（负值=向上，正值=向下）
  bool dinoOnGround = true;    // 恐龙是否在地面
  bool dinoDucking = false;    // 恐龙是否在蹲下状态
  
  // 物理参数 - 2024优化：提升高分段响应性
  static const double gravity = -1000;      // 重力加速度（增强25%，缩短跳跃时间）
  static const double jumpVelocity = 450;   // 跳跃初始速度（提升12.5%，保持跳跃高度）
  
  /// 重置恐龙物理状态
  void reset() {
    dinoY = 0;
    dinoVelocityY = 0;
    dinoOnGround = true;
    dinoDucking = false;  // 重置蹲下状态
  }
  
  /// 恐龙跳跃
  /// 只有在地面时且未蹲下才能跳跃
  bool jump() {
    if (dinoOnGround && !dinoDucking) {
      dinoVelocityY = jumpVelocity;  // 设置向上的初始速度
      dinoOnGround = false;          // 恐龙离开地面
      return true; // 跳跃成功
    }
    return false; // 跳跃失败（不在地面或正在蹲下）
  }
  
  /// 恐龙蹲下
  /// 只有在地面时才能蹲下
  bool duck() {
    if (dinoOnGround && !dinoDucking) {
      dinoDucking = true;  // 进入蹲下状态
      return true; // 蹲下成功
    }
    return false; // 蹲下失败（不在地面或已经在蹲下）
  }
  
  /// 停止蹲下
  void stopDucking() {
    dinoDucking = false;  // 退出蹲下状态
  }
  
  /// 更新恐龙物理状态
  /// [deltaTime] 时间间隔（秒）
  void update(double deltaTime) {
    if (!dinoOnGround) {
      // 应用重力（在dinoY坐标系中，向下为负值）
      dinoVelocityY += gravity * deltaTime;
      // 更新位置（dinoY坐标系中，正值表示向上）
      dinoY += dinoVelocityY * deltaTime;
      
      // 检查是否落地（dinoY <= 0 表示恐龙回到地面或低于地面）
      if (dinoY <= 0) {
        dinoY = 0;          // 重置到地面位置
        dinoVelocityY = 0;  // 重置垂直速度
        dinoOnGround = true; // 标记恐龙在地面
      }
    }
  }
  
  /// 获取恐龙的有效高度（蹲下时高度会减小）
  double getEffectiveHeight() {
    return dinoDucking ? dinoHeight * 0.5 : dinoHeight;  // 蹲下时高度减半
  }
  
  /// 获取恐龙在屏幕中的Y坐标（屏幕坐标系）
  /// [gameHeight] 游戏区域高度
  /// [groundHeight] 地面高度
  double getScreenY(double gameHeight, double groundHeight) {
    // 在屏幕坐标系中，恐龙的Y坐标 = 地面Y坐标 - 恐龙相对地面的高度 - 恐龙有效高度
    double groundY = gameHeight - groundHeight;
    return groundY - dinoY - getEffectiveHeight();
  }
  
  /// 获取恐龙的碰撞矩形（屏幕坐标系）
  /// 碰撞矩形稍微小一点以提供更好的游戏体验
  /// [gameHeight] 游戏区域高度
  /// [groundHeight] 地面高度
  Rect getCollisionRect(double gameHeight, double groundHeight) {
    double effectiveHeight = getEffectiveHeight();
    return Rect.fromLTWH(
      dinoX + 5, 
      getScreenY(gameHeight, groundHeight) + 5, 
      dinoWidth - 10, 
      effectiveHeight - 10  // 使用有效高度计算碰撞矩形
    );
  }
}
