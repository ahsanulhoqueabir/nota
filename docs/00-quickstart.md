# Noto — Quickstart

> Your notes. Always local.

A small Flutter app for the workshop. All notes live in a local SQLite database; no backend, no auth, no network calls in the core flow.

---

## Run it

```bash
flutter pub get
flutter run
```

That's it. No API keys, no `.env`, no build configs beyond the default Flutter scaffold.

---

## What it does

- Create / view / edit / delete notes
- Pin notes (they sort to the top)
- Favorite notes
- 4 fixed categories (Study, Work, Ideas, Personal)
- 5-color palette per note
- Live search
- Dark mode
- Statistics screen

See the full PRD in `noto-prd.md` for the spec, or jump to:

- `01-architecture.md` — how the code is laid out
- `02-data-model-and-sqlite.md` — `Note` model + schema + queries
- `03-database-layer.md` — `DatabaseHelper` + `NoteRepository`
- `04-screens.md` — each screen and what it does
- `05-widgets-and-theme.md` — reusable widgets + `AppTheme`
- `06-state-and-theme-management.md` — `setState`, `ValueNotifier`, navigation-as-refresh
- `07-error-and-empty-states.md` — how failures surface to the user
- `08-testing-manual.md` — manual test checklist
- `09-future-improvements.md` — bonus features deferred from the workshop

---

## Project structure

```
lib/
├── main.dart                       — App root, theme notifier, MaterialApp
├── models/note.dart                — Plain Dart model
├── database/database_helper.dart   — sqflite singleton
├── repositories/note_repository.dart — CRUD, search, filter, stats
├── screens/                        — Home, Editor, Detail, Settings
├── widgets/                        — NoteCard, CategoryFilter, EmptyState
└── theme/app_theme.dart            — Light + dark ThemeData
```

---

## Stack

- **Flutter** 3.x
- **sqflite** — local relational database
- **path** — file path joining for the SQLite file
- **intl** — date formatting ("2h ago", "Aug 21")

No state-management package, no DI package, no router package.