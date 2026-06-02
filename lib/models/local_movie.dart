import 'package:uuid/uuid.dart';

class LocalMovie {
  String id;
  int tmdbId;
  final String title;
  String? posterPath;
  String status;
  String notes;
  final DateTime addedDate;
  double tmdbRating;
  List<String> actors;
  List<int> genreIds;

  LocalMovie({
    String? id,
    this.tmdbId = 0,
    required this.title,
    this.posterPath,
    required this.status,
    this.notes = '',
    DateTime? addedDate,
    this.tmdbRating = 0,
    List<String>? actors,
    List<int>? genreIds,
  })  : id = id ?? const Uuid().v4(),
        addedDate = addedDate ?? DateTime.now(),
        actors = actors ?? [],
        genreIds = genreIds ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'tmdbId': tmdbId,
        'title': title,
        'posterPath': posterPath,
        'status': status,
        'notes': notes,
        'addedDate': addedDate.toIso8601String(),
        'tmdbRating': tmdbRating,
        'actors': actors,
        'genreIds': genreIds,
      };

  factory LocalMovie.fromJson(Map<String, dynamic> json) => LocalMovie(
        id: json['id'] ?? const Uuid().v4(),
        tmdbId: (json['tmdbId'] ?? 0).toInt(),
        title: json['title'] ?? '',
        posterPath: json['posterPath'],
        status: json['status'] ?? '',
        notes: json['notes'] ?? '',
        addedDate: DateTime.tryParse(json['addedDate'] ?? ''),
        tmdbRating: (json['tmdbRating'] ?? 0).toDouble(),
        actors: List<String>.from(json['actors'] ?? []),
        genreIds: List<int>.from(json['genreIds'] ?? []),
      );
}
