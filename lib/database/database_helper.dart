import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:hive/hive.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database;
  }

  Future<Database?> _initDatabase() async {
    if (kIsWeb) {
      return null; // Base de datos no necesaria en la web
    } else {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'medications.db');

      if (!kReleaseMode) {
        await deleteDatabase(path); // Solo para modo debug
      }

      return await openDatabase(
        path,
        version: 3,
        onCreate: (db, version) async {
          await db.execute(
            '''
            CREATE TABLE medications (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              date TEXT,
              days TEXT,
              time TEXT,
              latitude REAL,
              longitude REAL
            )
            ''',
          );
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              '''
              ALTER TABLE medications ADD COLUMN date TEXT;
              ''',
            );
          }
          if (oldVersion < 3) {
            await db.execute(
              '''
              ALTER TABLE medications ADD COLUMN latitude REAL;
              ALTER TABLE medications ADD COLUMN longitude REAL;
              ''',
            );
          }
        },
      );
    }
  }

  Future<void> insertMedication(Map<String, dynamic> medication) async {
    if (kIsWeb) {
      var box = await Hive.openBox<Map<String, dynamic>>('medications');
      await box.add(medication);
    } else {
      final db = await database;
      if (db != null) {
        await db.insert(
          'medications',
          medication,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        throw Exception("Database is not initialized");
      }
    }
  }

  Future<List<Map<String, dynamic>>> getAllMedications() async {
    if (kIsWeb) {
      var box = await Hive.openBox<Map<String, dynamic>>('medications');
      return box.values.toList();
    } else {
      final db = await database;
      if (db != null) {
        return await db.query('medications');
      } else {
        throw Exception("Database is not initialized");
      }
    }
  }
}
