import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileStorageUtils {
  /// Moves a file from [sourcePath] to the application support directory.
  /// If [subDir] is provided, it will be created inside the support directory.
  static Future<String> moveToSupportDirectory(String sourcePath,
      {String? subDir}) async {
    final file = File(sourcePath);
    if (!file.existsSync()) return sourcePath;

    final supportDir = await getApplicationSupportDirectory();
    String targetPath = supportDir.path;

    if (subDir != null) {
      final subDirectory = Directory('${supportDir.path}/$subDir');
      if (!subDirectory.existsSync()) {
        subDirectory.createSync(recursive: true);
      }
      targetPath = subDirectory.path;
    }

    final fileName = sourcePath.split(Platform.pathSeparator).last;
    final destinationPath = '$targetPath${Platform.pathSeparator}$fileName';

    final movedFile = await file.copy(destinationPath);

    // Optional: Delete the original if it was in temp
    if (sourcePath.contains(Directory.systemTemp.path)) {
      try {
        await file.delete();
      } catch (_) {
        // Ignore error if it's already deleted or not allowed
      }
    }

    return movedFile.path;
  }

  /// Checks if a path is in either temp or support directory for safe deletion.
  static Future<bool> isSafeToDelete(String path) async {
    final tempDir = Directory.systemTemp.path;
    final supportDir = await getApplicationSupportDirectory();

    return path.startsWith(tempDir) || path.startsWith(supportDir.path);
  }
}
