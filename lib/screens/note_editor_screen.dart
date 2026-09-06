import 'package:flutter/material.dart';

import '../models/note.dart';
import '../repositories/note_repository.dart';
import '../widgets/note_card.dart';

/// Shared screen for creating a new note or editing an existing one.
///
/// In create mode, [existing] is `null` and the AppBar reads "New Note".
/// In edit mode, [existing] is provided and the AppBar reads "Edit Note".
/// On successful save, the screen pops with the latest [Note] as its
/// return value so callers can refresh their lists.
class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, this.existing});

  final Note? existing;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = NoteRepository();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;

  late String _category;
  late String _colorKey;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final n = widget.existing;
    _titleCtrl = TextEditingController(text: n?.title ?? '');
    _contentCtrl = TextEditingController(text: n?.content ?? '');
    _category = n?.category ?? kCategories.first;
    _colorKey = n?.color ?? 'default';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final existing = widget.existing;

      Note toSave;
      if (existing == null) {
        toSave = Note(
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          category: _category,
          color: _colorKey,
          createdAt: now,
          updatedAt: now,
        );
        final id = await _repo.insertNote(toSave);
        toSave = toSave.copyWith(id: id);
      } else {
        toSave = existing.copyWith(
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          category: _category,
          color: _colorKey,
          updatedAt: now,
        );
        await _repo.updateNote(toSave);
      }

      if (!mounted) return;
      Navigator.of(context).pop<Note>(toSave);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save note: $e')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Note' : 'New Note'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _titleCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Give your note a title',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentCtrl,
              minLines: 6,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'Content',
                hintText: 'Write something...',
                alignLabelWithHint: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Content cannot be empty';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text('Category', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final cat in kCategories)
                  ChoiceChip(
                    label: Text(cat),
                    selected: _category == cat,
                    onSelected: (_) => setState(() => _category = cat),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Color', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            _ColorPickerRow(
              selected: _colorKey,
              onSelected: (key) => setState(() => _colorKey = key),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline horizontal row of color swatches used by the editor.
class _ColorPickerRow extends StatelessWidget {
  const _ColorPickerRow({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final key in kNoteColorOrder) ...[
          GestureDetector(
            onTap: () => onSelected(key),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorForKey(key),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == key
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: selected == key
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ],
    );
  }
}
