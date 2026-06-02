import '../config/api_config.dart';

class TmdbSerie {
  final int id;
  final String title;
  final String? posterPath;
  final String overview;
  final double voteAverage;
  final String releaseDate;
  final List<int> genreIds;
  final List<String> actors;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;

  TmdbSerie({
    required this.id,
    required this.title,
    this.posterPath,
    required this.overview,
    required this.voteAverage,
    required this.releaseDate,
    required this.genreIds,
    this.actors = const [],
    this.numberOfSeasons,
    this.numberOfEpisodes,
  });

  factory TmdbSerie.fromJson(Map<String, dynamic> json) {
    return TmdbSerie(
      id: json['id'],
      title: json['name'] ?? json['title'] ?? '',
      posterPath: json['poster_path'],
      overview: json['overview'] ?? '',
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      releaseDate: json['first_air_date'] ?? json['release_date'] ?? '',
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      numberOfSeasons: json['number_of_seasons'],
      numberOfEpisodes: json['number_of_episodes'],
    );
  }

  String? get posterUrl => posterPath != null ? ApiConfig.imageUrl(posterPath) : null;

  String get year => releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
}
