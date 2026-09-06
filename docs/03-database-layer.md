# Database Layer

This file covers the two files under `lib/database/` and `lib/repositories/`: `DatabaseHelper` (the low-level SQLite wrapper) and `NoteRepository` (the typed CRUD API screens actually use).

---

## 1. `DatabaseHelper` — `lib/database/database_helper.dart`

A singleton that owns the open `Database` reference.

### Why a singleton?

`sqflite` opens a connection to a file. Opening and closing that file on every call is slow and racy. The recommended pattern is to open it once and reuse it — a singleton is the simplest way to guarantee that here.

```dart
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();
  ...
}
```

### Lazy open

The database isn't opened until something calls `DatabaseHelper.instance.database`. That getter memoizes the result:

```dart
Database? _database;

Future<Database> get database async {
  return _database ??= await _open();
}
```

So the first read or write pays the open cost; everything after reuses the same `Database` object.

### File location and table name

```dart
static const String _dbFileName = 'noto.db';
static const String tableNotes = 'notes';
```

`_open()` uses `getDatabasesPath()` (sqflite provides the platform-correct per-app directory) and joins with the file name using the `path` package:

```dart
final dbDir = await getDatabasesPath();
final dbPath = p.join(dbDir, _dbFileName);
```

### Foreign keys

`onConfigure` enables `PRAGMA foreign_keys = ON`. We don't currently rely on it, but it's a one-line way to future-proof the schema for any related tables we might add.

### `close()`

```dart
Future<void> close() async {
  final db = _database;
  if (db != null) {
    await db.close();
    _database = null;
  }
}
```

Not used at runtime — the app keeps the database open for its whole lifetime. Useful in tests where each test wants a fresh connection.

---

## 2. `NoteRepository` — `lib/repositories/note_repository.dart`

The only thing the UI talks to. Every method is `async` because sqflite calls are non-blocking.

### Constructor injection (but defaults to the singleton)

```dart
NoteRepository({DatabaseHelper? helper})
    : _helper = helper ?? DatabaseHelper.instance;
```

This means tests can pass a fake `DatabaseHelper` (or a wrapper around an in-memory database) without monkey-patching globals.

### The methods

#### `Future<int> insertNote(Note note)`

- Calls `note.toMap()` and removes the `id` key so SQLite assigns one.
- Returns the auto-generated id from `db.insert`.

#### `Future<List<Note>> getAllNotes()`

- `ORDER BY isPinned DESC, updatedAt DESC` so pinned notes come first, then the most recently updated note wins within each group.
- Returns `List<Note>` via `rows.map(Note.fromMap)`.

#### `Future<Note?> getNoteById(int id)`

- Returns `null` when nothing matches (callers don't have to catch an exception for "not found").

#### `Future<List<Note>> searchNotes(String query)`

- Trims the query and wraps it in `%…%` for `LIKE`.
- Searches across both `title` and `content`.

#### `Future<List<Note>> getNotesByCategory(String category)`

- Same sort order as `getAllNotes`.

#### `Future<int> updateNote(Note note)`

- Throws `ArgumentError` if the note has no `id`. The editor always passes an existing note, so this is purely defensive.

#### `Future<int> togglePinned(int id, bool isPinned)` / `toggleFavorite`

- The simplest possible updates: write the new boolean value to a single row.
- These exist because the rest of the app wants to flip a flag without knowing the rest of the note's fields.

#### `Future<int> deleteNote(int id)`

- Hard delete. There is no soft-delete / archive yet (see `09-future-improvements.md`).

#### `Future<NoteStats> getStats()`

- Runs four queries:
  1. `SELECT COUNT(*) FROM notes` → total
  2. `SELECT COUNT(*) FROM notes WHERE isPinned = 1` → pinned
  3. `SELECT COUNT(*) FROM notes WHERE isFavorite = 1` → favorites
  4. `SELECT category, COUNT(*) AS count FROM notes GROUP BY category` → per-category

`Sqflite.firstIntValue(...)` is the idiomatic way to unwrap a `COUNT(*)` row in sqflite — it returns the first column of the first row, or `null` for an empty result.

### `NoteStats`

```dart
class NoteStats {
  final int total;
  final int pinned;
  final int favorites;
  final Map<String, int> byCategory;
  static const NoteStats zero = ...; // initial state for the Settings screen
}
```

`byCategory` only includes categories that have at least one note. The Settings screen fills in `0` for categories not in the map so the UI stays consistent.