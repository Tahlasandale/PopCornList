import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/film_filter.dart';

class SortBar extends StatelessWidget {
  final List<SortCriteria> currentCriteria;
  final ValueChanged<List<SortCriteria>> onCriteriaChanged;

  const SortBar({
    super.key,
    required this.currentCriteria,
    required this.onCriteriaChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _buildOptions(),
      ),
    );
  }

  List<Widget> _buildOptions() {
    final options = [
      _SortOption('Nom', SortBy.title),
      _SortOption('Note', SortBy.rating),
      _SortOption('Durée', SortBy.duration),
      _SortOption('Date', SortBy.releaseDate),
      _SortOption('Ajout', SortBy.addedDate),
    ];

    return [
      ...options.map((opt) {
        final index = currentCriteria.indexWhere((c) => c.field == opt.value);
        final active = index >= 0;
        final criterion = active ? currentCriteria[index] : null;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(opt.label, style: const TextStyle(fontSize: 12)),
                if (active) ...[
                  const SizedBox(width: 3),
                  Icon(
                    criterion!.ascending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: onyx,
                  ),
                  const SizedBox(width: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    decoration: BoxDecoration(
                      color: onyx.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            selected: active,
            selectedColor: popcorn,
            checkmarkColor: onyx,
            showCheckmark: false,
            backgroundColor: projecteur,
            side: active
                ? BorderSide(color: popcorn)
                : BorderSide(color: ticket.withValues(alpha: 0.3)),
            onSelected: (_) => _toggle(opt.value),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        );
      }),
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: IconButton(
          icon: const Icon(Icons.clear_all, size: 18),
          onPressed: currentCriteria.isEmpty
              ? null
              : () => onCriteriaChanged(
                    [const SortCriteria(SortBy.addedDate, false)],
                  ),
          visualDensity: VisualDensity.compact,
          tooltip: 'Réinitialiser le tri',
          color: currentCriteria.isEmpty ? ticket.withValues(alpha: 0.4) : null,
        ),
      ),
    ];
  }

  void _toggle(SortBy field) {
    final index = currentCriteria.indexWhere((c) => c.field == field);
    final updated = List<SortCriteria>.from(currentCriteria);

    if (index < 0) {
      // Pas encore sélectionné → ajouter en ascendant
      updated.add(SortCriteria(field, true));
    } else {
      final current = updated[index];
      if (current.ascending) {
        // Était ascendant → basculer en descendant
        updated[index] = SortCriteria(field, false);
      } else {
        // Était descendant → retirer
        updated.removeAt(index);
      }
    }

    onCriteriaChanged(updated);
  }
}

class _SortOption {
  final String label;
  final SortBy value;
  const _SortOption(this.label, this.value);
}
