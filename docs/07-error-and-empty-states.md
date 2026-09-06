# Error and Empty States

Noto follows one simple rule for failures: every async operation is wrapped in `try/catch`, and every failure surfaces to the user via a `SnackBar` or an inline message. No global error handler, no custom exception types.

---

## 1. Database initialization failure (`DatabaseHelper`)

The singleton opens the database lazily on first use. If `openDatabase` throws (extremely rare — usually only if the filesystem is full or the file is locked), the error bubbles up to whichever screen made the first call.

That screen's `try/catch` catches it and shows a `SnackBar` with the message. The app stays open, just without notes.

---

## 2. CRUD failures

Insert/update/delete/search failures all share the same shape:

```dart
try {
  await _repo.someAction();
  // success path
} catch (e) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Could not do X: $e')),
  );
}
```

The `if (!mounted) return` guard prevents calling `setState` on an unmounted widget if the user navigated away while the await was pending.

---

## 3. Form validation

`NoteEditorScreen` uses `Form` + `TextFormField` validators:

- Title: required, trimmed.
- Content: required, trimmed (soft validation — an empty note isn't useful, but it's not a hard error in the sense of "user typed something illegal").

Save is blocked until the form validates, so the user can't insert a malformed note. `autovalidateMode: AutovalidateMode.onUserInteraction` means the form only complains after the user has interacted with it — no red errors flashing on first open.

---

## 4. Empty states

Two distinct empty states on `HomeScreen`:

| Trigger | Title | Subtitle | Action |
|---------|-------|----------|--------|
| `_searchQuery.isNotEmpty && _notes.isEmpty` | "No notes found" | "Try a different search term or clear the search." | None (the search field already has a clear button) |
| `_notes.isEmpty` (no search) | "No notes yet" | "Create your first note to get started." | "New Note" FilledButton |

Both render via the `EmptyState` widget, which centers the icon, title, and subtitle and applies the same visual treatment in light/dark.

---

## 5. Loading states

`HomeScreen` shows a centered `CircularProgressIndicator` while the first list query is in flight. Subsequent queries (after toggle, search, etc.) replace the list contents but don't show a spinner — the new data lands fast enough that a spinner would just flash.

`SettingsScreen` shows a `CircularProgressIndicator` while stats load, since this screen is only ever entered intentionally.

`NoteEditorScreen` disables the Save button and swaps its label for a spinner while the save is in flight, so the user can't double-submit.

---

## 6. What we deliberately don't do

- **No blocking error dialogs.** A failed save is a `SnackBar`, not a modal that needs dismissing.
- **No "retry" buttons.** If the DB is broken, retrying the same call probably won't help. Just show the message.
- **No global error handlers.** We don't use `FlutterError.onError` or `PlatformDispatcher.instance.onError`. For an app this size, local `try/catch` is enough.

If you ever add a feature that does need richer error UX (e.g. a sync feature that needs to surface a retryable error), reconsider these decisions — but for CRUD on a local SQLite database, simpler is better.