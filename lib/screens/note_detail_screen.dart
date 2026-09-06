import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/note.dart';
import '../repositories/note_repository.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';

/// Read-only view of a single note with the full action set:
/// Edit, Pin, Favorite, Delete (with confirmation), and Copy.
class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({super.key, required this.note});

  final Note note;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late Note _note;
  final _repo = NoteRepository();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
  }

  String _formatTimestamp(DateTime ts) {
    return DateFormat('MMM d, yyyy • h:mm a').format(ts);
  }

  Future<void> _togglePin() async {
    if (_busy || _note.id == null) return;
    setState(() => _busy = true);
    try {
      final newVal = !_note.isPinned;
      await _repo.togglePinned(_note.id!, newVal);
      if (!mounted) return;
      setState(() {
        _note = _note.copyWith(isPinned: newVal);
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update pin: $e')),
      );
    }
  }

  Future<void> _toggleFavorite() async {
    if (_busy || _note.id == null) return;
    setState(() => _busy = true);
    try {
      final newVal = !_note.isFavorite;
      await _repo.toggleFavorite(_note.id!, newVal);
      if (!mounted) return;
      setState(() {
        _note = _note.copyWith(isFavorite: newVal);
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update favorite: $e')),
      );
    }
  }

  Future<void> _edit() async {
    final result = await Navigator.of(context).push<Note>(
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(existing: _note),
      ),
    );
    if (result != null && mounted) {
      setState(() => _note = result);
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(
      ClipboardData(text: '${_note.title}\n\n${_note.content}'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Future<void> _confirmDelete() async {
    if (_note.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text(
          'This will permanently delete "${_note.title}". This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _repo.deleteNote(_note.id!);
      if (!mounted) return;
      Navigator.of(context).pop(true); // signal Home to refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = colorForKey(_note.color);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Note'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: _edit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _note.category,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _note.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Updated ${_formatTimestamp(_note.updatedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  left: BorderSide(color: accent, width: 4),
                ),
              ),
              child: SelectableText(
                _note.content,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _togglePin,
                  icon: Icon(
                    _note.isPinned
                        ? Icons.push_pin
                        : Icons.push_pin_outlined,
                  ),
                  label: Text(_note.isPinned ? 'Unpin' : 'Pin'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _toggleFavorite,
                  icon: Icon(
                    _note.isFavorite ? Icons.star : Icons.star_border,
                  ),
                  label: Text(_note.isFavorite ? 'Unfavorite' : 'Favorite'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
