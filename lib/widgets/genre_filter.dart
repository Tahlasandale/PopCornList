import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Liste complète des genres TMDB.
const Map<int, String> kMovieGenres = {
  28: 'Action',
  12: 'Aventure',
  16: 'Animation',
  35: 'Comédie',
  80: 'Crime',
  99: 'Documentaire',
  18: 'Drame',
  10751: 'Familial',
  14: 'Fantastique',
  36: 'Histoire',
  27: 'Horreur',
  10402: 'Musique',
  9648: 'Mystère',
  10749: 'Romance',
  878: 'Science-Fiction',
  53: 'Thriller',
  10752: 'Guerre',
  37: 'Western',
};

/// Liste complète des genres TMDB pour les séries TV.
const Map<int, String> kSerieGenres = {
  10759: 'Action & Aventure',
  16: 'Animation',
  35: 'Comédie',
  80: 'Crime',
  99: 'Documentaire',
  18: 'Drame',
  10762: 'Enfants',
  10763: 'Actualités',
  10764: 'Réalité',
  10765: 'Science-Fiction & Fantastique',
  10766: 'Soap',
  10767: 'Talk',
  10768: 'Guerre & Politique',
  37: 'Western',
};

class GenreFilterSheet extends StatefulWidget {
  final List<int> selectedGenreIds;

  const GenreFilterSheet({super.key, this.selectedGenreIds = const []});

  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  late List<int> _selected;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedGenreIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<int, String>> get _filteredGenres {
    final list = kMovieGenres.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((e) => e.value.toLowerCase().contains(q)).toList();
  }

  void _toggleGenre(int genreId) {
    setState(() {
      if (_selected.contains(genreId)) {
        _selected.remove(genreId);
      } else {
        _selected.add(genreId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: ticket,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.category, size: 22, color: popcorn),
                  const SizedBox(width: 8),
                  Text(
                    'Filtrer par genre (ET)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Seuls les films ayant TOUS les genres sélectionnés seront affichés',
                style: TextStyle(color: ticket, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Chercher un genre...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filteredGenres.isEmpty
                    ? Center(
                        child: Text('Aucun genre trouvé', style: TextStyle(color: ticket)),
                      )
                    : ListView(
                        controller: scrollController,
                        children: _filteredGenres
                            .map((entry) => CheckboxListTile(
                                  title: Text(entry.value),
                                  subtitle: Text('ID ${entry.key}',
                                      style: const TextStyle(fontSize: 11)),
                                  value: _selected.contains(entry.key),
                                  onChanged: (_) => _toggleGenre(entry.key),
                                  dense: true,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  activeColor: popcorn,
                                  checkColor: onyx,
                                ))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() => _selected.clear());
                    },
                    child: const Text('Tout effacer'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    child: Text('Filtrer (${_selected.length})'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
