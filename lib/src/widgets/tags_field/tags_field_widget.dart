import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import '../field_label.dart';
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
              TextFormField(
                focusNode: widget.controller.getFocusNode(widget.component.key),
                controller: logic.textController,
                decoration: InputDecoration(
                  hintText:
                      widget.component.placeholder ?? 'Type and press enter...',
                  border: const OutlineInputBorder(),
                  errorText: widget.controller.errors[widget.component.key],
                ),
                enabled: !widget.component.disabled,
                onFieldSubmitted: (value) {
                  logic.addTag(value.trim());
                  FocusScope.of(context).requestFocus(
                      widget.controller.getFocusNode(widget.component.key));
                },
              ),
              if (logic.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: logic.tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        onDeleted: widget.component.disabled
                            ? null
                            : () => logic.removeTag(tag),
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
