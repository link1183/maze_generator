import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/maze_generator_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF121212),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MazeGeneratorApp());
}

class MazeGeneratorApp extends StatelessWidget {
  const MazeGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maze Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: Colors.cyan.shade400,
          secondary: Colors.cyan.shade300,
          surface: const Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
          bodyMedium: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.cyan.shade400,
          inactiveTrackColor: Colors.cyan.withValues(alpha: .3),
          thumbColor: Colors.cyan.shade300,
          overlayColor: Colors.cyan.withValues(alpha: 0.2),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan.shade400,
            foregroundColor: Colors.white,
            elevation: 4,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.grey[850],
          contentTextStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ),
      home: const MazeGeneratorScreen(),
    );
  }
}
