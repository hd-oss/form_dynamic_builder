import 'dart:convert';
import 'package:flutter/material.dart';

class PasteJsonDialog extends StatefulWidget {
  const PasteJsonDialog({super.key});

  @override
  State<PasteJsonDialog> createState() => _PasteJsonDialogState();
}

class _PasteJsonDialogState extends State<PasteJsonDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final text = _controller.text;
    if (text.isEmpty) {
      setState(() {
        _errorText = 'Please enter some JSON';
      });
      return;
    }
    try {
      final map = json.decode(text);
      if (map is! Map<String, dynamic>) {
        setState(() {
          _errorText = 'Expected a JSON object';
        });
        return;
      }
      Navigator.of(context).pop(map);
    } catch (e) {
      setState(() {
        _errorText = 'Invalid JSON: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Paste JSON Form'),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: _controller,
          maxLines: 15,
          decoration: InputDecoration(
            hintText: 'Paste your form JSON here...',
            border: const OutlineInputBorder(),
            errorText: _errorText,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _validateAndSubmit,
          child: const Text('Load Form'),
        ),
      ],
    );
  }
}
