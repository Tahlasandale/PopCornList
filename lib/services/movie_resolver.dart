import 'dart:async';
import '../models/local_movie.dart';
import 'tmdb_service.dart';
import 'database_service.dart';

class MovieResolverService {
  final TmdbService _tmdbService;

  MovieResolverService(this._tmdbService);

  Future<int> resolveAll({void Function(int resolved, int total, String title)? onProgress}) async {
    final unresolved = DatabaseService.getUnresolved();
    int resolved = 0;

    for (int i = 0; i < unresolved.length; i++) {
      final movie = unresolved[i];
      onProgress?.call(i, unresolved.length, movie.title);
      final ok = await resolveMovie(movie);
      if (ok) resolved++;
    }

    return resolved;
  }

  Future<bool> resolveMovie(LocalMovie movie) async {
    try {
      final results = await _tmdbService.searchMovies(movie.title);
      if (results.isEmpty) return false;

      final first = results.first;
      final data = await _tmdbService.getMovieWithCredits(first.id);

      movie.tmdbId = data['id'] as int;
      movie.posterPath = data['poster_path'] as String?;
      movie.tmdbRating = data['vote_average'] as double;
      movie.actors = List<String>.from(data['actors'] as List);

      await DatabaseService.updateMovie(movie);
      return true;
    } catch (_) {
      return false;
    }
  }
}
