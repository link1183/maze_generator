import 'package:flutter/cupertino.dart';
import 'package:flutter_maze/models/node.dart';

class MazeGeneratorService {
  static const List<Offset> possibleDirections = <Offset>[
    Offset(0, 1),
    Offset(1, 0),
    Offset(0, -1),
    Offset(-1, 0),
  ];

  static List<List<Node>> generateInitialMaze(int width, int height) {
    final List<List<Node>> maze = List<List<Node>>.generate(
      height,
      (int _) => List<Node>.generate(width, (int _) => Node()),
    );

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width - 1; x++) {
        maze[y][x].direction = const Offset(1, 0);
      }
    }

    for (int y = 0; y < height - 1; y++) {
      maze[y][width - 1].direction = const Offset(0, 1);
    }

    return maze;
  }

  static List<Offset> getValidNeighbors(Offset origin, int width, int height) {
    final List<Offset> neighbors = <Offset>[];
    for (final Offset dir in possibleDirections) {
      final double newX = origin.dx + dir.dx;
      final double newY = origin.dy + dir.dy;
      if (newX >= 0 && newX < width && newY >= 0 && newY < height) {
        neighbors.add(Offset(newX, newY));
      }
    }
    return neighbors;
  }
}
