# Noto — Flutter Workshop Project

## 1. Product Overview

Noto is a lightweight, local-first note-taking mobile application built with Flutter. All data is stored on-device using SQLite, requiring no backend, no authentication, and no network connection for core functionality. The app is designed as a teaching vehicle for a 1–1.5 hour Flutter workshop, where each feature maps directly to a specific Flutter, Dart, or SQLite concept.

Tagline: **"Your notes. Always local."**

## 2. Problem Statement

Beginners learning Flutter often practice isolated concepts (a counter app, a static list) without seeing how those concepts compose into a real, working product. There's a gap between "hello world" tutorials and full production apps that overwhelm beginners with architecture. Noto closes that gap: it's small enough to build live, but touches nearly every fundamental a new Flutter developer needs — forms, navigation, persistent storage, state, theming, and even a taste of REST APIs.

## 3. Goals

- Teach core Flutter/Dart concepts through a single, coherent, real app.
- Keep every feature scoped so it can be live-coded in minutes, not hours.
- Demonstrate SQLite as the primary persistence mechanism, including non-trivial queries (search, filtering, aggregation).
- Produce a visually polished result so students feel they built something "real."
- Keep the app fully offline-functional; treat any network feature as strictly optional and isolated.

## 4. Non-Goals

- Not a production-ready, scalable Notion/Evernote competitor.
- No cloud sync, authentication, multi-device support, or backend service.
- No advanced state management (Bloc, Riverpod, Redux) — the workshop teaches fundamentals, not ecosystem tooling.
- No complex custom animations, gesture systems, or plugin-heavy features.
- No attempt at 100% architectural "best practice" if it costs teaching clarity.

## 5. Target Users

**Primary:**
- Flutter beginners and workshop attendees.
- Developers with general programming background but new to Flutter.

**Secondary:**
- Beginner/intermediate Flutter developers wanting a compact reference project covering SQLite, REST integration, state management, navigation, forms, and theming.

## 6. Feature List

| # | Feature | Tier |
|---|---------|------|
| 1 | Create note | MVP |
| 2 | View notes (home list) | MVP |
| 3 | View note details | MVP |
| 4 | Edit note | MVP |
| 5 | Delete note (with confirmation) | MVP |
| 6 | Pin notes | MVP |
| 7 | Favorite notes | MVP |
| 8 | Search notes | MVP |
| 9 | Categories | MVP |
| 10 | Note colors | MVP |
| 11 | Dark mode | MVP |
| 12 | Statistics | MVP |
| 13 | Note of the Day | Bonus |
| 14 | Quote for Today (REST API) | Bonus |
| 15 | Copy note to clipboard | Bonus |
| 16 | Share note | Bonus |

## 7. MVP Scope

The 90-minute workshop build includes exactly:

1. Home screen with note list
2. Create note
3. View note detail
4. Edit note
5. Delete note (with confirmation dialog)
6. SQLite database (CRUD)
7. Search
8. Pin
9. Favorite
10. Categories (predefined, selectable + filterable)
11. Note colors (predefined palette)
12. Dark mode toggle
13. Basic statistics screen

Everything else is explicitly deferred to "Future Improvements."

## 8. Bonus Features

These are documented but **not built live** in the 90-minute session — offered as homework/extension exercises.

- **Note of the Day**: on app open, randomly select an existing note from SQLite and surface it in a small card.
- **Quote for Today**: fetch a quote from a public REST API (e.g. a free quotes API) in a `FutureBuilder`, shown as a self-contained card. Must degrade gracefully — if the network call fails, the rest of the app is unaffected. This is the only feature touching the network.
- **Copy Note**: use `Clipboard.setData` to copy note content.
- **Share Note**: use the `share_plus` plugin to invoke the native share sheet.

## 9. User Flow

