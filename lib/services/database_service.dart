import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/local_movie.dart';

class DatabaseService {
  static Box get _box => Hive.box('movies');

  static Future<void> _migrateIfNeeded() async {
    final keysToMigrate = <String>[];
    for (final key in _box.keys) {
      if (key is String && (int.tryParse(key) != null || key.isEmpty)) {
        keysToMigrate.add(key);
      }
    }
    for (final oldKey in keysToMigrate) {
      final data = Map<String, dynamic>.from(_box.get(oldKey));
      if (data['id'] == null) {
        data['id'] = const Uuid().v4();
      }
      final newKey = data['id'] as String;
      await _box.put(newKey, data);
      await _box.delete(oldKey);
    }
  }

  static Future<void> addMovie(LocalMovie movie) async {
    await _box.put(movie.id, movie.toJson());
  }

  static Future<void> removeMovie(int tmdbId) async {
    final movie = get(tmdbId);
    if (movie != null) {
      await _box.delete(movie.id);
    }
  }

  static Future<void> removeById(String id) async {
    await _box.delete(id);
  }

  static List<LocalMovie> getByStatus(String status) {
    return getAll()
        .where((m) => m.status == status)
        .toList()
      ..sort((a, b) => b.addedDate.compareTo(a.addedDate));
  }

  static LocalMovie? get(int tmdbId) {
    for (final entry in _box.values) {
      final data = Map<String, dynamic>.from(entry);
      if (data['tmdbId'] == tmdbId) {
        return LocalMovie.fromJson(data);
      }
    }
    return null;
  }

  static List<LocalMovie> getAll() {
    _migrateIfNeeded();
    return _box.values
        .map((e) => LocalMovie.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static bool exists(int tmdbId) {
    return _box.values.any((e) {
      final data = Map<String, dynamic>.from(e);
      return data['tmdbId'] == tmdbId;
    });
  }

  static Future<void> updateNotes(int tmdbId, String notes) async {
    final movie = get(tmdbId);
    if (movie != null) {
      movie.notes = notes;
      await _box.put(movie.id, movie.toJson());
    }
  }

  static Future<void> updateStatus(int tmdbId, String status) async {
    final movie = get(tmdbId);
    if (movie != null) {
      movie.status = status;
      await _box.put(movie.id, movie.toJson());
    }
  }

  static Future<void> updateMovie(LocalMovie movie) async {
    await _box.put(movie.id, movie.toJson());
  }

  static List<LocalMovie> getUnresolved() {
    return getAll().where((m) => m.tmdbId == 0).toList();
  }

  static int countUnresolved() {
    return getUnresolved().length;
  }
}
