# Future Improvements

The PRD marks these as out of scope for the 90-minute workshop, but worth picking up afterward. Each section explains *what* and *how* in enough detail to act as a starting point.

---

## 1. Persist dark mode with `shared_preferences`

Currently `themeNotifier` starts as `ThemeMode.system` every launch. To remember the user's choice:

1. Add `shared_preferences: ^2.x` to `pubspec.yaml`.
2. In `main.dart`, load the saved preference synchronously (`SharedPreferences.getInstance()` in `mainWidgetsFlutterBinding.ensureInitialized` + `await`).
3. Initialize `themeNotifier` with the loaded value.
4. In the Settings switch's `onChanged`, write the new value back via `SharedPreferences.setBool('darkMode', value)`.

If you ever support `ThemeMode.system`, store it as a small enum int (`0` system, `1` light, `2` dark).

---

## 2. Note of the Day (random note surfaced on launch)

Surface a random note as a small card at the top of `HomeScreen`.

1. Add to `NoteRepository`:

   ```dart
   Future<Note?> getRandomNote() async {
     final db = await _helper.database;
     final rows = await db.rawQuery(
       'SELECT * FROM notes ORDER BY RANDOM() LIMIT 1',
     );
     if (rows.isEmpty) return null;
     return Note.fromMap(rows.first);
   }
   ```

2. Add a `RandomNoteCard` widget that loads in `initState` and renders title + first line of content, with a tap that navigates to detail.

3. Show it as the first sliver in `HomeScreen`, between the search field and the category filter. Hide it when the list is empty (no note to surface).

---

## 3. Quote for Today (REST API, fully isolated)

The only feature in Noto that touches the network. It must be self-contained so a failure has zero impact on notes.

1. Add `http: ^1.x` to `pubspec.yaml`.
2. Create `lib/widgets/quote_of_the_day_card.dart`. It owns its own `Future<Quote>` built with a `FutureBuilder`:

   ```dart
   class QuoteOfTheDayCard extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return FutureBuilder<Quote>(
         future: _fetchQuote(),
         builder: (context, snap) {
           if (snap.connectionState != ConnectionState.done) {
             return const SizedBox.shrink(); // or a small shimmer
           }
           if (snap.hasError || !snap.hasData) {
             return const SizedBox.shrink(); // graceful failure
           }
           return _QuoteCard(quote: snap.data!);
         },
       );
     }
   }
   ```

3. The fetch lives entirely inside the widget — no shared state, no global error handler.
4. Free API option: `https://api.quotable.io/random` returns `{ content, author }`.

---

## 4. Copy note to clipboard (already partially done)

The `Copy` action is implemented in `NoteDetailScreen` using `Clipboard.setData` from `flutter/services`. To polish:

- Add the same action to the long-press menu on a `NoteCard`.
- Use `ClipboardData(text: note.content)` (no title) for that case.

---

## 5. Share note via `share_plus`

1. Add `share_plus: ^10.x` to `pubspec.yaml`.
2. In `NoteDetailScreen`, add a `Share` button:

   ```dart
   FilledButton.tonalIcon(
     onPressed: () => Share.share('${note.title}\n\n${note.content}'),
     icon: const Icon(Icons.share),
     label: const Text('Share'),
   );
   ```

3. Test on a real device — the simulator sometimes returns immediately without showing the share sheet.

---

## 6. Rich text / markdown

Out of scope for the workshop, but a natural next step.

- Easiest: store the raw markdown text, render with `flutter_markdown`.
- More work: a real WYSIWYG editor (`flutter_quill`).

---

## 7. Tags instead of fixed category

Replace the single `category` string with a join table:

```sql
CREATE TABLE tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
);

CREATE TABLE note_tags (
  note_id INTEGER NOT NULL,
  tag_id  INTEGER NOT NULL,
  PRIMARY KEY (note_id, tag_id),
  FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id)  REFERENCES tags(id)  ON DELETE CASCADE
);
```

Add a many-to-many helper on `NoteRepository`. The UI gets a multi-select chip field instead of `ChoiceChip`s.

---

## 8. Full-text search with FTS5

For larger libraries, `LIKE '%query%'` is slow because it can't use indexes. SQLite ships an FTS5 virtual table that handles tokenization and ranking for you.

Sketch:

```sql
CREATE VIRTUAL TABLE notes_fts USING fts5(
  title, content,
  content='notes',
  content_rowid='id'
);

-- Triggers keep the index in sync with the base table.
```

Then search becomes `MATCH` queries with ranking via `bm25(notes_fts)`.

---

## 9. Undo-delete via `SnackBar` action

Instead of immediately popping after a delete, show:

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('Note deleted'),
    action: SnackBarAction(
      label: 'Undo',
      onPressed: () => _repo.insertNote(deletedNote),
    ),
    duration: const Duration(seconds: 4),
  ),
);
```

The snackbar's auto-dismiss is the timeout for the undo window.

---

## 10. Note archiving instead of hard delete

Add `isArchived INTEGER NOT NULL DEFAULT 0` to `notes`. Update queries to filter `isArchived = 0`. Add an "Archived" section in Settings that lists archived notes with a "Restore" action. Real delete becomes a destructive admin action behind a confirmation.