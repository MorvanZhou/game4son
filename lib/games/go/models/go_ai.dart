import 'dart:math';
import 'package:flutter/material.dart';

import 'go_game_model.dart';

/// 围棋AI - 基于五子棋AI改进
/// 
/// 特点：
/// - 简化的围棋规则实现
/// - 基于势力和眼形的评估
/// - 支持基本的围棋战术
class GoAI {
  // 搜索参数
  int _searchDepth = 3;
  int _timeLimit = 1000; // 毫秒
  int _minSearchDepth = 1;
  int _maxCandidates = 20;
  
  // 搜索统计
  DateTime? _searchStartTime;
  int _nodesSearched = 0;
  int _currentDifficulty = 1;
  
  // 置换表（暂时未使用，为未来优化预留）
  // final int _hashTableSize = 1024;
  // late List<_HashEntry> _hashTable;
  
  // 随机数生成器
  final Random _random = Random();
  
  // 评估权重
  final Map<String, int> _evaluationWeights = {
    'STONE': 1,           // 基础棋子价值
    'EDGE': 5,            // 边角优势
    'CENTER': 3,          // 中央控制
    'INFLUENCE': 10,      // 势力范围
    'CAPTURE': 20,        // 提子价值
    'LIBERTY': 5,         // 气的价值
    'CONNECTION': 8,      // 连接价值
  };
  
  GoAI() {
    // 初始化置换表（未来可用于优化）
    // _hashTable = List.generate(_hashTableSize, (index) => _HashEntry());
  }
  
  /// 获取AI最佳移动
  List<int>? getBestMove(List<List<PieceType>> board, int difficulty, bool isBlackTurn) {
    _searchStartTime = DateTime.now();
    _nodesSearched = 0;
    _currentDifficulty = difficulty;
    
    // 根据难度设置搜索参数
    _configureSearchParameters(difficulty);
    
    // 处理特殊情况
    final specialMove = _handleSpecialCases(board, isBlackTurn);
    if (specialMove != null) return specialMove;
    
    // 简单模式：有概率走随机棋步
    if (difficulty == 0) {
      return _getEasyModeMove(board, isBlackTurn);
    }
    
    // 迭代加深搜索
    return _iterativeDeepeningSearch(board, isBlackTurn);
  }
  
  /// 配置搜索参数
  void _configureSearchParameters(int difficulty) {
    switch (difficulty) {
      case 0: // 简单
        _searchDepth = 2;
        _timeLimit = 1000; // 1秒
        break;
      case 1: // 中等
        _searchDepth = 3;
        _timeLimit = 3000; // 3秒
        break;
      case 2: // 困难
        _searchDepth = 4;
        _timeLimit = 5000; // 5秒
        break;
    }
  }
  
  /// 处理特殊情况
  List<int>? _handleSpecialCases(List<List<PieceType>> board, bool isBlackTurn) {
    // 开局：如果棋盘空，下在星位或天元
    if (_isEmptyBoard(board)) {
      final starPoints = [
        [3, 3], [3, 9], [3, 15],    // 上方星位
        [9, 3], [9, 9], [9, 15],    // 中间星位
        [15, 3], [15, 9], [15, 15], // 下方星位
      ];
      return starPoints[_random.nextInt(starPoints.length)];
    }
    
    // 检查是否有紧急的提子机会
    final captureMove = _findCaptureMove(board, isBlackTurn);
    if (captureMove != null) return captureMove;
    
    // 检查是否需要紧急逃子
    final escapeMove = _findEscapeMove(board, isBlackTurn);
    if (escapeMove != null) return escapeMove;
    
    return null;
  }
  
  /// 简单模式
  List<int>? _getEasyModeMove(List<List<PieceType>> board, bool isBlackTurn) {
    // 30% 概率走随机棋步
    if (_random.nextDouble() < 0.3) {
      final randomMove = _getRandomNearbyMove(board);
      if (randomMove != null) return randomMove;
    }
    
    // 其余情况走浅层搜索
    return _iterativeDeepeningSearch(board, isBlackTurn);
  }
  
