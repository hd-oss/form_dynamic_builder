import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';

class DateTimeLogic extends ChangeNotifier {
  final DateTimeComponent component;
  final FormController formController;

  DateTimeLogic(this.component, this.formController) {
    // DateTimeComponent no longer supports dataSource
    // initDefaultValue(
    //   dataSource: component.dataSource,
    //   controller: controller,
    //   componentKey: component.key,
    // );
  }

  DateTime getInitialDate() {
    final value = formController.getValue(component.key);
    if (value == null) return DateTime.now();

    try {
      if (component.format != null && component.format!.isNotEmpty) {
        return DateFormat(component.format!).parse(value.toString());
      }
    } catch (_) {}

    try {
      return DateTime.parse(value.toString());
    } catch (_) {}

    try {
      if (component.timeOnly) {
        final parsedTime = DateFormat('HH:mm').parse(value.toString());
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, parsedTime.hour,
            parsedTime.minute, parsedTime.second);
      }
    } catch (_) {}

    return DateTime.now();
  }

  DateTime? getMinDate() => _parseConstraint(component.setAfter);

  DateTime? getMaxDate() => _parseConstraint(component.setBefore);

  DateTime? _parseConstraint(Map<String, dynamic>? constraint) {
    if (constraint == null) return null;
    if (constraint['type'] == 'static') {
      final val = constraint['value'];
      if (val is int) {
        return DateTime.now().add(Duration(days: val));
      }
    }
    return null;
  }

  void updateControllerValue(DateTime finalDateTime) {
    String result;
    if (component.format != null && component.format!.isNotEmpty) {
      result = DateFormat(component.format!).format(finalDateTime);
    } else if (component.timeOnly) {
      result = DateFormat('HH:mm:ss').format(finalDateTime);
    } else if (component.enableTime) {
      result = DateFormat('yyyy-MM-dd HH:mm:ss').format(finalDateTime);
    } else {
      result = DateFormat('yyyy-MM-dd').format(finalDateTime);
    }
    formController.updateValue(component.key, result);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
