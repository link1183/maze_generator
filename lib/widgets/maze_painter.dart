import 'package:flutter/material.dart';
import '../models/node.dart';

class MazePainter extends CustomPainter {
  final List<List<Node>> maze;
  final Offset origin;
  final double cellSize;
  final double dotRadius;

  // Constants for visual configuration
  static const double lineStrokeWidth = 1.8;
  static const double glowStrokeWidth = 2.0;
  static const double glowBlurRadius = 1.5;
  static const double originGlowRadius = 4.0;
  static const double nodeGlowRadius = 2.0;
  static const double originDotScale = 1.2;
  static const double nodeDotScale = 1.5;

  final Paint glowPaint;
  final Paint linePaint;
  final Paint dotPaint;
  final Paint originPaint;
  final Paint nodeGlowPaint;
  final Paint originGlowPaint;

  MazePainter({
    required this.maze,
    required this.origin,
    required this.cellSize,
    required this.dotRadius,
  })  : glowPaint = Paint()
          ..color = Colors.cyan.withValues(alpha: 0.15)
          ..strokeWidth = glowStrokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter =
              const MaskFilter.blur(BlurStyle.normal, glowBlurRadius),
        linePaint = Paint()
          ..shader = LinearGradient(
            colors: <Color>[
              Colors.cyan.shade300,
              Colors.cyan.shade500,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, 1000, 1000))
          ..strokeWidth = lineStrokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
        dotPaint = Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              Colors.cyan.shade300,
              Colors.cyan.shade500,
            ],
          ).createShader(
              Rect.fromCircle(center: Offset.zero, radius: dotRadius))
          ..style = PaintingStyle.fill,
        originPaint = Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              Colors.white.withValues(alpha: 0.9),
              Colors.white.withValues(alpha: 0.7),
            ],
          ).createShader(Rect.fromCircle(
              center: Offset.zero, radius: dotRadius * originDotScale))
          ..style = PaintingStyle.fill,
        nodeGlowPaint = Paint()
          ..color = Colors.cyan.withValues(alpha: 0.2)
          ..maskFilter =
              const MaskFilter.blur(BlurStyle.normal, nodeGlowRadius),
        originGlowPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.2)
          ..maskFilter =
              const MaskFilter.blur(BlurStyle.normal, originGlowRadius);

  @override
  void paint(Canvas canvas, Size size) {
    linePaint.shader = LinearGradient(
      colors: <Color>[
        Colors.cyan.shade300,
        Colors.cyan.shade500,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(
        Rect.fromPoints(Offset.zero, Offset(size.width, size.height)));

    _drawMaze(canvas);
  }

  void _drawMaze(Canvas canvas) {
    for (int y = 0; y < maze.length; y++) {
      for (int x = 0; x < maze[y].length; x++) {
        final center = Offset(
          x * cellSize + cellSize / 2,
          y * cellSize + cellSize / 2,
        );

        _drawNodeConnections(canvas, x, y, center);
        _drawNode(canvas, x, y, center);
      }
    }
  }

  void _drawNodeConnections(Canvas canvas, int x, int y, Offset center) {
    final node = maze[y][x];
    if (node.direction != null) {
      final next = center + (node.direction! * cellSize);
      canvas.drawLine(center, next, glowPaint);
      canvas.drawLine(center, next, linePaint);
    }
  }

  void _drawNode(Canvas canvas, int x, int y, Offset center) {
    final isOrigin = Offset(x.toDouble(), y.toDouble()) == origin;

    if (isOrigin) {
      canvas.drawCircle(center, dotRadius * 2, originGlowPaint);
      canvas.drawCircle(center, dotRadius * originDotScale, originPaint);
    } else {
      canvas.drawCircle(center, dotRadius * nodeDotScale, nodeGlowPaint);
      canvas.drawCircle(center, dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(MazePainter oldDelegate) {
    return oldDelegate.maze != maze ||
        oldDelegate.origin != origin ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.dotRadius != dotRadius;
  }
}
