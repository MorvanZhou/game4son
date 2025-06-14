import 'package:flutter/material.dart';
import 'gomoku_ai.dart';

/// 五子棋游戏状态枚举
enum GomokuGameState { 
  ready,        // 准备状态 - 选择先后手和难度
  playing,      // 游戏进行中
  playerWin,    // 玩家获胜
  aiWin,        // AI获胜
  draw,         // 平局
  analyzing     // 分析模式 - 游戏结束后查看棋局
}

/// 棋子类型
enum PieceType { 
  none,   // 空位
  player, // 玩家棋子 (黑子)
  ai      // AI棋子 (白子)
}

/// 游戏难度枚举 - 高级AI智能度
enum DifficultyLevel {
  easy,   // 简单：搜索深度4，时间限制1秒，适合新手练习
  medium, // 中等：搜索深度6，时间限制3秒，平衡的挑战性
  hard    // 困难：搜索深度8，时间限制5秒，专业级AI挑战
}

/// 五子棋游戏数据模型
/// 
/// 功能特性：
/// 1. 支持15x15标准棋盘
/// 2. 玩家可选择先手或后手
/// 3. 三档AI难度调节
/// 4. 胜负局数统计
/// 5. Minimax + Alpha-Beta剪枝AI算法
class GomokuGameModel extends ChangeNotifier {
  // 棋盘尺寸常量
  static const int boardSize = 15;
  
  // 游戏状态
  GomokuGameState _gameState = GomokuGameState.ready;
  GomokuGameState get gameState => _gameState;
  
  // 棋盘数据 - 15x15二维数组
  late List<List<PieceType>> _board;
  List<List<PieceType>> get board => _board;
  
  // 游戏设置
  bool _playerGoesFirst = true; // 玩家是否先手
  bool get playerGoesFirst => _playerGoesFirst;
  
  DifficultyLevel _difficulty = DifficultyLevel.easy; 
  DifficultyLevel get difficulty => _difficulty;
  
  // 当前轮次 (true: 玩家回合, false: AI回合)
  bool _isPlayerTurn = true;
  bool get isPlayerTurn => _isPlayerTurn;
  
  // 胜负统计
  int _playerWins = 0;
  int _aiWins = 0;
  int _draws = 0;
  
  int get playerWins => _playerWins;
  int get aiWins => _aiWins;
  int get draws => _draws;
  int get totalGames => _playerWins + _aiWins + _draws;
  
  // AI系统
  late GomokuAdvancedAI _ai;
  
  // 最后一步棋的位置 (用于高亮显示)
  int? _lastMoveRow;
  int? _lastMoveCol;
  int? get lastMoveRow => _lastMoveRow;
  int? get lastMoveCol => _lastMoveCol;
  
  /// 构造函数 - 初始化游戏
  GomokuGameModel() {
    _initializeBoard();
    _ai = GomokuAdvancedAI();
  }
  
  /// 初始化棋盘
  void _initializeBoard() {
    _board = List.generate(
      boardSize, 
      (row) => List.generate(boardSize, (col) => PieceType.none)
    );
    _lastMoveRow = null;
    _lastMoveCol = null;
  }
  
  /// 设置玩家是否先手
  void setPlayerGoesFirst(bool goesFirst) {
    if (_gameState != GomokuGameState.ready) return;
    
    _playerGoesFirst = goesFirst;
    notifyListeners();
  }
  
  /// 设置游戏难度
  void setDifficulty(DifficultyLevel difficulty) {
    if (_gameState != GomokuGameState.ready) return;
    
    _difficulty = difficulty;
    notifyListeners();
  }
  
  /// 开始新游戏
  void startNewGame() {
    _gameState = GomokuGameState.playing;
    _initializeBoard();
    
    // 根据设置决定谁先手
    _isPlayerTurn = _playerGoesFirst;
    
    // 如果AI先手，立即让AI下棋
    if (!_isPlayerTurn) {
      _makeAIMove();
    }
    
    notifyListeners();
  }
  
  /// 重置游戏 (回到设置界面)
  void resetGame() {
    _gameState = GomokuGameState.ready;
    _initializeBoard();
    _isPlayerTurn = _playerGoesFirst;
    notifyListeners();
  }
  
  /// 进入分析模式 - 保留当前棋局状态供分析
  void enterAnalysisMode() {
    _gameState = GomokuGameState.analyzing;
    notifyListeners();
  }
  
