import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_dynamic_builder/src/controller/form_controller.dart';
import 'package:form_dynamic_builder/src/models/components/all_components.dart';
import 'package:form_dynamic_builder/src/models/form_config.dart';
import 'package:form_dynamic_builder/src/models/form_settings.dart';
import 'package:form_dynamic_builder/src/widgets/date_time/date_time_widget.dart';
import 'package:form_dynamic_builder/src/widgets/select/select_widget.dart';
import 'package:flutter/foundation.dart';

void main() {
  group('Adaptive Widgets Tests', () {
    testWidgets('DateTimeWidget shows CupertinoDatePicker on iOS',
        (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final component = DateTimeComponent(
        id: 'dt_ios',
        type: 'datetime',
        key: 'dt_ios',
        label: 'Date iOS',
        enableTime: true,
      );

      final controller = FormController(
        config: FormConfig(
          id: 'form_ios',
          title: 'Title',
          description: 'Desc',
          settings: FormSettings(),
          components: [component],
        ),
      );

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

      // Verify input logic
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      // Check if CupertinoDatePicker is present (it's inside a BottomSheet/ModalPopup)
      expect(find.byType(CupertinoDatePicker), findsOneWidget);

      // Step 1: Date Picker -> Next
      expect(find.text('Next'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 2: Time Picker -> Done
      expect(find.byType(CupertinoDatePicker), findsOneWidget); // New picker
      expect(find.text('Done'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('SelectWidget shows CupertinoPicker on iOS',
        (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final component = SelectComponent(
        id: 'sel_ios',
        type: 'select',
        key: 'sel_ios',
        label: 'Select iOS',
        options: [
          SelectOption(label: 'Option A', value: 'a'),
          SelectOption(label: 'Option B', value: 'b'),
        ],
      );

      final controller = FormController(
        config: FormConfig(
          id: 'form_ios_sel',
          title: 'Title',
          description: 'Desc',
          settings: FormSettings(),
          components: [component],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Material(
              child: DynamicSelect(
                component: component,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      // Verify tap opens picker
      // Note: In SelectWidget for iOS, we use GestureDetector -> AbsorbPointer -> TextFormField
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoPicker), findsOneWidget);
      expect(find.text('Option A'), findsOneWidget);

      // Select item? CupertinoPicker selection is by scrolling.
      // We can just tap Done to confirm default (first item or current).
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Verify value updated
      expect(controller.values['sel_ios'], 'a');

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('SelectWidget shows DropdownButtonFormField on Android',
        (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final component = SelectComponent(
        id: 'sel_android',
        type: 'select',
        key: 'sel_android',
        label: 'Select Android',
        options: [
          SelectOption(label: 'Option A', value: 'a'),
        ],
      );

      final controller = FormController(
        config: FormConfig(
          id: 'form_android',
          title: 'Title',
          description: 'Desc',
          settings: FormSettings(),
          components: [component],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Material(
              child: DynamicSelect(
                component: component,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.byType(CupertinoPicker), findsNothing);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
