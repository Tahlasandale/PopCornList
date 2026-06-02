import 'dart:async';
import 'package:flutter/material.dart';
import '../models/tmdb_movie.dart';
import '../services/tmdb_service.dart';
import '../services/film_filter.dart';
import '../config/theme.dart';
import '../widgets/movie_grid.dart';
import '../widgets/empty_state.dart';
import '../widgets/sort_bar.dart';
import '../widgets/actor_filter.dart';
import '../screens/ai_recommendation_screen.dart';
import 'movie_detail_screen.dart';

/// Mode de recherche : films ou séries.
enum SearchMode { movies, series }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TmdbService _tmdbService = TmdbService();
  final TextEditingController _searchController = TextEditingController();
  SearchMode _searchMode = SearchMode.movies;
  List<TmdbMovie> _results = [];
  List<String> _selectedActors = [];
  bool _isLoading = false;
  Timer? _debounce;

  List<SortCriteria> _sortCriteria = [const SortCriteria(SortBy.rating, false)];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_searchMode == SearchMode.movies) {
        final results = await _tmdbService.searchMovies(query);
        if (mounted) setState(() => _results = results);
      } else {
        final series = await _tmdbService.searchSeries(query);
        if (mounted) {
          setState(() {
            _results = series.map((s) => TmdbMovie(
              id: s.id,
              title: s.title,
              posterPath: s.posterPath,
              overview: s.overview,
              voteAverage: s.voteAverage,
              releaseDate: s.releaseDate,
              genreIds: s.genreIds,
              actors: s.actors,
              runtime: s.numberOfEpisodes,
            )).toList();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<TmdbMovie> get _filtered {
    if (_searchMode == SearchMode.series) return _results;
    return FilmFilter.apply(
      movies: _results,
      criteria: _sortCriteria,
      selectedActors: _selectedActors,
    );
  }

  List<String> get _allActors {
    return _results
        .expand((m) => m.actors)
        .toSet()
        .where((a) => a.isNotEmpty)
        .toList()
      ..sort();
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

  void _openDetail(TmdbMovie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(
          movie: movie,
          isSerie: _searchMode == SearchMode.series,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = _results.isNotEmpty;
    final hasActorFilter = _searchMode == SearchMode.movies && _selectedActors.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 4),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: _searchMode == SearchMode.movies
                            ? 'Rechercher un film...'
                            : 'Rechercher une série...',
                        hintStyle: const TextStyle(color: ticket),
                        prefixIcon: const Icon(Icons.search, color: ticket),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: ticket),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: projecteur,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: popcorn.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.auto_awesome, color: popcorn),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AiRecommendationScreen(),
                        ),
                      ),
                      tooltip: 'Recommandations IA',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<SearchMode>(
                  segments: const [
                    ButtonSegment(
                      value: SearchMode.movies,
                      label: Text('Films'),
                      icon: Icon(Icons.movie_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: SearchMode.series,
                      label: Text('Séries'),
                      icon: Icon(Icons.live_tv, size: 18),
                    ),
                  ],
                  selected: {_searchMode},
                  onSelectionChanged: (Set<SearchMode> selected) {
                    setState(() {
                      _searchMode = selected.first;
                      _results = [];
                      _selectedActors = [];
                      _searchController.clear();
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      return null;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFF121214);
                      }
                      return const Color(0xFFA0A0A0);
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasResults && _searchMode == SearchMode.movies) ...[
          Row(
            children: [
              Expanded(child: SortBar(
                currentCriteria: _sortCriteria,
                onCriteriaChanged: (v) => setState(() => _sortCriteria = v),
              )),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Badge(
                    isLabelVisible: hasActorFilter,
                    label: Text('${_selectedActors.length}'),
                    child: const Icon(Icons.person_search),
                  ),
                  onPressed: _openActorFilter,
                  tooltip: 'Filtrer par acteur',
                ),
              ),
            ],
          ),
          if (hasActorFilter)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _selectedActors
                      .map((a) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Chip(
                              label: Text(a, style: const TextStyle(fontSize: 12)),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () {
                                setState(() => _selectedActors.remove(a));
                              },
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
        ],
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : hasResults
                  ? MovieGrid(
                      movies: _filtered,
                      onMovieTap: _openDetail,
                      isSerie: _searchMode == SearchMode.series,
                    )
                  : EmptyState(
                      icon: _searchMode == SearchMode.movies
                          ? Icons.movie_filter_outlined
                          : Icons.live_tv_outlined,
                      title: _searchMode == SearchMode.movies
                          ? 'Recherchez un film'
                          : 'Recherchez une série',
                      subtitle: _searchMode == SearchMode.movies
                          ? "Tapez le titre d'un film pour commencer"
                          : "Tapez le titre d'une série pour commencer",
                    ),
        ),
      ],
    );
  }
}
