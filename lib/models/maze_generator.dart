import 'dart:math';

class Cell {
  final int x, y;
  bool topWall = true;
  bool rightWall = true;
  bool bottomWall = true;
  bool leftWall = true;
  bool visited = false;

  Cell(this.x, this.y);
}

class Edge {
  final Cell cell1, cell2;
  final String direction;

  Edge(this.cell1, this.cell2, this.direction);
}

class MazeGenerator {
  late List<List<Cell>> grid;
  late int width, height;
  final Random random = Random();

  List<List<Cell>> generateMaze(int w, int h) {
    width = w;
    height = h;
    
    // Initialize grid
    grid = List.generate(height, (y) => 
        List.generate(width, (x) => Cell(x, y)));

    // Use Kruskal's algorithm to generate maze
    _generateWithKruskal();
    
    return grid;
  }

  void _generateWithKruskal() {
    // Create all possible edges
    List<Edge> edges = [];
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (x < width - 1) {
          edges.add(Edge(grid[y][x], grid[y][x + 1], 'right'));
        }
        if (y < height - 1) {
          edges.add(Edge(grid[y][x], grid[y + 1][x], 'bottom'));
        }
      }
    }

    // Shuffle edges randomly
    edges.shuffle(random);

    // Union-Find data structure
    Map<Cell, Cell> parent = {};
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        parent[grid[y][x]] = grid[y][x];
      }
    }

    Cell find(Cell cell) {
      if (parent[cell] != cell) {
        parent[cell] = find(parent[cell]!);
      }
      return parent[cell]!;
    }

    void union(Cell cell1, Cell cell2) {
      Cell root1 = find(cell1);
      Cell root2 = find(cell2);
      if (root1 != root2) {
        parent[root2] = root1;
      }
    }

    // Process edges
    for (Edge edge in edges) {
      Cell cell1 = edge.cell1;
      Cell cell2 = edge.cell2;
      
      if (find(cell1) != find(cell2)) {
        union(cell1, cell2);
        
        // Remove walls between cells
        if (edge.direction == 'right') {
          cell1.rightWall = false;
          cell2.leftWall = false;
        } else if (edge.direction == 'bottom') {
          cell1.bottomWall = false;
          cell2.topWall = false;
        }
      }
    }
  }
}
