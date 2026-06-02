import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/tmdb_movie.dart';
import '../models/stored_media.dart';
import '../services/tmdb_service.dart';
import '../services/database_service.dart';

class MovieDetailScreen extends StatefulWidget {
  final TmdbMovie movie;
  final bool isSerie;

  const MovieDetailScreen({super.key, required this.movie, this.isSerie = false});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final TmdbService _tmdbService = TmdbService();
  final TextEditingController _notesController = TextEditingController();
  TmdbMovie? _fullMovie;
  int? _numberOfSeasons;
  int? _numberOfEpisodes;
  List<String> _actors = [];
  String? _currentStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      if (widget.isSerie) {
        final serie = await _tmdbService.getSerieDetails(widget.movie.id);
        final actors = await _tmdbService.getSerieActors(widget.movie.id);
        final local = DatabaseService.get(widget.movie.id);

        if (mounted) {
          setState(() {
            _fullMovie = TmdbMovie(
              id: serie.id,
              title: serie.title,
              posterPath: serie.posterPath,
              overview: serie.overview,
              voteAverage: serie.voteAverage,
              releaseDate: serie.releaseDate,
              genreIds: serie.genreIds,
              actors: serie.actors,
              runtime: serie.numberOfEpisodes,
            );
            _numberOfSeasons = serie.numberOfSeasons;
            _numberOfEpisodes = serie.numberOfEpisodes;
            _actors = actors;
            _currentStatus = local?.status;
            _notesController.text = local?.notes ?? '';
            _isLoading = false;
          });
        }
      } else {
        final details = await _tmdbService.getMovieDetails(widget.movie.id);
        final actors = await _tmdbService.getMovieActors(widget.movie.id);
        final local = DatabaseService.get(widget.movie.id);

        if (mounted) {
          setState(() {
            _fullMovie = details;
            _actors = actors;
            _currentStatus = local?.status;
            _notesController.text = local?.notes ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _toggleStatus(String status) async {
    if (_currentStatus == status) {
      await DatabaseService.removeMedia(widget.movie.id);
      setState(() => _currentStatus = null);
    } else {
      final exists = DatabaseService.exists(widget.movie.id);
      if (exists) {
        await DatabaseService.updateStatus(widget.movie.id, status);
      } else {
        await DatabaseService.addMedia(StoredMedia(
          tmdbId: widget.movie.id,
          title: widget.movie.title,
          posterPath: widget.movie.posterPath,
          status: status,
          tmdbRating: widget.movie.voteAverage,
          actors: _actors,
          type: widget.isSerie ? MediaType.series : MediaType.movie,
        ));
      }
      setState(() => _currentStatus = status);
    }
  }

  Future<void> _saveNotes() async {
    if (_currentStatus != null) {
      await DatabaseService.updateNotes(widget.movie.id, _notesController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note sauvegardée'), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = _fullMovie ?? widget.movie;

    return Scaffold(
      appBar: AppBar(
        title: Text(movie.title),
        actions: [
          if (_currentStatus != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: siege),
              onPressed: () => _toggleStatus(_currentStatus!),
              tooltip: 'Retirer des listes',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(movie),
                  const SizedBox(height: 16),
                  _buildStatusButtons(),
                  const SizedBox(height: 16),
                  _buildSynopsis(movie),
                  const SizedBox(height: 16),
                  _buildActors(),
                  const SizedBox(height: 16),
                  _buildNotesSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(TmdbMovie movie) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              movie.posterUrl != null
                  ? Hero(
                      tag: 'poster_${movie.id}',
                      child: Image.network(
                        movie.posterUrl!,
                        width: 120,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _posterPlaceholder(),
                      ),
                    )
                  : _posterPlaceholder(),
              if (widget.isSerie)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: popcorn,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'SÉRIE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: onyx,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movie.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ecran),
              ),
              if (movie.year.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(movie.year, style: const TextStyle(color: ticket, fontSize: 16)),
              ],
              if (widget.isSerie && _numberOfSeasons != null) ...[
                const SizedBox(height: 4),
                Text(
                  '$_numberOfSeasons saison${_numberOfSeasons! > 1 ? "s" : ""} · $_numberOfEpisodes épisodes',
                  style: const TextStyle(color: ticket, fontSize: 14),
                ),
              ],
              if (!widget.isSerie && movie.runtime != null && movie.runtime! > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${movie.runtime} min',
                  style: const TextStyle(color: ticket, fontSize: 14),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: popcorn, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    movie.voteAverage.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 18, color: ecran),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      width: 120,
      height: 180,
      color: projecteur,
      child: const Center(
        child: Icon(
          Icons.movie_outlined,
          color: ticket,
        ),
      ),
    );
  }

  Widget _buildStatusButtons() {
    return Row(
      children: [
        Expanded(
          child: _StatusButton(
            icon: Icons.bookmark,
            label: 'À regarder',
            isActive: _currentStatus == 'to_watch',
            activeColor: popcorn,
            onTap: () => _toggleStatus('to_watch'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatusButton(
            icon: Icons.check_circle,
            label: 'Vus',
            isActive: _currentStatus == 'watched',
            activeColor: siege,
            onTap: () => _toggleStatus('watched'),
          ),
        ),
      ],
    );
  }

  Widget _buildSynopsis(TmdbMovie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Synopsis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ecran)),
        const SizedBox(height: 8),
        Text(
          movie.overview.isNotEmpty ? movie.overview : 'Aucun synopsis disponible.',
          style: const TextStyle(color: ticket, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildActors() {
    if (_actors.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Acteurs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ecran)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _actors
              .map((actor) => Chip(
                    label: Text(actor, style: const TextStyle(fontSize: 13, color: ecran)),
                    backgroundColor: projecteur,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notes personnelles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ecran)),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 4,
          enabled: _currentStatus != null,
          style: const TextStyle(color: ecran),
          decoration: InputDecoration(
            hintText: _currentStatus == null
                ? 'Ajoutez d\'abord à une liste'
                : 'Écrivez votre note ici...',
            hintStyle: const TextStyle(color: ticket),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: projecteur,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonalIcon(
            onPressed: _currentStatus != null ? _saveNotes : null,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Sauvegarder'),
          ),
        ),
      ],
    );
  }
}

class _StatusButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _StatusButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(isActive ? icon : Icons.add),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: isActive ? activeColor : null,
        side: isActive ? BorderSide(color: activeColor) : null,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
