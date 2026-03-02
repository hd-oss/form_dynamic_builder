import '../utils/form_constants.dart';
import 'form_component.dart';
import 'form_settings.dart';
import 'form_step.dart';

typedef DatabaseQueryCallback = Future<List<Map<String, dynamic>>> Function(
  String connectionString,
  String dbName,
  String query,
);

typedef ApiQueryCallback = Future<dynamic> Function(
  String url,
  String method,
  Map<String, String> headers,
  String body,
);

typedef FileUploadCallback = Future<String?> Function(
  String localPath,
  String uploadUrl,
);

class FormConfig {
  final String id;
  final String title;
  final String description;
  final List<FormComponent> components;
  final List<FormStep> steps;
  final FormSettings settings;
  final Map<String, dynamic>? dsForm;

  final String type;
  final String? createdAt;
  final String? updatedAt;
  final DatabaseQueryCallback? onDatabaseQuery;
  final ApiQueryCallback? onApiQuery;
  final FileUploadCallback? onFileUpload;

  FormConfig({
    required this.id,
    required this.title,
    required this.description,
    this.type = FormConstants.formTypeDefault,
    required this.components,
    this.steps = const [],
    required this.settings,
    this.dsForm,
    this.createdAt,
    this.updatedAt,
    this.onDatabaseQuery,
    this.onApiQuery,
    this.onFileUpload,
  });

  factory FormConfig.fromJson(
    Map<String, dynamic> json, {
    DatabaseQueryCallback? onDatabaseQuery,
    ApiQueryCallback? onApiQuery,
    FileUploadCallback? onFileUpload,
  }) {
    var componentsList = <FormComponent>[];
    if (json['components'] != null) {
      componentsList = (json['components'] as List)
          .map((e) => FormComponent.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    var stepsList = <FormStep>[];
    if (json['steps'] != null) {
      stepsList = (json['steps'] as List)
          .map((e) => FormStep.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return FormConfig(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? FormConstants.formTypeDefault,
      components: componentsList,
      steps: stepsList,
      settings: json['settings'] != null
          ? FormSettings.fromJson(Map<String, dynamic>.from(json['settings']))
          : FormSettings(),
      dsForm: json['ds_form'] as Map<String, dynamic>?,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      onDatabaseQuery: onDatabaseQuery,
      onApiQuery: onApiQuery,
      onFileUpload: onFileUpload,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'components': components.map((e) => e.toJson()).toList(),
      'steps': steps.map((e) => e.toJson()).toList(),
      'settings': settings.toJson(),
      if (dsForm != null) 'ds_form': dsForm,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
