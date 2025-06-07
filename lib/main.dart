import 'package:flutter/material.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(const MazeGame());
}

class MazeGame extends StatelessWidget {
  const MazeGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cyber Maze',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FFFF), // Cyan
          secondary: Color(0xFFFF0080), // Magenta
          surface: Color(0xFF0A0A0A), // Almost black
          background: Color(0xFF1A1A1A), // Dark gray
          onPrimary: Color(0xFF000000),
          onSecondary: Color(0xFF000000),
          onSurface: Color(0xFF00FFFF),
          onBackground: Color(0xFF00FFFF),
        ),
        useMaterial3: true,
        fontFamily: 'monospace',
      ),
      home: const GameScreen(),
    );
  }
}
