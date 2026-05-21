import '../models/tmdb_movie.dart';

enum SortBy { title, rating, duration, releaseDate, addedDate }

class FilmFilter {
  static List<TmdbMovie> apply({
    required List<TmdbMovie> movies,
    SortBy sortBy = SortBy.rating,
    bool ascending = false,
    String? titleFilter,
    List<String> selectedActors = const [],
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

    result.sort((a, b) {
      int cmp;
      switch (sortBy) {
        case SortBy.title:
          cmp = a.title.compareTo(b.title);
        case SortBy.rating:
          cmp = a.voteAverage.compareTo(b.voteAverage);
        case SortBy.duration:
          cmp = (a.runtime ?? 0).compareTo(b.runtime ?? 0);
        case SortBy.releaseDate:
          cmp = a.releaseDate.compareTo(b.releaseDate);
        case SortBy.addedDate:
          final da = a.addedDate ?? DateTime(2000);
          final db = b.addedDate ?? DateTime(2000);
          cmp = da.compareTo(db);
      }
      return ascending ? cmp : -cmp;
    });

    return result;
  }
}
