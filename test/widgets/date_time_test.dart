import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';
import 'package:form_dynamic_builder/src/widgets/date_time/date_time_widget.dart';

void main() {
  testWidgets('DateTimeWidget renders calendar icon by default',
      (WidgetTester tester) async {
    final component = DateTimeComponent(
      id: 'dt1',
      type: 'datetime',
      key: 'dob',
      label: 'Date of Birth',
      enableTime: false,
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
    await tester.pump();

    expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    expect(find.byIcon(Icons.access_time), findsNothing);
  });

  testWidgets('DateTimeWidget renders time icon when timeOnly is true',
      (WidgetTester tester) async {
    final component = DateTimeComponent(
      id: 'dt2',
      type: 'datetime',
      key: 'time',
      label: 'Time',
      enableTime: true,
      timeOnly: true,
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
    await tester.pump();

    // Prefix icon should be time
    expect(find.byIcon(Icons.access_time), findsOneWidget);
    // Calendar should be gone
    expect(find.byIcon(Icons.calendar_today), findsNothing);
  });

  testWidgets(
      'DateTimeWidget renders both icons when enableTime is true (not timeOnly)',
      (WidgetTester tester) async {
    final component = DateTimeComponent(
      id: 'dt3',
      type: 'datetime',
      key: 'event',
      label: 'Event',
      enableTime: true,
      timeOnly: false,
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
    await tester.pump();

    // Prefix calendar
    expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    // Suffix time (as per logic: suffixIcon: (enableTime && !timeOnly) ? access_time : null)
    expect(find.byIcon(Icons.access_time), findsOneWidget);
  });

  testWidgets('DateTimeWidget handles dynamic API limits loading state',
      (WidgetTester tester) async {
    final component = DateTimeComponent(
      id: 'dt-api',
      type: 'datetime',
      key: 'api_date',
      label: 'API Date',
      setBefore: DateLimitConfig(
        type: 'api',
        unit: 'days',
        api: DataSourceApi(url: 'https://api.example.com/limit'),
      ),
    );

    final config = FormConfig(
      id: 'form-api',
      title: 'T',
      description: 'D',
      settings: FormSettings(),
      components: [component],
      onApiQuery: (url, method, headers, body) async {
        // Add a small delay to test loading state
        await Future.delayed(const Duration(milliseconds: 100));
        if (url == 'https://api.example.com/limit') {
          return 5;
        }
        return null;
      },
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

    // Initial frame: should show loading indicator in suffixIcon
    // Since _initLimits is called in logic constructor (initState), it sets isLoadingLimits = true
    // Before any await, it notifies listeners.
    await tester.pump(); // trigger the first frame after notifyListeners()
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the API call to complete
    await tester.pump(const Duration(milliseconds: 200));

    // Loading should be gone
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