  /// 获取随机的附近移动
  List<int>? _getRandomNearbyMove(List<List<PieceType>> board) {
    final nearbyMoves = <List<int>>[];
    
    // 找到所有有棋子附近的空位
    for (int row = 0; row < 19; row++) {
      for (int col = 0; col < 19; col++) {
        if (board[row][col] == PieceType.none && _hasNeighbor(board, row, col)) {
          nearbyMoves.add([row, col]);
        }
      }
    }
    
    if (nearbyMoves.isNotEmpty) {
      return nearbyMoves[_random.nextInt(nearbyMoves.length)];
    }
    
    // 如果没有附近位置，随机选择空位
    final emptyMoves = <List<int>>[];
    for (int row = 0; row < 19; row++) {
      for (int col = 0; col < 19; col++) {
        if (board[row][col] == PieceType.none) {
          emptyMoves.add([row, col]);
        }
      }
    }
    
    return emptyMoves.isNotEmpty ? emptyMoves[_random.nextInt(emptyMoves.length)] : null;
  }
  
  /// 迭代加深搜索
  List<int>? _iterativeDeepeningSearch(List<List<PieceType>> board, bool isBlackTurn) {
    List<int>? bestMove;
    
    for (int depth = _minSearchDepth; depth <= _searchDepth; depth++) {
      if (_isTimeUp()) break;
      
      final result = _alphaBetaSearch(board, depth, -999999, 999999, isBlackTurn);
      if (result != null && result['move'] != null) {
        bestMove = result['move'] as List<int>;
      }
    }
    
    // 输出搜索统计
    final searchTime = DateTime.now().difference(_searchStartTime!).inMilliseconds;
    debugPrint('围棋AI搜索完成: 深度=$_searchDepth, 节点=$_nodesSearched, 时间=${searchTime}ms');
    
    return bestMove;
  }
  
