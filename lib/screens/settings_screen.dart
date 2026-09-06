import 'package:flutter/material.dart';

import '../repositories/note_repository.dart';
import '../widgets/note_card.dart';

/// Settings screen — currently houses the dark-mode toggle and the
/// Statistics section. Anything app-wide and non-note-related lives here.
///
/// The app-wide `ValueNotifier<ThemeMode>` is passed in so the toggle
/// here can flip it without prop-drilling or a provider package.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.themeNotifier});

  final ValueNotifier<ThemeMode> themeNotifier;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _repo = NoteRepository();
  NoteStats _stats = NoteStats.zero;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _repo.getStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _SectionHeader(title: 'Appearance'),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: widget.themeNotifier,
            builder: (context, mode, _) {
              return SwitchListTile(
                title: const Text('Dark mode'),
                subtitle: Text(
                  mode == ThemeMode.dark ? 'On' : 'Off',
                ),
                secondary: Icon(
                  mode == ThemeMode.dark
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                ),
                value: mode == ThemeMode.dark,
                onChanged: (v) {
                  widget.themeNotifier.value =
                      v ? ThemeMode.dark : ThemeMode.light;
                },
              );
            },
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Statistics'),
          if (_loadingStats)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _StatTile(
              icon: Icons.note_alt_outlined,
              label: 'Total notes',
              value: _stats.total.toString(),
            ),
            _StatTile(
              icon: Icons.push_pin,
              label: 'Pinned',
              value: _stats.pinned.toString(),
            ),
            _StatTile(
              icon: Icons.star,
              label: 'Favorites',
              value: _stats.favorites.toString(),
            ),
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'By category',
                style: theme.textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 8),
            if (_stats.byCategory.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'No categories yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...kCategories.map(
                (c) => _StatTile(
                  icon: Icons.label_outline,
                  label: c,
                  value: (_stats.byCategory[c] ?? 0).toString(),
                ),
              ),
          ],
          const SizedBox(height: 32),
          const _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Noto'),
            subtitle: const Text(
              'Built with Flutter\nLocal SQLite storage\nv0.1.0',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label),
      trailing: Text(
        value,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
