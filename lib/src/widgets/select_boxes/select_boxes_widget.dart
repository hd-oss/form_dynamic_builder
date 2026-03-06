import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/select_boxes_component.dart';
import '../../services/mixins/datasource_mixin.dart';
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
              if (widget.component.dataSource != null &&
                  logic.dsState == DataSourceState.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 4),
                    ),
                  ),
                )
              else if (widget.component.dataSource != null &&
                  logic.dsState == DataSourceState.error)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                    child: Text(
                      logic.dsError ?? 'Failed to load data',
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                )
              else
                InputDecorator(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    errorText: widget.controller.errors[widget.component.key],
                  ),
                  child: Focus(
                    focusNode: widget.controller.getFocusNode(
                      widget.component.key,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: logic.allOptions.map((option) {
                        final isSelected = currentValues.contains(option.value);
                        return ListTile(
                            leading: Checkbox.adaptive(
                                value: isSelected,
                                onChanged: widget.component.disabled
                                    ? null
                                    : (bool? checked) => logic.updateValue(
                                          option.value,
                                          checked ?? false,
                                        )),
                            title: Text(option.label),
                            onTap: widget.component.disabled
                                ? null
                                : () => logic.updateValue(
                                    option.value, !isSelected),
                            contentPadding: EdgeInsets.zero,
                            minTileHeight: 0,
                            horizontalTitleGap: 0);
                      }).toList(),
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
