import '../config/api_config.dart';

class TmdbMovie {
  final int id;
  final String title;
  final String? posterPath;
  final String overview;
  final double voteAverage;
  final String releaseDate;
  final List<int> genreIds;
  final List<String> actors;
  final int? runtime;
  final DateTime? addedDate;
  final bool isSerie;

  TmdbMovie({
    required this.id,
    required this.title,
    this.posterPath,
    required this.overview,
    required this.voteAverage,
    required this.releaseDate,
    required this.genreIds,
    this.actors = const [],
    this.runtime,
    this.addedDate,
    this.isSerie = false,
  });

  factory TmdbMovie.fromJson(Map<String, dynamic> json) {
    return TmdbMovie(
      id: json['id'],
      title: json['title'] ?? '',
      posterPath: json['poster_path'],
      overview: json['overview'] ?? '',
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      releaseDate: json['release_date'] ?? '',
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      runtime: json['runtime'],
    );
  }

  String? get posterUrl => posterPath != null ? ApiConfig.imageUrl(posterPath) : null;

  String get year => releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
}
