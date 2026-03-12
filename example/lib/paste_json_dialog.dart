import 'dart:convert';
import 'package:flutter/material.dart';

class PasteJsonDialog extends StatefulWidget {
  const PasteJsonDialog({super.key});

  @override
  State<PasteJsonDialog> createState() => _PasteJsonDialogState();
}

class _PasteJsonDialogState extends State<PasteJsonDialog> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _dsFormController = TextEditingController();
  String? _errorText;
  String? _dsFormError;

  @override
  void dispose() {
    _controller.dispose();
    _dsFormController.dispose();
    super.dispose();
  }

  void _formatJson() {
    _formatField(_controller, false);
    _formatField(_dsFormController, true);
  }

  void _formatField(TextEditingController controller, bool isDsForm) {
    if (controller.text.isEmpty) return;
    try {
      final obj = json.decode(controller.text);
      final prettyString = const JsonEncoder.withIndent('  ').convert(obj);
      setState(() {
        controller.text = prettyString;
        if (isDsForm) {
          _dsFormError = null;
        } else {
          _errorText = null;
        }
      });
    } catch (e) {
      setState(() {
        if (isDsForm) {
          _dsFormError = 'Cannot format: Invalid JSON';
        } else {
          _errorText = 'Cannot format: Invalid JSON';
        }
      });
    }
  }

  void _validateAndSubmit() {
    final text = _controller.text;
    final dsText = _dsFormController.text;

    if (text.isEmpty) {
      setState(() {
        _errorText = 'Please enter some JSON for the Schema';
      });
      return;
    }

    try {
      final map = json.decode(text);
      if (map is! Map<String, dynamic>) {
        setState(() {
          _errorText = 'Schema must be a JSON object';
        });
        return;
      }
      _errorText = null;

      if (dsText.isNotEmpty) {
        final dsMap = json.decode(dsText);
        if (dsMap is! Map<String, dynamic>) {
          setState(() {
            _dsFormError = 'DS Form must be a JSON object';
          });
          return;
        }
        map['ds_form'] = dsMap;
      }
      _dsFormError = null;

      Navigator.of(context).pop(map);
    } catch (e) {
      setState(() {
        _errorText = 'Invalid JSON: $e';
      });
    }
  }

  Widget _buildEditor(BuildContext context, TextEditingController controller,
      String hint, String? error) {
    return Container(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          )),
      child: ClipRRect(
        child: Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicWidth(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width * 0.8 - 64,
                ),
                child: TextField(
                  controller: controller,
                  maxLines: 100,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontFamilyFallback: ['Courier', 'Menlo', 'Monaco'],
                    fontSize: 13,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontFamily:
                          Theme.of(context).textTheme.bodyMedium?.fontFamily,
                      color: Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorText: error,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: DefaultTabController(
          length: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded,
                        color: colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Paste Data',
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

              TabBar(
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicatorColor: colorScheme.primary,
                tabs: const [
                  Tab(text: 'Form Schema'),
                  Tab(text: 'DS Form (Optional)'),
                ],
              ),
              const Divider(height: 1),

              // Content / Text Area
              Flexible(
                child: TabBarView(
                  children: [
                    _buildEditor(
                        context,
                        _controller,
                        'Paste your form configuration JSON here...',
                        _errorText),
                    _buildEditor(
                        context,
                        _dsFormController,
                        'Paste your ds_form JSON map here (e.g. {"user": {"role": "admin"}})...',
                        _dsFormError),
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
