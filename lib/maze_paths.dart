import 'dart:io';
import 'package:path_provider_linux/path_provider_linux.dart' as path;

class MazePaths {
  static Future<String> getBasePath() async {
    final linuxProvider = path.PathProviderLinux();

    final paths = [
      await linuxProvider.getApplicationDocumentsPath(),
      await linuxProvider.getTemporaryPath(),
      '/tmp',
    ];

    for (final path in paths) {
      if (path != null) {
        final directory = Directory(path);
        try {
          if (await directory.exists()) {
            final testFile = File('${directory.path}/test_write');
            await testFile.create();
            await testFile.delete();
            return path;
          }
        } catch (e) {
          continue;
        }
      }
    }

    throw Exception('No valid writable path found');
  }

  static Future<String> getMazeDirectory() async {
    final basePath = await getBasePath();
    final mazeDir = Directory('$basePath/maze_configs');

    if (!await mazeDir.exists()) {
      await mazeDir.create(recursive: true);
    }

    return mazeDir.path;
  }
}
