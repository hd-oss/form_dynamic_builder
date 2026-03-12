import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../../services/mixins/datasource_mixin.dart';
import '../field_label.dart';
import '../common/dropdown_overlay.dart';
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
  bool _isDropdownShowing = false;

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
        builder: (context, _) => Column(
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
              [
                TargetPlatform.iOS,
                TargetPlatform.macOS,
              ].contains(Theme.of(context).platform)
                  ? _buildCupertinoSelect(context)
                  : _buildMaterialSelect(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialSelect(BuildContext context) {
    final focusNode = widget.controller.getFocusNode(widget.component.key);

    return DropdownOverlay<SelectOption>(
      isShowing: _isDropdownShowing && logic.filteredOptions.isNotEmpty,
      items: logic.filteredOptions,
      onItemSelected: (option) {
        setState(() {
          _isDropdownShowing = false;
        });
        logic.updateValue(option.value);
        focusNode.unfocus();
      },
      onDismissed: () {
        setState(() {
          _isDropdownShowing = false;
        });
      },
      itemBuilder: (context, option) {
        return ListTile(
          title: Text(option.label),
          selected: logic.value == option.value,
          minTileHeight: 0,
        );
      },
      child: TextFormField(
        focusNode: focusNode,
        controller: logic.textController,
        decoration: InputDecoration(
          hintText: widget.component.placeholder ?? 'Search...',
          border: const OutlineInputBorder(),
          errorText: widget.controller.errors[widget.component.key],
          suffixIcon: IconButton(
            icon: Icon(
              _isDropdownShowing ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            ),
            onPressed: widget.component.disabled
                ? null
                : () {
                    setState(() {
                      _isDropdownShowing = !_isDropdownShowing;
                      if (_isDropdownShowing) {
                        logic.clearSuggestions();
                        focusNode.requestFocus();
                      }
                    });
                  },
          ),
        ),
        enabled: !widget.component.disabled,
        onChanged: (value) {
          if (!_isDropdownShowing) {
            setState(() {
              _isDropdownShowing = true;
            });
          }
          logic.fetchSuggestions(value);
        },
        onTap: () {
          if (!_isDropdownShowing) {
            setState(() {
              _isDropdownShowing = true;
            });
          }
        },
      ),
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
