import 'package:flutter_test/flutter_test.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';

void main() {
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

    test('Should apply text transformation (uppercase)', () {
      final jsonMap = {
        "id": "form1",
        "title": "Test Form",
        "description": "",
        "components": [
          {
            "id": "c1",
            "type": "textfield",
            "key": "name",
            "label": "Name",
            "textTransform": "uppercase"
          }
        ],
        "settings": {}
      };
      final configTransform = FormConfig.fromJson(jsonMap);
      final controllerTransform = FormController(config: configTransform);

      controllerTransform.updateValue('name', 'john doe');
      expect(controllerTransform.getValue('name'), 'JOHN DOE');
    });

    test('Should store numeric values for number type', () {
      final jsonMap = {
        "id": "form1",
        "title": "Test Form",
        "description": "",
        "components": [
          {"id": "c1", "type": "number", "key": "age", "label": "Age"}
        ],
        "settings": {}
      };
      final configNum = FormConfig.fromJson(jsonMap);
      final controllerNum = FormController(config: configNum);

      controllerNum.updateValue('age', '25');
      expect(controllerNum.getValue('age'), isA<num>());
      expect(controllerNum.getValue('age'), 25);

      controllerNum.updateValue('age', '25.5');
      expect(controllerNum.getValue('age'), 25.5);
    });

    test('Should validate minLength and maxLength', () {
      final jsonMap = {
        "id": "form1",
        "title": "Test Form",
        "description": "",
        "components": [
          {
            "id": "c1",
            "type": "textfield",
            "key": "pin",
            "label": "PIN",
            "validation": [
              {"type": "minLength", "value": 4, "message": "Too short"},
              {"type": "maxLength", "value": 4, "message": "Too long"}
            ]
          }
        ],
        "settings": {}
      };
      final configVal = FormConfig.fromJson(jsonMap);
      final controllerVal = FormController(config: configVal);

      controllerVal.updateValue('pin', '12');
      expect(controllerVal.validate(), false);
      expect(controllerVal.errors['pin'], 'Too short');

      controllerVal.updateValue('pin', '12345');
      expect(controllerVal.validate(), false);
      expect(controllerVal.errors['pin'], 'Too long');

      controllerVal.updateValue('pin', '1234');
      expect(controllerVal.validate(), true);
    });

    test('Should validate regex pattern', () {
      final jsonMap = {
        "id": "form1",
        "title": "Test Form",
        "description": "",
        "components": [
          {
            "id": "c1",
            "type": "textfield",
            "key": "email",
            "label": "Email",
            "validation": [
              {
                "type": "pattern",
                "value": "^[a-z]+@test\\.com\$",
                "message": "Invalid email"
              }
            ]
          }
        ],
        "settings": {}
      };
      final configVal = FormConfig.fromJson(jsonMap);
      final controllerVal = FormController(config: configVal);

      controllerVal.updateValue('email', 'INVALID');
      expect(controllerVal.validate(), false);
      expect(controllerVal.errors['email'], 'Invalid email');

      controllerVal.updateValue('email', 'abc@test.com');
      expect(controllerVal.validate(), true);
    });

    test('Should handle wizard type forms correctly', () {
      final jsonMap = {
        "id": "wizard1",
        "title": "Wizard Form",
        "description": "",
        "type": "wizard",
        "components": [],
        "steps": [
          {
            "key": "step1",
            "title": "Step 1",
            "components": [
              {
                "id": "c1",
                "type": "textfield",
                "key": "name",
                "label": "Name",
                "required": true
              }
            ]
          }
        ],
        "settings": {}
      };
      final configWizard = FormConfig.fromJson(jsonMap);
      final controllerWizard = FormController(config: configWizard);

      // Controller should find component in steps
      expect(controllerWizard.validate(), false);

      controllerWizard.updateValue('name', 'Wizard User');
      expect(controllerWizard.validate(), true);
      controllerWizard.updateValue('name', 'Wizard User');
      expect(controllerWizard.validate(), true);
    });

    test('Should validate specific step', () {
      final jsonMap = {
        "id": "wizard1",
        "title": "Wizard Form",
        "description": "",
        "type": "wizard",
        "components": [],
        "steps": [
          {
            "key": "step1",
            "title": "Step 1",
            "components": [
              {
                "id": "c1",
                "type": "textfield",
                "key": "name",
                "label": "Name",
                "required": true
              }
            ]
          },
          {
            "key": "step2",
            "title": "Step 2",
            "components": [
              {
                "id": "c2",
                "type": "textfield",
                "key": "email",
                "label": "Email",
                "required": true
              }
            ]
          }
        ],
        "settings": {}
      };
      final configWizard = FormConfig.fromJson(jsonMap);
      final controllerWizard = FormController(config: configWizard);

      // Validate step 0 (should fail)
      expect(controllerWizard.validateStep(0), false);
      expect(controllerWizard.errors.containsKey('name'), true);
      expect(controllerWizard.errors.containsKey('email'),
          false); // Should not validate step 2

      // Fix step 0
      controllerWizard.updateValue('name', 'User');
      expect(controllerWizard.validateStep(0), true);

      // Step 2 still invalid if we validate it
      expect(controllerWizard.validateStep(1), false);
      expect(controllerWizard.errors.containsKey('email'), true);
    });
  });
}
