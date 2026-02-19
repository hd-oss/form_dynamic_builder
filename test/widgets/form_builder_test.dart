import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';

void main() {
  group('FormBuilder Widget Tests', () {
    testWidgets('Should render specific step', (WidgetTester tester) async {
      final jsonMap = {
        "id": "wizard1",
        "title": "Wizard Form",
        "type": "wizard",
        "components": [],
        "steps": [
          {
            "key": "step1",
            "title": "Personal Info",
            "components": [
              {"id": "c1", "type": "textfield", "key": "name", "label": "Name"}
            ]
          },
          {
            "key": "step2",
            "title": "Contact Info",
            "components": [
              {
                "id": "c2",
                "type": "textfield",
                "key": "email",
                "label": "Email"
              }
            ]
          }
        ],
        "settings": {}
      };
      final config = FormConfig.fromJson(jsonMap);
      final controller = FormController(config: config);

      // Render Step 0
      controller.goToStep(0);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FormDynamicBuilder(controller: controller),
        ),
      ));
      await tester.pump();

      // Expect Step 1 Title and Component
      expect(find.text('Personal Info'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget); // Label from step 1
      expect(find.text('Contact Info'), findsNothing); // Step 2 title
      expect(find.text('Email'), findsNothing);

      // Render Step 1
      controller.goToStep(1);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FormDynamicBuilder(controller: controller),
        ),
      ));
      await tester.pump();

      // Expect Step 2 Title and Component
      expect(find.text('Personal Info'), findsNothing);
    });
  });
}
