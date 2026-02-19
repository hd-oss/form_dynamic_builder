import 'form_component.dart';

class FormStep {
  final String key;
  final String title;
  final List<FormComponent> components;

  FormStep({
    required this.key,
    required this.title,
    this.components = const [],
  });

  factory FormStep.fromJson(Map<String, dynamic> json) {
    var componentsList = <FormComponent>[];
    if (json['components'] != null) {
      componentsList = (json['components'] as List)
          .map((e) => FormComponent.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return FormStep(
      key: json['key'] as String,
      title: json['title'] as String,
      components: componentsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title': title,
      'components': components.map((e) => e.toJson()).toList(),
    };
  }
}
