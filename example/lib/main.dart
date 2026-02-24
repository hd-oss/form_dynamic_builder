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

  Future<void> _loadSavedForm() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_storageKey);

      if (savedJson != null) {
        final jsonMap = json.decode(savedJson);
        _updateForm(jsonMap, save: false);
      } else {
        // Fallback to a very basic default form if nothing is saved
        _updateForm({
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
        }, save: false);
      }
    } catch (e) {
      debugPrint('Error loading saved form: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_storageKey, json.encode(jsonMap));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing form: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWizard = _formConfig?.type == 'wizard';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Form Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.paste),
            tooltip: 'Paste JSON',
            onPressed: () async {
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (context) => const PasteJsonDialog(),
              );
              if (result != null) {
                _updateForm(result);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Reset Form',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove(_storageKey);
              _loadSavedForm();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _formConfig == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.note_add_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No form loaded'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) => const PasteJsonDialog(),
                          );
                          if (result != null) {
                            _updateForm(result);
                          }
                        },
                        child: const Text('Paste JSON'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListenableBuilder(
                        listenable: _formController!,
                        builder: (context, child) {
                          return FormDynamicBuilder(
                            controller: _formController!,
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ListenableBuilder(
                          listenable: _formController!,
                          builder: (context, child) {
                            return Row(
                              children: [
                                if (isWizard &&
                                    _formController!.currentStep > 0)
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _formController!.previousStep();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[200],
                                          foregroundColor: Colors.black,
                                        ),
                                        child: const Text('Back'),
                                      ),
                                    ),
                                  ),
                                if (isWizard &&
                                    _formController!.currentStep <
                                        (_formConfig?.steps.length ?? 0) - 1)
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _formController!.nextStep();
                                      },
                                      child: const Text('Next'),
                                    ),
                                  ),
                                if (!isWizard ||
                                    (isWizard &&
                                        _formController!.currentStep ==
                                            (_formConfig?.steps.length ?? 0) -
                                                1))
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (_formController!.validate()) {
                                          debugPrint(
                                              "Form Values: ${_formController!.visibleValues}");
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                  'Submitted Values'),
                                              content: SingleChildScrollView(
                                                child: Text(const JsonEncoder
                                                        .withIndent('  ')
                                                    .convert(_formController!
                                                        .visibleValues)),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Close'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Submit'),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
