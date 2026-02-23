import 'package:flutter/material.dart';

import '../../controller/form_controller.dart';
import '../../models/components/all_components.dart';
import 'field_label.dart';

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
  late TextEditingController _textController;
  late FocusNode _focusNode;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = widget.controller.getFocusNode(widget.component.key);
    _initTags();
  }

  void _initTags() {
    final value = widget.controller.getValue(widget.component.key);
    if (value is List) {
      _tags = value.map((e) => e.toString()).toList();
    } else if (value is String && value.isNotEmpty) {
      if (widget.component.storeAs == 'string') {
        _tags = value.split(',').map((e) => e.trim()).toList();
      } else {
        _tags = [value];
      }
    } else {
      _tags = [];
    }
  }

  void _updateController() {
    dynamic valueToStore;
    if (widget.component.storeAs == 'string') {
      valueToStore = _tags.join(', ');
    } else {
      valueToStore = List<String>.from(_tags);
    }
    widget.controller.updateValue(widget.component.key, valueToStore);
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
      _updateController();
    }
    _textController.clear();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    _updateController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(component: widget.component),
              TextFormField(
                focusNode: _focusNode,
                controller: _textController,
                decoration: InputDecoration(
                  hintText:
                      widget.component.placeholder ?? 'Type and press enter...',
                  border: const OutlineInputBorder(),
                  errorText: widget.controller.errors[widget.component.key],
                ),
                enabled: !widget.component.disabled,
                onFieldSubmitted: (value) {
                  _addTag(value.trim());
                  _focusNode.requestFocus();
                },
              ),
              if (_tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        onDeleted: widget.component.disabled
                            ? null
                            : () => _removeTag(tag),
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
