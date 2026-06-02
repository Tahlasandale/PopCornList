import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/tmdb_movie.dart';
import '../models/tmdb_serie.dart';

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

  Future<Map<String, dynamic>> getMovieWithCredits(int id) async {
    final response = await _dio.get('/movie/$id', queryParameters: {'append_to_response': 'credits'});
    final data = response.data;
    final actors = (data['credits']['cast'] as List?)
            ?.take(5)
            .map((e) => e['name'] as String)
            .toList() ??
        [];
    return {
      'id': data['id'],
      'title': data['title'] ?? '',
      'poster_path': data['poster_path'],
      'vote_average': (data['vote_average'] ?? 0).toDouble(),
      'actors': actors,
    };
  }

  Future<List<TmdbSerie>> searchSeries(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await _dio.get('/search/tv', queryParameters: {'query': query});
    return (response.data['results'] as List).map((e) => TmdbSerie.fromJson(e)).toList();
  }

  Future<TmdbSerie> getSerieDetails(int id) async {
    final response = await _dio.get('/tv/$id');
    return TmdbSerie.fromJson(response.data);
  }

  Future<List<String>> getSerieActors(int id) async {
    final response = await _dio.get('/tv/$id/credits');
    return (response.data['cast'] as List)
        .take(5)
        .map((e) => e['name'] as String)
        .toList();
  }

  Future<Map<String, dynamic>> getSerieWithCredits(int id) async {
    final response = await _dio.get('/tv/$id', queryParameters: {'append_to_response': 'credits'});
    final data = response.data;
    final actors = (data['credits']['cast'] as List?)
            ?.take(5)
            .map((e) => e['name'] as String)
            .toList() ??
        [];
    return {
      'id': data['id'],
      'title': data['name'] ?? data['title'] ?? '',
      'poster_path': data['poster_path'],
      'vote_average': (data['vote_average'] ?? 0).toDouble(),
      'actors': actors,
    };
  }
}
