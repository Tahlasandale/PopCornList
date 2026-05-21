import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/database_service.dart';
import '../models/tmdb_movie.dart';
import '../services/film_filter.dart';
import '../widgets/movie_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/sort_bar.dart';
import '../widgets/actor_filter.dart';
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
  bool _isLoading = true;

  SortBy _sortBy = SortBy.addedDate;
  bool _ascending = false;

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

    final tmdbMovies = localMovies.map((local) => TmdbMovie(
      id: local.tmdbId,
      title: local.title,
      posterPath: local.posterPath,
      overview: '',
      voteAverage: local.tmdbRating,
      releaseDate: '',
      genreIds: [],
      actors: local.actors,
      addedDate: local.addedDate,
    )).toList();

    if (mounted) {
      setState(() {
        _movies = tmdbMovies;
        _isLoading = false;
      });
    }
  }

  List<TmdbMovie> get _filtered {
    return FilmFilter.apply(
      movies: _movies,
      sortBy: _sortBy,
      ascending: _ascending,
      titleFilter: _searchController.text,
      selectedActors: _selectedActors,
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

  void _openDetail(TmdbMovie movie) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
    );
    _loadMovies();
  }

  @override
  Widget build(BuildContext context) {
    final hasMovies = _movies.isNotEmpty;
    final hasActorFilter = _selectedActors.isNotEmpty;
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: projecteur,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
              ),
            ),
            if (hasActorFilter)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _selectedActors
                        .map((a) => Padding(
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
                            ))
                        .toList(),
                  ),
                ),
              ),
            SortBar(
              currentSort: _sortBy,
              ascending: _ascending,
              onSortChanged: (v) => setState(() => _sortBy = v),
              onOrderChanged: () => setState(() => _ascending = !_ascending),
              showAddedDate: true,
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
                        title: 'Aucun film',
                        subtitle: _searchController.text.isNotEmpty
                            ? 'Aucun film avec ce titre'
                            : hasActorFilter
                                ? 'Aucun film avec cet(te) acteur(trice)'
                                : widget.status == 'to_watch'
                                    ? 'Ajoutez des films depuis la recherche'
                                    : 'Marquez des films comme "Vus"',
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
}
