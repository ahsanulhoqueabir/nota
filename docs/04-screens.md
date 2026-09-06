# Screens

Noto has four screens. Each lives in `lib/screens/` and is a `StatefulWidget` that owns its own state via `setState`. No global store, no listeners.

---

## 1. `HomeScreen` (`lib/screens/home_screen.dart`)

The main entry point. Wires together the search field, category filter, list, FAB, and settings navigation.

### State it owns

- `_notes: List<Note>` — the currently displayed list.
- `_loading: bool` — `true` while the initial query is in flight.
- `_searchQuery: String` — current search text.
- `_selectedCategory: String?` — current category filter, `null` means "All".
- `_searchCtrl: TextEditingController` — owns the `TextField`.

### How it decides what to show

```dart
final notes = _searchQuery.isEmpty
    ? (_selectedCategory == null
        ? await _repo.getAllNotes()
        : await _repo.getNotesByCategory(_selectedCategory!))
    : await _repo.searchNotes(_searchQuery);
```

- Search has priority: if the user has typed anything, we always run the search query (against the full DB; the category filter is intentionally ignored here — there's no semantic reason to combine them for this scope).
- Otherwise, we honor the category filter.

### Refresh strategy

`_refresh()` is called from:

- `initState` (first paint).
- Every `onChanged` of the search field.
- Every category chip tap.
- After every `Navigator.push` that returns a value (create, edit, delete).
- After every pin/favorite toggle (so the list re-sorts).
- `RefreshIndicator` pull-to-refresh.

This is the simplest correct pattern for this app: any action that might have changed the list triggers a re-query. There are no streams or listeners to manage.

### FAB and navigation

- `FloatingActionButton.extended` ("New Note") → pushes `NoteEditorScreen(existing: null)`.
- Tapping a `NoteCard` → pushes `NoteDetailScreen(note: note)`.
- Settings icon in the AppBar → pushes `SettingsScreen(themeNotifier: ...)`.

### Empty states

- If `_searchQuery.isNotEmpty` → "No notes found".
- Otherwise → "No notes yet" with a CTA button.

---

## 2. `NoteEditorScreen` (`lib/screens/note_editor_screen.dart`)

Shared between Create and Edit modes.

### How mode is detected

```dart
bool get _isEdit => widget.existing != null;
```

In Create mode, `widget.existing` is `null` and the AppBar reads "New Note". In Edit mode, it's pre-populated and the AppBar reads "Edit Note".

### Controllers and initial state

```dart
_titleCtrl    = TextEditingController(text: n?.title ?? '');
_contentCtrl  = TextEditingController(text: n?.content ?? '');
_category     = n?.category ?? kCategories.first;
_colorKey     = n?.color ?? 'default';
```

Disposers are wired in `dispose()` to avoid leaks.

### Save flow

```dart
Note toSave;
if (existing == null) {
  toSave = Note(title, content, category, colorKey, createdAt: now, updatedAt: now);
  final id = await _repo.insertNote(toSave);
  toSave = toSave.copyWith(id: id);
} else {
  toSave = existing.copyWith(title, content, category, colorKey, updatedAt: now);
  await _repo.updateNote(toSave);
}
Navigator.of(context).pop<Note>(toSave);
```

- We always bump `updatedAt` on save.
- On create, we then `pop` with the newly-saved `Note` (with the assigned `id`) so the caller can refresh.
- On edit, we also pop with the latest version — `HomeScreen` and `NoteDetailScreen` both use the returned `Note` to update their local copy without re-querying.

### Validation

`Form` + `autovalidateMode: AutovalidateMode.onUserInteraction` with two validators:

- `title`: required, trimmed.
- `content`: required, trimmed.

The Save button is disabled (`_saving = true`) while the operation is in flight and shows a small `CircularProgressIndicator`.

### UI bits

- `Wrap` of `ChoiceChip`s for category selection.
- A custom `_ColorPickerRow` — small circular swatches in `kNoteColorOrder`. Selected swatch shows a check mark with a primary-color ring.

---

## 3. `NoteDetailScreen` (`lib/screens/note_detail_screen.dart`)

Read-only view of a single note with action buttons.

### State it owns

- `_note: Note` — initialized from `widget.note`. Updated locally after pin/favorite/edit so the UI reflects changes without re-fetching.
- `_busy: bool` — disables the toggle buttons while a DB write is in flight.

### Actions

- **Edit** → pushes `NoteEditorScreen(existing: _note)`. On return, updates `_note` to the latest value.
- **Pin / Favorite** → `NoteRepository.togglePinned` / `toggleFavorite`. Local copy is updated via `copyWith`. No list re-fetch needed because this screen has only one note.
- **Copy** → uses `Clipboard.setData` (from `flutter/services`) to copy `title + content` to the system clipboard, then shows a confirmation `SnackBar`.
- **Delete** → `showDialog<bool>(...)` with an `AlertDialog`. On confirm, calls `NoteRepository.deleteNote` and pops the screen with `true` so `HomeScreen` knows to refresh.

### Delete confirmation

```dart
final confirmed = await showDialog<bool>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: const Text('Delete note?'),
    content: Text('This will permanently delete "${_note.title}". This cannot be undone.'),
    actions: [
      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
      FilledButton.tonal(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
    ],
  ),
);
```

Returns `Future<bool>` — the dialog result is awaited as a normal async value.

---

## 4. `SettingsScreen` (`lib/screens/settings_screen.dart`)

Currently has three sections:

### Appearance

A `SwitchListTile` wrapped in `ValueListenableBuilder<ThemeMode>` that listens to the app-wide `ValueNotifier` and flips it on tap. Reading from the same notifier means the UI label (`"On"` / `"Off"`) is always in sync with the actual theme.

### Statistics

Loaded in `initState` via `NoteRepository.getStats()`. While loading, shows a `CircularProgressIndicator`. When loaded, displays three `_StatTile`s for totals and a category breakdown using the same `kCategories` list as the editor.

`NoteStats.zero` is the initial state — it gives a stable shape before the first query resolves, so we don't have to special-case empty UI.

### About

A `ListTile` with the app name, version, and a one-liner about the storage strategy. No data, no logic — purely informational.

---

## 5. Navigation summary

| From | To | Trigger | Return value |
|------|----|---------|--------------|
| Home | Editor | FAB or "New Note" CTA | `Note?` (saved note) |
| Detail | Editor | Edit IconButton | `Note?` (edited note) |
| Home | Detail | Tap a card | `bool` (`true` if deleted) |
| Home | Settings | Settings icon | _nothing_ |
| Detail | Home | After delete | `true` |

The caller uses the return value to decide whether to refresh its own state. This avoids any need for a shared "data version" counter or a stream.