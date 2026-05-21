import 'package:flutter/material.dart';
import '../services/film_filter.dart';

class SortBar extends StatelessWidget {
  final SortBy currentSort;
  final bool ascending;
  final ValueChanged<SortBy> onSortChanged;
  final VoidCallback onOrderChanged;
  final bool showAddedDate;

  const SortBar({
    super.key,
    required this.currentSort,
    required this.ascending,
    required this.onSortChanged,
    required this.onOrderChanged,
    this.showAddedDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final options = _buildOptions();

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          ...options.map((opt) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(opt.label, style: const TextStyle(fontSize: 12)),
                  selected: opt.value == currentSort,
                  onSelected: (_) => onSortChanged(opt.value),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              )),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 18),
              onPressed: onOrderChanged,
              visualDensity: VisualDensity.compact,
              tooltip: ascending ? 'Ascendant' : 'Descendant',
            ),
          ),
        ],
      ),
    );
  }

  List<_SortOption> _buildOptions() {
    final list = [
      _SortOption('Nom', SortBy.title),
      _SortOption('Note', SortBy.rating),
      _SortOption('Durée', SortBy.duration),
      _SortOption('Date', SortBy.releaseDate),
    ];
    if (showAddedDate) {
      list.add(_SortOption('Ajout', SortBy.addedDate));
    }
    return list;
  }
}

class _SortOption {
  final String label;
  final SortBy value;
  const _SortOption(this.label, this.value);
}
