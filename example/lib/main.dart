import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'paste_json_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Form Dynamic Builder Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const FormPage(),
    );
  }
}

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  FormConfig? _formConfig;
  FormController? _formController;
  bool _isLoading = true;

  static const String _storageKey = 'saved_form_json';

  @override
  void initState() {
    super.initState();
    _loadSavedForm();
  }

  // ---------------------------------------------------------------------------
  // REGION: STORAGE
  // ---------------------------------------------------------------------------

  Future<void> _loadSavedForm() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_storageKey);

      if (savedJson != null) {
        _updateForm(json.decode(savedJson), save: false);
      } else {
        _updateForm(_defaultForm(), save: false);
      }
    } catch (e) {
      debugPrint('Error loading saved form: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveForm(Map<String, dynamic> jsonMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(jsonMap));
  }

  Future<void> _resetForm() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    _loadSavedForm();
  }

  // ---------------------------------------------------------------------------
  // REGION: FORM HANDLING
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _defaultForm() {
    return {
      "type": "single",
      "title": "Welcome",
      "components": [
        {
          "type": "textfield",
          "key": "welcome",
          "label": "Welcome to Dynamic Builder",
          "placeholder": "Paste your custom JSON to begin!",
          "disabled": true
        }
      ]
    };
  }

  Future<void> _updateForm(Map<String, dynamic> jsonMap,
      {bool save = true}) async {
    try {
      final config = FormConfig.fromJson(jsonMap);

      setState(() {
        _formConfig = config;
        _formController = FormController(config: _formConfig!);
      });

      if (save) {
        await _saveForm(jsonMap);
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
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Submitted Values'),
          content: SingleChildScrollView(
            child: Text(
              const JsonEncoder.withIndent('  ')
                  .convert(_formController!.visibleValues),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // REGION: UI BUILDERS
  // ---------------------------------------------------------------------------

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.note_add_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No form loaded'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _showPasteDialog,
            child: const Text('Paste JSON'),
          ),
        ],
      ),
    );
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
            return Row(
              children: [
                if (isWizard && controller.currentStep > 0)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ElevatedButton(
                        onPressed: controller.previousStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  ),
                if (isWizard && controller.currentStep < lastStepIndex)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.nextStep,
                      child: const Text('Next'),
                    ),
                  ),
                if (!isWizard || controller.currentStep == lastStepIndex)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      child: const Text('Submit'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // REGION: MAIN BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Form Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.paste),
            tooltip: 'Paste JSON',
            onPressed: _showPasteDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Reset Form',
            onPressed: _resetForm,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _formConfig == null
              ? _buildEmpty()
              : _buildForm(),
    );
  }
}