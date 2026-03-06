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
}
