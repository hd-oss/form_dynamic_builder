import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _storageKey = 'saved_form_json';

  Future<Map<String, dynamic>?> loadSavedForm() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString(_storageKey);
    if (savedJson != null) {
      return json.decode(savedJson);
    }
    return null;
  }

  Future<void> saveForm(Map<String, dynamic> jsonMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(jsonMap));
  }

  Future<void> resetForm() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
