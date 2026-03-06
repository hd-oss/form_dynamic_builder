import 'package:flutter_test/flutter_test.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';

void main() {
  FormConfig _makeConfig() {
    return FormConfig.fromJson({
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
    });
  }

  group('FormController.reset()', () {
    test('clears values after reset', () {
      final ctrl = FormController(config: _makeConfig());
      ctrl.updateValue('name', 'John');
      expect(ctrl.getValue('name'), 'John');

      ctrl.reset();
      expect(ctrl.getValue('name'), isNull);
    });

    test('clears errors after reset', () {
      final ctrl = FormController(config: _makeConfig());
      ctrl.validate(); // populates errors
      expect(ctrl.errors.isNotEmpty, isTrue);

      ctrl.reset();
      expect(ctrl.errors.isEmpty, isTrue);
    });

    test('resetGeneration starts at 0', () {
      final ctrl = FormController(config: _makeConfig());
      expect(ctrl.resetGeneration, 0);
    });

    test('resetGeneration increments on each reset()', () {
      final ctrl = FormController(config: _makeConfig());
      ctrl.reset();
      expect(ctrl.resetGeneration, 1);
      ctrl.reset();
      expect(ctrl.resetGeneration, 2);
    });

    test('getFocusNode after reset returns a fresh (not disposed) FocusNode',
        () {
      final ctrl = FormController(config: _makeConfig());

      // Obtain a FocusNode before reset
      final nodeBefore = ctrl.getFocusNode('name');
      expect(nodeBefore, isNotNull);

      ctrl.reset(); // disposes and clears focus nodes

      // After reset, requesting the same key returns a new node
      final nodeAfter = ctrl.getFocusNode('name');
      expect(nodeAfter, isNotNull);
      // The two nodes must be different instances
      expect(identical(nodeBefore, nodeAfter), isFalse);
    });

    test('two different controllers for same form have different hashCodes',
        () {
      final ctrl1 = FormController(config: _makeConfig());
      final ctrl2 = FormController(config: _makeConfig());
      // hashCode is identity-based for ChangeNotifier subclasses
      expect(ctrl1.hashCode == ctrl2.hashCode, isFalse);
    });
  });
}
