import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    return await openDatabase(
      join(await getDatabasesPath(), 'aquarium_settings.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE settings(id INTEGER PRIMARY KEY, fishCount INTEGER, speed REAL, color INTEGER)',
        );
      },
      version: 1,
    );
  }

  Future<void> saveSettings(int fishCount, double speed, int color) async {
    final db = await database;
    await db.insert('settings', {
      'fishCount': fishCount,
      'speed': speed,
      'color': color
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> loadSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('settings');

    return maps.isNotEmpty ? maps.first : null;
  }
}