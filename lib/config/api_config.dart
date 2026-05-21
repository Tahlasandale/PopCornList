class ApiConfig {
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbApiKey = '4d84a0553d5aa1420e3fc54ad30aafb3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  static String imageUrl(String? path) {
    if (path == null) return '';
    return '$imageBaseUrl$path';
  }
}
