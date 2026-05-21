import 'package:hive/hive.dart';
import '../models/local_movie.dart';

class DatabaseService {
  static Box get _box => Hive.box('movies');

  static Future<void> addMovie(LocalMovie movie) async {
    await _box.put(movie.tmdbId.toString(), movie.toJson());
  }

  static Future<void> removeMovie(int tmdbId) async {
    await _box.delete(tmdbId.toString());
  }

  static List<LocalMovie> getByStatus(String status) {
    return _box.values
        .map((e) => LocalMovie.fromJson(Map<String, dynamic>.from(e)))
        .where((m) => m.status == status)
        .toList()
      ..sort((a, b) => b.addedDate.compareTo(a.addedDate));
  }

  static LocalMovie? get(int tmdbId) {
    final data = _box.get(tmdbId.toString());
    if (data == null) return null;
    return LocalMovie.fromJson(Map<String, dynamic>.from(data));
  }

  static List<LocalMovie> getAll() {
    return _box.values
        .map((e) => LocalMovie.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static bool exists(int tmdbId) {
    return _box.containsKey(tmdbId.toString());
  }

  static Future<void> updateNotes(int tmdbId, String notes) async {
    final movie = get(tmdbId);
    if (movie != null) {
      movie.notes = notes;
      await _box.put(tmdbId.toString(), movie.toJson());
    }
  }

  static Future<void> updateStatus(int tmdbId, String status) async {
    final movie = get(tmdbId);
    if (movie != null) {
      movie.status = status;
      await _box.put(tmdbId.toString(), movie.toJson());
    }
  }
}
