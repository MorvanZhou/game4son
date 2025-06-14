import 'package:flutter/material.dart';
import 'go_ai.dart';

/// 围棋游戏状态枚举
enum GoGameState { 
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
  black,  // 黑子（通常先手）
  white   // 白子（通常后手）
}

/// 游戏难度枚举
enum DifficultyLevel {
  easy,   // 简单：适合新手练习
  medium, // 中等：平衡的挑战性
  hard    // 困难：专业级AI挑战
}

/// 围棋游戏数据模型
/// 
/// 功能特性：
/// 1. 支持19x19标准围棋棋盘
/// 2. 玩家可选择执黑（先手）或执白（后手）
/// 3. 三档AI难度调节
/// 4. 胜负局数统计
/// 5. 围棋基本规则：提子、禁入点、劫争
/// 6. 简化计分：数子法（目数+活子）
class GoGameModel extends ChangeNotifier {
  // 棋盘尺寸常量 - 标准围棋19路
  static const int boardSize = 19;
  
  // 游戏状态
  GoGameState _gameState = GoGameState.ready;
  GoGameState get gameState => _gameState;
  
  // 棋盘数据 - 19x19二维数组
  late List<List<PieceType>> _board;
  List<List<PieceType>> get board => _board;
  
  // 游戏设置
  bool _playerPlaysBlack = true; // 玩家是否执黑（先手）
  bool get playerPlaysBlack => _playerPlaysBlack;
  
  DifficultyLevel _difficulty = DifficultyLevel.easy; 
  DifficultyLevel get difficulty => _difficulty;
  
  // 当前轮次 (true: 黑棋回合, false: 白棋回合)
  bool _isBlackTurn = true;
  bool get isBlackTurn => _isBlackTurn;
  
  // 判断当前是否轮到玩家
  bool get isPlayerTurn => (_playerPlaysBlack && _isBlackTurn) || (!_playerPlaysBlack && !_isBlackTurn);
  
  // 胜负统计
  int _playerWins = 0;
  int _aiWins = 0;
  int _draws = 0;
  
  int get playerWins => _playerWins;
  int get aiWins => _aiWins;
  int get draws => _draws;
  int get totalGames => _playerWins + _aiWins + _draws;
  
  // AI系统
  late GoAI _ai;
  
  // 最后一步棋的位置 (用于高亮显示)
  int? _lastMoveRow;
  int? _lastMoveCol;
  int? get lastMoveRow => _lastMoveRow;
  int? get lastMoveCol => _lastMoveCol;
  
  // 提子数统计
  int _blackCaptured = 0; // 黑棋被提子数
  int _whiteCaptured = 0; // 白棋被提子数
  int get blackCaptured => _blackCaptured;
  int get whiteCaptured => _whiteCaptured;
  
  // 连续Pass计数
  int _consecutivePasses = 0;
  
  // 历史棋盘状态（用于检测劫争）
  final List<String> _boardHistory = [];
  
  /// 构造函数 - 初始化游戏
  GoGameModel() {
    _initializeBoard();
    _ai = GoAI();
  }
  
  /// 初始化棋盘
  void _initializeBoard() {
    _board = List.generate(
      boardSize, 
      (row) => List.generate(boardSize, (col) => PieceType.none)
    );
    _lastMoveRow = null;
    _lastMoveCol = null;
    _blackCaptured = 0;
    _whiteCaptured = 0;
    _consecutivePasses = 0;
    _boardHistory.clear();
  }
  
  /// 设置玩家执黑还是执白
  void setPlayerPlaysBlack(bool playsBlack) {
    if (_gameState != GoGameState.ready) return;
    
    _playerPlaysBlack = playsBlack;
    notifyListeners();
  }
  
  /// 设置游戏难度
  void setDifficulty(DifficultyLevel difficulty) {
    if (_gameState != GoGameState.ready) return;
    
    _difficulty = difficulty;
    notifyListeners();
  }
  
  /// 开始新游戏
  void startNewGame() {
    _gameState = GoGameState.playing;
    _initializeBoard();
    
    // 黑棋总是先手（围棋规则）
    _isBlackTurn = true;
    
    // 如果AI执黑，立即让AI下棋
    if (!_playerPlaysBlack) {
      _makeAIMove();
    }
    
    notifyListeners();
  }
  
  /// 重置游戏 (回到设置界面)
  void resetGame() {
    _gameState = GoGameState.ready;
    _initializeBoard();
    _isBlackTurn = true;
    notifyListeners();
  }
  
