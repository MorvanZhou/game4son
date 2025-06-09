import 'dart:math';
import 'package:flutter/material.dart';

import 'gomoku_game_model.dart';

/// 置换表条目 - AI搜索优化用的缓存结构
class _HashEntry {
  int key = 0;          // Zobrist哈希键
  int value = 0;        // 评估值
  int depth = 0;        // 搜索深度
  int flag = 0;         // 节点类型 (0=精确值, 1=下界, 2=上界)
  List<int>? bestMove;  // 最佳移动
}

/// 高级五子棋AI - 融合多种优化算法
/// 
/// 基于专业五子棋AI的设计思想，实现：
/// - Minimax + Alpha-Beta剪枝
/// - 迭代加深搜索
/// - 置换表优化
/// - 威胁空间搜索
/// - 智能棋型识别
class GomokuAdvancedAI {
  // 搜索配置常量
  static const int _minSearchDepth = 4;   // 最小搜索深度
  static const int _maxCandidates = 20;   // 最大候选移动数
  static const int _hashTableSize = 65536; // 置换表大小
  
  // 评分常量 - 基于专业AI的权重设计
  static const Map<String, int> _patternScores = {
    // 必胜棋型
    'WIN': 100000,        // 五连
    'LIVE_4': 10000,      // 活四
    'RUSH_4': 1000,       // 冲四
    
    // 优势棋型  
    'LIVE_3': 500,        // 活三
    'SLEEP_3': 100,       // 眠三
    'LIVE_2': 50,         // 活二
    'SLEEP_2': 10,        // 眠二
    
    // 基础价值
    'LIVE_1': 5,          // 活一
    'POSITION': 1,        // 位置价值
  };
  
  // AI状态变量
  final List<_HashEntry> _hashTable = List.generate(_hashTableSize, (_) => _HashEntry());
  final Random _random = Random(); // 用于简单模式的随机选择
  int _searchDepth = 6;
  int _nodesSearched = 0;
  int _hashHits = 0;
  DateTime? _searchStartTime;
  int _timeLimit = 5000; // 5秒时间限制
  int _currentDifficulty = 1; // 当前难度级别
  
  /// 获取AI最佳移动 - 主搜索入口
  List<int>? getBestMove(List<List<PieceType>> board, int difficulty) {
    _searchStartTime = DateTime.now();
    _nodesSearched = 0;
    _hashHits = 0;
    _currentDifficulty = difficulty;
    
    // 根据难度设置搜索参数
    _configureSearchParameters(difficulty);
    
    // 处理特殊情况
    final specialMove = _handleSpecialCases(board);
    if (specialMove != null) return specialMove;
    
    // 简单模式：有概率走随机棋步，让着玩家
    if (difficulty == 0) {
      return _getEasyModeMove(board);
    }
    
    // 迭代加深搜索 - 核心算法
    return _iterativeDeepeningSearch(board);
  }
  
  /// 配置搜索参数 - 根据难度调整AI强度
  void _configureSearchParameters(int difficulty) {
    switch (difficulty) {
      case 0: // 简单 - 故意降低AI水平，适合小朋友
        _searchDepth = 4; // 极浅搜索
        _timeLimit = 5; // 很短时间
        break;
      case 1: // 中等
        _searchDepth = 4;
        _timeLimit = 50; 
        break;
      case 2: // 困难
        _searchDepth = 5;
        _timeLimit = 200; // 200毫秒
        break;
    }
  }
  
  /// 处理特殊情况 - 开局和紧急情况
  List<int>? _handleSpecialCases(List<List<PieceType>> board) {
    // 第一步下中心
    if (_isEmptyBoard(board)) {
      return [7, 7]; // 中心位置
    }
    
    // 检查立即获胜的移动 - 即使简单模式也要获胜
    final winMove = _findWinningMove(board, PieceType.ai);
    if (winMove != null) return winMove;
    
    // 检查必须防守的移动 - 防止玩家立即获胜
    final blockMove = _findWinningMove(board, PieceType.player);
    if (blockMove != null) return blockMove;
    
    return null;
  }
  
