import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../field_label.dart';
import '../common/data_source_state_builder.dart';
import 'radio_logic.dart';

class DynamicRadio extends StatefulWidget {
  final RadioComponent component;
  final FormController controller;

  const DynamicRadio({
    super.key,
    required this.component,
    required this.controller,
  });

  @override
  State<DynamicRadio> createState() => _DynamicRadioState();
}

class _DynamicRadioState extends State<DynamicRadio> {
  late final RadioLogic logic;

  @override
  void initState() {
    super.initState();
    logic = RadioLogic(widget.component, widget.controller);
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
          return DataSourceStateBuilder(
            logic: logic,
            component: widget.component,
            builder: (context) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FieldLabel(component: widget.component),
                  InputDecorator(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      errorText: widget.controller.errors[widget.component.key],
                    ),
                    child: Focus(
                      focusNode:
                          widget.controller.getFocusNode(widget.component.key),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: logic.allOptions.map((option) {
                          return ListTile(
                            leading: Radio<String>(
                              value: option.value,
                              groupValue: logic.groupValue,
                              onChanged: logic.onChanged,
                            ),
                            title: Text(option.label),
                            contentPadding: EdgeInsets.zero,
                            minTileHeight: 0,
                            horizontalTitleGap: 0,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
