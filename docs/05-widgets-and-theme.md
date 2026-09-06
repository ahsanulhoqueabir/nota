# Widgets and Theme

This file covers the reusable widgets in `lib/widgets/` and the theme tokens in `lib/theme/`.

---

## 1. `NoteCard` (`lib/widgets/note_card.dart`)

Renders one `Note` as a rounded card with a left color accent.

### Visual breakdown

```
┌──┬──────────────────────────────────────────────────┐
│  │ Title (bold)            ⭐ ★ 📌                   │
│  │ Lorem ipsum dolor sit amet, consectetur…          │
│  │ [Study]                             2h ago       │
└──┴──────────────────────────────────────────────────┘
 ↑ 6-px accent strip in the note's color
```

- **Left strip** — `Container(width: 6, color: accent)`. This is what makes a yellow note look yellow at a glance.
- **Title row** — title text + optional pin icon + favorite star + pin button.
- **Body** — `Text` with `maxLines: 2` and `ellipsis` so the list never grows out of proportion.
- **Footer** — small category badge in a tinted pill, plus a relative timestamp ("just now", "5m ago", "2d ago", or `DateFormat.MMMd` for older).

### Public callbacks

```dart
const NoteCard({
  required this.note,
  required this.onTap,
  required this.onTogglePin,
  required this.onToggleFavorite,
});
```

The card is purely presentational — it never decides anything. The parent (`HomeScreen`) wires the actions to the repository.

### The relative-time formatter

A small inline helper:

```dart
String _formatTimestamp(DateTime ts) {
  final diff = DateTime.now().difference(ts);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat.MMMd().format(ts);
}
```

Bumping from `intl` was justified for this — the relative-time ladder plus the `MMMd` fallback would otherwise be a lot of manual `DateTime` arithmetic.

---

## 2. `CategoryFilter` (`lib/widgets/category_filter.dart`)

A horizontally-scrollable row of `ChoiceChip`s with an "All" chip at the start.

```dart
CategoryFilter(
  categories: kCategories,
  selected: _selectedCategory,
  onSelected: (cat) {
    setState(() => _selectedCategory = cat);
    _refresh();
  },
);
```

- `selected: null` means "All".
- `onSelected` emits the chosen category, or `null` when the user picks "All".
- The horizontal `ListView` handles overflow on narrow screens.

---

## 3. `EmptyState` (`lib/widgets/empty_state.dart`)

Used in two places:

- "No notes yet" with a CTA button (the empty Home).
- "No notes found" (the no-search-results state).

Both reuse the same widget with different `icon`, `title`, `subtitle`, and optional `action`. The icon sits inside a primary-tinted circle to keep the visual interest without adding any custom illustration.

---

## 4. `AppTheme` (`lib/theme/app_theme.dart`)

Two `ThemeData` definitions: `AppTheme.light` and `AppTheme.dark`. Both are Material 3 (via `useMaterial3: true`) and seeded from a primary color so the rest of the color scheme is derived.

### What we override (and why)

- **AppBar** — flat, no elevation, transparent. Cards become the primary visual element, so the AppBar fades into the background.
- **Card** — zero elevation, large radius. Matches the "soft rounded cards" direction in the PRD.
- **FilledButton** — large radius, comfortable padding. Reads better on touch targets.
- **InputDecoration** — `filled: true`, no visible outline. Cleaner than the default Material 3 outlined look, especially in dark mode.
- **Chip** — consistent radius across `ChoiceChip` and the editor's color swatches.

Both themes share the same shapes/spacing so toggling dark mode doesn't cause layout shifts.

### Adding a new theme token

If you want to add a new shared style (e.g. a typography override), do it once in `AppTheme.light` and `AppTheme.dark`. Don't reach into `Theme.of(context)` from individual widgets to hardcode colors — that's how light/dark drift starts.