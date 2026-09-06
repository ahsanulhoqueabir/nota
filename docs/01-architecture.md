# Noto — Architecture Overview

This document explains how the Noto app is put together at a code level, so a new contributor can orient themselves by reading top-down.

---

## 1. High-level structure

Noto is a 4-screen, single-`MaterialApp` Flutter app with no backend. The runtime data flow looks like this:

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

Every layer only depends on the layer directly below it:

| Layer | File(s) | Knows about |
|-------|---------|-------------|
| `main.dart` | `lib/main.dart` | Flutter, `AppTheme`, `HomeScreen` |
| Screens | `lib/screens/*.dart` | `models/`, `repositories/`, `widgets/`, `theme/` |
| Widgets | `lib/widgets/*.dart` | `models/` (and Flutter) |
| Repository | `lib/repositories/note_repository.dart` | `models/`, `database/` |
| Database helper | `lib/database/database_helper.dart` | `sqflite` only |
| Models | `lib/models/note.dart` | Pure Dart — no Flutter, no SQL |

This is the deliberate "beginner-friendly layered" approach called for in the PRD: enough separation to teach good habits, without any framework overhead.

---

## 2. Folder layout

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
│   ├── note_card.dart              — One note as a card; also color/category constants
│   ├── category_filter.dart        — Horizontal chip row used on Home
│   └── empty_state.dart            — Friendly "no notes" / "no results"
└── theme/
    └── app_theme.dart              — Light + dark ThemeData
```

`docs/` contains walkthroughs of each piece:

- `01-architecture.md` — this file
- `02-data-model-and-sqlite.md` — `Note`, schema, SQL queries
- `03-database-layer.md` — `DatabaseHelper` and `NoteRepository`
- `04-screens.md` — what each screen does and how it talks to the repo
- `05-widgets-and-theme.md` — Reusable widgets and theme tokens
- `06-state-and-theme-management.md` — `ValueNotifier`, navigation, refresh strategy
- `07-error-and-empty-states.md` — How failures surface to the user
- `08-testing-manual.md` — The manual test checklist
- `09-future-improvements.md` — Bonus features deferred from the workshop

---

## 3. Design principles in this codebase

1. **No state-management package.** All in-screen state is `setState`. Theme is a `ValueNotifier` so the Settings screen can flip it app-wide.
2. **SQL is hidden behind `NoteRepository`.** Screens never see `sqflite` or row maps.
3. **Widgets are dumb.** `NoteCard` takes a `Note` and emits callbacks. It doesn't fetch anything.
4. **Failure surfaces as a `SnackBar`.** Every async call is wrapped in `try/catch`; the user sees a friendly message, never a raw exception.
5. **Navigation is the refresh signal.** When a screen wants Home to update, it pops with a value (`Note` for create/edit, `true` for delete). Home awaits that value in `Navigator.push`.

---

## 4. One screen at a glance

As a worked example, here's how **toggling the pin from the Home list** flows through the layers:

1. User taps the pin icon on a `NoteCard`.
2. `NoteCard` calls its `onTogglePin` callback (set by `HomeScreen`).
3. `HomeScreen._togglePin` calls `NoteRepository.togglePinned(note.id, !note.isPinned)`.
4. `NoteRepository.togglePinned` runs `UPDATE notes SET isPinned = ? WHERE id = ?` via `DatabaseHelper`.
5. On success, `HomeScreen._refresh()` re-queries `getAllNotes()` (which orders by `isPinned DESC, updatedAt DESC`) and rebuilds the list.
6. On failure, a `SnackBar` is shown — the UI keeps the old list.

The same six-step shape describes every CRUD action in the app. There are no listeners, no streams, no providers — just methods, awaits, and rebuilds.