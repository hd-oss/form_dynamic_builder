import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/select_boxes_component.dart';
import '../field_label.dart';
import 'select_boxes_logic.dart';

class SelectBoxesWidget extends StatefulWidget {
  final SelectBoxesComponent component;
  final FormController controller;

  const SelectBoxesWidget({
    super.key,
    required this.component,
    required this.controller,
  });

  @override
  State<SelectBoxesWidget> createState() => _SelectBoxesWidgetState();
}

class _SelectBoxesWidgetState extends State<SelectBoxesWidget> {
  late final SelectBoxesLogic logic;

  @override
  void initState() {
    super.initState();
    logic = SelectBoxesLogic(widget.component, widget.controller);
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
          final currentValues = logic.currentValues;

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
              ...widget.component.options.map((option) {
                final isSelected = currentValues.contains(option.value);
                return CheckboxListTile.adaptive(
                  title: Text(option.label),
                  value: isSelected,
                  onChanged: widget.component.disabled
                      ? null
                      : (bool? checked) {
                          logic.updateValue(option.value, checked ?? false);
                        },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }),
              if (widget.controller.errors.containsKey(widget.component.key))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    widget.controller.errors[widget.component.key]!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
