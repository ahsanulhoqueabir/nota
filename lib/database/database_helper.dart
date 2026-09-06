import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Singleton wrapper around `sqflite`.
///
/// Centralizing all low-level database work here means the rest of the
/// app never imports `sqflite` directly. The repository layer is the
/// only thing that talks to this helper.
///
/// Why a singleton?
///   - `sqflite` recommends keeping a single `Database` reference open
///     for the life of the app to avoid the cost (and race conditions)
///     of reopening the file.
///   - A plain Dart singleton is enough for this scope — no DI
///     framework needed.
class DatabaseHelper {
  DatabaseHelper._internal();

  /// The single shared instance.
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _dbFileName = 'noto.db';
  static const int _dbVersion = 1;

  /// The table that holds all notes for the app.
  static const String tableNotes = 'notes';

  /// The opened `Database` handle, or `null` until [database] is awaited.
  Database? _database;

  /// Returns the opened `Database`, opening it lazily on first call.
  Future<Database> get database async {
    return _database ??= await _open();
  }

  Future<Database> _open() async {
    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, _dbFileName);
    return openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: (db) async {
        // Foreign keys are off by default in SQLite — turn them on for
        // future-proofing, even though we only have one table today.
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  /// Runs the first-time table creation.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableNotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT NOT NULL,
        color TEXT NOT NULL DEFAULT 'default',
        isPinned INTEGER NOT NULL DEFAULT 0,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  /// Closes the database. Mostly useful for tests; the app doesn't need
  /// to call this explicitly.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
