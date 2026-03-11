import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../field_label.dart';
import 'checkbox_logic.dart';

class DynamicCheckbox extends StatefulWidget {
  final CheckboxComponent component;
  final FormController controller;

  const DynamicCheckbox({
    super.key,
    required this.component,
    required this.controller,
  });

  @override
  State<DynamicCheckbox> createState() => _DynamicCheckboxState();
}

class _DynamicCheckboxState extends State<DynamicCheckbox> {
  late final CheckboxLogic logic;

  @override
  void initState() {
    super.initState();
    logic = CheckboxLogic(widget.component, widget.controller);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(component: widget.component),
          InputDecorator(
            decoration: InputDecoration(
              border: InputBorder.none,
              errorText: widget.controller.errors[widget.component.key],
            ),
            child: ListTile(
              enabled: !widget.component.disabled,
              leading: Checkbox.adaptive(
                value: logic.value,
                onChanged: widget.component.disabled ? null : logic.onChanged,
              ),
              title: Text(widget.component.label),
              contentPadding: EdgeInsets.zero,
              minTileHeight: 0,
              horizontalTitleGap: 0,
            ),
          ),
        ],
      ),
    );
  }
}
