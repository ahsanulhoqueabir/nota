import 'package:flutter/material.dart';

import '../models/note.dart';
import '../repositories/note_repository.dart';
import '../widgets/category_filter.dart';
import '../widgets/empty_state.dart';
import '../widgets/note_card.dart';
import 'note_detail_screen.dart';
import 'note_editor_screen.dart';
import 'settings_screen.dart';

/// Main entry-point screen of the app.
///
/// Owns the master list of notes, the current search query, and the
/// current category filter. Calls into [NoteRepository] for all data
/// operations and re-fetches as needed.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.themeNotifier});

  /// App-wide theme-mode notifier; forwarded to the Settings screen so
  /// the dark-mode toggle has something to flip.
  final ValueNotifier<ThemeMode> themeNotifier;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = NoteRepository();
  final _searchCtrl = TextEditingController();

  List<Note> _notes = [];
  bool _loading = true;
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final notes = _searchQuery.isEmpty
          ? (_selectedCategory == null
              ? await _repo.getAllNotes()
              : await _repo.getNotesByCategory(_selectedCategory!))
          : await _repo.searchNotes(_searchQuery);
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load notes: $e')),
      );
    }
  }

  Future<void> _openEditor({Note? existing}) async {
    final result = await Navigator.of(context).push<Note>(
      MaterialPageRoute(builder: (_) => NoteEditorScreen(existing: existing)),
    );
    if (result != null) {
      _refresh();
    }
  }

  Future<void> _openDetail(Note note) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
    );
    if (deleted == true) {
      _refresh();
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(themeNotifier: widget.themeNotifier),
      ),
    );
    // No data refresh needed — settings doesn't change notes.
  }

  Future<void> _togglePin(Note note) async {
    if (note.id == null) return;
    try {
      await _repo.togglePinned(note.id!, !note.isPinned);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update pin: $e')),
      );
    }
  }

  Future<void> _toggleFavorite(Note note) async {
    if (note.id == null) return;
    try {
      await _repo.toggleFavorite(note.id!, !note.isFavorite);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update favorite: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Noto'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (value) {
                    _searchQuery = value;
                    _refresh();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search notes…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchCtrl.clear();
                              _searchQuery = '';
                              _refresh();
                            },
                          ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: CategoryFilter(
                categories: kCategories,
                selected: _selectedCategory,
                onSelected: (cat) {
                  setState(() => _selectedCategory = cat);
                  _refresh();
                },
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_notes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _searchQuery.isNotEmpty
                    ? const EmptyState(
                        icon: Icons.search_off,
                        title: 'No notes found',
                        subtitle:
                            'Try a different search term or clear the search.',
                      )
                    : EmptyState(
                        icon: Icons.note_alt_outlined,
                        title: 'No notes yet',
                        subtitle:
                            'Create your first note to get started.',
                        action: FilledButton.icon(
                          onPressed: () => _openEditor(),
                          icon: const Icon(Icons.add),
                          label: const Text('New Note'),
                        ),
                      ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                sliver: SliverList.separated(
                  itemCount: _notes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final note = _notes[i];
                    return NoteCard(
                      note: note,
                      onTap: () => _openDetail(note),
                      onTogglePin: () => _togglePin(note),
                      onToggleFavorite: () => _toggleFavorite(note),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }
}
