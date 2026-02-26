import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../field_label.dart';
import 'select_logic.dart';

class DynamicSelect extends StatefulWidget {
  final SelectComponent component;
  final FormController controller;

  const DynamicSelect({
    super.key,
    required this.component,
    required this.controller,
  });

  @override
  State<DynamicSelect> createState() => _DynamicSelectState();
}

class _DynamicSelectState extends State<DynamicSelect> {
  late final SelectLogic logic;

  @override
  void initState() {
    super.initState();
    logic = SelectLogic(widget.component, widget.controller);
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(component: widget.component),
              if (logic.isLoadingOptions)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (logic.dataSourceError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Failed to load options',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13),
                  ),
                )
              else if (Theme.of(context).platform == TargetPlatform.iOS ||
                  Theme.of(context).platform == TargetPlatform.macOS)
                _buildCupertinoSelect(context)
              else
                _buildMaterialSelect(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMaterialSelect(BuildContext context) {
    return DropdownButtonFormField<String>(
      focusNode: widget.controller.getFocusNode(widget.component.key),
      value: logic.value,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        errorText: widget.controller.errors[widget.component.key],
      ),
      items: logic.allOptions.map((option) {
        return DropdownMenuItem<String>(
          value: option.value,
          child: Text(option.label),
        );
      }).toList(),
      onChanged: logic.updateValue,
    );
  }

  Widget _buildCupertinoSelect(BuildContext context) {
    return GestureDetector(
      onTap: widget.component.disabled
          ? null
          : () => _showCupertinoPicker(context),
      child: AbsorbPointer(
        child: TextFormField(
          readOnly: true,
          controller: TextEditingController(text: logic.selectedOption.label),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            errorText: widget.controller.errors[widget.component.key],
            suffixIcon: const Icon(CupertinoIcons.chevron_down, size: 16),
          ),
        ),
      ),
    );
  }

  Future<void> _showCupertinoPicker(BuildContext context) async {
    int tempIndex = logic.initialIndex;

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
                      if (logic.allOptions.isNotEmpty) {
                        logic.updateValue(logic.allOptions[tempIndex].value);
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 32.0,
                  scrollController: FixedExtentScrollController(
                      initialItem: logic.initialIndex),
                  onSelectedItemChanged: (int index) {
                    tempIndex = index;
                  },
                  children: logic.allOptions.map((option) {
                    return Center(child: Text(option.label));
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
