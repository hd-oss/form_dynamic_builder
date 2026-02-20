import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import 'field_label.dart';

class DynamicSelect extends StatelessWidget {
  final SelectComponent component;
  final FormController controller;

  const DynamicSelect({
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(component: component),
              if (Theme.of(context).platform == TargetPlatform.iOS ||
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
      focusNode: controller.getFocusNode(component.key),
      value: controller.getValue(component.key),
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        errorText: controller.errors[component.key],
      ),
      items: component.options.map((option) {
        return DropdownMenuItem<String>(
          value: option.value,
          child: Text(option.label),
        );
      }).toList(),
      onChanged: component.disabled
          ? null
          : (String? newValue) {
              controller.updateValue(component.key, newValue);
            },
    );
  }

  Widget _buildCupertinoSelect(BuildContext context) {
    final value = controller.getValue(component.key);
    final selectedOption = component.options.firstWhere(
      (element) => element.value == value,
      orElse: () => SelectOption(label: '', value: ''),
    );

    return GestureDetector(
      onTap: component.disabled ? null : () => _showCupertinoPicker(context),
      child: AbsorbPointer(
        child: TextFormField(
          readOnly: true,
          controller: TextEditingController(text: selectedOption.label),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            errorText: controller.errors[component.key],
            suffixIcon: const Icon(CupertinoIcons.chevron_down, size: 16),
          ),
        ),
      ),
    );
  }

  Future<void> _showCupertinoPicker(BuildContext context) async {
    final value = controller.getValue(component.key);
    int initialIndex = component.options.indexWhere((e) => e.value == value);
    if (initialIndex == -1) initialIndex = 0;

    // We need to track selection in the picker
    int tempIndex = initialIndex;

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
                      if (component.options.isNotEmpty) {
                        controller.updateValue(
                            component.key, component.options[tempIndex].value);
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 32.0,
                  scrollController:
                      FixedExtentScrollController(initialItem: initialIndex),
                  onSelectedItemChanged: (int index) {
                    tempIndex = index;
                  },
                  children: component.options.map((option) {
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
