import 'package:flutter/foundation.dart';

enum UploadStatus {
  idle,
  uploading,
  success,
  error,
}

mixin UploadMixin on ChangeNotifier {
  UploadStatus _uploadStatus = UploadStatus.idle;
  String? _uploadError;

  UploadStatus get uploadStatus => _uploadStatus;
  String? get uploadError => _uploadError;

  bool get isUploading => _uploadStatus == UploadStatus.uploading;
  bool get hasUploadError => _uploadStatus == UploadStatus.error;

  void updateUploadStatus(UploadStatus status, {String? error}) {
    _uploadStatus = status;
    _uploadError = error;
    notifyListeners();
  }

  void resetUploadStatus() {
    _uploadStatus = UploadStatus.idle;
    _uploadError = null;
    notifyListeners();
  }

  /// Extracts a value from a dynamic response (usually a Map) using a dot-notation path.
  /// For example, if path is 'data.url' and data is {'data': {'url': 'http://...'}},
  /// it returns 'http://...'.
  dynamic extractValueFromPath(dynamic data, String path) {
    if (path.isEmpty || data == null) return data;

    final keys = path.split('.');
    dynamic current = data;

    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return data; // Fallback to raw data if path is invalid
      }
    }

    return current;
  }
}
