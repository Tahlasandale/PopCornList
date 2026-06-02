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

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TmdbService _tmdbService = TmdbService();
  final TextEditingController _searchController = TextEditingController();
  bool _searchFilms = true;
  bool _searchSeries = true;
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
      List<TmdbMovie> allResults = [];
      if (_searchFilms) {
        final movies = await _tmdbService.searchMovies(query);
        allResults.addAll(movies);
      }
      if (_searchSeries) {
        final series = await _tmdbService.searchSeries(query);
        allResults.addAll(series.map((s) => TmdbMovie(
              id: s.id,
              title: s.title,
              posterPath: s.posterPath,
              overview: s.overview,
              voteAverage: s.voteAverage,
              releaseDate: s.releaseDate,
              genreIds: s.genreIds,
              actors: s.actors,
              runtime: s.numberOfEpisodes,
              isSerie: true,
            )));
      }
      if (mounted) setState(() => _results = allResults);
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
          isSerie: movie.isSerie,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = _results.isNotEmpty;
    final hasActorFilter = _selectedActors.isNotEmpty;

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
                        hintText: 'Rechercher...',
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
              Row(
                children: [
                  FilterChip(
                    label: const Text('Films'),
                    selected: _searchFilms,
                    onSelected: (v) {
                      setState(() {
                        _searchFilms = v;
                        _search(_searchController.text);
                      });
                    },
                    avatar: const Icon(Icons.movie_outlined, size: 18),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Séries'),
                    selected: _searchSeries,
                    onSelected: (v) {
                      setState(() {
                        _searchSeries = v;
                        _search(_searchController.text);
                      });
                    },
                    avatar: const Icon(Icons.live_tv, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (hasResults) ...[
          Row(
            children: [
              Expanded(
                  child: SortBar(
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
                              label:
                                  Text(a, style: const TextStyle(fontSize: 12)),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () {
                                setState(() => _selectedActors.remove(a));
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
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
                    )
                  : const EmptyState(
                      icon: Icons.movie_filter_outlined,
                      title: 'Recherchez un film ou une série',
                      subtitle: "Tapez un titre pour commencer",
                    ),
        ),
      ],
    );
  }
}
