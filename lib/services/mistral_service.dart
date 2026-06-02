import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/local_movie.dart';

/// Service de recommandation IA via l'API Mistral.
///
/// Envoie la liste personnelle de l'utilisateur + ses critères (humeur,
/// durée, genres) à Mistral. Mistral retourne 1 à 3 films choisis dans
/// la liste personnelle avec une justification personnalisée.
class MistralService {
  final Dio _dio;

  MistralService()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://api.mistral.ai/v1',
          headers: {
            'Authorization': 'Bearer ${ApiConfig.mistralApiKey}',
            'Content-Type': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 15),
        ));

  /// Vérifie si la clé Mistral est configurée.
  static bool get isAvailable => ApiConfig.mistralApiKey.isNotEmpty;

  /// Obtient des recommandations de films depuis Mistral.
  ///
  /// [mood] : texte libre sur l'humeur/ambiance recherchée
  /// [maxDuration] : durée max souhaitée en minutes
  /// [selectedGenres] : liste des noms de genres sélectionnés (vide = tous)
  /// [allMovies] : tous les films de l'utilisateur (tous statuts confondus)
  ///
  /// Retourne une liste de maps {title, reason}.
  Future<List<Map<String, String>>> getRecommendations({
    required String mood,
    required int maxDuration,
    required List<String> selectedGenres,
    required List<LocalMovie> allMovies,
  }) async {
    if (!isAvailable) {
      throw Exception(
        'Clé Mistral non configurée. '
        'Ajoute MISTRAL_API_KEY dans .env et relance.',
      );
    }

    if (allMovies.isEmpty) {
      throw Exception('Liste vide');
    }

    // Construire le contexte des films pour Mistral
    final moviesStr = allMovies.asMap().entries.map((e) {
      final i = e.key + 1;
      final m = e.value;
      final status = m.status == 'to_watch' ? 'À regarder' : 'Vus';
      final actors =
          m.actors.isNotEmpty ? m.actors.take(3).join(', ') : 'N/A';
      return '$i. "${m.title}" — Note: ${m.tmdbRating.toStringAsFixed(1)}/10'
          ' — Statut: $status — Acteurs: $actors';
    }).join('\n');

    final systemPrompt = '''
Tu es PopCornMind, un assistant de recommandation de films spécialisé et enthousiaste.
Tu reçois la liste personnelle de films d'un utilisateur et ses préférences du moment.

RÈGLES STRICTES :
1. Ne propose QUE des films qui figurent DANS SA LISTE — pas de films externes.
2. Choisis 1 à 3 films maximum.
3. Pour chaque film, donne UNIQUEMENT le titre exact tel qu'écrit dans la liste.
4. La justification doit être personnalisée, chaleureuse et pertinente (2-3 phrases).
5. Lie chaque recommandation aux critères donnés (humeur, durée, genres).

Retourne UNIQUEMENT du JSON valide, sans aucun texte avant ou après.
Format EXACT :
{"recommendations": [
  {"title": "Titre Exact", "reason": "Justification personnalisée..."}
]}
''';

    final userPrompt = '''
Voici MA liste de films :

$moviesStr

Mes critères du moment :
- Humeur / Ambiance : $mood
- Durée max souhaitée : $maxDuration minutes
- Genres souhaités : ${selectedGenres.isEmpty ? 'Tous' : selectedGenres.join(', ')}

Quels films me recommandes-tu parmi MA liste ?
''';

    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': 'mistral-small-latest',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.7,
        'max_tokens': 1000,
      },
    );

    final content =
        response.data['choices'][0]['message']['content'] as String;

    // Nettoyer la réponse : Mistral peut encapsuler dans ```json ... ```
    var cleaned = content.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'^```(?:json)?\s*'), '');
      cleaned = cleaned.replaceAll(RegExp(r'\s*```$'), '');
    }

    final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
    if (!decoded.containsKey('recommendations')) {
      throw FormatException(
        'Réponse JSON invalide : clé "recommendations" manquante',
      );
    }

    final recs = decoded['recommendations'] as List;
    return recs.map((e) {
      return {
        'title': (e['title'] as String?)?.trim() ?? '',
        'reason': (e['reason'] as String?)?.trim() ?? '',
      };
    }).toList();
  }

  /// Fallback aléatoire si Mistral est indisponible.
  /// Retourne au maximum [count] films depuis [movies].
  static List<LocalMovie> getRandomFallback(
    List<LocalMovie> movies, {
    int count = 3,
  }) {
    if (movies.isEmpty) return [];
    final random = Random();
    final shuffled = List<LocalMovie>.from(movies)..shuffle(random);
    return shuffled.take(min(count, movies.length)).toList();
  }
}

/// Liste des genres TMDB pour le sélecteur multi-choix.
const Map<int, String> kMovieGenres = {
  28: 'Action',
  12: 'Aventure',
  16: 'Animation',
  35: 'Comédie',
  80: 'Crime',
  99: 'Documentaire',
  18: 'Drame',
  10751: 'Familial',
  14: 'Fantastique',
  36: 'Histoire',
  27: 'Horreur',
  10402: 'Musique',
  9648: 'Mystère',
  10749: 'Romance',
  878: 'Science-Fiction',
  53: 'Thriller',
  10752: 'Guerre',
  37: 'Western',
};