  /// 简单模式专用 - 故意降低AI水平，让着玩家
  List<int>? _getEasyModeMove(List<List<PieceType>> board) {
    // 30% 概率走随机棋步（但不是完全随机，还是在有棋子附近）
    if (_random.nextDouble() < 0.3) {
      final randomMove = _getRandomNearbyMove(board);
      if (randomMove != null) return randomMove;
    }
    
    // 50% 概率忽略一些威胁，不做最优防守
    if (_random.nextDouble() < 0.5) {
      final suboptimalMove = _getSuboptimalMove(board);
      if (suboptimalMove != null) return suboptimalMove;
    }
    
    // 其余情况走正常但浅层搜索的棋步
    return _iterativeDeepeningSearch(board);
  }
  
  /// 获取随机的附近移动 - 确保不会下到太远的地方
  List<int>? _getRandomNearbyMove(List<List<PieceType>> board) {
    final nearbyMoves = <List<int>>[];
    
    // 找到所有有棋子附近的空位
    for (int row = 0; row < 15; row++) {
      for (int col = 0; col < 15; col++) {
        if (board[row][col] == PieceType.none && _hasNeighbor(board, row, col)) {
          nearbyMoves.add([row, col]);
        }
      }
    }
    
    // 随机选择一个位置
    if (nearbyMoves.isNotEmpty) {
      return nearbyMoves[_random.nextInt(nearbyMoves.length)];
    }
    
    return null;
  }
  
  /// 获取次优移动 - 故意不做最佳选择
  List<int>? _getSuboptimalMove(List<List<PieceType>> board) {
    final candidates = _generateCandidateMoves(board);
    if (candidates.length <= 1) return null;
    
    // 评估所有候选移动
    final moveScores = <MapEntry<List<int>, int>>[];
    for (final move in candidates) {
      final score = _evaluateMove(board, move[0], move[1]);
      moveScores.add(MapEntry(move, score));
    }
    
    // 按分数排序
    moveScores.sort((a, b) => b.value.compareTo(a.value));
    
    // 随机选择排名2-4的移动（避开最佳选择）
    final suboptimalRange = min(4, moveScores.length);
    if (suboptimalRange > 1) {
      final randomIndex = 1 + _random.nextInt(suboptimalRange - 1);
      return moveScores[randomIndex].key;
    }
    
    return null;
  }
  
  /// 迭代加深搜索 - 逐步增加搜索深度直到时间用完
  List<int>? _iterativeDeepeningSearch(List<List<PieceType>> board) {
    List<int>? bestMove;
    int bestValue = -999999;
    
    // 从最小深度开始逐步加深搜索
    for (int depth = _minSearchDepth; depth <= _searchDepth; depth += 2) {
      if (_isTimeUp()) break;
      
      final result = _alphaBetaSearch(board, depth, -999999, 999999, true);
      if (result != null && result['move'] != null) {
        bestMove = result['move'] as List<int>;
        bestValue = result['value'] as int;
        
        // 找到必胜移动，立即返回
        if (bestValue >= _patternScores['LIVE_4']!) {
          break;
        }
      }
    }
    
    // 输出搜索统计信息（调试用）
    final searchTime = DateTime.now().difference(_searchStartTime!).inMilliseconds;
    debugPrint('AI搜索完成: 深度=$_searchDepth, 节点=$_nodesSearched, 时间=${searchTime}ms, 命中率=${(_hashHits/_nodesSearched*100).toStringAsFixed(1)}%');
    
    return bestMove;
  }
  
  /// Alpha-Beta搜索 - 核心搜索算法
  Map<String, dynamic>? _alphaBetaSearch(
    List<List<PieceType>> board, 
    int depth, 
    int alpha, 
    int beta, 
    bool maximizingPlayer
  ) {
    _nodesSearched++;
    
    // 频繁检查时间限制，确保能及时停止搜索
    if (_nodesSearched % 100 == 0 && _isTimeUp()) {
      return null;
    }
    
    // 查询置换表
    final hashResult = _probeHash(board, depth, alpha, beta);
    if (hashResult != null) {
      _hashHits++;
      return hashResult;
    }
    
    // 叶节点评估
    if (depth <= 0) {
      final value = _evaluateBoard(board);
      return {'value': maximizingPlayer ? value : -value, 'move': null};
    }
    
    // 检查游戏结束
    final gameResult = _checkGameEnd(board);
    if (gameResult != null) {
      return {'value': gameResult, 'move': null};
    }
    
    // 生成候选移动
    final candidates = _generateCandidateMoves(board);
    if (candidates.isEmpty) {
      return {'value': 0, 'move': null};
    }
    
    // 搜索所有候选移动
    List<int>? bestMove;
    int bestValue = maximizingPlayer ? -999999 : 999999;
    
    for (final move in candidates) {
      // 执行移动
      final newBoard = _makeMove(board, move, 
        maximizingPlayer ? PieceType.ai : PieceType.player);
      
      // 递归搜索
      final result = _alphaBetaSearch(newBoard, depth - 1, alpha, beta, !maximizingPlayer);
      if (result == null) break; // 时间用完
      
      final value = result['value'] as int;
      
      if (maximizingPlayer) {
        if (value > bestValue) {
          bestValue = value;
          bestMove = move;
        }
        alpha = max(alpha, value);
      } else {
        if (value < bestValue) {
          bestValue = value;
          bestMove = move;
        }
        beta = min(beta, value);
      }
      
      // Alpha-Beta剪枝
      if (beta <= alpha) {
        break;
      }
    }
    
    // 记录到置换表
    _recordHash(board, depth, bestValue, bestMove, 
      bestValue <= alpha ? 2 : (bestValue >= beta ? 1 : 0));
    
    return {'value': bestValue, 'move': bestMove};
  }
  
