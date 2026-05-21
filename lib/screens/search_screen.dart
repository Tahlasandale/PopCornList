import 'dart:async';
import 'package:flutter/material.dart';
import '../models/tmdb_movie.dart';
import '../services/tmdb_service.dart';
import '../services/film_filter.dart';
import '../widgets/movie_grid.dart';
import '../widgets/empty_state.dart';
import '../widgets/sort_bar.dart';
import 'movie_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TmdbService _tmdbService = TmdbService();
  final TextEditingController _searchController = TextEditingController();
  List<TmdbMovie> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  SortBy _sortBy = SortBy.rating;
  bool _ascending = false;

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
      final results = await _tmdbService.searchMovies(query);
      if (mounted) setState(() => _results = results);
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
      sortBy: _sortBy,
      ascending: _ascending,
    );
  }

  void _openDetail(TmdbMovie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = _results.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 4),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Rechercher un film...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        if (hasResults)
          SortBar(
            currentSort: _sortBy,
            ascending: _ascending,
            onSortChanged: (v) => setState(() => _sortBy = v),
            onOrderChanged: () => setState(() => _ascending = !_ascending),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : hasResults
                  ? MovieGrid(movies: _filtered, onMovieTap: _openDetail)
                  : const EmptyState(
                      icon: Icons.movie_filter_outlined,
                      title: 'Recherchez un film',
                      subtitle: 'Tapez le titre d\'un film pour commencer',
                    ),
        ),
      ],
    );
  }
}
