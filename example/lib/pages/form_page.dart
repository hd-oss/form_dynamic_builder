import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';
import '../constants/default_form.dart';
import '../services/api_handler.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../paste_json_dialog.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _databaseService = DatabaseService();
  final _storageService = StorageService();

  FormConfig? _formConfig;
  FormController? _formController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _databaseService.init().then((_) {
      _loadSavedForm();
    });
  }

  Future<void> _loadSavedForm() async {
    setState(() => _isLoading = true);
    try {
      final savedJson = await _storageService.loadSavedForm();
      if (savedJson != null) {
        _updateForm(savedJson, save: false);
      } else {
        _updateForm(defaultForm(), save: false);
      }
    } catch (e) {
      debugPrint('Error loading saved form: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetForm() async {
    await _storageService.resetForm();
    _loadSavedForm();
  }

  Future<void> _updateForm(Map<String, dynamic> jsonMap,
      {bool save = true}) async {
    try {
      final config = FormConfig.fromJson(
        jsonMap,
        onApiQuery: ApiHandler.onApiQuery,
        onFileUpload: ApiHandler.onFileUpload,
        onDatabaseQuery: _databaseService.onDatabaseQuery,
      );

      setState(() {
        _formConfig = config;
        _formController = FormController(config: _formConfig!);
      });

      if (save) {
        await _storageService.saveForm(jsonMap);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error parsing form: $e')),
      );
    }
  }

  void _submitForm() {
    if (_formController!.validate()) {
      print(
        const JsonEncoder.withIndent('  ').convert(_formController!.resultMap),
      );
      showDialog(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Submitted Values',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: ClipRRect(
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: IntrinsicWidth(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minWidth:
                                      MediaQuery.of(context).size.width * 0.8 -
                                          64),
                              child: Text(
                                const JsonEncoder.withIndent('  ')
                                    .convert(_formController!.resultMap),
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontFamilyFallback: [
                                      'Courier',
                                      'Menlo',
                                      'Monaco'
                                    ],
                                    fontSize: 13,
                                    height: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Future<void> _showPasteDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const PasteJsonDialog(),
    );

    if (result != null) {
      _updateForm(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Form Builder'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.paste_rounded,
                  color: Theme.of(context).colorScheme.primary),
              tooltip: 'Paste JSON',
              onPressed: _showPasteDialog,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Form',
            onPressed: _resetForm,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _formConfig == null
              ? _buildEmpty()
              : _buildForm(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.description_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No dynamic form loaded',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Paste your custom JSON configuration to start building dynamic forms instantly.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showPasteDialog,
              icon: const Icon(Icons.paste_rounded),
              label: const Text('Paste JSON Config'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final isWizard = _formConfig?.type == 'wizard';
    return Column(
      children: [
        Expanded(
          child: ListenableBuilder(
            listenable: _formController!,
            builder: (context, child) {
              return FormDynamicBuilder(controller: _formController!);
            },
          ),
        ),
        _buildBottomActions(isWizard),
      ],
    );
  }

  Widget _buildBottomActions(bool isWizard) {
    final controller = _formController!;
    final lastStepIndex = (_formConfig?.steps.length ?? 0) - 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  if (isWizard && controller.currentStep > 0)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: OutlinedButton(
                          onPressed: controller.previousStep,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Back',
                              style: TextStyle(color: Color(0xFF475569))),
                        ),
                      ),
                    ),
                  if (isWizard && controller.currentStep < lastStepIndex)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: controller.nextStep,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Next Step'),
                      ),
                    ),
                  if (!isWizard || controller.currentStep == lastStepIndex)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Submit Form'),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
