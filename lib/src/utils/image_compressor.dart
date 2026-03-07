import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressor {
  /// Compresses an image and saves it to a persistent drafted directory.
  ///
  /// Returns the path of the compressed image. If compression fails, or if the
  /// file is not an image format supported by the compressor, it returns the
  /// original path.
  static Future<String> compressImage({
    required String imagePath,
    required int quality,
  }) async {
    try {
      final File originalFile = File(imagePath);
      if (!originalFile.existsSync()) {
        return imagePath;
      }

      // Check if file is supported (jpg, jpeg, png, heic, webp)
      final ext = imagePath.split('.').last.toLowerCase();
      final supportedExtensions = ['jpg', 'jpeg', 'png', 'heic', 'webp'];
      if (!supportedExtensions.contains(ext)) {
        return imagePath;
      }

      // Define target path in system temp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String targetPath =
          '${Directory.systemTemp.path}/compressed_$timestamp.jpg';

      // Compress and get file
      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(imagePath, targetPath,
              quality: quality);

      if (compressedFile != null) {
        if (kDebugMode) {
          final originalSize = await originalFile.length();
          final compressedSize = await compressedFile.length();
          final String oriFormat = (originalSize / 1024).toStringAsFixed(2);
          final String comFormat = (compressedSize / 1024).toStringAsFixed(2);

          print('Fincore ImageCompressor: Saved to ${compressedFile.path}');
          print(
              'Fincore ImageCompressor: Size reduced from $oriFormat KB to $comFormat KB');
        }
        return compressedFile.path;
      } else {
        // Fallback to original if compression fails
        if (kDebugMode) print('Fincore ImageCompressor: Compression failed.');
        return imagePath;
      }
    } catch (e) {
      if (kDebugMode) print('Error compressing image $imagePath: $e');
      return imagePath; // Fallback to original
    }
  }
}
