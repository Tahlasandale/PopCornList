import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/stored_media.dart';
import 'tmdb_service.dart';
import 'database_service.dart';

class MovieResolverService {
  final TmdbService _tmdbService;

  MovieResolverService(this._tmdbService);

  Future<int> resolveAll({void Function(int resolved, int total, String title)? onProgress}) async {
    final unresolved = DatabaseService.getUnresolved();
    int resolved = 0;

    for (int i = 0; i < unresolved.length; i++) {
      final media = unresolved[i];
      onProgress?.call(i, unresolved.length, media.title);
      final ok = await resolveMedia(media);
      if (ok) resolved++;
    }

    return resolved;
  }

  Future<bool> resolveMedia(StoredMedia media) async {
    try {
      final results = await _tmdbService.searchMovies(media.title);
      if (results.isEmpty) return false;

      final first = results.first;
      final data = await _tmdbService.getMovieWithCredits(first.id);

      media.tmdbId = data['id'] as int;
      media.posterPath = data['poster_path'] as String?;
      media.tmdbRating = data['vote_average'] as double;
      media.actors = List<String>.from(data['actors'] as List);

      await DatabaseService.updateMedia(media);
      return true;
    } catch (e) {
      debugPrint('resolveMedia erreur pour "${media.title}": $e');
      return false;
    }
  }
}
