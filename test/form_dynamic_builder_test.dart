import 'package:flutter_test/flutter_test.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';
import 'dart:convert';

void main() {
  group('Form Parser Tests', () {
    test('Should parse FormConfig from JSON', () {
      final jsonStr = '''
      {
        "id": "form1",
        "title": "Test Form",
        "description": "A test form",
        "type": "form",
        "components": [
          {
            "id": "c1",
            "type": "textfield",
            "key": "name",
            "label": "Name",
            "required": true
          },
          {
            "id": "c2",
            "type": "number",
            "key": "age",
            "label": "Age"
          }
        ],
        "settings": {
            "submitLabel": "Go"
        }
      }
      ''';

      final jsonMap = json.decode(jsonStr);
      final config = FormConfig.fromJson(jsonMap);

      expect(config.title, 'Test Form');
      expect(config.components.length, 2);
      expect(config.components[0], isA<TextFieldComponent>());
      expect(config.components[1], isA<NumberComponent>());
      expect(config.settings.submitLabel, 'Go');
    });
  });

  group('Form Controller Tests', () {
    late FormConfig config;
    late FormController controller;

    setUp(() {
      final jsonMap = {
        "id": "form1",
        "title": "Test Form",
        "description": "",
        "type": "form",
        "components": [
          {
            "id": "c1",
            "type": "textfield",
            "key": "name",
            "label": "Name",
            "required": true
          }
        ],
        "settings": {}
      };
      config = FormConfig.fromJson(jsonMap);
      controller = FormController(config: config);
    });

    test('Initial values should be empty', () {
      expect(controller.values.isEmpty, true);
    });

    test('Update value should update controller state', () {
      controller.updateValue('name', 'John Doe');
      expect(controller.getValue('name'), 'John Doe');
    });

    test('Validation should fail if required field is empty', () {
      bool isValid = controller.validate();
      expect(isValid, false);
      expect(controller.errors.containsKey('name'), true);
    });

    test('Validation should pass if required field is filled', () {
      controller.updateValue('name', 'John Doe');
      bool isValid = controller.validate();
      expect(isValid, true);
      expect(controller.errors.isEmpty, true);
    });
  });
}
