import '../models/tmdb_movie.dart';

enum SortBy { title, rating, duration, releaseDate, addedDate }

/// Un critère de tri : champ + direction.
class SortCriteria {
  final SortBy field;
  final bool ascending;

  const SortCriteria(this.field, this.ascending);

  SortCriteria toggleDirection() => SortCriteria(field, !ascending);
}

class FilmFilter {
  static List<TmdbMovie> apply({
    required List<TmdbMovie> movies,
    List<SortCriteria> criteria = const [SortCriteria(SortBy.rating, false)],
    String? titleFilter,
    List<String> selectedActors = const [],
    List<int> selectedGenres = const [],
  }) {
    var result = movies;

    if (titleFilter != null && titleFilter.trim().isNotEmpty) {
      final q = titleFilter.toLowerCase();
      result = result.where((m) => m.title.toLowerCase().contains(q)).toList();
    }

    if (selectedActors.isNotEmpty) {
      result = result
          .where((m) => m.actors.any((a) => selectedActors.contains(a)))
          .toList();
    }

    if (selectedGenres.isNotEmpty) {
      result = result
          .where((m) => selectedGenres.every((g) => m.genreIds.contains(g)))
          .toList();
    }

    result.sort((a, b) {
      for (final c in criteria) {
        final cmp = _compare(c.field, a, b);
        if (cmp != 0) return c.ascending ? cmp : -cmp;
      }
      return 0;
    });

    return result;
  }

  static int _compare(SortBy field, TmdbMovie a, TmdbMovie b) {
    switch (field) {
      case SortBy.title:
        return a.title.compareTo(b.title);
      case SortBy.rating:
        return a.voteAverage.compareTo(b.voteAverage);
      case SortBy.duration:
        return (a.runtime ?? 0).compareTo(b.runtime ?? 0);
      case SortBy.releaseDate:
        return a.releaseDate.compareTo(b.releaseDate);
      case SortBy.addedDate:
        final da = a.addedDate ?? DateTime(2000);
        final db = b.addedDate ?? DateTime(2000);
        return da.compareTo(db);
    }
  }
}