  /// 玩家下棋
  /// [row] 行坐标 (0-14)
  /// [col] 列坐标 (0-14)
  /// 返回是否下棋成功
  bool makePlayerMove(int row, int col) {
    // 检查游戏状态和轮次
    if (_gameState != GomokuGameState.playing || !_isPlayerTurn) {
      return false;
    }
    
    // 检查位置是否合法
    if (!_isValidMove(row, col)) {
      return false;
    }
    
    // 放置玩家棋子
    _board[row][col] = PieceType.player;
    _lastMoveRow = row;
    _lastMoveCol = col;
    
    // 检查游戏结果
    if (_checkWinner(row, col, PieceType.player)) {
      _gameState = GomokuGameState.playerWin;
      _playerWins++;
      notifyListeners();
      return true;
    }
    
    // 检查平局
    if (_isBoardFull()) {
      _gameState = GomokuGameState.draw;
      _draws++;
      notifyListeners();
      return true;
    }
    
    // 切换到AI回合
    _isPlayerTurn = false;
    notifyListeners();
    
    // AI下棋 (延迟执行，避免界面卡顿)
    Future.delayed(const Duration(milliseconds: 300), () {
      _makeAIMove();
    });
    
    return true;
  }
  
  /// AI下棋 - 优化版本
  void _makeAIMove() {
    if (_gameState != GomokuGameState.playing || _isPlayerTurn) {
      return;
    }
    
    // 将难度枚举转换为AI系统识别的难度数值
    int difficultyLevel;
    switch (_difficulty) {
      case DifficultyLevel.easy:
        difficultyLevel = 0; // 简单：搜索深度4，时间限制1秒
        break;
      case DifficultyLevel.medium:
        difficultyLevel = 1; // 中等：搜索深度6，时间限制3秒
        break;
      case DifficultyLevel.hard:
        difficultyLevel = 2; // 困难：搜索深度8，时间限制5秒
        break;
    }
    
    // 调用高级AI系统计算最佳位置
    final aiMove = _ai.getBestMove(_board, difficultyLevel);
    
    if (aiMove != null) {
      final row = aiMove[0];
      final col = aiMove[1];
      
      // 放置AI棋子
      _board[row][col] = PieceType.ai;
      _lastMoveRow = row;
      _lastMoveCol = col;
      
      // 检查游戏结果
      if (_checkWinner(row, col, PieceType.ai)) {
        _gameState = GomokuGameState.aiWin;
        _aiWins++;
        notifyListeners();
        return;
      }
      
      // 检查平局
      if (_isBoardFull()) {
        _gameState = GomokuGameState.draw;
        _draws++;
        notifyListeners();
        return;
      }
      
      // 切换到玩家回合
      _isPlayerTurn = true;
    }
    
    notifyListeners();
  }
  
  /// 检查指定位置是否可以下棋
  bool _isValidMove(int row, int col) {
    if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) {
      return false;
    }
    return _board[row][col] == PieceType.none;
  }
  
  /// 检查棋盘是否已满
  bool _isBoardFull() {
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (_board[row][col] == PieceType.none) {
          return false;
        }
      }
    }
    return true;
  }
  
  /// 检查指定位置的棋子是否获胜
  /// 
  /// [row] 最后下棋的行
  /// [col] 最后下棋的列  
  /// [piece] 要检查的棋子类型
  /// 返回是否构成五子连珠
  bool _checkWinner(int row, int col, PieceType piece) {
    // 检查四个方向：水平、垂直、主对角线、副对角线
    const directions = [
      [0, 1],   // 水平方向
      [1, 0],   // 垂直方向
      [1, 1],   // 主对角线
      [1, -1],  // 副对角线
    ];
    
    for (final direction in directions) {
      final dRow = direction[0];
      final dCol = direction[1];
      
      int count = 1; // 包含当前位置
      
      // 向正方向计数
      int r = row + dRow;
      int c = col + dCol;
      while (r >= 0 && r < boardSize && c >= 0 && c < boardSize && 
             _board[r][c] == piece) {
        count++;
        r += dRow;
        c += dCol;
      }
      
      // 向负方向计数
      r = row - dRow;
      c = col - dCol;
      while (r >= 0 && r < boardSize && c >= 0 && c < boardSize && 
             _board[r][c] == piece) {
        count++;
        r -= dRow;
        c -= dCol;
      }
      
      // 如果连续5个或以上，获胜
      if (count >= 5) {
        return true;
      }
    }
    
    return false;
  }
  
  /// 获取难度描述文本
  String getDifficultyText() {
    switch (_difficulty) {
      case DifficultyLevel.easy:
        return '简单';
      case DifficultyLevel.medium:
        return '中等';
      case DifficultyLevel.hard:
        return '困难';
    }
  }
  
  /// 获取游戏状态描述文本
  String getGameStateText() {
    switch (_gameState) {
      case GomokuGameState.ready:
        return '选择设置并开始游戏';
      case GomokuGameState.playing:
        return _isPlayerTurn ? '轮到你下棋' : 'AI思考中...';
      case GomokuGameState.playerWin:
        return '恭喜！你获胜了！';
      case GomokuGameState.aiWin:
        return 'AI获胜，再接再厉！';
      case GomokuGameState.draw:
        return '平局！棋力相当！';
      case GomokuGameState.analyzing:
        return '分析模式 - 复盘当前棋局';
    }
  }
  
  /// 获取胜率统计
  double getWinRate() {
    if (totalGames == 0) return 0.0;
    return _playerWins / totalGames;
  }
}
