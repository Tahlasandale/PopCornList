import 'package:uuid/uuid.dart';

/// Type de média : film ou série TV.
enum MediaType { movie, series }

/// Représente un média (film ou série) stocké dans la base locale (Hive/CSV).
///
/// Compatibilité ascendante : les anciens enregistrements sans champ `type`
/// sont considérés comme [MediaType.movie] par défaut.
class StoredMedia {
  String id;
  int tmdbId;
  final String title;
  MediaType type;
  String? posterPath;
  String status;
  String notes;
  final DateTime addedDate;
  double tmdbRating;
  List<String> actors;
  List<int> genreIds;

  StoredMedia({
    String? id,
    this.tmdbId = 0,
    required this.title,
    this.type = MediaType.movie,
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
        'type': type.name,
        'posterPath': posterPath,
        'status': status,
        'notes': notes,
        'addedDate': addedDate.toIso8601String(),
        'tmdbRating': tmdbRating,
        'actors': actors,
        'genreIds': genreIds,
      };

  factory StoredMedia.fromJson(Map<String, dynamic> json) {
    // Compatibilité ascendante : si 'type' est absent, c'est un film
    final rawType = json['type'] as String?;
    return StoredMedia(
      id: json['id'] ?? const Uuid().v4(),
      tmdbId: (json['tmdbId'] ?? 0).toInt(),
      title: json['title'] ?? '',
      type: rawType != null
          ? MediaType.values.firstWhere((e) => e.name == rawType,
              orElse: () => MediaType.movie)
          : MediaType.movie,
      posterPath: json['posterPath'],
      status: json['status'] ?? '',
      notes: json['notes'] ?? '',
      addedDate: DateTime.tryParse(json['addedDate'] ?? ''),
      tmdbRating: (json['tmdbRating'] ?? 0).toDouble(),
      actors: List<String>.from(json['actors'] ?? []),
      genreIds: List<int>.from(json['genreIds'] ?? []),
    );
  }
}
