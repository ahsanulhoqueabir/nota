# Manual Testing Plan

There are no automated tests in the workshop version of Noto. The checklist below walks through every feature end-to-end and is the source of truth for "did we ship it?".

Run through these on a device or emulator after every meaningful change. They map 1:1 to the PRD's Section 26.

---

## How to run

```bash
flutter pub get
flutter run
```

If you change the schema or `DatabaseHelper`, delete the existing DB so `onCreate` runs again:

```bash
# Android
adb shell run-as com.example.note rm databases/noto.db

# iOS simulator
xcrun simctl uninstall booted com.example.note
```

(Or just uninstall the app from the device.)

---

## Checklist

### Create / Read / Update / Delete

| # | Action | Expected result |
|---|--------|-----------------|
| 1 | Tap the **New Note** FAB | Editor opens with empty fields and "New Note" title |
| 2 | Fill in title, content, pick a category and color, tap **Save** | Snackbar-free save, returns to Home, new card appears at the top of the list |
| 3 | Open the new note from the list | Detail screen shows the title, category chip, timestamp, full content, and the correct color accent on the body block |
| 4 | From Detail, tap the pencil icon | Editor opens with all fields pre-filled, AppBar says "Edit Note" |
| 5 | Change the title, tap **Save** | Returns to Detail, title and updated timestamp refresh in place |
| 6 | Back to Home, the title change is reflected | ✓ |
| 7 | From Detail, tap the trash icon | Confirmation dialog appears |
| 8 | Tap **Cancel** | Dialog closes, note is still there |
| 9 | Tap the trash icon again, tap **Delete** | Returns to Home, the note is gone |

### Validation

| # | Action | Expected result |
|---|--------|-----------------|
| 10 | Tap **New Note**, leave title empty, tap **Save** | Inline "Title is required" error, no save |
| 11 | Fill a title but leave content empty, tap **Save** | Inline "Content cannot be empty" error, no save |

### Search

| # | Action | Expected result |
|---|--------|-----------------|
| 12 | With at least two notes, type a word that appears only in content | List filters live as you type |
| 13 | Type a non-matching string | "No notes found" empty state appears |
| 14 | Tap the **×** in the search field | Search clears, full list returns |

### Pin

| # | Action | Expected result |
|---|--------|-----------------|
| 15 | Tap the pin icon on a card | Card jumps to the top of the list |
| 16 | Tap the pin icon again | Card returns to its normal sort position |
| 17 | Open a pinned note, tap **Unpin** in Detail | Pin icon on Home's card clears |

### Favorite

| # | Action | Expected result |
|---|--------|-----------------|
| 18 | Tap the star on a card | Star fills (yellow), icon updates immediately |
| 19 | Force-quit the app, reopen | Star state persisted |

### Category

| # | Action | Expected result |
|---|--------|-----------------|
| 20 | Create a note with category "Work" | Card shows the "Work" badge in the note's accent color |
| 21 | Tap the "Work" chip on Home | Only Work notes are shown |
| 22 | Tap "All" | All notes return |

### Color

| # | Action | Expected result |
|---|--------|-----------------|
| 23 | Pick a color in the editor | Left strip on the card reflects the new color |
| 24 | Open the detail of that note | Body block has a left border in the same color |

### Dark mode

| # | Action | Expected result |
|---|--------|-----------------|
| 25 | Open Settings, flip **Dark mode** on | Whole app switches to dark theme instantly |
| 26 | Navigate around (Home → Detail → Settings) | All screens honor the dark theme |
| 27 | Toggle off | App returns to light theme |

### Statistics

| # | Action | Expected result |
|---|--------|-----------------|
| 28 | Open Settings → Statistics | Totals match what you can count by hand on Home |
| 29 | Pin/favorite a note, return to Settings, navigate away and back | Counts refresh |

### Persistence

| # | Action | Expected result |
|---|--------|-----------------|
| 30 | Force-quit the app, relaunch | Every note, plus its pin/favorite/category/color, is exactly as you left it |

### Offline

| # | Action | Expected result |
|---|--------|-----------------|
| 31 | Turn on airplane mode | All core features still work; nothing tries to call the network |

---

## What you don't need to test by hand

These are the workshop's non-goals:

- Cloud sync
- Multi-device sync
- Authentication
- Rich text formatting
- Note archiving (we hard-delete)
- The bonus Quote API card (not implemented in this version)

If any of those become features, they get their own checklists.