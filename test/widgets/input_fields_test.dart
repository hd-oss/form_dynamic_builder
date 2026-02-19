import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';

void main() {
  group('Result Widget Input Field Tests', () {
    late FormConfig config;
    late FormController controller;

    testWidgets('Should apply input mask', (WidgetTester tester) async {
      final jsonMap = {
        "id": "form1",
        "title": "Mask Form",
        "components": [
          {
            "id": "c1",
            "type": "textfield",
            "key": "phone",
            "label": "Phone",
            "inputMask": "+(99) 999-999"
          }
        ],
        "settings": {}
      };
      config = FormConfig.fromJson(jsonMap);
      controller = FormController(config: config);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FormDynamicBuilder(controller: controller),
        ),
      ));

      final textField =
          find.byType(TextField); // TextFormField uses TextField internally
      await tester.enterText(textField, "123456");
      await tester.pump();

      // Expect formatted text: +(12) 345-6
      // mask: +(99) 999-999
      // input: 123456
      // result: +(12) 345-6

      expect(find.text('+(12) 345-6'), findsOneWidget);
      // Controller stores unmasked value now:
      // Input: 123456 -> Masked: +(12) 345-6 -> Unmasked digits: 123456
      expect(controller.getValue('phone'), '123456');
    });

    testWidgets('Should apply text transform visually',
        (WidgetTester tester) async {
      final jsonMap = {
        "id": "form1",
        "title": "Transform Form",
        "components": [
          {
            "id": "c1",
            "type": "textfield",
            "key": "upper",
            "label": "Upper",
            "textTransform": "uppercase"
          }
        ],
        "settings": {}
      };
      config = FormConfig.fromJson(jsonMap);
      controller = FormController(config: config);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FormDynamicBuilder(controller: controller),
        ),
      ));

      final textField = find.byType(TextField);
      await tester.enterText(textField, "hello");
      await tester.pump();

      // The find.text() searches for text rendered on screen.
      // If the formatter works, "HELLO" should be found, not "hello".
      expect(find.text('HELLO'), findsOneWidget);
      expect(find.text('hello'), findsNothing);
      expect(controller.getValue('upper'), 'HELLO');
    });

    testWidgets('Should validate unmasked value for masked fields',
        (WidgetTester tester) async {
      final jsonMap = {
        "id": "form1",
        "title": "Mask Validation Form",
        "components": [
          {
            "id": "c1",
            "type": "textfield",
            "key": "npwp",
            "label": "NPWP",
            "inputMask": "99.999.999.9-999.999", // 15 digits, 20 chars
            "validation": [
              {"type": "maxLength", "value": 15, "message": "Max 15 digits"},
              {"type": "minLength", "value": 15, "message": "Min 15 digits"}
            ]
          }
        ],
        "settings": {}
      };
      config = FormConfig.fromJson(jsonMap);
      controller = FormController(config: config);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FormDynamicBuilder(controller: controller),
        ),
      ));

      final textField = find.byType(TextField);
      // Enter 15 digits
      await tester.enterText(textField, "123456789012345");
      await tester.pump();

      // UI should show masked value (20 chars)
      expect(find.text('12.345.678.9-012.345'), findsOneWidget);

      // Controller should validate UNMASKED value (15 chars)
      // If it validates masked value, length is 20, so maxLength 15 rule will FAIL.
      expect(controller.validate(), true);
      expect(controller.values['npwp'], '123456789012345');
    });

    testWidgets('Should restrict input for number/currency types',
        (WidgetTester tester) async {
      final jsonMap = {
        "id": "form1",
        "title": "Number Restriction Form",
        "components": [
          {"id": "c1", "type": "number", "key": "age", "label": "Age"},
          {"id": "c2", "type": "currency", "key": "price", "label": "Price"}
        ],
        "settings": {}
      };
      config = FormConfig.fromJson(jsonMap);
      controller = FormController(config: config);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FormDynamicBuilder(controller: controller),
        ),
      ));

      final fields = find.byType(TextField);
      final ageField = fields.at(0);
      final priceField = fields.at(1);

      // Test Number
      await tester.enterText(ageField, "abc12xyz");
      await tester.pump();
      expect(find.text('12'), findsOneWidget);
      expect(controller.getValue('age'), 12);

      // Test Currency
      await tester.enterText(priceField, "\$99.99abc");
      await tester.pump();
      expect(find.text('99.99'), findsOneWidget);
      expect(controller.getValue('price'), 99.99);
    });

    testWidgets('Should support enhanced mask filters (9, a, #)',
        (WidgetTester tester) async {
      final jsonMap = {
        "id": "form1",
        "title": "Enhanced Mask Form",
        "components": [
          {
            "id": "c1",
            "type": "textfield",
            "key": "numeric",
            "label": "Num",
            "inputMask": "99-99"
          },
          {
            "id": "c2",
            "type": "textfield",
            "key": "alpha",
            "label": "Alpha",
            "inputMask": "aa-aa"
          },
          {
            "id": "c3",
            "type": "textfield",
            "key": "alphanum",
            "label": "Alphanum",
            "inputMask": "##-##"
          }
        ],
        "settings": {}
      };
      config = FormConfig.fromJson(jsonMap);
      controller = FormController(config: config);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FormDynamicBuilder(controller: controller),
        ),
      ));

      final fields = find.byType(TextField);
      final numField = fields.at(0);
      final alphaField = fields.at(1);
      final alnumField = fields.at(2);

      // Test Numeric (9) - Input '1a2b' -> Expect '12' -> Mask '12' (partial)
      // Actually '12' -> '12-' ? MaskTextInputFormatter behavior depends on type.
      // Let's try simple valid/invalid.

      await tester.enterText(numField, "1a2b");
      await tester.pump();
      // '1' ok, 'a' blocked, '2' ok, 'b' blocked. Result: "12"
      // Lazy mask: separator '-' only appears when next char is typed.
      expect(find.text('12'), findsOneWidget);
      expect(controller.getValue('numeric'), '12');

      // Test Alpha (a) - Input '1a2b' -> Expect 'ab'
      await tester.enterText(alphaField, "1a2b");
      await tester.pump();
      expect(find.text('ab'), findsOneWidget);
      expect(controller.getValue('alpha'), 'ab');

      // Test Alphanum (#) - Input '1a' -> Expect '1a'
      await tester.enterText(alnumField, "1a");
      await tester.pump();
      expect(find.text('1a'), findsOneWidget);
      expect(controller.getValue('alphanum'), '1a');
    });

    testWidgets('Should render description as Tooltip',
        (WidgetTester tester) async {
      final jsonMap = {
        "id": "form1",
        "title": "Tooltip Form",
        "components": [
          {
            "id": "c1",
            "type": "textfield",
            "key": "tip",
            "label": "With Tooltip",
            "description": "This is a tooltip"
          }
        ],
        "settings": {}
      };
      config = FormConfig.fromJson(jsonMap);
      controller = FormController(config: config);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FormDynamicBuilder(controller: controller),
        ),
      ));

      // Should show Info Icon
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      // Should have Tooltip with message
      final tooltipFinder = find.byType(Tooltip);
      expect(tooltipFinder, findsOneWidget);
      final tooltip = tester.widget<Tooltip>(tooltipFinder);
      expect(tooltip.message, "This is a tooltip");

      // Description text should NOT be visible initially (unlike helperText)
      expect(find.text("This is a tooltip"), findsNothing);
    });

    testWidgets('Should focus on first error field',
        (WidgetTester tester) async {
      final jsonMap = {
        "id": "form1",
        "title": "Focus Form",
        "components": [
          {
            "id": "c1",
            "type": "textfield",
            "key": "f1",
            "label": "Field 1",
            "required": true
          },
          {
            "id": "c2",
            "type": "textfield",
            "key": "f2",
            "label": "Field 2",
            "required": true
          }
        ],
        "settings": {}
      };

      // Use local variables to avoid reusing the lateinit ones from setUp
      var config = FormConfig.fromJson(jsonMap);
      var controller = FormController(config: config);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FormDynamicBuilder(controller: controller),
        ),
      ));

      // Validate -> both fail. f1 is first.
      controller.validate();
      await tester.pumpAndSettle();

      // Check if f1 has focus
      expect(controller.getFocusNode("f1").hasFocus, true);
      expect(controller.getFocusNode("f2").hasFocus, false);

      // Fill f1
      await tester.enterText(find.byType(TextField).at(0), "Data");
      await tester.pumpAndSettle();
      controller.validate();
      await tester.pumpAndSettle();

      // Now f2 should be focused
      // Focus might remain on f1 if enterText keeps it there unless explicitly moved?
      // But validateStep calls requestFocus on f2.
      // Let's check f2 has focus.

      expect(controller.getFocusNode("f2").hasFocus, true);
    });
  });
}