```
App Launch
   │
   ▼
Home Screen (list of notes, search bar, category chips)
   │
   ├── Tap FAB ───────────────► Note Editor (Create) ──► Save ──► back to Home (refreshed)
   │
   ├── Tap Note Card ─────────► Note Detail Screen
   │                                  │
   │                                  ├── Edit ──► Note Editor (Edit) ──► Save ──► back to Detail (refreshed)
   │                                  ├── Pin/Unpin ──► updates in place
   │                                  ├── Favorite/Unfavorite ──► updates in place
   │                                  └── Delete ──► Confirm dialog ──► back to Home (refreshed)
   │
   ├── Type in Search bar ────► filtered list updates live
   │
   ├── Tap Category chip ─────► filtered list updates live
   │
   └── Tap Settings icon ─────► Settings Screen
                                    ├── Dark mode toggle
                                    └── Statistics section
```

## 10. Screen Specification

### Home Screen
- AppBar: title "Noto", search icon (or persistent search field), settings icon.
- Body: greeting header, pinned section, category filter chips, "All Notes" list.
- FAB: "+ New Note".
- Empty state when no notes exist.

### Note Editor Screen (shared for Create/Edit)
- AppBar title changes based on mode ("New Note" / "Edit Note").
- Title `TextFormField` (required).
- Content `TextFormField`, multiline (should not be empty — soft validation/warning).
- Category selector (ChoiceChips).
- Color selector (small swatch row, opened via BottomSheet or inline).
- Save button in AppBar or bottom bar.

### Note Detail Screen
- Title, category chip, last updated timestamp.
- Full content (scrollable).
- Action row: Edit, Pin, Favorite, Delete, Copy.
- Delete triggers `AlertDialog` confirmation.

### Settings Screen
- **Appearance**: Dark Mode switch.
- **Statistics**: total notes, pinned count, favorites count, per-category counts.
- **About**: app name, "Built with Flutter", "Local SQLite storage" note.

## 11. UI/UX Specification

Direction: minimal, modern, Material 3-inspired, soft rounded cards, generous spacing, clear typography, light and dark themes, subtle (not decorative) motion.

Avoid: heavy gradients, complex animation choreography, excess dependencies, visual clutter.

Card design: rounded corners (~12–16px radius), left color accent or full soft-tinted background matching the note's chosen color, title in medium/semibold weight, content preview truncated to ~2 lines, small footer row with category tag, pin icon (if pinned), favorite star (if favorited), and relative/updated timestamp.

## 12. Data Model

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

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.color,
    this.isPinned = false,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'category': category,
    'color': color,
    'isPinned': isPinned ? 1 : 0,
    'isFavorite': isFavorite ? 1 : 0,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
    id: map['id'],
    title: map['title'],
    content: map['content'],
    category: map['category'],
    color: map['color'],
    isPinned: map['isPinned'] == 1,
    isFavorite: map['isFavorite'] == 1,
    createdAt: DateTime.parse(map['createdAt']),
    updatedAt: DateTime.parse(map['updatedAt']),
  );
}
```

**Dart → SQLite type mapping:**

| Dart type | SQLite type | Notes |
|-----------|-------------|-------|
| `int` | `INTEGER` | id, booleans stored as 0/1 |
| `String` | `TEXT` | title, content, category, color, dates (ISO 8601 string) |
| `bool` | `INTEGER` | SQLite has no native boolean; store 0/1 |
| `DateTime` | `TEXT` | store as ISO 8601 string, parse back with `DateTime.parse` |

## 13. SQLite Schema

```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT 'default',
  isPinned INTEGER NOT NULL DEFAULT 0,
  isFavorite INTEGER NOT NULL DEFAULT 0,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
);
```

## 14. SQL Queries

```sql
-- Insert
INSERT INTO notes (title, content, category, color, isPinned, isFavorite, createdAt, updatedAt)
VALUES (?, ?, ?, ?, ?, ?, ?, ?);

-- Select all, pinned first, most recently updated first
SELECT * FROM notes ORDER BY isPinned DESC, updatedAt DESC;

-- Select one
SELECT * FROM notes WHERE id = ?;

-- Update
UPDATE notes
SET title = ?, content = ?, category = ?, color = ?, updatedAt = ?
WHERE id = ?;

-- Toggle pin
UPDATE notes SET isPinned = ? WHERE id = ?;

-- Toggle favorite
UPDATE notes SET isFavorite = ? WHERE id = ?;

-- Delete
DELETE FROM notes WHERE id = ?;

-- Search
SELECT * FROM notes
WHERE title LIKE ? OR content LIKE ?
ORDER BY isPinned DESC, updatedAt DESC;

