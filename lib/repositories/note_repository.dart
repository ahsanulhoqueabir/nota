import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/note.dart';

/// Read/write API for [Note] objects, sitting on top of [DatabaseHelper].
///
/// This is the only layer the UI talks to. Screens never see SQL, never
/// touch `sqflite`, and never deal with row maps — they call methods
/// like `getAllNotes()` or `insertNote()` and work with typed [Note]s.
///
/// Every method is async because sqflite calls are non-blocking.
class NoteRepository {
  NoteRepository({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  // ---------------------------------------------------------------------------
  // CREATE
  // ---------------------------------------------------------------------------

  /// Inserts a new note and returns the generated id.
  Future<int> insertNote(Note note) async {
    final db = await _helper.database;
    final values = note.toMap()..remove('id'); // let SQLite assign id
    return db.insert(DatabaseHelper.tableNotes, values);
  }

  // ---------------------------------------------------------------------------
  // READ
  // ---------------------------------------------------------------------------

  /// Returns every note, with pinned notes first and most-recently-updated
  /// first within each group.
  Future<List<Note>> getAllNotes() async {
    final db = await _helper.database;
    final rows = await db.query(
      DatabaseHelper.tableNotes,
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  /// Returns a single note by id, or `null` if nothing matches.
  Future<Note?> getNoteById(int id) async {
    final db = await _helper.database;
    final rows = await db.query(
      DatabaseHelper.tableNotes,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Note.fromMap(rows.first);
  }

  /// Case-insensitive substring search over title and content.
  ///
  /// The `%...%` wildcards are pre-applied so callers can pass the
  /// raw user query.
  Future<List<Note>> searchNotes(String query) async {
    final db = await _helper.database;
    final like = '%${query.trim()}%';
    final rows = await db.query(
      DatabaseHelper.tableNotes,
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: [like, like],
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  /// Returns notes in a single category, same sort as [getAllNotes].
  Future<List<Note>> getNotesByCategory(String category) async {
    final db = await _helper.database;
    final rows = await db.query(
      DatabaseHelper.tableNotes,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // UPDATE
  // ---------------------------------------------------------------------------

  /// Persists edits to an existing note. The caller is responsible for
  /// bumping `updatedAt` before calling (see [Note.copyWith]).
  Future<int> updateNote(Note note) async {
    final db = await _helper.database;
    final values = note.toMap();
    if (values['id'] == null) {
      throw ArgumentError('Cannot update a note without an id.');
    }
    return db.update(
      DatabaseHelper.tableNotes,
      values,
      where: 'id = ?',
      whereArgs: [values['id']],
    );
  }

  /// Toggles [Note.isPinned] for a single note. Returns 1 on success.
  Future<int> togglePinned(int id, bool isPinned) async {
    final db = await _helper.database;
    return db.update(
      DatabaseHelper.tableNotes,
      {'isPinned': isPinned ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Toggles [Note.isFavorite] for a single note. Returns 1 on success.
  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await _helper.database;
    return db.update(
      DatabaseHelper.tableNotes,
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  /// Hard-deletes a note by id.
  Future<int> deleteNote(int id) async {
    final db = await _helper.database;
    return db.delete(
      DatabaseHelper.tableNotes,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------------------------------------------------------------------
  // STATISTICS
  // ---------------------------------------------------------------------------

  /// Aggregate counts powering the Statistics screen.
  Future<NoteStats> getStats() async {
    final db = await _helper.database;

    final total = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.tableNotes}',
        )) ??
        0;

    final pinned = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.tableNotes} WHERE isPinned = 1',
        )) ??
        0;

    final favorites = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM ${DatabaseHelper.tableNotes} WHERE isFavorite = 1',
        )) ??
        0;

    final byCategoryRows = await db.rawQuery(
      'SELECT category, COUNT(*) AS count FROM ${DatabaseHelper.tableNotes} GROUP BY category',
    );
    final byCategory = <String, int>{
      for (final row in byCategoryRows)
        row['category'] as String: (row['count'] as num).toInt(),
    };

    return NoteStats(
      total: total,
      pinned: pinned,
      favorites: favorites,
      byCategory: byCategory,
    );
  }
}

/// Aggregate result returned by [NoteRepository.getStats].
class NoteStats {
  const NoteStats({
    required this.total,
    required this.pinned,
    required this.favorites,
    required this.byCategory,
  });

  final int total;
  final int pinned;
  final int favorites;

  /// Category name → count. Categories with zero notes are omitted.
  final Map<String, int> byCategory;

  /// Empty stats object, useful as an initial state.
  static const NoteStats zero = NoteStats(
    total: 0,
    pinned: 0,
    favorites: 0,
    byCategory: {},
  );
}
