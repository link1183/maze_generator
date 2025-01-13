import 'package:flutter/material.dart';

class MazeControls extends StatelessWidget {
  final int width;
  final int height;
  final double simulationSpeed;
  final bool isRunning;
  final int iterationCount;
  final VoidCallback onStart;
  final VoidCallback onStep;
  final VoidCallback onReset;
  final VoidCallback onExport;
  final VoidCallback onImport;
  final Function(int, int) onSizeChanged;
  final Function(double) onSpeedChanged;

  static const int minSize = 5;
  static const int maxSize = 40;
  static const int minSpeed = 10;
  static const int maxSpeed = 2000;

  const MazeControls({
    super.key,
    required this.width,
    required this.height,
    required this.simulationSpeed,
    required this.isRunning,
    required this.iterationCount,
    required this.onStart,
    required this.onStep,
    required this.onReset,
    required this.onExport,
    required this.onImport,
    required this.onSizeChanged,
    required this.onSpeedChanged,
  });

  Widget _buildSliderRow(
    String label,
    int value,
    int min,
    int max,
    Function(double) onChanged, {
    String suffix = '',
  }) {
    return Row(
      children: <Widget>[
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

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    bool isPrimary = false,
    String? tooltip,
  }) {
    final ElevatedButton button = ElevatedButton(
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

    if (tooltip != null) {
      return Tooltip(
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
      );
    }

    return button;
  }

  Widget _buildIterationCounter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        'Iterations: $iterationCount',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 16,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  Widget _buildSliders() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: <Widget>[
          _buildSliderRow(
            'Width',
            width,
            minSize,
            maxSize,
            (double value) => onSizeChanged(value.toInt(), height),
          ),
          _buildSliderRow(
            'Height',
            height,
            minSize,
            maxSize,
            (double value) => onSizeChanged(width, value.toInt()),
          ),
          _buildSliderRow(
            'Speed',
            simulationSpeed.round(),
            minSpeed,
            maxSpeed,
            onSpeedChanged,
            suffix: 'Hz',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: <Widget>[
          _buildActionButton(
            text: isRunning ? 'Stop' : 'Start',
            onPressed: onStart,
            isPrimary: true,
            tooltip: 'Press Space',
          ),
          _buildActionButton(
            text: 'Step',
            onPressed: onStep,
            tooltip: 'Hold I key',
          ),
          _buildActionButton(
            text: 'Reset',
            onPressed: onReset,
            tooltip: 'Press R',
          ),
          _buildActionButton(
            text: 'Export',
            onPressed: onExport,
          ),
          _buildActionButton(
            text: 'Import',
            onPressed: onImport,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildIterationCounter(),
        _buildSliders(),
        _buildActionButtons(),
      ],
    );
  }
}
