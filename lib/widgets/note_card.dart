import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/note.dart';

/// Mapping from the `color` string stored in SQLite to the accent color
/// shown on cards and as the editor's selected swatch.
///
/// Keep the keys in sync with the editor's swatch row and the README.
const Map<String, Color> kNoteColorPalette = {
  'default': Color(0xFFE0E0E0), // neutral grey accent
  'blue': Color(0xFF64B5F6),
  'green': Color(0xFF81C784),
  'yellow': Color(0xFFFFD54F),
  'purple': Color(0xFFBA68C8),
};

/// Order to display the swatch row in.
const List<String> kNoteColorOrder = [
  'default',
  'blue',
  'green',
  'yellow',
  'purple',
];

/// All categories available to a note.
const List<String> kCategories = ['Study', 'Work', 'Ideas', 'Personal'];

/// Looks up the [Color] for a given note color key, falling back to
/// the default if the key isn't recognized.
Color colorForKey(String key) => kNoteColorPalette[key] ?? kNoteColorPalette['default']!;

/// A single note rendered as a rounded card with a left color accent.
///
/// Pure UI: takes a [Note] and emits callbacks when the user taps the
/// card, the pin, or the favorite star. All data changes happen in the
/// repository — the card just rebuilds when the parent passes new data.
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onTogglePin,
    required this.onToggleFavorite,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final VoidCallback onToggleFavorite;

  String _formatTimestamp(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.MMMd().format(ts);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = colorForKey(note.color);
    final cardBg = theme.colorScheme.surfaceContainerHighest;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left color accent strip.
              Container(width: 6, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              note.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (note.isPinned)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.push_pin,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          IconButton(
                            tooltip: note.isFavorite ? 'Unfavorite' : 'Favorite',
                            visualDensity: VisualDensity.compact,
                            onPressed: onToggleFavorite,
                            icon: Icon(
                              note.isFavorite ? Icons.star : Icons.star_border,
                              color: note.isFavorite
                                  ? Colors.amber
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          IconButton(
                            tooltip: note.isPinned ? 'Unpin' : 'Pin',
                            visualDensity: VisualDensity.compact,
                            onPressed: onTogglePin,
                            icon: Icon(
                              note.isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              color: note.isPinned
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        note.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              note.category,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatTimestamp(note.updatedAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
