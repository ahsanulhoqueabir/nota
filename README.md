# Noto — Your notes. Always local.

A lightweight, local-first note-taking app built with Flutter. All notes live in a SQLite database on your phone. No backend, no auth, no network calls in the core flow.

> Built as a teaching vehicle for a 90-minute Flutter workshop — each feature maps to a specific Flutter, Dart, or SQLite concept.

![Flutter](https://img.shields.io/badge/Flutter-3.47-blue?logo=flutter) ![Dart](https://img.shields.io/badge/Dart-3.13-blue?logo=dart) ![SQLite](https://img.shields.io/badge/SQLite-local-green?logo=sqlite) ![License](https://img.shields.io/badge/License-MIT-purple)

---

## ✨ Features

### MVP (built live in 90 minutes)
- 📝 **Create / Edit / Delete** notes with confirmation dialog
- 📋 **Home list** with pinned notes first, most recent first
- 🔍 **Live search** over title and content
- 📌 **Pin** notes to the top
- ⭐ **Favorite** notes
- 🏷️ **Categories** — Study, Work, Ideas, Personal
- 🎨 **5 color themes** per note (default, blue, green, yellow, purple)
- 🌙 **Dark mode** toggle (app-wide)
- 📊 **Statistics** screen — total, pinned, favorites, per-category counts

### Bonus (take-home extensions)
- 🎲 Note of the Day — random note on launch
- 💬 Quote for Today — REST API card (offline-safe)
- 📋 Copy note to clipboard
- 📤 Share note via native share sheet

---

## 🚀 Quick Start

```bash
# ১. Dependencies install
flutter pub get

# ২. Phone connect করুন (USB debugging on থাকতে হবে)
flutter devices    # connected device দেখতে

# ৩. App run করুন (debug mode, hot reload সহ)
flutter run -d <device-id>
```

**Phone এ space কম থাকলে** debug এর বদলে release APK ব্যবহার করুন (16 MB):

```bash
flutter build apk --release --split-per-abi
adb -s <device-id> install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
adb -s <device-id> shell am start -n com.example.note/.MainActivity
```

> ⚠️ Phone এ যদি "Install from unknown source" block থাকে: **Settings → Apps → Special app access → Install unknown apps → ADB → Allow**

---

## 📱 Screenshots & User Flow

```
App Launch
   │
   ▼
Home Screen (list of notes, search bar, category chips)
   │
   ├── Tap FAB ───────────────► Note Editor (Create) ──► Save ──► back to Home
   │
   ├── Tap Note Card ─────────► Note Detail Screen
   │                                  │
   │                                  ├── Edit ──► Note Editor (Edit)
   │                                  ├── Pin / Unpin ──► updates in place
   │                                  ├── Favorite / Unfavorite ──► updates in place
   │                                  └── Delete ──► Confirm dialog ──► back to Home
   │
   ├── Type in Search bar ────► filtered list updates live
   │
   ├── Tap Category chip ─────► filtered list updates live
   │
   └── Tap Settings icon ─────► Settings Screen
                                    ├── Dark mode toggle
                                    └── Statistics section
```

---

## 🏗️ Architecture

Beginner-friendly layered approach — enough separation to teach good habits, without enterprise overhead.

```
            ┌──────────────────────────────────────────────┐
            │                  main.dart                   │
            │  ValueNotifier<ThemeMode> → MaterialApp      │
            └────────────┬─────────────────────────────────┘
                         │
                         ▼
                   HomeScreen
            ┌────────────┬─────────────┬─────────────┐
            ▼            ▼             ▼             ▼
     NoteEditorScreen  DetailScreen  SettingsScreen   (FAB → Editor)
            │            │
            └─► Note ───┘
                 │
                 ▼
           NoteRepository
                 │
                 ▼
          DatabaseHelper (singleton)
                 │
                 ▼
            sqflite (SQLite file)
```

| Layer | File | Knows about |
|-------|------|-------------|
| `main.dart` | `lib/main.dart` | Flutter, `AppTheme`, `HomeScreen` |
| Screens | `lib/screens/*.dart` | models, repositories, widgets, theme |
| Widgets | `lib/widgets/*.dart` | models (and Flutter) |
| Repository | `lib/repositories/note_repository.dart` | models, database |
| Database helper | `lib/database/database_helper.dart` | sqflite only |
| Models | `lib/models/note.dart` | Pure Dart — no Flutter, no SQL |

**Design principles:**
1. No state-management package (no Provider, no Riverpod, no BLoC). All in-screen state via `setState`. Theme via `ValueNotifier`.
2. SQL is hidden behind `NoteRepository`. Screens never see `sqflite`.
3. Widgets are dumb — `NoteCard` takes a `Note` and emits callbacks.
4. Failure surfaces as a `SnackBar`. Every async call wrapped in `try/catch`.
5. Navigation is the refresh signal — `Navigator.push` returns a value, screens await it and re-fetch.

---

## 📂 Project Structure

```
lib/
├── main.dart                       — App root, theme notifier, MaterialApp
├── models/
│   └── note.dart                   — Plain Dart Note class
├── database/
│   └── database_helper.dart        — sqflite singleton (open + CREATE TABLE)
├── repositories/
│   └── note_repository.dart        — CRUD, search, filter, stats + NoteStats
├── screens/
│   ├── home_screen.dart            — List, search, category filter, FAB
│   ├── note_editor_screen.dart     — Create + Edit form
│   ├── note_detail_screen.dart     — View + actions
│   └── settings_screen.dart        — Dark mode + Statistics
├── widgets/
│   ├── note_card.dart              — One note as a card + color/category constants
│   ├── category_filter.dart        — Horizontal chip row used on Home
│   └── empty_state.dart            — Friendly "no notes" / "no results"
└── theme/
    └── app_theme.dart              — Light + dark ThemeData

docs/
├── 00-quickstart.md                — TL;DR + project layout
├── 01-architecture.md              — How the code is laid out
├── 02-data-model-and-sqlite.md     — Note model + schema + queries
├── 03-database-layer.md            — DatabaseHelper + NoteRepository
├── 04-screens.md                   — Each screen's state & callbacks
├── 05-widgets-and-theme.md         — Reusable widgets + theme tokens
├── 06-state-and-theme-management.md — setState + ValueNotifier + nav refresh
├── 07-error-and-empty-states.md    — How failures surface
├── 08-testing-manual.md            — Manual test checklist
├── 09-future-improvements.md       — Bonus features deferred from workshop
└── 10-useful-commands.md           — All useful Flutter/ADB commands
```

---

## 🗄️ Data Model & Schema

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

### SQL queries used

| Operation | SQL |
|-----------|-----|
| Insert | `db.insert(...)` (sqflite) |
| Get all (pinned first, recent first) | `ORDER BY isPinned DESC, updatedAt DESC` |
| Search | `WHERE title LIKE ? OR content LIKE ?` |
| Filter by category | `WHERE category = ?` |
| Stats | `COUNT(*)`, `GROUP BY category` |

Full table of all SQL queries: [`docs/02-data-model-and-sqlite.md`](docs/02-data-model-and-sqlite.md)

---

## 📚 Tech Stack

| Package | Purpose | Why |
|---------|---------|-----|
| `flutter` | UI framework | — |
| `sqflite` | Local relational DB | Standard, well-supported SQLite plugin. No built-in SQL in Flutter |
| `path` | DB file path joining | Idiomatic, cross-platform safe |
| `intl` | Date formatting | "2h ago", "Aug 21" — relative timestamps |
| `flutter_lints` | Static analysis | Catches common mistakes |

**No** state-management package. **No** DI package. **No** routing package — `Navigator` is enough for 4 screens.

Full dependency rationale: [`noto-prd.md`](noto-prd.md) Section 17

---

## 🧪 Testing

This is a workshop project — no automated tests. Use the [manual test checklist](docs/08-testing-manual.md) which covers every feature end-to-end.

Quick smoke test:

```bash
flutter analyze     # should report "No issues found"
flutter run -d <device-id>
```

Then walk through: create → edit → delete → pin → favorite → search → filter → dark mode → stats.

---

## 📖 Documentation

Everything beyond the README lives in `docs/`:

| Doc | What's inside |
|-----|---------------|
| [`docs/00-quickstart.md`](docs/00-quickstart.md) | TL;DR + project layout |
| [`docs/01-architecture.md`](docs/01-architecture.md) | Layered architecture, design principles |
| [`docs/02-data-model-and-sqlite.md`](docs/02-data-model-and-sqlite.md) | `Note` model, schema, all SQL queries |
| [`docs/03-database-layer.md`](docs/03-database-layer.md) | `DatabaseHelper` singleton, `NoteRepository` methods |
| [`docs/04-screens.md`](docs/04-screens.md) | Each screen's state, callbacks, refresh strategy |
| [`docs/05-widgets-and-theme.md`](docs/05-widgets-and-theme.md) | Reusable widgets + `AppTheme` tokens |
| [`docs/06-state-and-theme-management.md`](docs/06-state-and-theme-management.md) | `setState`, `ValueNotifier`, navigation-as-refresh |
| [`docs/07-error-and-empty-states.md`](docs/07-error-and-empty-states.md) | `try/catch` + `SnackBar` + `EmptyState` patterns |
| [`docs/08-testing-manual.md`](docs/08-testing-manual.md) | 31-item manual test checklist |
| [`docs/09-future-improvements.md`](docs/09-future-improvements.md) | Bonus features (FTS5, tags, undo-delete, share) |
| [`docs/10-useful-commands.md`](docs/10-useful-commands.md) | All useful Flutter/ADB commands in Bengali-English |

The original PRD lives at [`noto-prd.md`](noto-prd.md).

---

## 🛠️ Useful Commands (most common)

```bash
# Run
flutter run -d <device-id>
flutter run --release -d <device-id>

# Build
flutter build apk --debug                     # ~150 MB, dev only
flutter build apk --release --split-per-abi   # ~16 MB per ABI, install on phone

# Quality
flutter analyze                               # static analysis
dart format .                                 # format code

# ADB (phone তে)
adb devices
adb -s <id> install -r path/to/app.apk
adb -s <id> shell am start -n com.example.note/.MainActivity
adb -s <id> logcat | findstr "flutter"
adb -s <id> uninstall com.example.note
```

Full command reference (with Bengali explanations): [`docs/10-useful-commands.md`](docs/10-useful-commands.md)

---

## 🚧 Common Issues

### ❌ `INSTALL_FAILED_USER_RESTRICTED`
Phone এ "Install from unknown source" block করা আছে।
**Fix:** Settings → Apps → Special app access → Install unknown apps → ADB → Allow

### ❌ `Requested internal only, but not enough space`
Debug APK (~150 MB) install করার মতো space নেই।
**Fix:** Phone থেকে অপ্রয়োজনীয় content clear করুন, অথবা release APK install করুন (~16 MB)

### ❌ Gradle build fail
```bash
cd android && ./gradlew clean
cd ..
flutter clean && flutter pub get
flutter run
```

More troubleshooting in [`docs/10-useful-commands.md`](docs/10-useful-commands.md) Section 4.

---

## 🎯 Roadmap (Bonus / Future)

- [ ] Persist dark mode with `shared_preferences`
- [ ] Note of the Day (random note on launch)
- [ ] Quote for Today (`http` + `FutureBuilder`, isolated widget)
- [ ] Share note via `share_plus`
- [ ] Tags instead of fixed category (many-to-many)
- [ ] Full-text search with SQLite FTS5
- [ ] Undo-delete via `SnackBar` action
- [ ] Note archiving instead of hard delete
- [ ] Rich text / markdown

Detail per item: [`docs/09-future-improvements.md`](docs/09-future-improvements.md)

---

## 📜 License

MIT — see source for details. Built as an educational project; use freely.

---

## 🙏 Acknowledgments

- **PRD**: Original spec by the workshop organizer — [`noto-prd.md`](noto-prd.md)
- **Flutter team**: For the framework and `sqflite` plugin
- **Workshop attendees**: For the iterative feedback that shaped this implementation

---

**Happy note-taking! 📝**

*Built with Flutter. Stored in SQLite. Runs offline.*