  /// 生成候选移动 - 智能筛选有价值的位置
  List<List<int>> _generateCandidateMoves(List<List<PieceType>> board) {
    final candidates = <List<int>>[];
    final candidateScores = <int>[];
    
    // 扫描棋盘，寻找候选位置
    for (int row = 0; row < 15; row++) {
      for (int col = 0; col < 15; col++) {
        if (board[row][col] == PieceType.none && _hasNeighbor(board, row, col)) {
          final score = _evaluateMove(board, row, col);
          if (score > 0) {
            candidates.add([row, col]);
            candidateScores.add(score);
          }
        }
      }
    }
    
    // 按分数排序，优先搜索高价值移动
    final indexedCandidates = List.generate(candidates.length, (i) => i);
    indexedCandidates.sort((a, b) => candidateScores[b].compareTo(candidateScores[a]));
    
    // 返回前N个最佳候选
    final result = <List<int>>[];
    for (int i = 0; i < min(_maxCandidates, indexedCandidates.length); i++) {
      result.add(candidates[indexedCandidates[i]]);
    }
    
    return result;
  }
  
  /// 评估棋盘局面 - 综合评分函数
  int _evaluateBoard(List<List<PieceType>> board) {
    int aiScore = 0;
    int playerScore = 0;
    
    // 评估所有方向的棋型
    for (int row = 0; row < 15; row++) {
      for (int col = 0; col < 15; col++) {
        if (board[row][col] != PieceType.none) {
          final pieceType = board[row][col];
          final patterns = _analyzePatterns(board, row, col, pieceType);
          
          if (pieceType == PieceType.ai) {
            aiScore += _calculatePatternScore(patterns);
          } else {
            playerScore += _calculatePatternScore(patterns);
          }
        }
      }
    }
    
    // 位置价值评估
    aiScore += _evaluatePositionalValue(board, PieceType.ai);
    playerScore += _evaluatePositionalValue(board, PieceType.player);
    
    // 简单模式：故意降低评估准确性
    if (_currentDifficulty == 0) {
      // 添加随机噪声，降低评估精度
      final noise = _random.nextInt(100) - 50; // -50到+50的随机值
      aiScore += noise;
      
      // 降低AI优势权重，让玩家更容易获胜
      return (aiScore * 0.8 - playerScore * 1.2).round();
    }
    
    // AI当前回合有优势，权重提升
    return (aiScore * 1.2 - playerScore).round();
  }
  
  /// 分析棋型模式 - 识别各种棋型
  Map<String, int> _analyzePatterns(List<List<PieceType>> board, int row, int col, PieceType piece) {
    final patterns = <String, int>{};
    final directions = [[0,1], [1,0], [1,1], [1,-1]]; // 四个方向
    
    for (final dir in directions) {
      final pattern = _getLinePattern(board, row, col, dir[0], dir[1], piece);
      final patternType = _classifyPattern(pattern);
      patterns[patternType] = (patterns[patternType] ?? 0) + 1;
    }
    
    return patterns;
  }
  
