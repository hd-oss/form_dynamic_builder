import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  Database? _database;

  Future<void> init() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(docsDir.path, 'example.db');

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

  Future<List<Map<String, dynamic>>> onDatabaseQuery(
      String connectionString, String dbName, String query) async {
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
  }
}
