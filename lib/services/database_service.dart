import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/stored_media.dart';

class DatabaseService {
  static Box get _box => Hive.box('movies');

  /// Migre les anciens enregistrements qui n'ont pas de champ [type].
  /// Compatibilité ascendante : ajoute [type = 'movie'] aux anciennes données.
  static Future<void> _migrateIfNeeded() async {
    bool needsMigrate = false;
    for (final key in _box.keys) {
      if (key is String && (int.tryParse(key) != null || key.isEmpty)) {
        needsMigrate = true;
        break;
      }
    }

    if (!needsMigrate) {
      // Vérifier aussi si des enregistrements existent sans champ 'type'
      for (final entry in _box.values) {
        final data = Map<String, dynamic>.from(entry);
        if (data['type'] == null) {
          needsMigrate = true;
          break;
        }
      }
    }

    if (!needsMigrate) return;

    // Phase 1 : migrer les clés numériques/vides vers des UUID
    final keysToMigrate = <String>[];
    for (final key in _box.keys) {
      if (key is String && (int.tryParse(key) != null || key.isEmpty)) {
        keysToMigrate.add(key);
      }
    }
    for (final oldKey in keysToMigrate) {
      final data = Map<String, dynamic>.from(_box.get(oldKey));
      if (data['id'] == null) data['id'] = const Uuid().v4();
      // Ancienne donnée → typée comme film
      data['type'] = data['type'] ?? 'movie';
      final newKey = data['id'] as String;
      await _box.put(newKey, data);
      await _box.delete(oldKey);
    }

    // Phase 2 : ajouter 'type' aux enregistrements qui en sont dépourvus
    for (final key in _box.keys) {
      if (key is! String) continue;
      final data = Map<String, dynamic>.from(_box.get(key));
      if (data['type'] == null) {
        data['type'] = 'movie';
        await _box.put(key, data);
      }
    }
  }

  /// Ajoute un média (film ou série) à la base.
  static Future<void> addMedia(StoredMedia media) async {
    await _box.put(media.id, media.toJson());
  }

  static Future<void> removeMedia(int tmdbId, {MediaType? type}) async {
    final media = get(tmdbId, type: type);
    if (media != null) {
      await _box.delete(media.id);
    }
  }

  static Future<void> removeById(String id) async {
    await _box.delete(id);
  }

  /// Retourne les médias filtrés par statut ET (optionnellement) par type.
  static List<StoredMedia> getByStatus(String status, {MediaType? type}) {
    return getAll(type: type)
        .where((m) => m.status == status)
        .toList()
      ..sort((a, b) => b.addedDate.compareTo(a.addedDate));
  }

  /// Récupère un média par son TMDB ID, optionnellement filtré par type.
  static StoredMedia? get(int tmdbId, {MediaType? type}) {
    for (final entry in _box.values) {
      final data = Map<String, dynamic>.from(entry);
      if (data['tmdbId'] == tmdbId) {
        final media = StoredMedia.fromJson(data);
        if (type == null || media.type == type) return media;
      }
    }
    return null;
  }

  /// Retourne tous les médias, optionnellement filtrés par type.
  static List<StoredMedia> getAll({MediaType? type}) {
    _migrateIfNeeded();
    var result = _box.values
        .map((e) => StoredMedia.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    if (type != null) {
      result = result.where((m) => m.type == type).toList();
    }
    return result;
  }

  static bool exists(int tmdbId) {
    return _box.values.any((e) {
      final data = Map<String, dynamic>.from(e);
      return data['tmdbId'] == tmdbId;
    });
  }

  static Future<void> updateNotes(int tmdbId, String notes) async {
    final media = get(tmdbId);
    if (media != null) {
      media.notes = notes;
      await _box.put(media.id, media.toJson());
    }
  }

  static Future<void> updateStatus(int tmdbId, String status) async {
    final media = get(tmdbId);
    if (media != null) {
      media.status = status;
      await _box.put(media.id, media.toJson());
    }
  }

  static Future<void> updateMedia(StoredMedia media) async {
    await _box.put(media.id, media.toJson());
  }

  /// Retourne les médias non résolus (sans TMDB ID), filtrés par type.
  static List<StoredMedia> getUnresolved({MediaType? type}) {
    return getAll(type: type).where((m) => m.tmdbId == 0).toList();
  }

  static int countUnresolved() {
    return getUnresolved().length;
  }

  // ── Aliases de compatibilité ascendante ──────────────────────────────
  // Les méthodes ci-dessous ne sont utilisées par aucun code actif,
  // mais sont conservées pour ne pas casser d'éventuels appels externes.
  @Deprecated('Use addMedia instead')
  static Future<void> addMovie(StoredMedia media) => addMedia(media);

  @Deprecated('Use removeMedia instead')
  static Future<void> removeMovie(int tmdbId) => removeMedia(tmdbId);

  @Deprecated('Use updateMedia instead')
  static Future<void> updateMovie(StoredMedia media) => updateMedia(media);
}
