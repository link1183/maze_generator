import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_maze/maze_paths.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:math';

class MazePainter extends CustomPainter {
  final List<List<dynamic>> maze;
  final Offset origin;
  final double cellSize;
  final double dotRadius;

  MazePainter({
    required this.maze,
    required this.origin,
    required this.cellSize,
    required this.dotRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.15)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.cyan.shade300,
          Colors.cyan.shade500,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(
          Rect.fromPoints(Offset.zero, Offset(size.width, size.height)))
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.cyan.shade300,
          Colors.cyan.shade500,
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: dotRadius))
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final originPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.9),
          Colors.white.withValues(alpha: 0.7),
        ],
      ).createShader(
          Rect.fromCircle(center: Offset.zero, radius: dotRadius * 1.2))
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (var y = 0; y < maze.length; y++) {
      for (var x = 0; x < maze[y].length; x++) {
        final center = Offset(
          x * cellSize + cellSize / 2,
          y * cellSize + cellSize / 2,
        );

        final node = maze[y][x];

        if (node.direction != null) {
          final next = center + (node.direction! * cellSize);

          canvas.drawLine(center, next, glowPaint);

          canvas.drawLine(center, next, linePaint);
        }

        if (Offset(x.toDouble(), y.toDouble()) == origin) {
          canvas.drawCircle(
              center,
              dotRadius * 2,
              Paint()
                ..color = Colors.white.withValues(alpha: 0.2)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0));
          canvas.drawCircle(center, dotRadius * 1.2, originPaint);
        } else {
          canvas.drawCircle(
              center,
              dotRadius * 1.5,
              Paint()
                ..color = Colors.cyan.withValues(alpha: 0.2)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0));
          canvas.drawCircle(center, dotRadius, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(MazePainter oldDelegate) {
    return oldDelegate.maze != maze ||
        oldDelegate.origin != origin ||
        oldDelegate.cellSize != cellSize;
  }
}

class Node {
  Offset? direction;
  Node();
}

class MazeGenerator extends StatefulWidget {
  const MazeGenerator({super.key});

  @override
  State<MazeGenerator> createState() => _MazeGeneratorState();
}

class _MazeGeneratorState extends State<MazeGenerator>
    with SingleTickerProviderStateMixin {
  int width = 20;
  int height = 20;
  static const double minCellSize = 20;
  static const double maxCellSize = 40;
  static const double dotRadiusRatio = 0.1;

  late List<List<Node>> maze;
  late Offset origin;
  bool isRunning = false;
  Timer? animationTimer;
  Timer? keyPressTimer;
  int iterationCount = 0;
  double simulationSpeed = 10;
  final int minSpeed = 10;
  final int maxSpeed = 500;

  final List<Offset> possibleDirections = [
    const Offset(0, 1),
    const Offset(1, 0),
    const Offset(0, -1),
    const Offset(-1, 0),
  ];

  @override
  void initState() {
    super.initState();
    maze = List.generate(
      height,
      (_) => List.generate(width, (_) => Node()),
    );
    generatePerfectMaze();
  }

  double calculateCellSize(BoxConstraints constraints) {
    double maxWidth = constraints.maxWidth * 0.9;
    double maxHeight = constraints.maxHeight * 0.7;

    double cellSizeFromWidth = maxWidth / width;
    double cellSizeFromHeight = maxHeight / height;

    double calculatedSize = min(cellSizeFromWidth, cellSizeFromHeight);
    return calculatedSize.clamp(minCellSize, maxCellSize);
  }

  void generatePerfectMaze() {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        maze[y][x].direction = null;
      }
    }

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width - 1; x++) {
        maze[y][x].direction = const Offset(1, 0);
      }
    }

    for (var y = 0; y < height - 1; y++) {
      maze[y][width - 1].direction = const Offset(0, 1);
    }

    origin = Offset(width - 1, height - 1);
    maze[height - 1][width - 1].direction = null;
  }

  void updateMazeSize(int newWidth, int newHeight) {
    setState(() {
      width = newWidth;
      height = newHeight;
      maze = List.generate(
        height,
        (_) => List.generate(width, (_) => Node()),
      );
      generatePerfectMaze();
      iterationCount = 0;
    });
  }

  void iterate() {
    final neighbors = <Offset>[];
    for (final dir in possibleDirections) {
      final newX = origin.dx + dir.dx;
      final newY = origin.dy + dir.dy;
      if (newX >= 0 && newX < width && newY >= 0 && newY < height) {
        neighbors.add(Offset(newX, newY));
      }
    }

    if (neighbors.isNotEmpty) {
      iterationCount++;

      final newOrigin = neighbors[Random().nextInt(neighbors.length)];
      final dirX = newOrigin.dx - origin.dx;
      final dirY = newOrigin.dy - origin.dy;
      maze[origin.dy.toInt()][origin.dx.toInt()].direction = Offset(dirX, dirY);

      origin = newOrigin;
      maze[origin.dy.toInt()][origin.dx.toInt()].direction = null;

      setState(() {});
    }
  }

  void toggleAnimation() {
    setState(() {
      isRunning = !isRunning;
      if (isRunning) {
        animationTimer = Timer.periodic(
          Duration(milliseconds: (1000 / simulationSpeed).round()),
          (_) => iterate(),
        );
      } else {
        animationTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    animationTimer?.cancel();
    super.dispose();
  }

  Map<String, dynamic> exportMazeConfiguration() {
    return {
      'width': width,
      'height': height,
      'simulationSpeed': simulationSpeed,
      'origin': {'x': origin.dx, 'y': origin.dy},
      'iterationCount': iterationCount,
      'maze': maze
          .map((row) => row
              .map((node) => {
                    'direction': node.direction != null
                        ? {'dx': node.direction!.dx, 'dy': node.direction!.dy}
                        : null
                  })
              .toList())
          .toList()
    };
  }

  void importMazeConfiguration(Map<String, dynamic> config) {
    setState(() {
      width = config['width'] is int
          ? config['width']
          : int.parse(config['width'].toString());
      height = config['height'] is int
          ? config['height']
          : int.parse(config['height'].toString());
      simulationSpeed = config['simulationSpeed'] is double
          ? config['simulationSpeed']
          : double.parse(config['simulationSpeed'].toString());
      iterationCount = config['iterationCount'] is int
          ? config['iterationCount']
          : int.parse(config['iterationCount'].toString());

      maze = List.generate(
        height,
        (_) => List.generate(width, (_) => Node()),
      );

      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final nodeConfig = config['maze'][y][x];
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

      origin = Offset(
        (config['origin']['x'] is int
                ? config['origin']['x']
                : double.parse(config['origin']['x'].toString()))
            .toDouble(),
        (config['origin']['y'] is int
                ? config['origin']['y']
                : double.parse(config['origin']['y'].toString()))
            .toDouble(),
      );
    });
  }

  Future<void> exportMazeToFile() async {
    try {
      final mazeConfig = exportMazeConfiguration();
      final directory = await MazePaths.getMazeDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final filename = 'maze_config_$timestamp.json';
      final file = File('$directory/$filename');

      final jsonString = JsonEncoder.withIndent('  ').convert(mazeConfig);
      await file.writeAsString(jsonString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maze exported to $filename'),
            backgroundColor: Colors.cyan.shade400,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export maze: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> importMazeFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
          dialogTitle: 'Select a maze configuration file',
          allowMultiple: false);

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = File(result.files.first.path!);
      final filename = file.path.split('/').last;

      final jsonString = await file.readAsString();
      final mazeConfig = json.decode(jsonString);

      importMazeConfiguration(mazeConfig);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maze imported from $filename'),
            backgroundColor: Colors.cyan.shade400,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import maze: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Widget _buildSliderRow(
    String label,
    int value,
    int min,
    int max,
    Function(double) onChanged, {
    String suffix = '',
  }) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w300,
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.cyan.shade400,
              inactiveTrackColor: Colors.cyan.withValues(alpha: 0.3),
              thumbColor: Colors.cyan.shade300,
              overlayColor: Colors.cyan.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              label: '$value$suffix',
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            '$value$suffix',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      {required String text,
      required VoidCallback onPressed,
      bool isPrimary = false,
      String? tooltip}) {
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary
            ? Colors.cyan.shade400
            : Colors.cyan.withValues(alpha: 0.2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: isPrimary ? 4 : 2,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isPrimary ? FontWeight.w500 : FontWeight.w300,
          letterSpacing: 1.1,
        ),
      ),
    );

    return tooltip != null
        ? Tooltip(
            message: tooltip,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(4),
            ),
            textStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
            child: button,
          )
        : button;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Focus(
        autofocus: true,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.space) {
              toggleAnimation();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyI &&
                !isRunning) {
              iterate();
              keyPressTimer?.cancel();
              keyPressTimer = Timer(
                const Duration(milliseconds: 500),
                () {
                  if (!isRunning) {
                    iterate();
                    keyPressTimer = Timer.periodic(
                        const Duration(milliseconds: 50), (_) => iterate());
                  }
                },
              );
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
              setState(() {
                generatePerfectMaze();
                iterationCount = 0;
              });

              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              void increaseSpeed() {
                setState(() {
                  if (simulationSpeed + 10 <= maxSpeed) {
                    simulationSpeed += 10;
                    if (isRunning) {
                      animationTimer?.cancel();
                      animationTimer = Timer.periodic(
                        Duration(
                            milliseconds: (1000 / simulationSpeed).round()),
                        (_) => iterate(),
                      );
                    }
                  }
                });
              }

              increaseSpeed();

              keyPressTimer?.cancel();
              keyPressTimer = Timer(
                const Duration(milliseconds: 500),
                () {
                  keyPressTimer = Timer.periodic(
                    const Duration(milliseconds: 50),
                    (_) => increaseSpeed(),
                  );
                },
              );

              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              void decreaseSpeed() {
                setState(() {
                  if (simulationSpeed - 10 >= minSpeed) {
                    simulationSpeed -= 10;
                    if (isRunning) {
                      animationTimer?.cancel();
                      animationTimer = Timer.periodic(
                        Duration(
                            milliseconds: (1000 / simulationSpeed).round()),
                        (_) => iterate(),
                      );
                    }
                  }
                });
              }

              // Initial speed decrease
              decreaseSpeed();

              // Setup timer for held key
              keyPressTimer?.cancel();
              keyPressTimer = Timer(
                const Duration(milliseconds: 500),
                () {
                  keyPressTimer = Timer.periodic(
                    const Duration(milliseconds: 50),
                    (_) => decreaseSpeed(),
                  );
                },
              );

              return KeyEventResult.handled;
            }
          } else if (event is KeyUpEvent) {
            if (event.logicalKey == LogicalKeyboardKey.keyI) {
              keyPressTimer?.cancel();
              keyPressTimer = null;
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellSize = calculateCellSize(constraints);
            final dotRadius = cellSize * dotRadiusRatio;

            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'Maze Generator',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyan.withValues(alpha: 0.1),
                              blurRadius: 15,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: GestureDetector(
                          onTapDown: (TapDownDetails details) {
                            final localPos = details.localPosition;
                            final x = (localPos.dx / cellSize).floor();
                            final y = (localPos.dy / cellSize).floor();

                            if (x >= 0 && x < width && y >= 0 && y < height) {
                              setState(() {
                                origin = Offset(x.toDouble(), y.toDouble());

                                final currentNode = maze[y][x];
                                if (currentNode.direction != null) {
                                  int newDirX = 0, newDirY = 0;

                                  for (final dir in possibleDirections) {
                                    final nextX = (x + dir.dx).toInt();
                                    final nextY = (y + dir.dy).toInt();

                                    if (nextX >= 0 &&
                                        nextX < width &&
                                        nextY >= 0 &&
                                        nextY < height &&
                                        maze[nextY][nextX].direction != null) {
                                      newDirX = dir.dx.toInt();
                                      newDirY = dir.dy.toInt();
                                      break;
                                    }
                                  }

                                  currentNode.direction = Offset(
                                      newDirX.toDouble(), newDirY.toDouble());
                                }

                                iterationCount++;
                              });
                            }
                          },
                          child: CustomPaint(
                            size: Size(width * cellSize, height * cellSize),
                            painter: MazePainter(
                              maze: maze,
                              origin: origin,
                              cellSize: cellSize,
                              dotRadius: dotRadius,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Iterations: $iterationCount',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        _buildSliderRow('Width', width, 5, 40,
                            (value) => updateMazeSize(value.toInt(), height)),
                        _buildSliderRow('Height', height, 5, 40,
                            (value) => updateMazeSize(width, value.toInt())),
                        _buildSliderRow('Speed', simulationSpeed.round(),
                            minSpeed, maxSpeed, (value) {
                          setState(() {
                            simulationSpeed = value;
                            if (isRunning) {
                              animationTimer?.cancel();
                              animationTimer = Timer.periodic(
                                Duration(
                                    milliseconds:
                                        (1000 / simulationSpeed.toInt())
                                            .round()),
                                (_) => iterate(),
                              );
                            }
                          });
                        }, suffix: 'Hz'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildActionButton(
                            text: isRunning ? 'Stop' : 'Start',
                            onPressed: toggleAnimation,
                            isPrimary: true,
                            tooltip: 'Press Space'),
                        _buildActionButton(
                            text: 'Step',
                            onPressed: iterate,
                            tooltip: 'Hold I key'),
                        _buildActionButton(
                            text: 'Reset',
                            onPressed: () {
                              setState(() {
                                generatePerfectMaze();
                                iterationCount = 0;
                              });
                            },
                            tooltip: 'Press R'),
                        _buildActionButton(
                          text: 'Export',
                          onPressed: exportMazeToFile,
                        ),
                        _buildActionButton(
                          text: 'Import',
                          onPressed: importMazeFromFile,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
