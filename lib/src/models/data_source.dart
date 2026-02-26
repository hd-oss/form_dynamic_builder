class DataSourceApi {
  final String url;
  final String method;
  final String dataKey;
  final String labelPath;
  final String valuePath;
  final String body;
  final List<Map<String, String>> headers;

  DataSourceApi({
    required this.url,
    this.method = 'GET',
    this.dataKey = '',
    this.labelPath = 'label',
    this.valuePath = 'value',
    this.body = '',
    this.headers = const [],
  });

  factory DataSourceApi.fromJson(Map<String, dynamic> json) {
    return DataSourceApi(
      url: json['url'] ?? '',
      method: json['method'] ?? 'GET',
      dataKey: json['dataKey'] ?? '',
      labelPath: json['labelPath'] ?? 'label',
      valuePath: json['valuePath'] ?? 'value',
      body: json['body'] ?? '',
      headers: (json['headers'] as List?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'method': method,
      'dataKey': dataKey,
      'labelPath': labelPath,
      'valuePath': valuePath,
      'body': body,
      'headers': headers,
    };
  }
}

class DataSource {
  final String type; // "static" | "api"
  final DataSourceApi? api;

  DataSource({
    required this.type,
    this.api,
  });

  bool get isApi => type == 'api' && api != null;

  factory DataSource.fromJson(Map<String, dynamic> json) {
    return DataSource(
      type: json['type'] ?? 'static',
      api: json['api'] != null
          ? DataSourceApi.fromJson(json['api'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (api != null) 'api': api!.toJson(),
    };
  }
}