-- Filter by category
SELECT * FROM notes WHERE category = ? ORDER BY isPinned DESC, updatedAt DESC;

-- Statistics
SELECT COUNT(*) AS total FROM notes;
SELECT COUNT(*) AS pinned FROM notes WHERE isPinned = 1;
SELECT COUNT(*) AS favorites FROM notes WHERE isFavorite = 1;
SELECT category, COUNT(*) AS count FROM notes GROUP BY category;
```

## 15. Architecture

Beginner-friendly layered approach — enough separation to teach good habits, without enterprise overhead:

- **Models** — plain Dart classes representing data (`Note`).
- **Database** — a single `DatabaseHelper` singleton wrapping `sqflite` (open DB, create table, low-level exec).
- **Repository** — `NoteRepository` exposes clean async methods (`getAllNotes()`, `insertNote()`, etc.) that call the database helper. This is the layer screens actually talk to — it hides SQL from the UI.
- **Screens** — one file per screen, each a `StatefulWidget` holding its own local state.
- **Widgets** — small reusable pieces (`NoteCard`, `EmptyState`, `CategoryFilter`).
- **Theme** — centralized `ThemeData` definitions for light/dark.

No BLoC/Provider/Riverpod. State lives in `StatefulWidget`s and is passed down via constructor parameters and callbacks, or lifted with a simple `ChangeNotifier` only for theme mode (justified: theme needs to be readable from the whole widget tree without prop-drilling through every screen).

## 16. Folder Structure

```
lib/
│
├── main.dart
│
├── models/
│   └── note.dart
│
├── database/
│   └── database_helper.dart
│
├── repositories/
│   └── note_repository.dart
│
├── screens/
│   ├── home_screen.dart
│   ├── note_editor_screen.dart
│   ├── note_detail_screen.dart
│   └── settings_screen.dart
│
├── widgets/
│   ├── note_card.dart
│   ├── category_filter.dart
│   └── empty_state.dart
│
└── theme/
    └── app_theme.dart
