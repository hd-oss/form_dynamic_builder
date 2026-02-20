import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';
import 'package:form_dynamic_builder/src/widgets/fields/date_time_widget.dart';

void main() {
  testWidgets(
      'DateTimeWidget uses default format yyyy-MM-dd HH:mm:ss when format is null and enableTime is true',
      (WidgetTester tester) async {
    final component = DateTimeComponent(
      id: 'dt_default',
      type: 'datetime',
      key: 'dt_default',
      label: 'Date Time',
      enableTime: true,
      // format is null by default
    );

    final config = FormConfig(
      id: 'form1',
      title: 'T',
      description: 'D',
      settings: FormSettings(),
      components: [component],
    );
    final controller = FormController(config: config);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Material(
            child: DynamicDateTime(
              component: component,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    // We can't easily check the *logic* of _handlePicker without interacting.
    // However, if we manually set a value in the controller that matches the format, it should display?
    // No, the widget displays `controller.getValue(key)`.
    // The Formatting happens ON SELECTION.
    // So to test this, we must simulate selection.
    // Simulating usage of `DateFormat` inside the widget is implied if we trust the code change.
    // But to be sure, let's verify if we can trigger the update.
    // Or, we can verifying via unit test of `_handlePicker` logic if it was accessible.
    // Since it's not, we trust the integration or we try to open picker?
    // Opening picker and selecting "OK" (default is now) should result in formatted string.

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    // Date Picker shows up. Tap OK/Confirm.
    // Material 3 DatePicker has "OK" or "Switch to Input"?
    // Finds "OK" text button?
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Time Picker shows up (because enableTime=true).
    // Tap OK.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Now check the value in controller.
    final value = controller.getValue('dt_default');
    // It should match pattern yyyy-MM-dd HH:mm:ss
    // Note: Minutes might change if test runs slow, but format check matters.

    expect(value, matches(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$'));
    // ISO would be 2023-10-05T14:30:00.000
    // Check it does NOT contain T
    expect(value, isNot(contains('T')));
  });

  testWidgets(
      'DateTimeWidget uses default format yyyy-MM-dd when enableTime is false',
      (WidgetTester tester) async {
    final component = DateTimeComponent(
      id: 'dt_date',
      type: 'datetime',
      key: 'dt_date',
      label: 'Date Only',
      enableTime: false,
    );

    final config = FormConfig(
      id: 'form2',
      title: 'T',
      description: 'D',
      settings: FormSettings(),
      components: [component],
    );
    final controller = FormController(config: config);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Material(
            child: DynamicDateTime(
              component: component,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    // Tap OK in Date Picker
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final value = controller.getValue('dt_date');
    // Expect yyyy-MM-dd
    expect(value, matches(r'^\d{4}-\d{2}-\d{2}$'));
  });

  testWidgets(
      'DateTimeWidget uses default format HH:mm:ss when timeOnly is true',
      (WidgetTester tester) async {
    final component = DateTimeComponent(
      id: 'dt_time',
      type: 'datetime',
      key: 'dt_time',
      label: 'Time Only',
      enableTime: true,
      timeOnly: true,
    );

    final config = FormConfig(
      id: 'form3',
      title: 'T',
      description: 'D',
      settings: FormSettings(),
      components: [component],
    );
    final controller = FormController(config: config);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Material(
            child: DynamicDateTime(
              component: component,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    // Tap OK in Time Picker
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final value = controller.getValue('dt_time');
    // Expect HH:mm:ss
    expect(value, matches(r'^\d{2}:\d{2}:\d{2}$'));
  });
}
