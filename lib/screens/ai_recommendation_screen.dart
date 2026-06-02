import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/stored_media.dart';
import '../models/tmdb_movie.dart';
import '../services/database_service.dart';
import '../services/mistral_service.dart';
import '../widgets/genre_filter.dart';
import 'movie_detail_screen.dart';
/// Écran de recommandation IA.
///
/// L'utilisateur renseigne son humeur, une durée max et des genres,
/// puis Mistral propose 1 à 3 films depuis sa liste personnelle.
class AiRecommendationScreen extends StatefulWidget {
  const AiRecommendationScreen({super.key});

  @override
  State<AiRecommendationScreen> createState() => _AiRecommendationScreenState();
}

class _AiRecommendationScreenState extends State<AiRecommendationScreen> {
  final _moodController = TextEditingController();
  final _genres = kMovieGenres.values.toList();

  double _maxDuration = 120;
  final Set<String> _selectedGenres = {};
  bool _isLoading = false;
  bool _hasResult = false;
  String? _errorMessage;

  /// Résultat : liste des films recommandés avec leur justification
  List<_Recommendation> _recommendations = [];

  /// Tous les films de l'utilisateur (cache)
  List<StoredMedia> _allMovies = [];

  @override
  void initState() {
    super.initState();
    _allMovies = DatabaseService.getAll();
  }

  @override
  void dispose() {
    _moodController.dispose();
    super.dispose();
  }

  bool get _canPropose =>
      _moodController.text.trim().isNotEmpty && _allMovies.isNotEmpty;

