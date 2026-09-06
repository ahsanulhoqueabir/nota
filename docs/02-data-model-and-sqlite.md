# Data Model and SQLite Schema

This file documents how a `Note` is represented in Dart and on disk.

---

## 1. The `Note` class (`lib/models/note.dart`)

```dart
class Note {
  final int? id;
  final String title;
  final String content;
  final String category;   // 'Study' | 'Work' | 'Ideas' | 'Personal'
  final String color;      // 'default' | 'blue' | 'green' | 'yellow' | 'purple'
  final bool isPinned;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

Notes about the shape:

- `id` is `int?` because it's `null` until SQLite assigns one.
- `category` and `color` are typed `String` (not enums) because they're persisted as text and enums add friction without benefit at this size.
- `isPinned` / `isFavorite` are real `bool` in Dart — the conversion to 0/1 happens only in `toMap`.
- `createdAt` / `updatedAt` are `DateTime` — converted to ISO 8601 strings on disk.

### `toMap` and `fromMap`

- `toMap()` produces a `Map<String, dynamic>` ready for `sqflite`'s `insert`/`update`. Booleans become `1`/`0`; dates become ISO 8601.
- `Note.fromMap(map)` rebuilds a `Note` from a row returned by `sqflite`'s `query`.

### `copyWith`

Handy for partial updates. Used in `NoteEditorScreen` to update fields while preserving `id`, `createdAt`, etc. Used in `NoteDetailScreen` to flip `isPinned`/`isFavorite` without rebuilding the object.

---

## 2. Categories (`lib/widgets/note_card.dart`)

Categories live as a top-level constant:

```dart
const List<String> kCategories = ['Study', 'Work', 'Ideas', 'Personal'];
```

Both the editor (selection) and the home screen (filtering) use this list. Adding a new category is a one-line change.

---

## 3. Color palette (`lib/widgets/note_card.dart`)

```dart
const Map<String, Color> kNoteColorPalette = {
  'default': Color(0xFFE0E0E0),
  'blue':    Color(0xFF64B5F6),
  'green':   Color(0xFF81C784),
  'yellow':  Color(0xFFFFD54F),
  'purple':  Color(0xFFBA68C8),
};

const List<String> kNoteColorOrder = ['default', 'blue', 'green', 'yellow', 'purple'];
```

The `colorForKey(key)` helper looks up a `Color` by string key (with a safe fallback to `'default'`).

---

## 4. SQLite schema (`lib/database/database_helper.dart`)

Created on first launch by `DatabaseHelper._onCreate`:

```sql
CREATE TABLE notes (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  title      TEXT    NOT NULL,
  content    TEXT    NOT NULL,
  category   TEXT    NOT NULL,
  color      TEXT    NOT NULL DEFAULT 'default',
  isPinned   INTEGER NOT NULL DEFAULT 0,
  isFavorite INTEGER NOT NULL DEFAULT 0,
  createdAt  TEXT    NOT NULL,
  updatedAt  TEXT    NOT NULL
);
```

### Dart ↔ SQLite type mapping

| Dart   | SQLite   | Notes                                       |
|--------|----------|---------------------------------------------|
| `int`  | INTEGER  | `id`, also used for booleans (0/1)          |
| `String` | TEXT   | All free-text fields                        |
| `bool` | INTEGER  | No native boolean in SQLite — store 0/1     |
| `DateTime` | TEXT | ISO 8601 string, parsed with `DateTime.parse` |

### Schema migration strategy

`DatabaseHelper` uses `version: 1`. Migrations are a non-goal for the workshop, but if you ever bump the version, add an `onUpgrade` callback in `_open()`:

```dart
onUpgrade: (db, oldVersion, newVersion) async {
  if (oldVersion < 2) {
    await db.execute('ALTER TABLE notes ADD COLUMN tags TEXT');
  }
},
```

---

## 5. SQL queries (`lib/repositories/note_repository.dart`)

| Operation | SQL |
|-----------|-----|
| Insert | `INSERT INTO notes (title, content, category, color, isPinned, isFavorite, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?)` (handled by `sqflite`'s `insert`) |
| Get all (pinned first, recently updated first) | `SELECT * FROM notes ORDER BY isPinned DESC, updatedAt DESC` |
| Get by id | `SELECT * FROM notes WHERE id = ?` |
| Search (title OR content) | `SELECT * FROM notes WHERE title LIKE ? OR content LIKE ? ORDER BY isPinned DESC, updatedAt DESC` |
| Filter by category | `SELECT * FROM notes WHERE category = ? ORDER BY isPinned DESC, updatedAt DESC` |
| Update | `UPDATE notes SET … WHERE id = ?` |
| Toggle pin | `UPDATE notes SET isPinned = ? WHERE id = ?` |
| Toggle favorite | `UPDATE notes SET isFavorite = ? WHERE id = ?` |
| Delete | `DELETE FROM notes WHERE id = ?` |
| Total count | `SELECT COUNT(*) FROM notes` |
| Pinned count | `SELECT COUNT(*) FROM notes WHERE isPinned = 1` |
| Favorites count | `SELECT COUNT(*) FROM notes WHERE isFavorite = 1` |
| Counts per category | `SELECT category, COUNT(*) AS count FROM notes GROUP BY category` |

### Why `ORDER BY isPinned DESC, updatedAt DESC`?

`isPinned` is stored as 0/1, and `DESC` puts the larger value first — so `1` (pinned) comes before `0` (unpinned). Within each group, the most recently updated note wins, matching the typical notes-app mental model.