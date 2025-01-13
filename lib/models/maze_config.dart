import 'package:flutter/semantics.dart';
import 'package:flutter_maze/models/node.dart';

class MazeConfig {
  final int width;
  final int height;
  final double simulationSpeed;
  final Offset origin;
  final int iterationCount;
  final List<List<Node>> maze;

  MazeConfig({
    required this.width,
    required this.height,
    required this.simulationSpeed,
    required this.origin,
    required this.iterationCount,
    required this.maze,
  });

  factory MazeConfig.fromJson(Map<String, dynamic> json) {
    final dynamic width = json['width'] is int
        ? json['width']
        : int.parse(json['width'].toString());
    final dynamic height = json['height'] is int
        ? json['height']
        : int.parse(json['height'].toString());
    final dynamic simulationSpeed = json['simulationSpeed'] is double
        ? json['simulationSpeed']
        : double.parse(json['simulationSpeed'].toString());
    final dynamic iterationCount = json['iterationCount'] is int
        ? json['iterationCount']
        : int.parse(json['iterationCount'].toString());

    final List<List<Node>> maze = List<List<Node>>.generate(
      height,
      (int _) => List<Node>.generate(width, (int _) => Node()),
    );

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final dynamic nodeConfig = json['maze'][y][x];
        if (nodeConfig['direction'] != null) {
          maze[y][x].direction = Offset(
            (nodeConfig['direction']['dx'] is int
                    ? nodeConfig['direction']['dx']
                    : double.parse(nodeConfig['direction']['dx'].toString()))
                .toDouble(),
            (nodeConfig['direction']['dy'] is int
                    ? nodeConfig['direction']['dy']
                    : double.parse(nodeConfig['direction']['dy'].toString()))
                .toDouble(),
          );
        }
      }
    }

    return MazeConfig(
      width: width,
      height: height,
      simulationSpeed: simulationSpeed,
      origin: Offset(
        (json['origin']['x'] is int
                ? json['origin']['x']
                : double.parse(json['origin']['x'].toString()))
            .toDouble(),
        (json['origin']['y'] is int
                ? json['origin']['y']
                : double.parse(json['origin']['y'].toString()))
            .toDouble(),
      ),
      iterationCount: iterationCount,
      maze: maze,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'width': width,
      'height': height,
      'simulationSpeed': simulationSpeed,
      'origin': <String, double>{'x': origin.dx, 'y': origin.dy},
      'iterationCount': iterationCount,
      'maze': maze
          .map<List<Map<String, Map<String, double>?>>>((List<Node> row) => row
              .map<Map<String, Map<String, double>?>>(
                  (Node node) => <String, Map<String, double>?>{
                        'direction': node.direction != null
                            ? <String, double>{
                                'dx': node.direction!.dx,
                                'dy': node.direction!.dy
                              }
                            : null
                      })
              .toList())
          .toList()
    };
  }
}
