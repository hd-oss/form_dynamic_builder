import 'form_component.dart';
import 'form_settings.dart';
import 'form_step.dart';
import '../utils/form_constants.dart';

class FormConfig {
  final String id;
  final String title;
  final String description;
  final List<FormComponent> components;
  final List<FormStep> steps;
  final FormSettings settings;

  final String type;
  final String? createdAt;
  final String? updatedAt;

  FormConfig({
    required this.id,
    required this.title,
    required this.description,
    this.type = FormConstants.formTypeDefault,
    required this.components,
    this.steps = const [],
    required this.settings,
    this.createdAt,
    this.updatedAt,
  });

  factory FormConfig.fromJson(Map<String, dynamic> json) {
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
      'steps': steps.map((e) => e.toJson()).toList(),
      'settings': settings.toJson(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
