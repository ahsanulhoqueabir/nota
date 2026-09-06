import 'package:flutter/material.dart';

/// Horizontally-scrollable row of category filter chips, including an
/// "All" chip at the start. Pure UI — the parent owns the selected value.
class CategoryFilter extends StatelessWidget {
  const CategoryFilter({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    this.allLabel = 'All',
  });

  /// All available categories, e.g. `['Study', 'Work', 'Ideas', 'Personal']`.
  final List<String> categories;

  /// Currently selected category, or `null` to mean "All".
  final String? selected;

  /// Called with the new selection. `null` means the user tapped "All".
  final ValueChanged<String?> onSelected;

  final String allLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ChoiceChip(
            label: Text(allLabel),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          for (final category in categories) ...[
            ChoiceChip(
              label: Text(category),
              selected: selected == category,
              onSelected: (_) => onSelected(category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
