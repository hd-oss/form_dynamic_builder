/// Represents a single file entry in a File Upload component.
///
/// Separates the locally-selected file info (for UI display) from
/// the server upload response (for form submission).
class FileData {
  /// Original file name from local selection (always set, never from server).
  final String name;

  /// File size in bytes (from local file).
  final int? size;

  /// Local file path. Retained so the file can be deleted if removed.
  final String? localPath;

  /// Upload status: `'local'`, `'success'`, or `'error'`.
  final String status;

  /// Set when the server returns a plain URL string.
  final String? uploadedUrl;

  /// Set when the server returns a JSON object (Map) or full response.
  final dynamic uploadResponse;

  const FileData({
    required this.name,
    this.size,
    this.localPath,
    this.status = 'local',
    this.uploadedUrl,
    this.uploadResponse,
  });

  /// Returns the best available URL for this file, or `null`.
  String? get url {
    if (uploadedUrl != null) return uploadedUrl;
    if (uploadResponse is Map) {
      final m = uploadResponse as Map;
      return (m['url'] ?? m['location'] ?? m['path'])?.toString();
    }
    return null;
  }

  /// Returns the raw value for form submission.
  /// Prioritizes remote data over local paths.
  dynamic get submissionValue {
    return uploadedUrl ?? uploadResponse ?? localPath;
  }

  /// Whether this file has been successfully uploaded to a remote server.
  bool get isUploaded => status == 'success';

  /// Whether this file is stored only locally.
  bool get isLocal => status == 'local';

  FileData copyWith({
    String? name,
    int? size,
    String? localPath,
    String? status,
    String? uploadedUrl,
    dynamic uploadResponse,
  }) {
    return FileData(
      name: name ?? this.name,
      size: size ?? this.size,
      localPath: localPath ?? this.localPath,
      status: status ?? this.status,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
      uploadResponse: uploadResponse ?? this.uploadResponse,
    );
  }

  /// Creates a [FileData] from a local file path (before upload).
  factory FileData.fromLocalPath(String path, {int? size}) {
    final name =
        path.contains('/') ? path.split('/').last : path.split(r'\').last;
    return FileData(
      name: name,
      size: size,
      localPath: path,
      status: 'local',
    );
  }

  /// Creates a [FileData] representing a successfully uploaded file.
  factory FileData.fromUpload({
    required String localPath,
    int? size,
    String? uploadedUrl,
    dynamic uploadResponse,
  }) {
    final name = localPath.contains('/')
        ? localPath.split('/').last
        : localPath.split(r'\').last;
    return FileData(
      name: name,
      size: size,
      localPath: localPath,
      status: 'success',
      uploadedUrl: uploadedUrl,
      uploadResponse: uploadResponse,
    );
  }

  factory FileData.fromJson(Map<String, dynamic> json) {
    return FileData(
      name: json['name'] as String? ?? '',
      size: json['size'] as int?,
      localPath: json['localPath'] as String?,
      status: json['status'] as String? ?? 'local',
      uploadedUrl: json['uploadedUrl'] as String?,
      uploadResponse: json['uploadResponse'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (size != null) 'size': size,
        if (localPath != null) 'localPath': localPath,
        'status': status,
        if (uploadedUrl != null) 'uploadedUrl': uploadedUrl,
        if (uploadResponse != null) 'uploadResponse': uploadResponse,
      };

  @override
  String toString() => 'FileData(name: $name, status: $status, url: $url)';
}
