import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/tmdb_movie.dart';
import '../services/tmdb_service.dart';
import '../widgets/movie_card.dart';
import '../widgets/empty_state.dart';
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
  final TextEditingController _actorController = TextEditingController();
  final TmdbService _tmdbService = TmdbService();
  List<TmdbMovie> _movies = [];
  List<TmdbMovie> _filtered = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  @override
  void dispose() {
    _actorController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    setState(() => _isLoading = true);
    final localMovies = DatabaseService.getByStatus(widget.status);

    final tmdbMovies = <TmdbMovie>[];
    for (final local in localMovies) {
      try {
        final movie = await _tmdbService.getMovieDetails(local.tmdbId);
        tmdbMovies.add(movie);
      } catch (_) {
        tmdbMovies.add(TmdbMovie(
          id: local.tmdbId,
          title: local.title,
          posterPath: local.posterPath,
          overview: '',
          voteAverage: local.tmdbRating,
          releaseDate: '',
          genreIds: [],
          actors: local.actors,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _movies = tmdbMovies;
        _filtered = tmdbMovies;
        _isLoading = false;
        _applyFilter();
      });
    }
  }

  void _applyFilter() {
    final query = _actorController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filtered = List.from(_movies);
      } else {
        _filtered = _movies.where((m) {
          final local = DatabaseService.get(m.id);
          return local?.actors.any((a) => a.toLowerCase().contains(query)) ?? false;
        }).toList();
      }
    });
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          ActorFilter(
            controller: _actorController,
            onChanged: _applyFilter,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? EmptyState(
                        icon: widget.status == 'to_watch'
                            ? Icons.bookmark_border
                            : Icons.check_circle_outline,
                        title: 'Aucun film',
                        subtitle: _actorController.text.isNotEmpty
                            ? 'Aucun film avec cet acteur'
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
