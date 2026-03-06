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

  void _formatJson() {
    final text = _controller.text;
    if (text.isEmpty) return;
    try {
      final obj = json.decode(text);
      final prettyString = const JsonEncoder.withIndent('  ').convert(obj);
      setState(() {
        _controller.text = prettyString;
        _errorText = null;
      });
    } catch (e) {
      setState(() {
        _errorText = 'Cannot format: Invalid JSON';
      });
    }
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
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded,
                        color: colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Paste JSON Form',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                      ),
                    ),
                    Material(
                      color: colorScheme.primaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _formatJson,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_fix_high_rounded,
                                  size: 16, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Format',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Content / Text Area
              Flexible(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: IntrinsicWidth(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth:
                                  MediaQuery.of(context).size.width * 0.8 - 64,
                            ),
                            child: TextField(
                              controller: _controller,
                              maxLines: 15,
                              autocorrect: false,
                              enableSuggestions: false,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontFamilyFallback: [
                                  'Courier',
                                  'Menlo',
                                  'Monaco'
                                ],
                                fontSize: 13,
                                height: 1.5,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Paste your form configuration JSON here...',
                                hintStyle: TextStyle(
                                  fontFamily: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.fontFamily,
                                  color: Colors.grey[400],
                                ),
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorText: _errorText,
                                contentPadding: const EdgeInsets.all(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel',
                          style: TextStyle(color: Colors.grey[600])),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _validateAndSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Load Configuration'),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
