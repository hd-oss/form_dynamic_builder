import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../field_label.dart';
import '../common/data_source_state_builder.dart';
import '../common/dropdown_overlay.dart';
import 'tags_field_logic.dart';

class TagsFieldWidget extends StatefulWidget {
  final TagsComponent component;
  final FormController controller;

  const TagsFieldWidget({
    super.key,
    required this.component,
    required this.controller,
  });

  @override
  State<TagsFieldWidget> createState() => _TagsFieldWidgetState();
}

class _TagsFieldWidgetState extends State<TagsFieldWidget> {
  late final TagsFieldLogic logic;

  @override
  void initState() {
    super.initState();
    logic = TagsFieldLogic(widget.component, widget.controller);

    final focusNode = widget.controller.getFocusNode(widget.component.key);
    focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    final focusNode = widget.controller.getFocusNode(widget.component.key);
    if (!focusNode.hasFocus) {
      logic.clearSuggestions();
    }
  }

  @override
  void dispose() {
    final focusNode = widget.controller.getFocusNode(widget.component.key);
    focusNode.removeListener(_onFocusChanged);
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
          DataSourceStateBuilder(
            logic: logic,
            component: widget.component,
            builder: (context) {
              final focusNode =
                  widget.controller.getFocusNode(widget.component.key);
              final isShowing =
                  logic.suggestions.isNotEmpty && focusNode.hasFocus;

              return DropdownOverlay<SelectOption>(
                isShowing: isShowing,
                items: logic.suggestions,
                onItemSelected: (option) => logic.selectSuggestion(option),
                itemBuilder: (context, option) =>
                    ListTile(title: Text(option.label), minTileHeight: 0),
                child: TextFormField(
                  focusNode: focusNode,
                  controller: logic.textController,
                  decoration: InputDecoration(
                    hintText: widget.component.placeholder ??
                        'Type and press enter...',
                    border: const OutlineInputBorder(),
                    errorText: widget.controller.errors[widget.component.key],
                  ),
                  enabled: !widget.component.disabled,
                  onChanged: (value) => logic.fetchSuggestions(value),
                  onFieldSubmitted: (value) {
                    logic.addTag(value.trim());
                    FocusScope.of(context).requestFocus(focusNode);
                  },
                ),
              );
            },
          ),
          if (logic.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: logic.tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          onDeleted: widget.component.disabled
                              ? null
                              : () => logic.removeTag(tag),
                        ))
                    .toList()),
          ]
        ],
      ),
    );
  }
}
