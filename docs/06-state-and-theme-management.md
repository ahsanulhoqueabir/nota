# State and Theme Management

Noto deliberately avoids heavyweight state-management packages. Here's how every kind of state is handled.

---

## 1. Per-screen state (`setState`)

Each screen is a `StatefulWidget` with private fields and `setState`. Examples:

| Screen | Fields |
|--------|--------|
| `HomeScreen` | `_notes`, `_loading`, `_searchQuery`, `_selectedCategory`, `_searchCtrl` |
| `NoteEditorScreen` | `_titleCtrl`, `_contentCtrl`, `_category`, `_colorKey`, `_saving` |
| `NoteDetailScreen` | `_note`, `_busy` |
| `SettingsScreen` | `_stats`, `_loadingStats` |

There's no central store because every piece of state is owned by exactly one screen.

---

## 2. Theme state (`ValueNotifier`)

The only piece of state that has to be readable from multiple places is the theme mode. We hold it in a single `ValueNotifier<ThemeMode>` created in `main.dart`:

```dart
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

return ValueListenableBuilder<ThemeMode>(
  valueListenable: themeNotifier,
  builder: (context, mode, _) {
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: HomeScreen(themeNotifier: themeNotifier),
    );
  },
);
```

- `MaterialApp.themeMode` is bound to the notifier, so any change rebuilds the whole app with the new theme.
- The notifier is passed to `HomeScreen`, which forwards it to `SettingsScreen`.
- The Settings switch is wrapped in `ValueListenableBuilder` so its label stays in sync with the actual mode.

This is the lightest possible "app-wide reactive state" — no provider, no Riverpod, no BLoC.

---

## 3. Data refresh after navigation

`Navigator.push` returns a `Future`. The caller awaits it and decides what to do:

```dart
final result = await Navigator.of(context).push<Note>(
  MaterialPageRoute(builder: (_) => NoteEditorScreen(existing: existing)),
);
if (result != null) {
  _refresh();
}
```

| Action | Pops with | Caller reacts by |
|--------|-----------|------------------|
| Save (create or edit) | `Note?` (the saved note) | Refreshing the list |
| Delete | `true` | Refreshing the list |
| Settings | _nothing_ | No refresh needed |

No global counter, no event bus, no `notifyListeners()` — just a value returned from the route.

---

## 4. Why not Provider/Riverpod/BLoC?

The PRD explicitly rules these out — they're overkill for 4 screens and one piece of app-wide state. The patterns above scale comfortably to the size of this app and are easier for beginners to read.

When would you reach for a state-management package?

- Many screens need to react to the same piece of data.
- You need fine-grained, surgical rebuilds (e.g. a complex list where only one row should rebuild).
- You're modeling async streams (websocket, polling, etc.) with multiple subscribers.

None of those apply here. Adding a package would be ceremony without payoff.

---

## 5. `FutureBuilder` vs `setState`

Per the PRD, we use `FutureBuilder` only for one-shot loads that don't need manual refresh (the bonus Quote card). The main list uses `setState` with a manual `_refresh()` because:

- It needs to re-fetch after navigation, search typing, and toggle actions — `FutureBuilder` would have to be re-keyed each time.
- The list rebuilds frequently; we want explicit control over when that happens.

The Settings screen uses `setState` for the same reason — its stats can be refreshed if we ever need to (and the screen is rebuilt every time you navigate to it, so the first paint already triggers `_loadStats`).