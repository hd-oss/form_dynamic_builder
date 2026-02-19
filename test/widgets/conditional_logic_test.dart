import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';

void main() {
  group('Conditional Visibility Tests', () {
    late FormConfig config;
    late FormController controller;

    setUp(() {
      final jsonMap = {
        "id": "form1",
        "title": "Conditional Form",
        "components": [
          {
            "id": "c1",
            "type": "checkbox",
            "key": "toggle",
            "label": "Use Phone",
            "defaultValue": false,
          },
          {
            "id": "c2",
            "type": "textfield",
            "key": "email",
            "label": "Email Address",
            "required": true,
            "conditional": {
              "show": true,
              "conditions": [
                {
                  "when": "toggle",
                  "operator": "eq",
                  "value": false,
                  "logicWithPrevious": "and"
                }
              ]
            }
          },
          {
            "id": "c3",
            "type": "textfield",
            "key": "phone",
            "label": "Phone Number",
            "required": true,
            "conditional": {
              "show": true,
              "conditions": [
                {
                  "when": "toggle",
                  "operator": "eq",
                  "value": true,
                  "logicWithPrevious": "and"
                }
              ]
            }
          }
        ],
        "settings": {}
      };
      config = FormConfig.fromJson(jsonMap);
      controller = FormController(config: config);
    });

    test('defaultValue should be initialized', () {
      expect(controller.getValue('toggle'), false);
    });

    test('email visible when toggle=false, phone hidden', () {
      // toggle defaults to false
      final emailComp = config.components[1];
      final phoneComp = config.components[2];

      expect(controller.isComponentVisible(emailComp), true);
      expect(controller.isComponentVisible(phoneComp), false);
    });

    test('phone visible when toggle=true, email hidden', () {
      controller.updateValue('toggle', true);

      final emailComp = config.components[1];
      final phoneComp = config.components[2];

      expect(controller.isComponentVisible(emailComp), false);
      expect(controller.isComponentVisible(phoneComp), true);
    });

    test('hidden required fields should NOT be validated', () {
      // toggle=false → email visible (required), phone hidden (required)
      // Leave email empty → validation fails for email only
      final result = controller.validate();
      expect(result, false);
      expect(controller.errors.containsKey('email'), true);
      expect(controller.errors.containsKey('phone'), false);
    });

    test('after toggle, only newly visible fields are validated', () {
      controller.updateValue('toggle', true);

      final result = controller.validate();
      expect(result, false);
      // phone is now visible and required
      expect(controller.errors.containsKey('phone'), true);
      // email is now hidden
      expect(controller.errors.containsKey('email'), false);
    });

    testWidgets('conditional visibility renders correct widgets',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FormDynamicBuilder(controller: controller),
        ),
      ));

      // toggle=false → email visible, phone hidden
      expect(find.textContaining('Email Address'), findsOneWidget);
      expect(find.textContaining('Phone Number'), findsNothing);

      // Toggle checkbox
      controller.updateValue('toggle', true);
      await tester.pumpAndSettle();

      // Now phone visible, email hidden
      expect(find.textContaining('Phone Number'), findsOneWidget);
      expect(find.textContaining('Email Address'), findsNothing);
    });

    test('notEmpty operator works correctly', () {
      final jsonMap = {
        "id": "form2",
        "title": "NotEmpty Test",
        "components": [
          {
            "id": "c1",
            "type": "textfield",
            "key": "name",
            "label": "Name",
          },
          {
            "id": "c2",
            "type": "textfield",
            "key": "details",
            "label": "Details",
            "conditional": {
              "show": true,
              "conditions": [
                {
                  "when": "name",
                  "operator": "notEmpty",
                  "logicWithPrevious": "and"
                }
              ]
            }
          }
        ],
        "settings": {}
      };
      final cfg = FormConfig.fromJson(jsonMap);
      final ctrl = FormController(config: cfg);

      // name is null/empty → details hidden
      expect(ctrl.isComponentVisible(cfg.components[1]), false);

      // name has value → details visible
      ctrl.updateValue('name', 'John');
      expect(ctrl.isComponentVisible(cfg.components[1]), true);
    });

    test('OR logic between conditions works', () {
      final jsonMap = {
        "id": "form3",
        "title": "OR Logic Test",
        "components": [
          {
            "id": "c1",
            "type": "textfield",
            "key": "a",
            "label": "Field A",
          },
          {
            "id": "c2",
            "type": "textfield",
            "key": "b",
            "label": "Field B",
          },
          {
            "id": "c3",
            "type": "textfield",
            "key": "target",
            "label": "Target",
            "conditional": {
              "show": true,
              "conditions": [
                {
                  "when": "a",
                  "operator": "notEmpty",
                  "logicWithPrevious": "and"
                },
                {"when": "b", "operator": "notEmpty", "logicWithPrevious": "or"}
              ]
            }
          }
        ],
        "settings": {}
      };
      final cfg = FormConfig.fromJson(jsonMap);
      final ctrl = FormController(config: cfg);

      // Both empty → false OR false = false
      expect(ctrl.isComponentVisible(cfg.components[2]), false);

      // Only a filled → true OR false = true
      ctrl.updateValue('a', 'x');
      expect(ctrl.isComponentVisible(cfg.components[2]), true);

      // Only b filled → false OR true = true
      ctrl.updateValue('a', '');
      ctrl.updateValue('b', 'y');
      expect(ctrl.isComponentVisible(cfg.components[2]), true);
    });

    test('Numeric comparisons (gt, lt, gte, lte) work', () {
      final jsonMap = {
        "id": "form4",
        "title": "Numeric Test",
        "components": [
          {
            "id": "c1",
            "type": "number",
            "key": "age",
            "label": "Age",
          },
          {
            "id": "c2",
            "type": "textfield",
            "key": "adult_field",
            "label": "Adult Info",
            "conditional": {
              "show": true,
              "conditions": [
                {
                  "when": "age",
                  "operator": "gte",
                  "value": 18,
                  "logicWithPrevious": "and"
                }
              ]
            }
          }
        ],
        "settings": {}
      };
      final cfg = FormConfig.fromJson(jsonMap);
      final ctrl = FormController(config: cfg);

      // age = 10 -> hidden
      ctrl.updateValue('age', 10);
      expect(ctrl.isComponentVisible(cfg.components[1]), false);

      // age = 18 -> visible
      ctrl.updateValue('age', 18);
      expect(ctrl.isComponentVisible(cfg.components[1]), true);

      // age = 20 -> visible
      ctrl.updateValue('age', 20);
      expect(ctrl.isComponentVisible(cfg.components[1]), true);
    });

    test('String Contains operator works', () {
      final jsonMap = {
        "id": "form5",
        "title": "Contains Test",
        "components": [
          {
            "id": "c1",
            "type": "textfield",
            "key": "notes",
            "label": "Notes",
          },
          {
            "id": "c2",
            "type": "textfield",
            "key": "alert",
            "label": "Alert",
            "conditional": {
              "show": true,
              "conditions": [
                {
                  "when": "notes",
                  "operator": "contains",
                  "value": "urgent",
                  "logicWithPrevious": "and"
                }
              ]
            }
          }
        ],
        "settings": {}
      };
      final cfg = FormConfig.fromJson(jsonMap);
      final ctrl = FormController(config: cfg);

      // notes = "hello" -> hidden
      ctrl.updateValue('notes', "hello");
      expect(ctrl.isComponentVisible(cfg.components[1]), false);

      // notes = "this is urgent" -> visible
      ctrl.updateValue('notes', "this is urgent task");
      expect(ctrl.isComponentVisible(cfg.components[1]), true);
    });

    testWidgets(
        'toggling visibility preserves field state (prevents collision)',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FormDynamicBuilder(controller: controller),
        ),
      ));

      // 1. Enter text in Email (toggle=false)
      await tester.enterText(find.byType(TextFormField), 'test@email.com');
      expect(controller.getValue('email'), 'test@email.com');

      // 2. Toggle to Phone
      controller.updateValue('toggle', true);
      await tester.pumpAndSettle();

      // Email should be gone, Phone should be visible
      expect(find.textContaining('Email Address'), findsNothing);
      expect(find.textContaining('Phone Number'), findsOneWidget);

      // Phone field should NOT have email's text (it should be empty or new)
      // Note: find.widgetWithText searches for a widget that has a descendant Text with that string.
      // TextFormField usually displays text via a RenderEditable, which find.text finds.
      expect(find.text('test@email.com'), findsNothing);

      // 3. Enter text in Phone
      await tester.enterText(find.byType(TextFormField), '1234567890');
      expect(controller.getValue('phone'), '1234567890');

      // 4. Toggle back to Email
      controller.updateValue('toggle', false);
      await tester.pumpAndSettle();

      // Phone gone, Email back
      expect(find.textContaining('Phone Number'), findsNothing);
      expect(find.textContaining('Email Address'), findsOneWidget);

      // Email should have its original text restored (or re-initialized from controller value)
      expect(find.text('test@email.com'), findsOneWidget);
    });

    test('Cascading visibility works (Grandchild hidden when Parent hidden)',
        () {
      final jsonMap = {
        "id": "form6",
        "title": "Cascading Test",
        "components": [
          {
            "id": "c1",
            "type": "textfield",
            "key": "A",
            "label": "Field A",
          },
          {
            "id": "c2",
            "type": "textfield",
            "key": "B",
            "label": "Field B", // Visible if A=yes
            "conditional": {
              "show": true,
              "conditions": [
                {
                  "when": "A",
                  "operator": "eq",
                  "value": "yes",
                  "logicWithPrevious": "and"
                }
              ]
            }
          },
          {
            "id": "c3",
            "type": "textfield",
            "key": "C",
            "label": "Field C", // Visible if B=Sedan
            "conditional": {
              "show": true,
              "conditions": [
                {
                  "when": "B",
                  "operator": "eq",
                  "value": "Sedan",
                  "logicWithPrevious": "and"
                }
              ]
            }
          }
        ],
        "settings": {}
      };
      final cfg = FormConfig.fromJson(jsonMap);
      final ctrl = FormController(config: cfg);

      // 1. Initial State: A empty. B hidden. C hidden.
      expect(ctrl.isComponentVisible(cfg.components[1]), false); // B
      expect(ctrl.isComponentVisible(cfg.components[2]), false); // C

      // 2. Set A=yes. B visible. C hidden.
      ctrl.updateValue('A', 'yes');
      expect(ctrl.isComponentVisible(cfg.components[1]), true); // B shown
      expect(ctrl.isComponentVisible(cfg.components[2]), false); // C hidden

      // 3. Set B=Sedan. C visible.
      ctrl.updateValue('B', 'Sedan');
      expect(ctrl.isComponentVisible(cfg.components[2]), true); // C shown

      // 4. Set A=no.
      // - B should hide.
      // - B value ('Sedan') persists in map.
      // - C depends on B.
      // - Since B is hidden, C should ALSO hide (cascading).
      ctrl.updateValue('A', 'no');
      expect(ctrl.isComponentVisible(cfg.components[1]), false); // B hidden

      // THIS IS THE CRITICAL CHECK for the fix:
      expect(ctrl.isComponentVisible(cfg.components[2]),
          false); // C must be hidden
    });
  });
}
