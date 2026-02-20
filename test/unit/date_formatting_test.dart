import 'package:flutter_test/flutter_test.dart';
import 'package:form_dynamic_builder/src/models/components/component_utils.dart';

void main() {
  group('formatDate', () {
    final date = DateTime(2023, 10, 5, 14, 30, 45); // 5th Oct 2023, 14:30:45

    test('formats dd/MM/yyyy', () {
      expect(formatDate(date, 'dd/MM/yyyy'), '05/10/2023');
    });

    test('formats yyyy-MM-dd HH:mm:ss', () {
      expect(formatDate(date, 'yyyy-MM-dd HH:mm:ss'), '2023-10-05 14:30:45');
    });

    test('formats complex string with quotes', () {
      // DateFormat requires single quotes for literals
      expect(formatDate(date, "'Date:' dd-MM-yyyy 'Time:' HH:mm"),
          'Date: 05-10-2023 Time: 14:30');
    });
  });
}
