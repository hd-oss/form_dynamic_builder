import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Form Dynamic Builder Example',
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFormConfig();
  }

  Future<void> _loadFormConfig() async {
    try {
      final jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/jsons/form_dynamic.json');
      final jsonMap = json.decode(jsonString);

      setState(() {
        _formConfig = FormConfig.fromJson(jsonMap);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error parsing JSON from assets: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Form'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _formConfig == null
              ? const Center(child: Text('Failed to load form'))
              : FormDynamicBuilder(
                  formConfig: _formConfig!,
                  onSubmit: (values) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Form Submitted'),
                        content: Text(json.encode(values)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
