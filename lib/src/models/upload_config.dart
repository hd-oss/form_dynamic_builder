class UploadKeyValue {
  final String key;
  final String value;

  const UploadKeyValue({required this.key, required this.value});

  factory UploadKeyValue.fromJson(Map<String, dynamic> json) {
    return UploadKeyValue(
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'key': key, 'value': value};
}

class OtherUploadConfig {
  final String method;

  final List<UploadKeyValue> headers;

  final String responseFileUrlPath;

  final List<UploadKeyValue> extraBodyFields;

  final String fileFieldName;

  const OtherUploadConfig({
    this.method = 'POST',
    this.headers = const [],
    this.responseFileUrlPath = '',
    this.extraBodyFields = const [],
    this.fileFieldName = 'file',
  });

  factory OtherUploadConfig.fromJson(Map<String, dynamic> json) {
    return OtherUploadConfig(
      method: json['method'] as String? ?? 'POST',
      headers: (json['headers'] as List<dynamic>?)
              ?.map((e) => UploadKeyValue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      responseFileUrlPath: json['responseFileUrlPath'] as String? ?? '',
      extraBodyFields: (json['extraBodyFields'] as List<dynamic>?)
              ?.map((e) => UploadKeyValue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      fileFieldName: json['fileFieldName'] as String? ?? 'file',
    );
  }

  Map<String, dynamic> toJson() => {
        'method': method,
        'headers': headers.map((e) => e.toJson()).toList(),
        'responseFileUrlPath': responseFileUrlPath,
        'extraBodyFields': extraBodyFields.map((e) => e.toJson()).toList(),
        'fileFieldName': fileFieldName,
      };
}
