import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MazePaths {
  static Future<String> getBasePath() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      return appDir.path;
    } catch (e) {
      try {
        final Directory tempDir = await getTemporaryDirectory();
        return tempDir.path;
      } catch (e) {
        if (Platform.isLinux || Platform.isMacOS) {
          return '/tmp';
        }
        throw Exception('No valid writable path found');
      }
    }
  }

  static Future<String> getMazeDirectory() async {
    final String basePath = await getBasePath();
    final Directory mazeDir = Directory('$basePath/maze_configs');

    if (!await mazeDir.exists()) {
      await mazeDir.create(recursive: true);
    }

    return mazeDir.path;
  }
}
