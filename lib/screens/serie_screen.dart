import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/database_service.dart';
import '../models/stored_media.dart';
import '../models/tmdb_movie.dart';
import '../services/film_filter.dart';
import '../widgets/movie_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/sort_bar.dart';
import '../widgets/actor_filter.dart';
import '../widgets/genre_filter.dart';
import 'movie_detail_screen.dart';

/// Options de filtre pour l'écran Séries.
enum SeriesFilter { toWatch, watched, all }

class SerieScreen extends StatefulWidget {
  const SerieScreen({super.key});

  @override
  State<SerieScreen> createState() => _SerieScreenState();
}

class _SerieScreenState extends State<SerieScreen> {
  SeriesFilter _filter = SeriesFilter.toWatch;
  final TextEditingController _searchController = TextEditingController();
  List<TmdbMovie> _series = [];
  List<String> _selectedActors = [];
  List<int> _selectedGenres = [];
  bool _isLoading = true;

  List<SortCriteria> _sortCriteria = [const SortCriteria(SortBy.addedDate, false)];

  @override
  void initState() {
    super.initState();
    _loadSeries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _allActors {
    return _series
        .expand((m) => m.actors)
        .toSet()
        .where((a) => a.isNotEmpty)
        .toList()
      ..sort();
  }

  Future<void> _loadSeries() async {
    setState(() => _isLoading = true);

    final List<StoredMedia> localSeries;
    if (_filter == SeriesFilter.all) {
      localSeries = DatabaseService.getAll(type: MediaType.series);
      localSeries.sort((a, b) => b.addedDate.compareTo(a.addedDate));
    } else {
      final status = _filter == SeriesFilter.toWatch ? 'to_watch' : 'watched';
      localSeries = DatabaseService.getByStatus(status, type: MediaType.series);
    }

    final tmdbSeries = localSeries.map((local) => TmdbMovie(
      id: local.tmdbId,
      title: local.title,
      posterPath: local.posterPath,
      overview: '',
      voteAverage: local.tmdbRating,
      releaseDate: '',
      genreIds: local.genreIds,
      actors: local.actors,
      addedDate: local.addedDate,
    )).toList();

    if (mounted) {
      setState(() {
        _series = tmdbSeries;
        _isLoading = false;
      });
    }
  }

  List<TmdbMovie> get _filtered {
    return FilmFilter.apply(
      movies: _series,
      criteria: _sortCriteria,
      titleFilter: _searchController.text,
      selectedActors: _selectedActors,
      selectedGenres: _selectedGenres,
    );
  }

  Future<void> _openActorFilter() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ActorFilterSheet(
        allActors: _allActors,
        selectedActors: _selectedActors,
      ),
    );
    if (result != null) {
      setState(() => _selectedActors = result);
    }
  }

  Future<void> _openGenreFilter() async {
    final result = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => GenreFilterSheet(
        selectedGenreIds: _selectedGenres,
      ),
    );
    if (result != null) {
      setState(() => _selectedGenres = result);
    }
  }

  void _openDetail(TmdbMovie movie) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie, isSerie: true)),
    );
    _loadSeries();
  }

  // String get _statusForCurrentFilter {
  //   if (_filter == SeriesFilter.all) return '';
  //   return _filter == SeriesFilter.toWatch ? 'to_watch' : 'watched';
  // }

  @override
  Widget build(BuildContext context) {
    final hasSeries = _series.isNotEmpty;
    final hasActorFilter = _selectedActors.isNotEmpty;
    final hasGenreFilter = _selectedGenres.isNotEmpty;
    final hasAnyFilter = hasActorFilter || hasGenreFilter;
    final accent = _filter == SeriesFilter.watched ? siege : popcorn;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.live_tv, color: popcorn, size: 20),
            SizedBox(width: 8),
            Text('Séries'),
          ],
        ),
        actions: [
          if (hasSeries)
            IconButton(
              icon: Icon(Icons.category, color: hasGenreFilter ? popcorn : null),
              onPressed: _openGenreFilter,
              tooltip: 'Filtrer par genre',
            ),
          if (hasSeries)
            IconButton(
              icon: Badge(
                isLabelVisible: hasActorFilter,
                label: Text('${_selectedActors.length}'),
                child: const Icon(Icons.person_search),
              ),
              onPressed: _openActorFilter,
              tooltip: 'Filtrer par acteur',
            ),
        ],
      ),
      body: Column(
        children: [
          // Toggle À regarder / Vus / Tous
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<SeriesFilter>(
              segments: const [
                ButtonSegment(value: SeriesFilter.toWatch, label: Text('À regarder')),
                ButtonSegment(value: SeriesFilter.watched, label: Text('Vus')),
                ButtonSegment(value: SeriesFilter.all, label: Text('Tous')),
              ],
              selected: {_filter},
              onSelectionChanged: (newFilter) {
                setState(() {
                  _filter = newFilter.first;
                  _selectedActors = [];
                  _selectedGenres = [];
                  _searchController.clear();
                });
                _loadSeries();
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          if (hasSeries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Rechercher par titre...',
                  hintStyle: const TextStyle(color: ticket),
                  prefixIcon: const Icon(Icons.filter_list, color: ticket),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: projecteur,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
              ),
            ),
            if (hasAnyFilter)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (hasActorFilter)
                        ..._selectedActors.map((a) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Chip(
                                label: Text(a, style: const TextStyle(fontSize: 12, color: ecran)),
                                backgroundColor: accent.withValues(alpha: 0.15),
                                deleteIcon: Icon(Icons.close, size: 14, color: accent),
                                onDeleted: () {
                                  setState(() => _selectedActors.remove(a));
                                },
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            )),
                      if (hasGenreFilter)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Chip(
                            label: Text(
                              '${_selectedGenres.length} genre${_selectedGenres.length > 1 ? 's' : ''}',
                              style: const TextStyle(fontSize: 12, color: ecran),
                            ),
                            backgroundColor: popcorn.withValues(alpha: 0.15),
                            deleteIcon: Icon(Icons.close, size: 14, color: popcorn),
                            onDeleted: () {
                              setState(() => _selectedGenres.clear());
                            },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            SortBar(
              currentCriteria: _sortCriteria,
              onCriteriaChanged: (v) => setState(() => _sortCriteria = v),
            ),
          ],
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.live_tv,
                        title: 'Aucune série',
                        subtitle: _buildEmptySubtitle(),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.55,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          return MovieCard(
                            movie: _filtered[index],
                            onTap: () => _openDetail(_filtered[index]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _buildEmptySubtitle() {
    if (_searchController.text.isNotEmpty) {
      return 'Aucune série avec ce titre';
    }
    if (_selectedActors.isNotEmpty) {
      return 'Aucune série avec cet(te) acteur(trice)';
    }
    if (_selectedGenres.isNotEmpty) {
      return 'Aucune série avec tous ces genres';
    }
    switch (_filter) {
      case SeriesFilter.toWatch:
        return 'Ajoutez des séries depuis la recherche';
      case SeriesFilter.watched:
        return 'Marquez des séries comme "Vues"';
      case SeriesFilter.all:
        return 'Aucune série ajoutée';
    }
  }
}