```

(Dropped the standalone `search_bar.dart` widget from the original proposal — a search `TextField` inline in `home_screen.dart` is simpler to teach and doesn't need its own file for something this small.)

## 17. Dependencies

| Package | Why needed | Problem it solves | Can Flutter/Dart do it alone? |
|---|---|---|---|
| `sqflite` | Local relational database | Persistent structured storage with SQL querying, sorting, filtering, aggregation | No — Flutter has no built-in SQL database; this is the standard, well-supported plugin |
| `path` | Building the DB file path | Cross-platform-safe path joining for the SQLite file location | Technically possible manually via `dart:io`, but `path` is the idiomatic, safer approach and is a required companion to `sqflite` in virtually every tutorial/reference |
| `intl` | Date/time formatting | Human-readable "last updated" timestamps (e.g. "2h ago" or "Aug 21") | Partially — you can format manually with `DateTime` getters, but `intl` is the standard, low-effort solution and worth the one dependency |
| `http` (bonus only) | REST API calls for "Quote for Today" | Fetching JSON from a public endpoint | No — Dart's `dart:io` `HttpClient` is lower level and clunkier for JSON workflows |
| `share_plus` (bonus only) | Native share sheet | Access to OS-level share intents | No — this requires platform channel/plugin support |

No state management package, no DI package, no routing package (`Navigator` is sufficient for 4 screens).

## 18. State Management

- **Per-screen state** (form field values, loading flags, filtered list, search query): plain `setState` inside `StatefulWidget`.
- **Theme mode** (light/dark): a small `ChangeNotifier` (`ThemeNotifier`) provided at the top of the widget tree via `ChangeNotifierProvider` from the `provider` package — *or*, to avoid even that dependency, a `ValueNotifier<ThemeMode>` held in `main.dart` and passed down, with `ValueListenableBuilder` wrapping `MaterialApp`. **Recommendation: use `ValueNotifier` + `ValueListenableBuilder`** to avoid adding the `provider` dependency entirely, keeping the dependency list minimal as required.
- **Data refresh after navigation**: `Navigator.push` returns a `Future`; screens `await` the result and call `setState` to reload data — no global store needed.

## 19. Feature-by-Feature Implementation Plan

### Create Note
**What we build:** A form screen with title/content fields, category chips, and color swatches; saving inserts a row into SQLite and returns to Home.
**Flutter concepts:** `Form`, `TextFormField`, `TextEditingController`, `ChoiceChip`, navigation with `Navigator.push`, callbacks.
**Dart concepts:** classes, named constructors, `async`/`await`, `Future`.
**Database concepts:** `INSERT INTO`.
**Educational value:** Students see the full loop of collecting user input, validating it, and persisting it — the single most common mobile app pattern.

### View Notes (Home List)
**What we build:** A `ListView.builder` rendering `NoteCard` widgets sorted with pinned notes first.
**Flutter concepts:** `ListView.builder`, custom widgets, `StatefulWidget` lifecycle (`initState` to load data).
**Dart concepts:** collections, `List<Note>`, sorting via SQL `ORDER BY`.
**Database concepts:** `SELECT ... ORDER BY isPinned DESC, updatedAt DESC`.
**Educational value:** Demonstrates dynamic, data-driven UI generation instead of hardcoded widgets.

### View Note Details
**What we build:** A detail screen receiving a `Note` object via constructor, displaying full content and actions.
**Flutter concepts:** Navigator, passing objects between screens, receiving a result back.
**Dart concepts:** object passing by reference, immutability considerations.
**Database concepts:** none directly (uses in-memory object passed from list); relies on prior `SELECT`.
**Educational value:** Teaches how to move structured data between screens without global state.

### Edit Note
**What we build:** Reuse the Note Editor screen, pre-filled with existing data; saving runs an `UPDATE`.
**Flutter concepts:** `TextEditingController` initialization with existing values, conditional AppBar titles.
**Dart concepts:** optional parameters, ternary/conditional logic.
**Database concepts:** `UPDATE ... WHERE id = ?`.
**Educational value:** Shows how the same UI can serve two purposes (create/edit) — a very common real-world pattern.

### Delete Note
**What we build:** A confirmation `AlertDialog` before deleting; on confirm, deletes from SQLite and pops back to Home.
**Flutter concepts:** `showDialog`, `AlertDialog`, async callbacks inside dialogs.
**Dart concepts:** `Future<bool>` for dialog results.
**Database concepts:** `DELETE FROM notes WHERE id = ?`.
**Educational value:** Introduces destructive-action UX patterns and modal dialogs.

### Pin Notes
**What we build:** A pin `IconButton` on cards/detail screen that toggles `isPinned` and re-sorts the list.
**Flutter concepts:** `IconButton`, conditional icon rendering, state re-fetch.
**Dart concepts:** boolean toggling.
**Database concepts:** `UPDATE notes SET isPinned = ?`, `ORDER BY isPinned DESC`.
**Educational value:** Shows how a small boolean flag can drive both UI state and query-level sorting logic.

### Favorite Notes
**What we build:** A star icon toggle, same pattern as Pin but independent field.
**Flutter concepts:** dynamic icon swapping (`Icons.star` vs `Icons.star_border`).
**Dart concepts:** boolean state.
**Database concepts:** `UPDATE notes SET isFavorite = ?`.
**Educational value:** Reinforces the toggle pattern learned in Pin, showing how to generalize a concept to a second feature quickly.

### Search Notes
**What we build:** A search field on Home that filters the note list as the user types.
**Flutter concepts:** `TextField`, `onChanged`, rebuilding `ListView` from filtered results.
**Dart concepts:** `async`/`await`, `Future<List<Note>>`.
**Database concepts:** `WHERE title LIKE ? OR content LIKE ?`.
**Educational value:** Students understand how user input can trigger asynchronous database operations and update the UI in near real-time.

### Categories
**What we build:** Predefined category chips in the editor (selection) and on Home (filtering).
**Flutter concepts:** `ChoiceChip`, `Wrap`/`Row` layout, filter state.
**Dart concepts:** enums or constant string lists.
**Database concepts:** `WHERE category = ?`.
**Educational value:** Demonstrates constrained-choice UI (safer than free text) and simple `WHERE` filtering.

### Note Colors
**What we build:** A small palette (5 colors) selectable via chips or a `BottomSheet`; the note card renders with that color as an accent.
**Flutter concepts:** `BottomSheet` or inline row, `Container` decoration, color mapping.
**Dart concepts:** `Map<String, Color>` lookups.
**Database concepts:** storing a `TEXT` value representing color, retrieved and mapped back to a `Color` at render time.
**Educational value:** Shows how UI-only concerns (styling) can still be persisted as simple data.

### Dark Mode
**What we build:** A switch in Settings toggling `ThemeMode` app-wide.
**Flutter concepts:** `ThemeData`, `ThemeMode`, `MaterialApp.themeMode`.
**Dart concepts:** `ValueNotifier`, `ValueListenableBuilder`.
**Database concepts:** none (state is in-memory / could optionally persist via `shared_preferences`, noted as future improvement).
**Educational value:** Introduces app-wide reactive state without a heavy state management library.

### Statistics
**What we build:** A Settings sub-section showing counts via aggregate SQL queries.
**Flutter concepts:** `FutureBuilder` or `initState`-loaded state, simple layout (`Column`/`Row` of stat tiles).
**Dart concepts:** `Future`, `async`/`await`, working with `Map` results from `groupBy`-style queries.
**Database concepts:** `COUNT(*)`, `GROUP BY`.
**Educational value:** Demonstrates that a database isn't just for storing/retrieving records — it's a tool for aggregation and analysis, a concept many beginners miss.

## 20. Flutter Concepts Covered

Project structure, widgets, `StatelessWidget` vs `StatefulWidget`, Material 3 widgets, `Scaffold`, `AppBar`, `TextField`/`TextFormField`, `TextEditingController`, `Form` + validation, buttons and callbacks, `ListView.builder`, `Card`, `Navigator` (push/pop, passing data, returning results), `showDialog`/`AlertDialog`, `IconButton`, `ChoiceChip`, `BottomSheet`, `ThemeData`/`ThemeMode`, `ValueNotifier`/`ValueListenableBuilder`, `FutureBuilder` (bonus API section).

## 21. Dart Concepts Covered

Classes and constructors, named/optional parameters, `Map<String, dynamic>` serialization, `async`/`await`, `Future`, collections (`List`, `Map`), string interpolation, conditional expressions, null safety (`?`, `??`, `late` where relevant).

## 22. Database Concepts Covered

`CREATE TABLE`, data types and Dart↔SQLite mapping, `INSERT`, `SELECT`, `UPDATE`, `DELETE`, `WHERE`, `LIKE` for search, `ORDER BY` for sorting/pinning, `COUNT(*)` and `GROUP BY` for aggregation/statistics.

## 23. API Integration Plan (Bonus Only)

- Endpoint: any free public quote API returning JSON (e.g. a "quote of the day" style endpoint).
- Flow: `http.get()` → parse JSON body → map to a small `Quote` model (`text`, `author`) → render in a `FutureBuilder`.
- States to handle: loading (`CircularProgressIndicator`), success (quote card), error (silently hide the card or show a small "Couldn't load a quote" message — never a blocking error).
- Isolation requirement: this call must live entirely inside its own widget (e.g. `QuoteOfTheDayCard`), with its own `FutureBuilder`, so a failure has zero impact on note CRUD functionality. It should not share state, error handling, or lifecycle with the notes repository.

## 24. Error Handling

| Scenario | Approach |
|---|---|
| Database initialization failure | Wrap DB open in `try/catch` in `DatabaseHelper`; show a simple full-screen error message if it fails (rare, mostly for teaching the pattern) |
| Insert/Update/Delete failure | Wrap repository calls in `try/catch`; show a `SnackBar` with a friendly error message on failure |
| Search failure | Same `try/catch` + `SnackBar` pattern; fall back to showing the last known list |
| Invalid form input | `FormState.validate()` with inline `validator` functions on fields; block submission until valid |
| API failure (bonus) | Caught inside the `FutureBuilder`'s error branch; render a small inline fallback, never a dialog or blocking screen |

Beginner-friendly principle: every async operation gets a `try/catch`, and every failure surfaces via `SnackBar` or inline text — no custom exception hierarates, no global error handler needed for this scope.

## 25. Loading & Empty States

**Loading indicators needed:**
- Initial database load on Home screen (brief `CircularProgressIndicator` while first `SELECT` resolves).
- Save/update/delete operations — optionally disable the button and show a small inline spinner during the `await`.
- Bonus API request — `FutureBuilder`'s loading branch.

**When to use `FutureBuilder` vs. simple state variables:**
- Use `FutureBuilder` for one-shot, screen-entry data fetches that don't need to be manually refreshed mid-session (good fit for the bonus Quote card).
- Use simple state variables (`List<Note> _notes = []`, `bool _isLoading = false`) with manual `setState` calls for data that needs to be refreshed repeatedly after user actions (search typing, pin/favorite toggles, post-navigation refresh). This avoids `FutureBuilder` rebuilding awkwardly on every parent rebuild and gives more control over exactly when a refetch happens — the more correct pattern for the Home screen's list.

**Empty states:**
- No notes at all: "No notes yet — Create your first note to get started."
- Search with no results: "No notes found."

## 26. Testing Plan (Manual)

1. Create a note with all fields filled — appears on Home.
2. Attempt to create a note with an empty title — validation blocks submission.
3. Edit an existing note — changes persist and reflect on Home and Detail.
4. Delete a note — confirmation dialog appears; cancel keeps the note; confirm removes it.
5. Search by a word only in the content — correct notes appear.
6. Search with no matches — empty state message shows.
7. Pin a note — it moves to the top of the list.
8. Unpin a note — it returns to normal sort position.
9. Favorite/unfavorite a note — star icon updates immediately.
10. Change a note's category — reflects on card and in category filter.
11. Change a note's color — card accent updates.
12. Force-close and reopen the app — all notes and their pin/favorite/color/category state persist.
13. Toggle dark mode — entire app switches theme immediately.
14. Open Statistics — counts match manually-counted totals.
15. Turn off network (airplane mode) — core app (create/edit/delete/search/pin/favorite) still works fully; only the bonus Quote card fails gracefully.

## 27. 90-Minute Workshop Timeline

The original suggested timeline is close to realistic but slightly tight once you account for live-coding friction (typos, hot-reload waits, explaining concepts as you go). Adjusted timeline:

| Time | Block |
|---|---|
| 0–10 min | Project setup, dependencies, folder skeleton, basic `MaterialApp` + empty Home scaffold |
| 10–20 min | `Note` model + `DatabaseHelper` (open DB, create table) |
| 20–35 min | `NoteRepository` + Create Note flow (form → insert → navigate back) |
| 35–45 min | Home list rendering (`ListView.builder`, `NoteCard`) + Note Detail screen |
| 45–55 min | Edit + Delete (with confirmation dialog) |
| 55–65 min | Search + Pin |
| 65–75 min | Category + Favorite + Color |
| 75–82 min | Dark mode toggle |
| 82–90 min | Statistics screen + wrap-up/recap |

Bonus API integration is explicitly **cut from the live session** and left as a take-home extension — trying to also demo `http`/`FutureBuilder` live risks running over time and dilutes focus on SQLite, which is meant to be the centerpiece.

## 28. Step-by-Step Implementation Order

1. Create Flutter project, clean up default counter app.
2. Add dependencies (`sqflite`, `path`, `intl`) to `pubspec.yaml`.
3. Build folder structure.
4. Define `Note` model with `toMap`/`fromMap`.
5. Implement `DatabaseHelper` (singleton, `openDatabase`, `CREATE TABLE`).
6. Implement `NoteRepository` (insert, getAll, getById, update, delete, search, filterByCategory, stats queries).
7. Build `AppTheme` (light + dark `ThemeData`).
8. Build `main.dart` with `ValueNotifier<ThemeMode>` + `MaterialApp`.
9. Build Home screen skeleton (AppBar, empty body, FAB).
10. Build `NoteCard` widget.
11. Wire Home screen to `NoteRepository.getAllNotes()`, render list.
12. Build Note Editor screen (form fields, category chips, color swatches).
13. Wire Create flow: FAB → Editor → insert → pop with result → refresh Home.
14. Build Note Detail screen; wire card tap → Detail.
15. Wire Edit flow: Detail → Editor (pre-filled) → update → pop → refresh Detail/Home.
16. Wire Delete flow: confirmation dialog → delete → pop to Home → refresh.
17. Add search field to Home; wire to repository search query.
18. Add Pin toggle (card + detail); wire to UPDATE + re-sort.
19. Add Favorite toggle (card + detail); wire to UPDATE.
20. Add category filter chips to Home; wire to filtered query.
21. Wire color selection to persist and render on cards.
22. Build Settings screen; wire Dark Mode switch to `ValueNotifier`.
23. Add Statistics section to Settings; wire aggregate queries.
24. Add empty states (no notes / no search results).
25. Manual test pass using the Testing Plan checklist.
26. Recap: discuss bonus features as take-home extensions.

## 29. Future Improvements

- Persist dark mode preference with `shared_preferences`.
- Note of the Day (random note surfaced on launch).
- Quote for Today via REST API (`http` + `FutureBuilder`), fully isolated from core note flow.
- Copy note to clipboard.
- Share note via `share_plus`.
- Rich text / markdown support in notes.
- Tags instead of single fixed category.
- Full-text search improvements (SQLite FTS5).
- Undo-delete via `SnackBar` action.
- Note archiving instead of hard delete.

## 30. Final Workshop Checklist

- [ ] Project created and dependencies installed
- [ ] `Note` model implemented
- [ ] SQLite table created via `DatabaseHelper`
- [ ] `NoteRepository` CRUD methods working
- [ ] Home screen lists notes correctly
- [ ] Create Note flow works end-to-end
- [ ] Note Detail screen displays full note
- [ ] Edit Note flow works and persists changes
- [ ] Delete Note flow works with confirmation
- [ ] Search filters notes correctly
- [ ] Pin toggle re-sorts list correctly
- [ ] Favorite toggle updates icon and persists
- [ ] Category selection + filtering works
- [ ] Color selection persists and displays on cards
- [ ] Dark mode toggle switches theme app-wide
- [ ] Statistics screen shows correct counts
- [ ] Empty states display correctly
- [ ] App works fully offline
- [ ] Manual test plan passed

---

# Recommended Implementation Sequence

1. Scaffold the Flutter project and strip the default template.
2. Add `sqflite`, `path`, and `intl` to `pubspec.yaml`; run `flutter pub get`.
3. Create the folder structure (`models/`, `database/`, `repositories/`, `screens/`, `widgets/`, `theme/`).
4. Write the `Note` model with `toMap`/`fromMap` converters.
5. Write `DatabaseHelper` with singleton pattern, `openDatabase`, and `CREATE TABLE` statement.
6. Write `NoteRepository` with all CRUD, search, filter, and statistics query methods.
7. Define `AppTheme` with light and dark `ThemeData`.
8. Wire up `main.dart`: `ValueNotifier<ThemeMode>`, `ValueListenableBuilder`, `MaterialApp`.
9. Build the Home screen shell: `Scaffold`, `AppBar`, empty `ListView`, FAB.
10. Build the `NoteCard` widget and connect it to real data from the repository.
11. Build the Note Editor screen (Create mode) and wire the FAB to it.
12. Implement Create Note: form validation → `insertNote` → pop with result → refresh Home.
13. Build the Note Detail screen; wire card taps to navigate to it.
14. Extend the Note Editor screen to support Edit mode (pre-filled fields); wire Edit action from Detail.
15. Implement Delete Note with an `AlertDialog` confirmation; wire from Detail; refresh Home on return.
16. Add the search `TextField` to Home; wire `onChanged` to the repository's search query.
17. Add Pin toggle to card and Detail screen; wire to `UPDATE` + re-sort query.
18. Add Favorite toggle to card and Detail screen; wire to `UPDATE`.
19. Add category chips to the Editor (selection) and Home (filtering); wire both to the repository.
20. Add color swatches to the Editor; wire persistence and card rendering.
21. Build the Settings screen with the Dark Mode switch wired to the app-wide `ValueNotifier`.
22. Add the Statistics section to Settings, wired to aggregate SQL queries.
23. Add empty-state widgets for "no notes" and "no search results."
24. Run through the full manual Testing Plan.
25. Recap architecture and walk through Bonus Features as take-home extensions (Note of the Day, Quote API, Copy, Share).
