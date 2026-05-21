class LocalMovie {
  final int tmdbId;
  final String title;
  final String? posterPath;
  String status;
  String notes;
  final DateTime addedDate;
  final double tmdbRating;
  final List<String> actors;

  LocalMovie({
    required this.tmdbId,
    required this.title,
    this.posterPath,
    required this.status,
    this.notes = '',
    DateTime? addedDate,
    this.tmdbRating = 0,
    this.actors = const [],
  }) : addedDate = addedDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'tmdbId': tmdbId,
        'title': title,
        'posterPath': posterPath,
        'status': status,
        'notes': notes,
        'addedDate': addedDate.toIso8601String(),
        'tmdbRating': tmdbRating,
        'actors': actors,
      };

  factory LocalMovie.fromJson(Map<String, dynamic> json) => LocalMovie(
        tmdbId: json['tmdbId'],
        title: json['title'],
        posterPath: json['posterPath'],
        status: json['status'],
        notes: json['notes'] ?? '',
        addedDate: DateTime.parse(json['addedDate']),
        tmdbRating: (json['tmdbRating'] ?? 0).toDouble(),
        actors: List<String>.from(json['actors'] ?? []),
      );
}
