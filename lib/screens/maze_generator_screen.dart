import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_maze/models/maze_config.dart';
import 'package:flutter_maze/models/node.dart';
import '../services/maze_generator_service.dart';
import '../services/file_service.dart';
import '../widgets/maze_controls.dart';
import '../widgets/maze_painter.dart';

class KeyShortcut {
  final String description;
  final VoidCallback onKeyDown;
  final VoidCallback? onKeyUp;

  const KeyShortcut({
    required this.description,
    required this.onKeyDown,
    this.onKeyUp,
  });
}

class MazeGeneratorScreen extends StatefulWidget {
  const MazeGeneratorScreen({super.key});

  @override
  State<MazeGeneratorScreen> createState() => _MazeGeneratorScreenState();
}

class _MazeGeneratorScreenState extends State<MazeGeneratorScreen>
    with SingleTickerProviderStateMixin<MazeGeneratorScreen> {
  static const double minCellSize = 20;
  static const double maxCellSize = 40;
  static const double dotRadiusRatio = 0.1;
  static const int minSpeed = 10;
  static const int maxSpeed = 500;

  late MazeConfig _config;
  bool _isRunning = false;
  Timer? _animationTimer;
  Timer? _keyPressTimer;

  final Map<LogicalKeyboardKey, KeyShortcut> _shortcuts =
      <LogicalKeyboardKey, KeyShortcut>{};

  void _initializeShortcuts() {
    _shortcuts.addAll({
      LogicalKeyboardKey.space: KeyShortcut(
        description: 'Start/Stop generation',
        onKeyDown: _toggleAnimation,
      ),
      LogicalKeyboardKey.keyR: KeyShortcut(
        description: 'Reset maze',
        onKeyDown: _reset,
      ),
      LogicalKeyboardKey.keyI: KeyShortcut(
          description: 'Step through generation',
          onKeyDown: () {
            if (_isRunning) return;

            _iterate();
            _keyPressTimer?.cancel();
            _keyPressTimer = Timer(const Duration(milliseconds: 500), () {
              if (_isRunning) return;

              _iterate();
              _keyPressTimer = Timer.periodic(
                  const Duration(milliseconds: 500), (Timer _) => _iterate());
            });
          },
          onKeyUp: () {
            _keyPressTimer?.cancel();
            _keyPressTimer = null;
          }),
      LogicalKeyboardKey.arrowUp: KeyShortcut(
          description: 'Increase speed',
          onKeyDown: () => _handleSpeedChange(true),
          onKeyUp: () {
            _keyPressTimer?.cancel();
            _keyPressTimer = null;
          }),
      LogicalKeyboardKey.arrowDown: KeyShortcut(
          description: 'Decrease speed',
          onKeyDown: () => _handleSpeedChange(false),
          onKeyUp: () {
            _keyPressTimer?.cancel();
            _keyPressTimer = null;
          })
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeMaze();
    _initializeShortcuts();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _keyPressTimer?.cancel();
    super.dispose();
  }

  void _initializeMaze() {
    final List<List<Node>> maze =
        MazeGeneratorService.generateInitialMaze(20, 20);
    _config = MazeConfig(
      width: 20,
      height: 20,
      simulationSpeed: 10,
      origin: const Offset(19, 19),
      iterationCount: 0,
      maze: maze,
    );
    maze[_config.origin.dy.toInt()][_config.origin.dx.toInt()].direction = null;
  }

  double _calculateCellSize(BoxConstraints constraints) {
    double maxWidth = constraints.maxWidth * 0.9;
    double maxHeight = constraints.maxHeight * 0.7;

    double cellSizeFromWidth = maxWidth / _config.width;
    double cellSizeFromHeight = maxHeight / _config.height;

    return min<double>(cellSizeFromWidth, cellSizeFromHeight)
        .clamp(minCellSize, maxCellSize);
  }

  void _iterate() {
    final List<Offset> neighbors = MazeGeneratorService.getValidNeighbors(
      _config.origin,
      _config.width,
      _config.height,
    );

    if (neighbors.isNotEmpty) {
      setState(() {
        final Offset newOrigin = neighbors[Random().nextInt(neighbors.length)];
        final double dirX = newOrigin.dx - _config.origin.dx;
        final double dirY = newOrigin.dy - _config.origin.dy;

        _config.maze[_config.origin.dy.toInt()][_config.origin.dx.toInt()]
            .direction = Offset(dirX, dirY);

        _config = MazeConfig(
          width: _config.width,
          height: _config.height,
          simulationSpeed: _config.simulationSpeed,
          origin: newOrigin,
          iterationCount: _config.iterationCount + 1,
          maze: _config.maze,
        );

        _config.maze[_config.origin.dy.toInt()][_config.origin.dx.toInt()]
            .direction = null;
      });
    }
  }

  void _toggleAnimation() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _animationTimer = Timer.periodic(
          Duration(milliseconds: (1000 / _config.simulationSpeed).round()),
          (Timer _) => _iterate(),
        );
      } else {
        _animationTimer?.cancel();
      }
    });
  }

  void _updateMazeSize(int newWidth, int newHeight) {
    setState(() {
      final List<List<Node>> maze =
          MazeGeneratorService.generateInitialMaze(newWidth, newHeight);
      _config = MazeConfig(
        width: newWidth,
        height: newHeight,
        simulationSpeed: _config.simulationSpeed,
        origin: Offset(newWidth - 1, newHeight - 1),
        iterationCount: 0,
        maze: maze,
      );
      maze[_config.origin.dy.toInt()][_config.origin.dx.toInt()].direction =
          null;
    });
  }

  void _updateSimulationSpeed(double newSpeed) {
    setState(() {
      _config = MazeConfig(
        width: _config.width,
        height: _config.height,
        simulationSpeed: newSpeed,
        origin: _config.origin,
        iterationCount: _config.iterationCount,
        maze: _config.maze,
      );

      if (_isRunning) {
        _animationTimer?.cancel();
        _animationTimer = Timer.periodic(
          Duration(milliseconds: (1000 / newSpeed).round()),
          (Timer _) => _iterate(),
        );
      }
    });
  }

  void _reset() {
    setState(() {
      _initializeMaze();
    });
  }

  Future<void> _exportMaze() async {
    try {
      final String filename = await FileService.exportMazeToFile(_config);
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
            content: Text(e.toString()),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _importMaze() async {
    try {
      final MazeConfig newConfig = await FileService.importMazeFromFile();
      setState(() {
        _config = newConfig;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Maze imported successfully'),
            backgroundColor: Colors.cyan.shade400,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  void _handleGridTap(TapDownDetails details, double cellSize) {
    final Offset localPos = details.localPosition;
    final int x = (localPos.dx / cellSize).floor();
    final int y = (localPos.dy / cellSize).floor();

    if (x >= 0 && x < _config.width && y >= 0 && y < _config.height) {
      setState(() {
        final Offset newOrigin = Offset(x.toDouble(), y.toDouble());
        final Node currentNode = _config.maze[y][x];

        if (currentNode.direction != null) {
          int newDirX = 0, newDirY = 0;

          for (final Offset dir in MazeGeneratorService.possibleDirections) {
            final int nextX = (x + dir.dx).toInt();
            final int nextY = (y + dir.dy).toInt();

            if (nextX >= 0 &&
                nextX < _config.width &&
                nextY >= 0 &&
                nextY < _config.height &&
                _config.maze[nextY][nextX].direction != null) {
              newDirX = dir.dx.toInt();
              newDirY = dir.dy.toInt();
              break;
            }
          }

          currentNode.direction =
              Offset(newDirX.toDouble(), newDirY.toDouble());
        }

        _config = MazeConfig(
          width: _config.width,
          height: _config.height,
          simulationSpeed: _config.simulationSpeed,
          origin: newOrigin,
          iterationCount: _config.iterationCount + 1,
          maze: _config.maze,
        );
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final KeyShortcut? shortcut = _shortcuts[event.logicalKey];
    if (shortcut == null) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      shortcut.onKeyDown();
      return KeyEventResult.handled;
    } else if (event is KeyUpEvent && shortcut.onKeyUp != null) {
      shortcut.onKeyUp!();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _handleSpeedChange(bool increase) {
    void updateSpeed() {
      setState(() {
        final newSpeed = increase
            ? _config.simulationSpeed + 10
            : _config.simulationSpeed - 10;

        if (newSpeed >= minSpeed && newSpeed <= maxSpeed) {
          _updateSimulationSpeed(newSpeed);
        }
      });
    }

    updateSpeed();

    _keyPressTimer?.cancel();
    _keyPressTimer = Timer(
      const Duration(milliseconds: 500),
      () {
        _keyPressTimer = Timer.periodic(
          const Duration(milliseconds: 50),
          (Timer _) => updateSpeed(),
        );
      },
    );
  }

  Widget _buildMazeView(double cellSize, double dotRadius) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 5,
          )
        ],
      ),
      child: GestureDetector(
        onTapDown: (TapDownDetails details) =>
            _handleGridTap(details, cellSize),
        child: CustomPaint(
          size: Size(_config.width * cellSize, _config.height * cellSize),
          painter: MazePainter(
            maze: _config.maze,
            origin: _config.origin,
            cellSize: cellSize,
            dotRadius: dotRadius,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Focus(
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double cellSize = _calculateCellSize(constraints);
            final double dotRadius = cellSize * dotRadiusRatio;

            return SafeArea(
              child: Column(
                children: <Widget>[
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
                      child: _buildMazeView(cellSize, dotRadius),
                    ),
                  ),
                  MazeControls(
                    width: _config.width,
                    height: _config.height,
                    simulationSpeed: _config.simulationSpeed,
                    isRunning: _isRunning,
                    iterationCount: _config.iterationCount,
                    onStart: _toggleAnimation,
                    onStep: _iterate,
                    onReset: _reset,
                    onExport: _exportMaze,
                    onImport: _importMaze,
                    onSizeChanged: _updateMazeSize,
                    onSpeedChanged: _updateSimulationSpeed,
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
