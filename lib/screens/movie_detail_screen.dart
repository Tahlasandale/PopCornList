import 'package:flutter/material.dart';
import '../models/tmdb_movie.dart';
import '../models/local_movie.dart';
import '../services/tmdb_service.dart';
import '../services/database_service.dart';

class MovieDetailScreen extends StatefulWidget {
  final TmdbMovie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final TmdbService _tmdbService = TmdbService();
  final TextEditingController _notesController = TextEditingController();
  TmdbMovie? _fullMovie;
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
      await DatabaseService.removeMovie(widget.movie.id);
      setState(() => _currentStatus = null);
    } else {
      final exists = DatabaseService.exists(widget.movie.id);
      if (exists) {
        await DatabaseService.updateStatus(widget.movie.id, status);
      } else {
        await DatabaseService.addMovie(LocalMovie(
          tmdbId: widget.movie.id,
          title: widget.movie.title,
          posterPath: widget.movie.posterPath,
          status: status,
          tmdbRating: widget.movie.voteAverage,
          actors: _actors,
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
              icon: const Icon(Icons.delete_outline),
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
          child: movie.posterUrl != null
              ? Image.network(
                  movie.posterUrl!,
                  width: 120,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 120,
                    height: 180,
                    color: Colors.grey[900],
                    child: const Icon(Icons.movie_outlined, color: Colors.grey),
                  ),
                )
              : Container(
                  width: 120,
                  height: 180,
                  color: Colors.grey[900],
                  child: const Icon(Icons.movie_outlined, color: Colors.grey),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movie.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (movie.year.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(movie.year, style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    movie.voteAverage.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
            onTap: () => _toggleStatus('to_watch'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatusButton(
            icon: Icons.check_circle,
            label: 'Vus',
            isActive: _currentStatus == 'watched',
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
        const Text('Synopsis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          movie.overview.isNotEmpty ? movie.overview : 'Aucun synopsis disponible.',
          style: TextStyle(color: Colors.grey[300], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildActors() {
    if (_actors.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Acteurs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _actors
              .map((actor) => Chip(
                    label: Text(actor, style: const TextStyle(fontSize: 13)),
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
        const Text('Notes personnelles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 4,
          enabled: _currentStatus != null,
          decoration: InputDecoration(
            hintText: _currentStatus == null
                ? 'Ajoutez d\'abord le film à une liste'
                : 'Écrivez votre note ici...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
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
  final VoidCallback onTap;

  const _StatusButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(isActive ? icon : Icons.add),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: isActive ? Theme.of(context).colorScheme.primaryContainer : null,
        foregroundColor: isActive ? Theme.of(context).colorScheme.onPrimaryContainer : null,
        side: isActive
            ? BorderSide(color: Theme.of(context).colorScheme.primary)
            : null,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