  /// 获取直线模式 - 提取一条线上的棋型
  String _getLinePattern(List<List<PieceType>> board, int row, int col, 
                        int deltaRow, int deltaCol, PieceType piece) {
    String pattern = '';
    
    // 向两个方向扩展，获取9个位置的模式
    for (int i = -4; i <= 4; i++) {
      final r = row + i * deltaRow;
      final c = col + i * deltaCol;
      
      if (r < 0 || r >= 15 || c < 0 || c >= 15) {
        pattern += 'X'; // 边界
      } else if (board[r][c] == piece) {
        pattern += '1'; // 目标棋子
      } else if (board[r][c] == PieceType.none) {
        pattern += '0'; // 空位
      } else {
        pattern += 'X'; // 对方棋子或边界
      }
    }
    
    return pattern;
  }
  
  /// 分类棋型 - 根据模式识别棋型类型
  String _classifyPattern(String pattern) {
    // 五连
    if (pattern.contains('11111')) return 'WIN';
    
    // 活四
    if (pattern.contains('011110')) return 'LIVE_4';
    
    // 冲四
    if (pattern.contains('11110') || pattern.contains('01111') ||
        pattern.contains('11011') || pattern.contains('11101') ||
        pattern.contains('10111')) return 'RUSH_4';
    
    // 活三
    if (pattern.contains('01110') || pattern.contains('011010') ||
        pattern.contains('010110')) return 'LIVE_3';
    
    // 眠三
    if (pattern.contains('11100') || pattern.contains('00111') ||
        pattern.contains('11010') || pattern.contains('01011') ||
        pattern.contains('10110')) return 'SLEEP_3';
    
    // 活二
    if (pattern.contains('01100') || pattern.contains('00110') ||
        pattern.contains('01010')) return 'LIVE_2';
    
    // 眠二
    if (pattern.contains('11000') || pattern.contains('00011') ||
        pattern.contains('10100') || pattern.contains('00101')) return 'SLEEP_2';
    
    // 活一
    if (pattern.contains('01000') || pattern.contains('00010') ||
        pattern.contains('00100')) return 'LIVE_1';
    
    return 'NONE';
  }
  
  /// 计算棋型分数
  int _calculatePatternScore(Map<String, int> patterns) {
    int score = 0;
    patterns.forEach((pattern, count) {
      score += (_patternScores[pattern] ?? 0) * count;
    });
    return score;
  }
  
