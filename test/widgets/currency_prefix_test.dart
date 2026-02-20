import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';
import 'package:form_dynamic_builder/src/widgets/fields/text_field_widget.dart';

void main() {
  testWidgets('NumberComponent displays currency symbol from intl (IDR)',
      (WidgetTester tester) async {
    final component = NumberComponent(
      id: 'n1',
      type: 'number',
      key: 'price',
      label: 'Price',
      enableCurrency: true,
      currency: 'IDR',
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
            child: DynamicTextField(
              component: component,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    // Should find 'Rp' in the text/prefix
    // PrefixText is in InputDecoration.
    // find.text('Rp') might not find it if it's in prefixText?
    // Actually standard find.text sometimes misses prefixText.
    // Let's verify via widget inspector style (byType TextField).

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.decoration?.prefixText, 'Rp');
  });

  testWidgets('NumberComponent displays currency symbol from intl (USD)',
      (WidgetTester tester) async {
    final component = NumberComponent(
      id: 'n2',
      type: 'number',
      key: 'cost',
      label: 'Cost',
      enableCurrency: true,
      currency: 'USD',
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
            child: DynamicTextField(
              component: component,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.decoration?.prefixText, '\$');
  });
}