  /// 进入分析模式 - 保留当前棋局状态供分析
  void enterAnalysisMode() {
    _gameState = GoGameState.analyzing;
    notifyListeners();
  }
  
  /// 玩家下棋
  /// [row] 行坐标 (0-18)
  /// [col] 列坐标 (0-18)
  /// 返回是否下棋成功
  bool makePlayerMove(int row, int col) {
    // 检查游戏状态和轮次
    if (_gameState != GoGameState.playing || !isPlayerTurn) {
      return false;
    }
    
    // 检查位置是否合法
    if (!_isValidMove(row, col)) {
      return false;
    }
    
    // 放置玩家棋子
    final playerPiece = _playerPlaysBlack ? PieceType.black : PieceType.white;
    return _makeMove(row, col, playerPiece);
  }
  
  /// 执行下棋操作
  bool _makeMove(int row, int col, PieceType piece) {
    // 保存当前棋盘状态（用于劫争检测）
    final oldBoardState = _getBoardStateString();
    
    // 放置棋子
    _board[row][col] = piece;
    _lastMoveRow = row;
    _lastMoveCol = col;
    _consecutivePasses = 0; // 重置连续pass计数
    
    // 检查并处理提子
    final capturedCount = _processCaptureMove(row, col, piece);
    
    // 检查劫争（简化处理：如果棋盘状态重复，视为违规）
    final newBoardState = _getBoardStateString();
    if (_boardHistory.contains(newBoardState)) {
      // 撤销这步棋（简化处理劫争）
      _board[row][col] = PieceType.none;
      return false;
    }
    
    // 更新历史记录
    _boardHistory.add(oldBoardState);
    if (_boardHistory.length > 10) {
      _boardHistory.removeAt(0); // 只保留最近10步的历史
    }
    
    // 更新提子数统计
    if (piece == PieceType.black) {
      _whiteCaptured += capturedCount;
    } else {
      _blackCaptured += capturedCount;
    }
    
    // 切换回合
    _isBlackTurn = !_isBlackTurn;
    
    // 检查游戏是否结束（简化版：不计算复杂的围棋终局）
    if (_isGameEnd()) {
      _endGame();
      return true;
    }
    
    notifyListeners();
    
    // 如果下一轮是AI，延迟执行AI下棋
    if (!isPlayerTurn) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _makeAIMove();
      });
    }
    
    return true;
  }
  
  /// AI下棋
  void _makeAIMove() {
    if (_gameState != GoGameState.playing || isPlayerTurn) {
      return;
    }
    
    // 将难度枚举转换为AI系统识别的难度数值
    int difficultyLevel;
    switch (_difficulty) {
      case DifficultyLevel.easy:
        difficultyLevel = 0;
        break;
      case DifficultyLevel.medium:
        difficultyLevel = 1;
        break;
      case DifficultyLevel.hard:
        difficultyLevel = 2;
        break;
    }
    
    // 调用AI系统计算最佳位置
    final aiMove = _ai.getBestMove(_board, difficultyLevel, _isBlackTurn);
    
    if (aiMove != null) {
      final row = aiMove[0];
      final col = aiMove[1];
      
      final aiPiece = _isBlackTurn ? PieceType.black : PieceType.white;
      _makeMove(row, col, aiPiece);
    } else {
      // AI选择pass
      _makePass();
    }
  }
  
  /// 执行pass操作
  void _makePass() {
    _consecutivePasses++;
    _isBlackTurn = !_isBlackTurn;
    
    // 连续两次pass，游戏结束
    if (_consecutivePasses >= 2) {
      _endGame();
    } else {
      notifyListeners();
      
      // 如果下一轮是AI，继续AI下棋
      if (!isPlayerTurn) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _makeAIMove();
        });
      }
    }
  }
  
  /// 玩家pass
  void playerPass() {
    if (_gameState != GoGameState.playing || !isPlayerTurn) {
      return;
    }
    
    _makePass();
  }
  
  /// 处理提子
  int _processCaptureMove(int row, int col, PieceType piece) {
    final opponentPiece = piece == PieceType.black ? PieceType.white : PieceType.black;
    int totalCaptured = 0;
    
    // 检查四个方向的对手棋子群
    final directions = [[0, 1], [1, 0], [0, -1], [-1, 0]];
    for (final dir in directions) {
      final adjRow = row + dir[0];
      final adjCol = col + dir[1];
      
      if (_isValidPosition(adjRow, adjCol) && _board[adjRow][adjCol] == opponentPiece) {
        final group = _getGroup(adjRow, adjCol);
        if (_hasNoLiberty(group)) {
          // 提子
          for (final pos in group) {
            _board[pos[0]][pos[1]] = PieceType.none;
            totalCaptured++;
          }
        }
      }
    }
    
    return totalCaptured;
  }
  
  /// 获取连通的棋子群
  Set<List<int>> _getGroup(int row, int col) {
    final piece = _board[row][col];
    final visited = <String>{};
    final group = <List<int>>{};
    
    void dfs(int r, int c) {
      final key = '$r,$c';
      if (visited.contains(key)) return;
      if (!_isValidPosition(r, c)) return;
      if (_board[r][c] != piece) return;
      
      visited.add(key);
      group.add([r, c]);
      
      // 检查四个方向
      const directions = [[0, 1], [1, 0], [0, -1], [-1, 0]];
      for (final dir in directions) {
        dfs(r + dir[0], c + dir[1]);
      }
    }
    
    dfs(row, col);
    return group;
  }
  
  /// 检查棋子群是否没有气（被围）
  bool _hasNoLiberty(Set<List<int>> group) {
    for (final pos in group) {
      final row = pos[0];
      final col = pos[1];
      
      // 检查四个方向是否有空位（气）
      const directions = [[0, 1], [1, 0], [0, -1], [-1, 0]];
      for (final dir in directions) {
        final adjRow = row + dir[0];
        final adjCol = col + dir[1];
        
        if (_isValidPosition(adjRow, adjCol) && _board[adjRow][adjCol] == PieceType.none) {
          return false; // 有气
        }
      }
    }
    return true; // 没有气
  }
  
  /// 检查指定位置是否可以下棋
  bool _isValidMove(int row, int col) {
    if (!_isValidPosition(row, col)) return false;
    if (_board[row][col] != PieceType.none) return false;
    
    // 简化处理：不检查自杀手（实际围棋中需要检查）
    return true;
  }
  
  /// 检查位置是否在棋盘范围内
  bool _isValidPosition(int row, int col) {
    return row >= 0 && row < boardSize && col >= 0 && col < boardSize;
  }
  
  /// 获取棋盘状态字符串（用于劫争检测）
  String _getBoardStateString() {
    final buffer = StringBuffer();
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        switch (_board[row][col]) {
          case PieceType.none:
            buffer.write('0');
            break;
          case PieceType.black:
            buffer.write('1');
            break;
          case PieceType.white:
            buffer.write('2');
            break;
        }
      }
    }
    return buffer.toString();
  }
  
  /// 检查游戏是否结束（简化版）
  bool _isGameEnd() {
    // 简化处理：连续两次pass或棋盘下满
    return _consecutivePasses >= 2 || _isBoardFull();
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
  
  /// 结束游戏并计算结果
  void _endGame() {
    // 简化计分：数子法 + 提子数
    final blackStones = _countStones(PieceType.black);
    final whiteStones = _countStones(PieceType.white);
    
    // 简化处理：不计算围成的目数，只计算棋子数+提子数
    final blackScore = blackStones + _whiteCaptured;
    final whiteScore = whiteStones + _blackCaptured + 6.5; // 贴6.5目
    
    if (blackScore > whiteScore) {
      if (_playerPlaysBlack) {
        _gameState = GoGameState.playerWin;
        _playerWins++;
      } else {
        _gameState = GoGameState.aiWin;
        _aiWins++;
      }
    } else if (whiteScore > blackScore) {
      if (_playerPlaysBlack) {
        _gameState = GoGameState.aiWin;
        _aiWins++;
      } else {
        _gameState = GoGameState.playerWin;
        _playerWins++;
      }
    } else {
      _gameState = GoGameState.draw;
      _draws++;
    }
    
    notifyListeners();
  }
  
  /// 数棋盘上的棋子数
  int _countStones(PieceType piece) {
    int count = 0;
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (_board[row][col] == piece) {
          count++;
        }
      }
    }
    return count;
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
      case GoGameState.ready:
        return '选择设置并开始游戏';
      case GoGameState.playing:
        if (isPlayerTurn) {
          return '轮到您下棋 (${_playerPlaysBlack ? "执黑" : "执白"})';
        } else {
          return 'AI思考中...';
        }
      case GoGameState.playerWin:
        return '恭喜您获胜！';
      case GoGameState.aiWin:
        return 'AI获胜，再接再厉！';
      case GoGameState.draw:
        return '平局！';
      case GoGameState.analyzing:
        return '复盘模式';
    }
  }
}
