import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';
import 'package:form_dynamic_builder/src/widgets/fields/select_boxes_widget.dart';
import 'package:form_dynamic_builder/src/widgets/fields/text_field_widget.dart';

void main() {
  testWidgets('SelectBoxes renders options and updates controller',
      (WidgetTester tester) async {
    final component = SelectBoxesComponent(
      id: 'sb1',
      type: 'selectboxes',
      key: 'interests',
      label: 'Interests',
      options: [
        SelectOption(label: 'Coding', value: 'coding'),
        SelectOption(label: 'Design', value: 'design'),
      ],
    );

    final config = FormConfig(
      id: 'form1',
      title: 'Test Form',
      description: 'Desc',
      settings: FormSettings(),
      components: [component],
    );

    final controller = FormController(config: config);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Material(
            child: SelectBoxesWidget(
              component: component,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Coding'), findsOneWidget);
    expect(find.text('Design'), findsOneWidget);

    // Tap Coding
    await tester.tap(find.text('Coding'));
    await tester.pump();

    expect(controller.getValue('interests'), contains('coding'));
    expect(controller.getValue('interests'), isNot(contains('design')));

    // Tap Design
    await tester.tap(find.text('Design'));
    await tester.pump();

    expect(controller.getValue('interests'), contains('coding'));
    expect(controller.getValue('interests'), contains('design'));

    // Untap Coding
    await tester.tap(find.text('Coding'));
    await tester.pump();

    expect(controller.getValue('interests'), isNot(contains('coding')));
    expect(controller.getValue('interests'), contains('design'));
  });

  testWidgets('SelectBoxes visibility logic works with "eq" operator',
      (WidgetTester tester) async {
    final sbComponent = SelectBoxesComponent(
      id: 'sb2',
      type: 'selectboxes',
      key: 'roles',
      label: 'Roles',
      options: [
        SelectOption(label: 'Admin', value: 'admin'),
        SelectOption(label: 'User', value: 'user'),
      ],
    );

    final tfComponent = TextFieldComponent(
      id: 'tf1',
      type: 'textfield',
      key: 'admin_code',
      label: 'Admin Code',
      conditional: ConditionalConfig(
        show: true,
        conditions: [
          Condition(
            when: 'roles',
            operator: 'eq',
            value: 'admin',
          ),
        ],
      ),
    );

    final config = FormConfig(
      id: 'form2',
      title: 'Test Form 2',
      description: 'Desc',
      settings: FormSettings(),
      components: [sbComponent, tfComponent],
    );

    final controller = FormController(config: config);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SelectBoxesWidget(
                    component: sbComponent, controller: controller),
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    if (!controller.isComponentVisible(tfComponent)) {
                      return const SizedBox.shrink();
                    }
                    return DynamicTextField(
                        component: tfComponent, controller: controller);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Initially tf hidden because roles is empty (or not containing admin)
    expect(find.byType(TextField), findsNothing);

    // Select User -> still hidden
    await tester.tap(find.text('User'));
    await tester.pump();
    expect(find.byType(TextField), findsNothing);

    // Select Admin -> visible
    await tester.tap(find.text('Admin'));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);

    // Deselect Admin -> hidden
    await tester.tap(find.text('Admin'));
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
  });
}