  /// Alpha-Beta搜索
  Map<String, dynamic>? _alphaBetaSearch(
    List<List<PieceType>> board, 
    int depth, 
    int alpha, 
    int beta, 
    bool isBlackTurn
  ) {
    _nodesSearched++;
    
    if (_nodesSearched % 50 == 0 && _isTimeUp()) {
      return null;
    }
    
    // 叶节点评估
    if (depth <= 0) {
      final value = _evaluateBoard(board, isBlackTurn);
      return {'value': value, 'move': null};
    }
    
    // 生成候选移动
    final candidates = _generateCandidateMoves(board);
    if (candidates.isEmpty) {
      return {'value': 0, 'move': null};
    }
    
    List<int>? bestMove;
    int bestValue = isBlackTurn ? -999999 : 999999;
    
    for (final move in candidates) {
      // 执行移动
      final newBoard = _makeMove(board, move, isBlackTurn ? PieceType.black : PieceType.white);
      
      // 递归搜索
      final result = _alphaBetaSearch(newBoard, depth - 1, alpha, beta, !isBlackTurn);
      if (result == null) break;
      
      final value = result['value'] as int;
      
      if (isBlackTurn) {
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
      
      if (beta <= alpha) break;
    }
    
    return {'value': bestValue, 'move': bestMove};
  }
  
  /// 生成候选移动
  List<List<int>> _generateCandidateMoves(List<List<PieceType>> board) {
    final candidates = <List<int>>[];
    final candidateScores = <int>[];
    
    // 扫描棋盘，寻找候选位置
    for (int row = 0; row < 19; row++) {
      for (int col = 0; col < 19; col++) {
        if (board[row][col] == PieceType.none) {
          // 只考虑有邻居的位置或星位
          if (_hasNeighbor(board, row, col) || _isStarPoint(row, col)) {
            final score = _evaluateMove(board, row, col);
            candidates.add([row, col]);
            candidateScores.add(score);
          }
        }
      }
    }
    
    // 按分数排序
    final indexedCandidates = List.generate(candidates.length, (i) => i);
    indexedCandidates.sort((a, b) => candidateScores[b].compareTo(candidateScores[a]));
    
    // 返回前N个最佳候选
    final result = <List<int>>[];
    for (int i = 0; i < min(_maxCandidates, indexedCandidates.length); i++) {
      result.add(candidates[indexedCandidates[i]]);
    }
    
    return result;
  }
  
  /// 评估棋盘局面
  int _evaluateBoard(List<List<PieceType>> board, bool isBlackTurn) {
    int blackScore = 0;
    int whiteScore = 0;
    
    // 计算基础分数
    for (int row = 0; row < 19; row++) {
      for (int col = 0; col < 19; col++) {
        if (board[row][col] == PieceType.black) {
          blackScore += _evaluateStone(board, row, col, PieceType.black);
        } else if (board[row][col] == PieceType.white) {
          whiteScore += _evaluateStone(board, row, col, PieceType.white);
        }
      }
    }
    
    // 简单模式：降低评估准确性
    if (_currentDifficulty == 0) {
      final noise = _random.nextInt(50) - 25;
      blackScore += noise;
    }
    
    return isBlackTurn ? (blackScore - whiteScore) : (whiteScore - blackScore);
  }
  
  /// 评估单个棋子的价值
  int _evaluateStone(List<List<PieceType>> board, int row, int col, PieceType piece) {
    int score = _evaluationWeights['STONE']!;
    
    // 边角优势
    if (_isCorner(row, col)) {
      score += _evaluationWeights['EDGE']! * 2;
    } else if (_isEdge(row, col)) {
      score += _evaluationWeights['EDGE']!;
    }
    
    // 中央控制
    final centerDistance = (row - 9).abs() + (col - 9).abs();
    if (centerDistance <= 4) {
      score += _evaluationWeights['CENTER']! * (5 - centerDistance);
    }
    
    // 连接度
    final connections = _countConnections(board, row, col, piece);
    score += connections * _evaluationWeights['CONNECTION']!;
    
    // 气的数量
    final liberties = _countLiberties(board, row, col);
    score += liberties * _evaluationWeights['LIBERTY']!;
    
    return score;
  }
  
  /// 评估单步移动
  int _evaluateMove(List<List<PieceType>> board, int row, int col) {
    int score = 0;
    
    // 基础位置价值
    if (_isStarPoint(row, col)) {
      score += 20;
    }
    
    // 中央倾向
    final centerDistance = (row - 9).abs() + (col - 9).abs();
    score += max(0, 18 - centerDistance);
    
    // 邻居数量
    final neighbors = _countNeighbors(board, row, col);
    score += neighbors * 5;
    
    return score;
  }
  
  /// 查找提子机会
  List<int>? _findCaptureMove(List<List<PieceType>> board, bool isBlackTurn) {
    final myPiece = isBlackTurn ? PieceType.black : PieceType.white;
    final opponentPiece = isBlackTurn ? PieceType.white : PieceType.black;
    
    for (int row = 0; row < 19; row++) {
      for (int col = 0; col < 19; col++) {
        if (board[row][col] == PieceType.none) {
          // 模拟下棋
          board[row][col] = myPiece;
          
          // 检查是否能提子
          if (_canCapture(board, row, col, opponentPiece)) {
            board[row][col] = PieceType.none;
            return [row, col];
          }
          
          board[row][col] = PieceType.none;
        }
      }
    }
    
    return null;
  }
  
  /// 查找逃子机会
  List<int>? _findEscapeMove(List<List<PieceType>> board, bool isBlackTurn) {
    final myPiece = isBlackTurn ? PieceType.black : PieceType.white;
    
    // 找到气少的己方棋子群
    for (int row = 0; row < 19; row++) {
      for (int col = 0; col < 19; col++) {
        if (board[row][col] == myPiece) {
          final liberties = _countLiberties(board, row, col);
          if (liberties <= 2) {
            // 寻找增加气的移动
            final escapeMove = _findEscapeMoveForGroup(board, row, col);
            if (escapeMove != null) return escapeMove;
          }
        }
      }
    }
    
    return null;
  }
  
  /// 为特定棋子群寻找逃子移动
  List<int>? _findEscapeMoveForGroup(List<List<PieceType>> board, int row, int col) {
    final directions = [[0, 1], [1, 0], [0, -1], [-1, 0]];
    
    for (final dir in directions) {
      final newRow = row + dir[0];
      final newCol = col + dir[1];
      
      if (_isValidPosition(newRow, newCol) && board[newRow][newCol] == PieceType.none) {
        return [newRow, newCol];
      }
    }
    
    return null;
  }
  
  // 辅助方法
  bool _isTimeUp() => DateTime.now().difference(_searchStartTime!).inMilliseconds >= _timeLimit;
  
  bool _isEmptyBoard(List<List<PieceType>> board) => 
    board.every((row) => row.every((cell) => cell == PieceType.none));
  
  bool _hasNeighbor(List<List<PieceType>> board, int row, int col) {
    const directions = [[0, 1], [1, 0], [0, -1], [-1, 0]];
    for (final dir in directions) {
      final r = row + dir[0], c = col + dir[1];
      if (_isValidPosition(r, c) && board[r][c] != PieceType.none) {
        return true;
      }
    }
    return false;
  }
  
  bool _isStarPoint(int row, int col) {
    const starPoints = [
      [3, 3], [3, 9], [3, 15],
      [9, 3], [9, 9], [9, 15],
      [15, 3], [15, 9], [15, 15],
    ];
    return starPoints.any((point) => point[0] == row && point[1] == col);
  }
  
  bool _isCorner(int row, int col) {
    return (row == 0 || row == 18) && (col == 0 || col == 18);
  }
  
  bool _isEdge(int row, int col) {
    return row == 0 || row == 18 || col == 0 || col == 18;
  }
  
  bool _isValidPosition(int row, int col) {
    return row >= 0 && row < 19 && col >= 0 && col < 19;
  }
  
  int _countConnections(List<List<PieceType>> board, int row, int col, PieceType piece) {
    int connections = 0;
    const directions = [[0, 1], [1, 0], [0, -1], [-1, 0]];
    
    for (final dir in directions) {
      final r = row + dir[0], c = col + dir[1];
      if (_isValidPosition(r, c) && board[r][c] == piece) {
        connections++;
      }
    }
    
    return connections;
  }
  
  int _countLiberties(List<List<PieceType>> board, int row, int col) {
    int liberties = 0;
    const directions = [[0, 1], [1, 0], [0, -1], [-1, 0]];
    
    for (final dir in directions) {
      final r = row + dir[0], c = col + dir[1];
      if (_isValidPosition(r, c) && board[r][c] == PieceType.none) {
        liberties++;
      }
    }
    
    return liberties;
  }
  
  int _countNeighbors(List<List<PieceType>> board, int row, int col) {
    int neighbors = 0;
    const directions = [[0, 1], [1, 0], [0, -1], [-1, 0]];
    
    for (final dir in directions) {
      final r = row + dir[0], c = col + dir[1];
      if (_isValidPosition(r, c) && board[r][c] != PieceType.none) {
        neighbors++;
      }
    }
    
    return neighbors;
  }
  
  bool _canCapture(List<List<PieceType>> board, int row, int col, PieceType opponentPiece) {
    const directions = [[0, 1], [1, 0], [0, -1], [-1, 0]];
    
    for (final dir in directions) {
      final adjRow = row + dir[0];
      final adjCol = col + dir[1];
      
      if (_isValidPosition(adjRow, adjCol) && board[adjRow][adjCol] == opponentPiece) {
        final liberties = _countLiberties(board, adjRow, adjCol);
        if (liberties == 0) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// 执行移动
  List<List<PieceType>> _makeMove(List<List<PieceType>> board, List<int> move, PieceType piece) {
    final newBoard = board.map((row) => List<PieceType>.from(row)).toList();
    newBoard[move[0]][move[1]] = piece;
    return newBoard;
  }
}