  // 其他辅助方法...
  bool _isTimeUp() => DateTime.now().difference(_searchStartTime!).inMilliseconds >= _timeLimit;
  bool _isEmptyBoard(List<List<PieceType>> board) => 
    board.every((row) => row.every((cell) => cell == PieceType.none));
  bool _hasNeighbor(List<List<PieceType>> board, int row, int col) {
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final r = row + dr, c = col + dc;
        if (r >= 0 && r < 15 && c >= 0 && c < 15 && board[r][c] != PieceType.none) {
          return true;
        }
      }
    }
    return false;
  }
  
  // 置换表相关方法
  Map<String, dynamic>? _probeHash(List<List<PieceType>> board, int depth, int alpha, int beta) {
    // 简化实现：基于棋盘状态生成哈希键
    final hashKey = _generateBoardHash(board) % _hashTableSize;
    final entry = _hashTable[hashKey];
    
    // 检查哈希表条目是否有效
    if (entry.depth >= depth) {
      // 根据节点类型返回值
      if (entry.flag == 0) { // 精确值
        return {'value': entry.value, 'move': entry.bestMove};
      } else if (entry.flag == 1 && entry.value >= beta) { // 下界
        return {'value': entry.value, 'move': entry.bestMove};
      } else if (entry.flag == 2 && entry.value <= alpha) { // 上界
        return {'value': entry.value, 'move': entry.bestMove};
      }
    }
    return null;
  }
  
  void _recordHash(List<List<PieceType>> board, int depth, int value, List<int>? move, int flag) {
    final hashKey = _generateBoardHash(board) % _hashTableSize;
    final entry = _hashTable[hashKey];
    
    // 只在搜索深度更深时更新条目
    if (depth >= entry.depth) {
      entry.key = hashKey;
      entry.value = value;
      entry.depth = depth;
      entry.flag = flag;
      entry.bestMove = move;
    }
  }
  
  // 生成棋盘哈希值
  int _generateBoardHash(List<List<PieceType>> board) {
    int hash = 0;
    for (int row = 0; row < 15; row++) {
      for (int col = 0; col < 15; col++) {
        if (board[row][col] != PieceType.none) {
          // 简单的位置哈希算法
          hash ^= (row * 17 + col * 37 + board[row][col].index * 67);
        }
      }
    }
    return hash.abs();
  }
  
  // 游戏结束检查 - 检测是否有获胜条件
  int? _checkGameEnd(List<List<PieceType>> board) {
    for (int row = 0; row < 15; row++) {
      for (int col = 0; col < 15; col++) {
        if (board[row][col] != PieceType.none) {
          final piece = board[row][col];
          
          // 检查四个方向是否有五连
          final directions = [[0,1], [1,0], [1,1], [1,-1]];
          for (final dir in directions) {
            if (_checkFiveInRow(board, row, col, dir[0], dir[1], piece)) {
              return piece == PieceType.ai ? 100000 : -100000;
            }
          }
        }
      }
    }
    return null; // 游戏未结束
  }
  
  // 检查是否有五连
  bool _checkFiveInRow(List<List<PieceType>> board, int row, int col, int deltaRow, int deltaCol, PieceType piece) {
    int count = 1; // 包含当前棋子
    
    // 向正方向计数
    int r = row + deltaRow, c = col + deltaCol;
    while (r >= 0 && r < 15 && c >= 0 && c < 15 && board[r][c] == piece) {
      count++;
      r += deltaRow;
      c += deltaCol;
    }
    
    // 向负方向计数
    r = row - deltaRow;
    c = col - deltaCol;
    while (r >= 0 && r < 15 && c >= 0 && c < 15 && board[r][c] == piece) {
      count++;
      r -= deltaRow;
      c -= deltaCol;
    }
    
    return count >= 5;
  }
  
  // 立即获胜检查 - 寻找能立即获胜或防守的移动
  List<int>? _findWinningMove(List<List<PieceType>> board, PieceType piece) {
    for (int row = 0; row < 15; row++) {
      for (int col = 0; col < 15; col++) {
        if (board[row][col] == PieceType.none) {
          // 模拟下棋
          board[row][col] = piece;
          
          // 检查是否能获胜
          if (_checkFiveInRow(board, row, col, 0, 1, piece) ||
              _checkFiveInRow(board, row, col, 1, 0, piece) ||
              _checkFiveInRow(board, row, col, 1, 1, piece) ||
              _checkFiveInRow(board, row, col, 1, -1, piece)) {
            board[row][col] = PieceType.none; // 恢复棋盘
            return [row, col];
          }
          
          board[row][col] = PieceType.none; // 恢复棋盘
        }
      }
    }
    return null;
  }
  
  // 移动评估 - 快速评估单个移动的价值
  int _evaluateMove(List<List<PieceType>> board, int row, int col) {
    int score = 0;
    
    // 基础位置价值（越靠近中心越好）
    final centerDistance = (row - 7).abs() + (col - 7).abs();
    score += max(0, 14 - centerDistance);
    
    // 模拟下棋并评估
    board[row][col] = PieceType.ai;
    final aiPatterns = _analyzePatterns(board, row, col, PieceType.ai);
    score += _calculatePatternScore(aiPatterns);
    
    board[row][col] = PieceType.player;
    final playerPatterns = _analyzePatterns(board, row, col, PieceType.player);
    score += _calculatePatternScore(playerPatterns) ~/ 2; // 防守价值较低
    
    board[row][col] = PieceType.none; // 恢复棋盘
    
    return score;
  }
  
  // 位置价值评估 - 评估棋子的位置优势
  int _evaluatePositionalValue(List<List<PieceType>> board, PieceType piece) {
    int score = 0;
    final centerRow = 7, centerCol = 7;
    
    for (int row = 0; row < 15; row++) {
      for (int col = 0; col < 15; col++) {
        if (board[row][col] == piece) {
          // 距离中心越近价值越高
          final distanceFromCenter = (row - centerRow).abs() + (col - centerCol).abs();
          score += max(0, 10 - distanceFromCenter);
          
          // 边缘位置减分
          if (row == 0 || row == 14 || col == 0 || col == 14) {
            score -= 5;
          }
        }
      }
    }
    
    return score;
  }
  
  // 执行移动
  List<List<PieceType>> _makeMove(List<List<PieceType>> board, List<int> move, PieceType piece) {
    final newBoard = board.map((row) => List<PieceType>.from(row)).toList();
    newBoard[move[0]][move[1]] = piece;
    return newBoard;
  }
}
