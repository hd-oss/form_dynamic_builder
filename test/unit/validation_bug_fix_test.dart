import 'package:flutter_test/flutter_test.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';

void main() {
  group('Validation Bug Fix Tests', () {
    late FormController controller;

    void setupWithComponent(FormComponent component) {
      final config = FormConfig(
        id: 'test_form',
        title: 'Test Form',
        description: 'Testing validation bug fix',
        settings: FormSettings(),
        components: [component],
      );
      controller = FormController(config: config);
    }

    test('SelectBoxes with empty list [] fails required validation', () {
      final selectBoxes = SelectBoxesComponent(
        id: '1',
        type: 'selectboxes',
        key: 'boxes',
        label: 'Select Options',
        required: true,
        options: [
          SelectOption(label: 'Opt 1', value: '1'),
        ],
      );

      setupWithComponent(selectBoxes);

      // Initial value is null (or empty list if initialized)
      expect(controller.validate(), isFalse);
      expect(controller.errors['boxes'], contains('is required'));

      // Set to empty list
      controller.updateValue('boxes', []);
      expect(controller.validate(), isFalse);
    });

    test('String with only whitespace fails required validation', () {
      final textField = TextFieldComponent(
        id: '2',
        type: 'textfield',
        key: 'text',
        label: 'Name',
        required: true,
      );

      setupWithComponent(textField);

      // Empty string
      controller.updateValue('text', '');
      expect(controller.validate(), isFalse);

      // Whitespace
      controller.updateValue('text', '   ');
      expect(controller.validate(), isFalse);

      // Valid string
      controller.updateValue('text', 'Antigravity');
      expect(controller.validate(), isTrue);
    });

    test('SelectBoxes with values passes required validation', () {
      final selectBoxes = SelectBoxesComponent(
        id: '1',
        type: 'selectboxes',
        key: 'boxes',
        label: 'Select Options',
        required: true,
        options: [
          SelectOption(label: 'Opt 1', value: '1'),
        ],
      );

      setupWithComponent(selectBoxes);

      controller.updateValue('boxes', ['1']);
      expect(controller.validate(), isTrue);
    });
  });
}
