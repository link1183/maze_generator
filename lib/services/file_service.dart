import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_maze/models/maze_config.dart';
import 'package:flutter_maze/services/maze_paths.dart';

class FileService {
  static Future<String> exportMazeToFile(MazeConfig config) async {
    try {
      final String directory = await MazePaths.getMazeDirectory();
      final String timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-');
      final String filename = 'maze_config_$timestamp.json';
      final File file = File('$directory/$filename');

      final String jsonString =
          JsonEncoder.withIndent('  ').convert(config.toJson());
      await file.writeAsString(jsonString);

      return filename;
    } catch (e) {
      throw Exception('Failed to export maze: $e');
    }
  }

  static Future<MazeConfig> importMazeFromFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['json'],
        dialogTitle: 'Select a maze configuration file',
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      final File file = File(result.files.first.path!);
      final String jsonString = await file.readAsString();
      final dynamic mazeConfig = json.decode(jsonString);

      return MazeConfig.fromJson(mazeConfig);
    } catch (e) {
      throw Exception('Failed to import maze: $e');
    }
  }
}
