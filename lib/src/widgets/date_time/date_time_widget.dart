import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../field_label.dart';
import 'date_time_logic.dart';

class DynamicDateTime extends StatefulWidget {
  final DateTimeComponent component;
  final FormController controller;

  const DynamicDateTime({
    super.key,
    required this.component,
    required this.controller,
  });

  @override
  State<DynamicDateTime> createState() => _DynamicDateTimeState();
}

class _DynamicDateTimeState extends State<DynamicDateTime> {
  late final DateTimeLogic logic;

  @override
  void initState() {
    super.initState();
    logic = DateTimeLogic(widget.component, widget.controller);
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.controller, logic]),
        builder: (context, _) {
          final value = widget.controller.getValue(widget.component.key);
          final textController =
              TextEditingController(text: value?.toString() ?? '');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(component: widget.component),
              if (widget.component.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    widget.component.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              TextFormField(
                focusNode: widget.controller.getFocusNode(widget.component.key),
                controller: textController,
                decoration: InputDecoration(
                  hintText: widget.component.placeholder,
                  border: const OutlineInputBorder(),
                  errorText: widget.controller.errors[widget.component.key],
                  prefixIcon: widget.component.timeOnly
                      ? const Icon(Icons.access_time)
                      : const Icon(Icons.calendar_today),
                  suffixIcon: (widget.component.enableTime &&
                          !widget.component.timeOnly)
                      ? const Icon(Icons.access_time)
                      : null,
                ),
                readOnly: true,
                onTap: widget.component.disabled
                    ? null
                    : () => _handlePicker(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handlePicker(BuildContext context) async {
    if (widget.component.disabled) return;

    final initialDate = logic.getInitialDate();

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
    if (widget.component.enableTime && !widget.component.timeOnly) {
      await _showCupertinoSplitPicker(context, initialDate);
      return;
    }

    DateTime tempPickedDate = initialDate;

    CupertinoDatePickerMode mode = CupertinoDatePickerMode.date;
    if (widget.component.timeOnly) {
      mode = CupertinoDatePickerMode.time;
    }

    final minDate = logic.getMinDate();
    final maxDate = logic.getMaxDate();

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
                      logic.updateControllerValue(tempPickedDate);
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
                  use24hFormat: widget.component.timeUse24Hour,
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

    final minDate = logic.getMinDate();
    final maxDate = logic.getMaxDate();

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
                    child: const Text('Next'),
                    onPressed: () {
                      pickedDate = tempDate;
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
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
    DateTime tempTime = pickedDate!;

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
                    child: const Text('Back'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () {
                      logic.updateControllerValue(tempTime);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: tempTime,
                  use24hFormat: widget.component.timeUse24Hour,
                  onDateTimeChanged: (DateTime newDate) {
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

    if (widget.component.timeOnly) {
      pickedDate = DateTime.now(); // default for time only
      pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: widget.component.timeUse24Hour,
            ),
            child: child!,
          );
        },
      );
      if (pickedTime == null) return;
    } else {
      final firstDate = logic.getMinDate();
      final lastDate = logic.getMaxDate();

      pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate ?? DateTime(1900),
        lastDate: lastDate ?? DateTime(2100),
      );

      if (pickedDate == null) return;

      if (widget.component.enableTime) {
        if (!context.mounted) return;
        pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(initialDate),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                alwaysUse24HourFormat: widget.component.timeUse24Hour,
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

    logic.updateControllerValue(finalDateTime);
  }
}
