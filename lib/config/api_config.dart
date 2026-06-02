class ApiConfig {
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  /// Clé API TMDB.
  /// Priorité : --dart-define=TMDB_API_KEY=xxx > fallback intégré.
  /// Pour surcharger : flutter build apk --dart-define=TMDB_API_KEY=xxx
  static const String tmdbApiKey = String.fromEnvironment(
    'TMDB_API_KEY',
    defaultValue: '4d84a0553d5aa1420e3fc54ad30aafb3',
  );

  /// Clé API Mistral.
  /// Injectée via --dart-define=MISTRAL_API_KEY=xxx (build release)
  /// ou --dart-define-from-file=.env.
  /// Optionnelle — nécessaire seulement pour les recommandations IA (P7).
  /// Clé API Mistral — intégrée directement à la compilation.
  static const String mistralApiKey = 'D0uyIwRS0HhaGUM1bnWJgvEmWf0ZjgjH';

  static String imageUrl(String? path) {
    if (path == null) return '';
    return '$imageBaseUrl$path';
  }
}
