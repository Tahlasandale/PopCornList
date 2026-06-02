import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/local_movie.dart';
import 'database_service.dart';

class ImportResult {
  final int imported;
  final int skipped;
  final int errors;
  final int unresolved;

  const ImportResult({
    required this.imported,
    required this.skipped,
    required this.errors,
    this.unresolved = 0,
  });
}

class CsvService {
  /// Normalise un titre pour la comparaison : lowercase, accents → ascii,
  /// suppression ponctuation, normalisation espaces.
  static String _normalizeTitle(String title) {
    const accents = {
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'à': 'a', 'â': 'a', 'ä': 'a',
      'î': 'i', 'ï': 'i',
      'ô': 'o', 'ö': 'o',
      'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c',
    };
    var result = title.toLowerCase();
    for (final e in accents.entries) {
      result = result.replaceAll(e.key, e.value);
    }
    return result
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _encodeList(List<String> items) => items.join('|');

  static List<String> _decodeList(String raw) {
    if (raw.trim().isEmpty) return [];
    return raw.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String _buildCsvRow(LocalMovie m) {
    return [
      m.tmdbId,
      _escapeCsv(m.title),
      m.posterPath ?? '',
      m.status,
      _escapeCsv(m.notes),
      m.addedDate.toIso8601String(),
      m.tmdbRating.toStringAsFixed(1),
      _encodeList(m.actors),
    ].join(',');
  }

  static String exportAll() {
    final buffer = StringBuffer();
    buffer.writeln('tmdbId,title,posterPath,status,notes,addedDate,tmdbRating,actors');

    final all = DatabaseService.getAll();
    for (final m in all) {
      buffer.writeln(_buildCsvRow(m));
    }
    return buffer.toString();
  }

  static Future<ImportResult> importCsv(String content) async {
    int imported = 0;
    int skipped = 0;
    int errors = 0;
    int unresolved = 0;

    // Lookup des titres normalisés existants (fallback dedup quand tmdbId == 0)
    // Mis à jour pendant l'import pour éviter les doublons intra-CSV.
    final existingTitles =
        DatabaseService.getAll().map((m) => _normalizeTitle(m.title)).toSet();

    final decoder = CsvDecoder();
    final rows = decoder.convert(content);

    for (int i = 0; i < rows.length; i++) {
      if (i == 0) continue;
      final row = rows[i];
      if (row.length < 8) {
        errors++;
        continue;
      }
      try {
        final tmdbId = row[0] is int ? row[0] as int : int.tryParse(row[0].toString());
        final title = row[1].toString().trim();
        if (title.isEmpty) {
          errors++;
          continue;
        }

        // Vérification par TMDB ID (primaire)
        if (tmdbId != null && tmdbId > 0 && DatabaseService.exists(tmdbId)) {
          skipped++;
          continue;
        }

        // Fallback : vérification par titre normalisé (quand pas de TMDB ID)
        if (tmdbId == null || tmdbId <= 0) {
          final normalized = _normalizeTitle(title);
          if (existingTitles.contains(normalized)) {
            skipped++;
            continue;
          }
        }

        final resolvedTmdbId = (tmdbId != null && tmdbId > 0) ? tmdbId : 0;
        if (resolvedTmdbId == 0) unresolved++;

        await DatabaseService.addMovie(LocalMovie(
          tmdbId: resolvedTmdbId,
          title: title,
          posterPath: row[2].toString().isNotEmpty ? row[2].toString() : null,
          status: row[3].toString(),
          notes: row[4].toString(),
          addedDate: DateTime.tryParse(row[5].toString()) ?? DateTime.now(),
          tmdbRating: double.tryParse(row[6].toString()) ?? 0,
          actors: _decodeList(row[7].toString()),
        ));
        existingTitles.add(_normalizeTitle(title));
        imported++;
      } catch (_) {
        errors++;
      }
    }

    return ImportResult(imported: imported, skipped: skipped, errors: errors, unresolved: unresolved);
  }

  static Future<PlatformFile?> pickCsvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.single;
  }

  static Future<void> shareCsv(String csvContent) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/PopCornList_export.csv');
    await file.writeAsString(csvContent);
    await Share.shareXFiles([XFile(file.path)], text: 'PopCornList - Mes listes de films');
  }
}
