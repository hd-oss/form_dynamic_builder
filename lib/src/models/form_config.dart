import 'form_component.dart';
import 'form_settings.dart';

class FormConfig {
  final String id;
  final String title;
  final String description;
  final String type;
  final List<FormComponent> components;
  final FormSettings settings;
  final String? createdAt;
  final String? updatedAt;

  FormConfig({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.components,
    required this.settings,
    this.createdAt,
    this.updatedAt,
  });

  factory FormConfig.fromJson(Map<String, dynamic> json) {
    var componentsList = <FormComponent>[];
    if (json['components'] != null) {
      componentsList = (json['components'] as List)
          .map((e) => FormComponent.fromJson(e))
          .toList();
    }

    return FormConfig(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'form',
      components: componentsList,
      settings: json['settings'] != null
          ? FormSettings.fromJson(Map<String, dynamic>.from(json['settings']))
          : FormSettings(),
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'components': components.map((e) => e.toJson()).toList(),
      'settings': settings.toJson(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
