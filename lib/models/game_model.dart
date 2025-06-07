import 'package:flutter/material.dart';
import 'maze_generator.dart';

enum GameState { playing, paused, levelComplete, gameComplete }

class Player {
  int x, y;
  
  Player(this.x, this.y);
  
  void moveTo(int newX, int newY) {
    x = newX;
    y = newY;
  }
}

class GameModel extends ChangeNotifier {
  late List<List<Cell>> maze;
  late Player player;
  late int currentLevel;
  late int totalLevels;
  late GameState gameState;
  late int mazeWidth, mazeHeight;
  
  GameModel() {
    totalLevels = 15;
    currentLevel = 1;
    gameState = GameState.playing;
    _initializeLevel();
  }

  void _initializeLevel() {
    // Maze size increases with level
    mazeWidth = 8 + (currentLevel - 1) * 2;
    mazeHeight = 8 + (currentLevel - 1) * 2;
    
    // Ensure maze size doesn't get too large
    mazeWidth = mazeWidth.clamp(8, 20);
    mazeHeight = mazeHeight.clamp(8, 20);
    
    // Generate new maze
    MazeGenerator generator = MazeGenerator();
    maze = generator.generateMaze(mazeWidth, mazeHeight);
    
    // Place player at start (top-left)
    player = Player(0, 0);
    
    gameState = GameState.playing;
    notifyListeners();
  }

  bool movePlayer(Direction direction) {
    if (gameState != GameState.playing) return false;
    
    int newX = player.x;
    int newY = player.y;
    
    switch (direction) {
      case Direction.up:
        if (newY > 0 && !maze[newY][newX].topWall) {
          newY--;
        }
        break;
      case Direction.down:
        if (newY < mazeHeight - 1 && !maze[newY][newX].bottomWall) {
          newY++;
        }
        break;
      case Direction.left:
        if (newX > 0 && !maze[newY][newX].leftWall) {
          newX--;
        }
        break;
      case Direction.right:
        if (newX < mazeWidth - 1 && !maze[newY][newX].rightWall) {
          newX++;
        }
        break;
    }
    
    if (newX != player.x || newY != player.y) {
      player.moveTo(newX, newY);
      _checkWinCondition();
      notifyListeners();
      return true; // Movement successful
    }
    
    return false; // No movement occurred
  }

  void _checkWinCondition() {
    // Win condition: reach bottom-right corner
    if (player.x == mazeWidth - 1 && player.y == mazeHeight - 1) {
      if (currentLevel >= totalLevels) {
        gameState = GameState.gameComplete;
      } else {
        gameState = GameState.levelComplete;
      }
    }
  }

  void nextLevel() {
    if (currentLevel < totalLevels) {
      currentLevel++;
      _initializeLevel();
    }
  }

  void restartGame() {
    currentLevel = 1;
    _initializeLevel();
  }

  void pauseGame() {
    if (gameState == GameState.playing) {
      gameState = GameState.paused;
      notifyListeners();
    }
  }

  void resumeGame() {
    if (gameState == GameState.paused) {
      gameState = GameState.playing;
      notifyListeners();
    }
  }
}

enum Direction { up, down, left, right }
