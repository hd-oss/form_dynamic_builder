import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';

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
  final Map<String, String> _forms = {
    'Single Page Form': 'assets/jsons/form_dynamic.json',
    'Wizard Form': 'assets/jsons/form_wizard.json',
  };
  String _selectedForm = 'assets/jsons/form_dynamic.json';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadFormConfig();
    }
  }

  Future<void> _loadFormConfig() async {
    try {
      final jsonString =
          await DefaultAssetBundle.of(context).loadString(_selectedForm);
      final jsonMap = json.decode(jsonString);

      setState(() {
        _formConfig = FormConfig.fromJson(jsonMap);
        _formController = FormController(config: _formConfig!);
      });
    } catch (e) {
      debugPrint('Error parsing JSON from assets: $e');
    }
  }

  void _loadForm(String formName) {
    _selectedForm = 'assets/jsons/$formName.json';
    _loadFormConfig();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if current form is wizard
    final isWizard = _formConfig?.type == 'wizard';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Dynamic Builder'),
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
                try {
                  setState(() {
                    _formConfig = FormConfig.fromJson(result);
                    _formController = FormController(config: _formConfig!);
                  });
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error parsing form: $e')),
                    );
                  }
                }
              }
            },
          ),
          // Switcher between Single Page and Wizard
          PopupMenuButton<String>(
            onSelected: _loadForm,
            itemBuilder: (BuildContext context) {
              return _forms.entries.map((entry) {
                return PopupMenuItem<String>(
                  value: entry.value
                      .replaceAll('assets/jsons/', '')
                      .replaceAll('.json', ''),
                  child: Text(entry.key),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: _formConfig == null
          ? const Center(child: CircularProgressIndicator())
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
                            if (isWizard && _formController!.currentStep > 0)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _formController!.previousStep();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
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
                                        (_formConfig?.steps.length ?? 0) - 1))
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_formController!.validate()) {
                                      debugPrint(
                                          "Form Submitted: ${_formController!.visibleValues}");
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              "Form Submitted: ${_formController!.visibleValues}"),
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
