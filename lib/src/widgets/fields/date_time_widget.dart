import 'package:flutter/material.dart';
import '../../models/components/all_components.dart';
import '../../controller/form_controller.dart';
import 'field_label.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

class DynamicDateTime extends StatelessWidget {
  final DateTimeComponent component;
  final FormController controller;

  const DynamicDateTime({
    super.key,
    required this.component,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final value = controller.getValue(component.key);
          final textController =
              TextEditingController(text: value?.toString() ?? '');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(component: component),
              if (component.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    component.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              TextFormField(
                focusNode: controller.getFocusNode(component.key),
                controller: textController,
                decoration: InputDecoration(
                  hintText: component.placeholder,
                  border: const OutlineInputBorder(),
                  errorText: controller.errors[component.key],
                  prefixIcon: component.timeOnly
                      ? const Icon(Icons.access_time)
                      : const Icon(Icons.calendar_today),
                  suffixIcon: (component.enableTime && !component.timeOnly)
                      ? const Icon(Icons.access_time)
                      : null,
                ),
                readOnly: true,
                onTap: component.disabled ? null : () => _handlePicker(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handlePicker(BuildContext context) async {
    if (component.disabled) return;

    final initialDate =
        _parseInitialDate(controller.getValue(component.key)) ?? DateTime.now();

    // Platform check
    if (Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS) {
      await _showCupertinoDatePicker(context, initialDate);
    } else {
      await _showMaterialPicker(context, initialDate);
    }
  }

  Future<void> _showCupertinoDatePicker(
      BuildContext context, DateTime initialDate) async {
    // If it's Date+Time, we split into two steps to allow Year selection (standard Cupertino DateAndTime mode hides year column).
    if (component.enableTime && !component.timeOnly) {
      await _showCupertinoSplitPicker(context, initialDate);
      return;
    }

    DateTime tempPickedDate = initialDate;

    CupertinoDatePickerMode mode = CupertinoDatePickerMode.date;
    if (component.timeOnly) {
      mode = CupertinoDatePickerMode.time;
    }
    // Else date only

    final minDate = _parseConstraint(component.setAfter);
    final maxDate = _parseConstraint(component.setBefore);

    // Clamp
    if (minDate != null && tempPickedDate.isBefore(minDate)) {
      tempPickedDate = minDate;
    }
    if (maxDate != null && tempPickedDate.isAfter(maxDate)) {
      tempPickedDate = maxDate;
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () {
                      _updateControllerValue(tempPickedDate);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: mode,
                  initialDateTime: tempPickedDate,
                  minimumDate: minDate,
                  maximumDate: maxDate,
                  use24hFormat: component.timeUse24Hour,
                  onDateTimeChanged: (DateTime newDate) {
                    tempPickedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCupertinoSplitPicker(
      BuildContext context, DateTime initialDate) async {
    // Step 1: Pick Date
    DateTime? pickedDate;
    DateTime tempDate = initialDate;

    final minDate = _parseConstraint(component.setAfter);
    final maxDate = _parseConstraint(component.setBefore);

    // Clamp
    if (minDate != null && tempDate.isBefore(minDate)) tempDate = minDate;
    if (maxDate != null && tempDate.isAfter(maxDate)) tempDate = maxDate;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    child: const Text('Next'), // Next instead of Done
                    onPressed: () {
                      pickedDate = tempDate;
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode:
                      CupertinoDatePickerMode.date, // Force date mode for year
                  initialDateTime: tempDate,
                  minimumDate: minDate,
                  maximumDate: maxDate,
                  onDateTimeChanged: (DateTime newDate) {
                    tempDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (pickedDate == null) return;

    // Step 2: Pick Time
    // We can reuse the same modal logic but different mode
    // Wait, iOS native feels weird with back-to-back modals?
    // It's acceptable for this constraint.

    DateTime tempTime = pickedDate!;
    // Preserve the date, but we need to pick time.
    // CupertinoDatePicker mode.time ignores the date part of initialDateTime usually,
    // but returns a DateTime with today's date + picked time?
    // Actually it returns a DateTime with the date from initialDateTime + picked time.

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Back'), // Or Cancel
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () {
                      _updateControllerValue(tempTime);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: tempTime,
                  use24hFormat: component.timeUse24Hour,
                  onDateTimeChanged: (DateTime newDate) {
                    // newDate from mode.time has the date components of initialDateTime (tempTime)
                    // so we just update tempTime.
                    tempTime = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showMaterialPicker(
      BuildContext context, DateTime initialDate) async {
    DateTime? pickedDate;
    TimeOfDay? pickedTime;

    if (component.timeOnly) {
      pickedDate = DateTime.now(); // default for time only
      pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: component.timeUse24Hour,
            ),
            child: child!,
          );
        },
      );
      if (pickedTime == null) return;
    } else {
      final firstDate = _parseConstraint(component.setAfter);
      final lastDate = _parseConstraint(component.setBefore);

      pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate ?? DateTime(1900),
        lastDate: lastDate ?? DateTime(2100),
      );

      if (pickedDate == null) return;

      if (component.enableTime) {
        if (!context.mounted) return;
        pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(initialDate),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                alwaysUse24HourFormat: component.timeUse24Hour,
              ),
              child: child!,
            );
          },
        );
        if (pickedTime == null) return;
      }
    }

    // Combine
    final finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime?.hour ?? 0,
      pickedTime?.minute ?? 0,
    );

    _updateControllerValue(finalDateTime);
  }

  void _updateControllerValue(DateTime finalDateTime) {
    // Format based on type or component.format
    String result;
    if (component.format != null && component.format!.isNotEmpty) {
      result = formatDate(finalDateTime, component.format!);
    } else if (component.timeOnly) {
      // Default: HH:mm:ss
      result = DateFormat('HH:mm:ss').format(finalDateTime);
    } else if (component.enableTime) {
      // Default: yyyy-MM-dd HH:mm:ss
      result = DateFormat('yyyy-MM-dd HH:mm:ss').format(finalDateTime);
    } else {
      // Default: yyyy-MM-dd
      result = DateFormat('yyyy-MM-dd').format(finalDateTime);
    }

    controller.updateValue(component.key, result);
  }

  DateTime? _parseInitialDate(dynamic value) {
    if (value == null) return null;
    try {
      // Try ISO first
      return DateTime.parse(value.toString());
    } catch (e) {
      // Fallback? If formats differ, parsing is hard without knowing input format.
      // But we generally store ISO or standardized string.
      // If customized format is used, we technically can't parse it back easily without 'intl' parse method and EXACT pattern.
      // If we used DateFormat to write, we can use DateFormat to read?
      if (component.format != null) {
        try {
          return DateFormat(component.format).parse(value.toString());
        } catch (_) {}
      }
      return null;
    }
  }

  DateTime? _parseConstraint(Map<String, dynamic>? constraint) {
    if (constraint == null) return null;
    if (constraint['type'] == 'static') {
      final val = constraint['value'];
      if (val is int) {
        // Assumption: value is days offset from Today.
        // Positive value adds days.
        // Example: setBefore: 7 -> Today + 7 days.
        // Example: setAfter: 30 -> Today + 30 days.
        // Wait, usually Min Date (setAfter) should be in the past? Or future?
        // Let's strictly follow: Date = Now + val days.
        return DateTime.now().add(Duration(days: val));
      }
    }
    return null;
  }
}
