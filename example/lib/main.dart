import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:form_dynamic_builder/form_dynamic_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
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
  Database? _database;

  @override
  void initState() {
    super.initState();
    _initDatabase().then((_) {
      _loadSavedForm();
    });
  }

  Future<void> _initDatabase() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dbPath = join(docsDir.path, 'example.db');

      _database = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE items (id INTEGER PRIMARY KEY, name TEXT)',
          );
          await db.insert('items', {'name': 'Real DB Item 1 (Sqflite)'});
          await db.insert('items', {'name': 'Real DB Item 2 (Sqflite)'});
          await db.insert('items', {'name': 'Real DB Item 3 (Sqflite)'});
        },
      );
    } catch (e) {
      debugPrint('Error initializing database: $e');
    }
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
        },
        {
          "type": "select",
          "key": "api_test",
          "label": "Test API Data Source",
          "dataSource": {
            "type": "api",
            "api": {
              "url": "https://potterapi-fedeperin.vercel.app/en/books",
              "method": "GET",
              "labelPath": "title",
              "valuePath": "index"
            }
          }
        },
        {
          "type": "select",
          "key": "db_test",
          "label": "Test DB Data Source",
          "dataSource": {
            "type": "database",
            "database": {
              "query": "SELECT id, name FROM items",
              "labelPath": "name",
              "valuePath": "id"
            }
          }
        },
        {
          "type": "camera",
          "key": "photo",
          "label": "Take a Photo (Immediate Upload)",
          "uploadTiming": "immediate",
          "uploadUrl": "https://example.com/api/upload"
        }
      ]
    };
  }

  Future<void> _updateForm(Map<String, dynamic> jsonMap,
      {bool save = true}) async {
    try {
      final config = FormConfig.fromJson(
        jsonMap,
        onApiQuery: (url, method, headers, body) async {
          debugPrint('API Query (Dio): $method $url');
          final dio = Dio();
          try {
            final response = await dio.request(
              url,
              data: body.isNotEmpty ? body : null,
              options: Options(
                method: method,
                headers: headers,
              ),
            );
            return response
                .data; // Dio parses JSON automatically for maps/lists
          } catch (e) {
            debugPrint('Dio Error: $e');
            return null;
          }
        },
        onFileUpload: (localPath, uploadUrl) async {
          debugPrint('File Upload (Dio): $localPath to $uploadUrl');
          final dio = Dio();
          try {
            final fileName = localPath.split(Platform.pathSeparator).last;
            final formData = FormData.fromMap({
              'file':
                  await MultipartFile.fromFile(localPath, filename: fileName),
            });

            // Dummy implementation using post request, assuming backend exists
            // Since this is an example, we catch the socket exception
            // and fallback to returning a simulated remote URL
            final response = await dio.post(uploadUrl, data: formData);
            if (response.statusCode == 200) {
              return response.data['url'] ??
                  'https://example.com/uploads/$fileName';
            }
          } catch (e) {
            debugPrint('Dio Upload Error: $e');

            // Simulating a successful upload response if backend is offline
            await Future.delayed(const Duration(seconds: 1));
            final fileName = localPath.split(Platform.pathSeparator).last;
            return 'https://example.com/uploads/simulated_$fileName';
          }
          return null;
        },
        onDatabaseQuery: (connectionString, dbName, query) async {
          debugPrint('DB Query (Sqflite): $query');
          if (_database != null) {
            try {
              return await _database!.rawQuery(query);
            } catch (e) {
              debugPrint('DB Query Error: $e');
              return [];
            }
          }
          return [];
        },
      );

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
