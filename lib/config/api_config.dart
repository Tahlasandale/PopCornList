class ApiConfig {
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  /// Clé API TMDB.
  /// Injectée via --dart-define=TMDB_API_KEY=xxx (build release)
  /// ou --dart-define-from-file=.env (développement local).
  /// Voir .env.example pour la configuration.
  static const String tmdbApiKey = String.fromEnvironment(
    'TMDB_API_KEY',
    defaultValue: '',
  );

  /// Clé API Mistral.
  /// Injectée via --dart-define=MISTRAL_API_KEY=xxx (build release)
  /// ou --dart-define-from-file=.env.
  /// Optionnelle — nécessaire seulement pour les recommandations IA (P7).
  static const String mistralApiKey = String.fromEnvironment(
    'MISTRAL_API_KEY',
    defaultValue: '',
  );

  static String imageUrl(String? path) {
    if (path == null) return '';
    return '$imageBaseUrl$path';
  }
}
