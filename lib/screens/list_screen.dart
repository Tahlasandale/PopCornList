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

class ListScreen extends StatefulWidget {
  final String status;
  final String title;

  const ListScreen({super.key, required this.status, required this.title});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<TmdbMovie> _movies = [];
  List<String> _selectedActors = [];
  List<int> _selectedGenres = [];
  MediaType? _mediaFilter;
  bool _isLoading = true;

  List<SortCriteria> _sortCriteria = [
    const SortCriteria(SortBy.addedDate, false)
  ];

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _allActors {
    return _movies
        .expand((m) => m.actors)
        .toSet()
        .where((a) => a.isNotEmpty)
        .toList()
      ..sort();
  }

  Future<void> _loadMovies() async {
    setState(() => _isLoading = true);
    final localMovies = DatabaseService.getByStatus(widget.status);

    final tmdbMovies = localMovies
        .map((local) => TmdbMovie(
              id: local.tmdbId,
              title: local.title,
              posterPath: local.posterPath,
              overview: '',
              voteAverage: local.tmdbRating,
              releaseDate: '',
              genreIds: local.genreIds,
              actors: local.actors,
              addedDate: local.addedDate,
              isSerie: local.type == MediaType.series,
            ))
        .toList();

    if (mounted) {
      setState(() {
        _movies = tmdbMovies;
        _isLoading = false;
      });
    }
  }

  List<TmdbMovie> get _filtered {
    final filtered = FilmFilter.apply(
      movies: _movies,
      criteria: _sortCriteria,
      titleFilter: _searchController.text,
      selectedActors: _selectedActors,
      selectedGenres: _selectedGenres,
    );

    if (_mediaFilter == null) return filtered;
    return filtered
        .where((m) => m.isSerie == (_mediaFilter == MediaType.series))
        .toList();
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
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(
          movie: movie,
          isSerie: movie.isSerie,
        ),
      ),
    );
    _loadMovies();
  }

  @override
  Widget build(BuildContext context) {
    final hasMovies = _movies.isNotEmpty;
    final hasActorFilter = _selectedActors.isNotEmpty;
    final hasGenreFilter = _selectedGenres.isNotEmpty;
    final hasAnyFilter = hasActorFilter || hasGenreFilter;
    final accent = widget.status == 'to_watch' ? popcorn : siege;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              widget.status == 'to_watch' ? Icons.bookmark : Icons.check_circle,
              color: accent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(widget.title),
          ],
        ),
        actions: [
          if (hasMovies)
            PopupMenuButton<MediaType?>(
              initialValue: _mediaFilter,
              onSelected: (v) => setState(() => _mediaFilter = v),
              icon: Icon(
                _mediaFilter == null
                    ? Icons.filter_list
                    : (_mediaFilter == MediaType.movie
                        ? Icons.movie_outlined
                        : Icons.live_tv),
                color: _mediaFilter != null ? popcorn : null,
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(value: null, child: Text('Tout')),
                const PopupMenuItem(
                    value: MediaType.movie, child: Text('Films')),
                const PopupMenuItem(
                    value: MediaType.series, child: Text('Séries')),
              ],
              tooltip: 'Filtrer par type',
            ),
          if (hasMovies)
            IconButton(
              icon:
                  Icon(Icons.category, color: hasGenreFilter ? popcorn : null),
              onPressed: _openGenreFilter,
              tooltip: 'Filtrer par genre',
            ),
          if (hasMovies)
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
          if (hasMovies) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: projecteur,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                label: Text(a,
                                    style: const TextStyle(
                                        fontSize: 12, color: ecran)),
                                backgroundColor: accent.withValues(alpha: 0.15),
                                deleteIcon:
                                    Icon(Icons.close, size: 14, color: accent),
                                onDeleted: () {
                                  setState(() => _selectedActors.remove(a));
                                },
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            )),
                      if (hasGenreFilter)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Chip(
                            label: Text(
                              '${_selectedGenres.length} genre${_selectedGenres.length > 1 ? 's' : ''}',
                              style:
                                  const TextStyle(fontSize: 12, color: ecran),
                            ),
                            backgroundColor: popcorn.withValues(alpha: 0.15),
                            deleteIcon:
                                Icon(Icons.close, size: 14, color: popcorn),
                            onDeleted: () {
                              setState(() => _selectedGenres.clear());
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
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
                        icon: widget.status == 'to_watch'
                            ? Icons.bookmark_border
                            : Icons.check_circle_outline,
                        title: 'Aucun résultat',
                        subtitle: _buildEmptySubtitle(),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
      return 'Aucun titre correspondant';
    }
    if (_selectedActors.isNotEmpty) {
      return 'Aucun(e) acteur(trice) correspondant(e)';
    }
    if (_selectedGenres.isNotEmpty) {
      return 'Aucun genre correspondant';
    }
    if (_mediaFilter != null) {
      return _mediaFilter == MediaType.movie
          ? 'Aucun film trouvé'
          : 'Aucune série trouvée';
    }
    return widget.status == 'to_watch'
        ? 'Ajoutez des films ou séries depuis la recherche'
        : 'Marquez des éléments comme "Vus"';
  }
}
