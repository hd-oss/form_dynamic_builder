import 'package:flutter_test/flutter_test.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';
import 'dart:convert';

void main() {
  group('Form Parser Tests', () {
    test('Should parse FormConfig from JSON', () {
      const jsonStr = '''
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

    test('Should parse wizard JSON correctly', () {
      final jsonMap = {
        "id": "comp_1771384591912_91da61yae",
        "title": "Untitled Form",
        "type": "wizard",
        "components": [],
        "steps": [
          {
            "key": "page1",
            "title": "Page 1",
            "components": [
              {"id": "c1", "type": "textfield", "key": "t1", "label": "Text 1"}
            ]
          },
          {
            "key": "page2",
            "title": "Page 2",
            "components": [
              {"id": "c2", "type": "textfield", "key": "t2", "label": "Text 2"}
            ]
          }
        ],
        "settings": {}
      };

      final config = FormConfig.fromJson(jsonMap);
      expect(config.type, 'wizard');
      expect(config.steps.length, 2);
      expect(config.steps[0].components.length, 1);
      expect(config.steps[1].components.length, 1);
    });
  });
}
