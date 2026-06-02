import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/stored_media.dart';

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
  /// [allMovies] : tous les médias de l'utilisateur (tous statuts confondus)
  ///
  /// Retourne une liste de maps {title, reason}.
  Future<List<Map<String, String>>> getRecommendations({
    required String mood,
    required int maxDuration,
    required List<String> selectedGenres,
    required List<StoredMedia> allMovies,
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
      final typeLabel = m.type == MediaType.series ? 'Série' : 'Film';
      final actors =
          m.actors.isNotEmpty ? m.actors.take(3).join(', ') : 'N/A';
      return '$i. "$typeLabel: ${m.title}" — Note: ${m.tmdbRating.toStringAsFixed(1)}/10'
          ' — Statut: $status — Acteurs: $actors';
    }).join('\n');

    final systemPrompt = '''
Tu es PopCornMind, un assistant de recommandation de films spécialisé et enthousiaste.
Tu reçois la liste personnelle de films/séries d'un utilisateur et ses préférences du moment.

RÈGLES STRICTES :
1. Ne propose QUE des films/séries qui figurent DANS SA LISTE — pas de contenus externes.
2. Choisis 1 à 3 films/séries maximum.
3. Pour chaque recommandation, donne UNIQUEMENT le titre exact tel qu'écrit dans la liste.
4. La justification doit être personnalisée, chaleureuse et pertinente (2-3 phrases).
5. Lie chaque recommandation aux critères donnés (humeur, durée, genres).

Retourne UNIQUEMENT du JSON valide, sans aucun texte avant ou après.
Format EXACT :
{"recommendations": [
  {"title": "Titre Exact", "reason": "Justification personnalisée..."}
]}
''';

    final userPrompt = '''
Voici MA liste de films/séries :

$moviesStr

Mes critères du moment :
- Humeur / Ambiance : $mood
- Durée max souhaitée : $maxDuration minutes
- Genres souhaités : ${selectedGenres.isEmpty ? 'Tous' : selectedGenres.join(', ')}

Quels contenus me recommandes-tu parmi MA liste ?
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
  /// Retourne au maximum [count] contenus depuis [mediaList].
  static List<StoredMedia> getRandomFallback(
    List<StoredMedia> mediaList, {
    int count = 3,
  }) {
    if (mediaList.isEmpty) return [];
    final random = Random();
    final shuffled = List<StoredMedia>.from(mediaList)..shuffle(random);
    return shuffled.take(min(count, mediaList.length)).toList();
  }
}