  Future<void> _propose() async {
    if (!_canPropose) return;

    setState(() {
      _isLoading = true;
      _hasResult = false;
      _errorMessage = null;
      _recommendations = [];
    });

    try {
      if (!MistralService.isAvailable) {
        // Fallback aléatoire si pas de clé Mistral
        final fallback = MistralService.getRandomFallback(_allMovies);
        setState(() {
          _recommendations = fallback.map((m) => _Recommendation(
                localMovie: m,
                reason: '🎲 Suggestion aléatoire (clé Mistral non configurée)',
              )).toList();
          _hasResult = true;
        });
        return;
      }

      final results = await MistralService().getRecommendations(
        mood: _moodController.text.trim(),
        maxDuration: _maxDuration.round(),
        selectedGenres: _selectedGenres.toList(),
        allMovies: _allMovies,
      );

      if (results.isEmpty) {
        // Fallback aléatoire si Mistral n'a rien trouvé
        final fallback = MistralService.getRandomFallback(_allMovies, count: 3);
        setState(() {
          _recommendations = fallback.map((m) => _Recommendation(
                localMovie: m,
                reason: '🎲 Mistral n\'a rien trouvé — suggestion aléatoire',
              )).toList();
          _hasResult = true;
        });
        return;
      }

      // Associer chaque titre recommandé au StoredMedia correspondant
      setState(() {
        _recommendations = results.map((r) {
          final match = _allMovies.cast<StoredMedia?>().firstWhere(
                (m) => m!.title.trim().toLowerCase() ==
                    r['title']!.trim().toLowerCase(),
                orElse: () => null,
              );
          return _Recommendation(
            localMovie: match,
            title: r['title']!,
            reason: r['reason']!,
          );
        }).toList();
        _hasResult = true;
      });
    } on DioException catch (e) {
      // Timeout ou erreur réseau → fallback aléatoire
      final fallback = MistralService.getRandomFallback(_allMovies);
      setState(() {
        _recommendations = fallback.map((m) => _Recommendation(
              localMovie: m,
              reason:
                  '📡 Mistral indisponible (${e.type.name}) — suggestion aléatoire',
            )).toList();
        _hasResult = true;
        _errorMessage = null;
      });
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg == 'Liste vide') {
        setState(() {
          _errorMessage = 'Ajoute déjà des films avant de demander une recommandation !';
          _hasResult = true;
        });
      } else {
        // Fallback sur erreur
        final fallback = MistralService.getRandomFallback(_allMovies);
        setState(() {
          _recommendations = fallback.map((m) => _Recommendation(
                localMovie: m,
                reason: '⚠️ Erreur : $msg — suggestion aléatoire',
              )).toList();
          _hasResult = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openDetail(StoredMedia? movie) {
    if (movie == null) return;
    final tmdb = TmdbMovie(
      id: movie.tmdbId,
      title: movie.title,
      posterPath: movie.posterPath,
      overview: '',
      voteAverage: movie.tmdbRating,
      releaseDate: '',
      genreIds: [],
      actors: movie.actors,
      addedDate: movie.addedDate,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: tmdb)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🧠 '),
            Text('Aide-moi à choisir'),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- En-tête décoratif ---
            _buildHeader(),
            const SizedBox(height: 24),

            // --- Section Humeur ---
            _buildSectionTitle(Icons.psychology, 'Ambiance'),
            const SizedBox(height: 8),
            _buildMoodField(),
            const SizedBox(height: 24),

            // --- Section Durée ---
            _buildSectionTitle(Icons.timer_outlined, 'Durée max'),
            const SizedBox(height: 8),
            _buildDurationSlider(),
            const SizedBox(height: 24),

            // --- Section Genres ---
            _buildSectionTitle(Icons.category_outlined, 'Genres'),
            const SizedBox(height: 8),
            _buildGenreChips(),
            const SizedBox(height: 28),

            // --- Bouton Proposer ---
            _buildProposeButton(),
            const SizedBox(height: 32),

            // --- Résultats ---
            if (_isLoading) _buildLoadingState(),
            if (_hasResult && !_isLoading) _buildResults(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            popcorn.withValues(alpha: 0.15),
            siege.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: popcorn.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, size: 40, color: popcorn),
          const SizedBox(height: 12),
          Text(
            'Dis-moi ce que tu as envie de regarder,\nje fouille ta liste et je te propose le film parfait !',
            textAlign: TextAlign.center,
            style: TextStyle(color: ticket, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: popcorn),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ecran,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodField() {
    return TextField(
      controller: _moodController,
      maxLines: 3,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: ecran, height: 1.4),
      decoration: InputDecoration(
        hintText: 'Ex: j\'ai envie de rire, soirée flippante, '
            'feel-good du dimanche, un film qui fait réfléchir…',
        hintStyle: TextStyle(color: ticket.withValues(alpha: 0.7), fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: projecteur,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 48),
          child: Icon(Icons.edit_note, color: popcorn),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildDurationSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: projecteur,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('30 min', style: TextStyle(color: ticket, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: popcorn.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_maxDuration.round()} min',
                  style: const TextStyle(
                    color: popcorn,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const Text('4 h', style: TextStyle(color: ticket, fontSize: 13)),
            ],
          ),
          Slider(
            value: _maxDuration,
            min: 30,
            max: 240,
            divisions: 14,
            activeColor: popcorn,
            inactiveColor: ticket.withValues(alpha: 0.3),
            onChanged: (v) => setState(() => _maxDuration = v),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChips() {
    if (_genres.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _genres.map((genre) {
        final selected = _selectedGenres.contains(genre);
        return FilterChip(
          label: Text(
            genre,
            style: TextStyle(
              color: selected ? onyx : ecran,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          selected: selected,
          selectedColor: popcorn,
          checkmarkColor: onyx,
          backgroundColor: projecteur,
          side: selected
              ? BorderSide(color: popcorn)
              : BorderSide(color: ticket.withValues(alpha: 0.3)),
          onSelected: (v) {
            setState(() {
              if (v) {
                _selectedGenres.add(genre);
              } else {
                _selectedGenres.remove(genre);
              }
            });
          },
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  Widget _buildProposeButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: _canPropose && !_isLoading ? _propose : null,
        icon: const Icon(Icons.auto_awesome, size: 22),
        label: Text(
          _isLoading ? 'Consultation de PopCornMind…' : '🎬 Proposer',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: popcorn,
          foregroundColor: onyx,
          disabledBackgroundColor: projecteur,
          disabledForegroundColor: ticket,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(color: popcorn, strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            'PopCornMind réfléchit…',
            style: TextStyle(color: ticket, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Il analyse ta liste et tes préférences',
            style: TextStyle(
              color: ticket.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    if (_recommendations.isEmpty) {
      return _buildEmptyState();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: popcorn, size: 20),
            const SizedBox(width: 8),
            Text(
              'PopCornMind te propose :',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ecran,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._recommendations.asMap().entries.map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key < _recommendations.length - 1 ? 16 : 0,
                ),
                child: _buildRecommendationCard(entry.value, entry.key),
              ),
            ),
      ],
    );
  }

  Widget _buildRecommendationCard(_Recommendation rec, int index) {
    final movie = rec.localMovie;
    final hasMovie = movie != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: projecteur,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: popcorn.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du numéro
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: popcorn.withValues(alpha: 0.10),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: popcorn,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: onyx,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Recommandation',
                  style: TextStyle(
                    color: popcorn,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Corps de la carte
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Infos film
                if (hasMovie) _buildMovieInfoRow(movie),
                if (hasMovie) const SizedBox(height: 16),

                // Justification Mistral
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: onyx,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: popcorn.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💬',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          rec.reason,
                          style: TextStyle(
                            color: ticket,
                            fontSize: 13,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasMovie) const SizedBox(height: 14),

                // Bouton Voir la fiche
                if (hasMovie)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _openDetail(movie),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Voir la fiche'),
                      style: TextButton.styleFrom(
                        foregroundColor: popcorn,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ),

                // Fallback : pas de film trouvé dans la liste
                if (!hasMovie)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '⚠️ "${rec.title}" n\'a pas été trouvé dans ta liste. '
                      'Vérifie l\'orthographe du titre.',
                      style: TextStyle(color: siege, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieInfoRow(StoredMedia movie) {
    return Row(
      children: [
        // Poster
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: movie.posterPath != null
              ? Image.network(
                  'https://image.tmdb.org/t/p/w92${movie.posterPath}',
                  width: 60,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _posterPlaceholder(60, 90),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: 60,
                      height: 90,
                      color: projecteur,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                )
              : _posterPlaceholder(60, 90),
        ),
        const SizedBox(width: 14),

        // Infos
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movie.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ecran,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: popcorn),
                  const SizedBox(width: 4),
                  Text(
                    movie.tmdbRating.toStringAsFixed(1),
                    style: const TextStyle(color: popcorn, fontSize: 14),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: movie.status == 'to_watch'
                          ? popcorn.withValues(alpha: 0.15)
                          : siege.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      movie.status == 'to_watch' ? 'À regarder' : 'Vus',
                      style: TextStyle(
                        color: movie.status == 'to_watch' ? popcorn : siege,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (movie.actors.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  movie.actors.take(2).join(', '),
                  style: const TextStyle(color: ticket, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _posterPlaceholder(double w, double h) {
    return Container(
      width: w,
      height: h,
      color: projecteur,
      child: const Center(child: Icon(Icons.movie_outlined, color: ticket)),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: siege.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: siege.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, size: 48, color: siege),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ecran, fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    // Si la liste est vide
    if (_allMovies.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: popcorn.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: popcorn.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.movie_creation_outlined, size: 48, color: popcorn),
            const SizedBox(height: 12),
            const Text(
              'Ajoute déjà des films à ta liste !',
              textAlign: TextAlign.center,
              style: TextStyle(color: ecran, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Va chercher des films dans l\'onglet Recherche\n'
              'et ajoute-les à "À regarder" ou "Vus".',
              textAlign: TextAlign.center,
              style: TextStyle(color: ticket, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Représente une recommandation individuelle.
class _Recommendation {
  final StoredMedia? localMovie;
  final String? title;
  final String reason;

  const _Recommendation({
    this.localMovie,
    this.title,
    required this.reason,
  });
}
