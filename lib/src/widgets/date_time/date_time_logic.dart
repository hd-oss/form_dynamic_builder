import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../../models/components/date_limit_config.dart';
import '../../services/datasource_api_service.dart';
import '../../services/datasource_db_service.dart';

class DateTimeLogic extends ChangeNotifier {
  final DateTimeComponent component;
  final FormController formController;

  bool isLoadingLimits = false;
  DateTime? minDate;
  DateTime? maxDate;

  DateTimeLogic(this.component, this.formController) {
    _initLimits();
  }

  Future<void> _initLimits() async {
    isLoadingLimits = true;
    notifyListeners();

    minDate = await _resolveConstraint(component.setAfter);
    maxDate = await _resolveConstraint(component.setBefore);

    isLoadingLimits = false;
    notifyListeners();
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

  DateTime? getMinDate() => minDate;

  DateTime? getMaxDate() => maxDate;

  Future<DateTime?> _resolveConstraint(DateLimitConfig? constraint) async {
    if (constraint == null) return null;

    int? offsetValue;

    if (constraint.type == 'static') {
      offsetValue = constraint.value;
    } else if (constraint.type == 'api' && constraint.api != null) {
      final res = await DatasourceApiService.fetchDefaultValue(
        api: constraint.api!,
        controller: formController,
      );
      offsetValue = int.tryParse(res?.toString() ?? '');
    } else if (constraint.type == 'database' && constraint.database != null) {
      final res = await DatasourceDbService.fetchDatabaseDefaultValue(
        database: constraint.database!,
        controller: formController,
      );
      offsetValue = int.tryParse(res?.toString() ?? '');
    }

    if (offsetValue == null) return null;

    final now = DateTime.now();
    final unit = constraint.unit ?? 'days';

    if (unit == 'years') {
      return DateTime(now.year + offsetValue, now.month, now.day, now.hour,
          now.minute, now.second);
    } else if (unit == 'months') {
      return DateTime(now.year, now.month + offsetValue, now.day, now.hour,
          now.minute, now.second);
    } else {
      // default to days
      return now.add(Duration(days: offsetValue));
    }
  }

  void updateControllerValue(DateTime finalDateTime) {
    String displayText;
    if (component.format != null && component.format!.isNotEmpty) {
      displayText = DateFormat(component.format!).format(finalDateTime);
    } else if (component.timeOnly) {
      displayText = DateFormat('HH:mm:ss').format(finalDateTime);
    } else if (component.enableTime) {
      displayText = DateFormat('yyyy-MM-dd HH:mm:ss').format(finalDateTime);
    } else {
      displayText = DateFormat('yyyy-MM-dd').format(finalDateTime);
    }
    // answerValue = ISO string for machine processing, answerText = formatted for display/drafting
    formController.updateValueWithLabel(
        component.key, displayText, displayText);
  }
}
