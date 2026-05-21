import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/tmdb_movie.dart';

class TmdbService {
  final Dio _dio;

  TmdbService()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.tmdbBaseUrl,
          queryParameters: {'api_key': ApiConfig.tmdbApiKey, 'language': 'fr-FR'},
        ));

  Future<List<TmdbMovie>> searchMovies(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await _dio.get('/search/movie', queryParameters: {'query': query});
    return (response.data['results'] as List).map((e) => TmdbMovie.fromJson(e)).toList();
  }

  Future<TmdbMovie> getMovieDetails(int id) async {
    final response = await _dio.get('/movie/$id');
    return TmdbMovie.fromJson(response.data);
  }

  Future<List<String>> getMovieActors(int id) async {
    final response = await _dio.get('/movie/$id/credits');
    return (response.data['cast'] as List)
        .take(5)
        .map((e) => e['name'] as String)
        .toList();
  }
}
