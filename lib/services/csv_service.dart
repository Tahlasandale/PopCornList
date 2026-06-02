import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/stored_media.dart';
import 'database_service.dart';

// Import conditionnel pour le web (pour le téléchargement de fichier)
import 'dart:convert';
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

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
  /// Normalise un titre pour la comparaison.
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

  static String _encodeIntList(List<int> items) => items.join('|');

  static List<int> _decodeIntList(String raw) {
    if (raw.trim().isEmpty) return [];
    return raw
        .split('|')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList();
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String _buildCsvRow(StoredMedia m) {
    return [
      m.type.name,
      m.tmdbId,
      _escapeCsv(m.title),
      m.posterPath ?? '',
      m.status,
      _escapeCsv(m.notes),
      m.addedDate.toIso8601String(),
      m.tmdbRating.toStringAsFixed(1),
      _encodeList(m.actors),
      _encodeIntList(m.genreIds),
    ].join(',');
  }

  static String exportAll() {
    final buffer = StringBuffer();
    buffer.writeln('type,tmdbId,title,posterPath,status,notes,addedDate,tmdbRating,actors,genreIds');

    final all = DatabaseService.getAll();
    for (final m in all) {
      buffer.writeln(_buildCsvRow(m));
    }
    return buffer.toString();
  }

  static MediaType _parseMediaType(dynamic raw) {
    final str = raw.toString().trim().toLowerCase();
    if (str == 'series') return MediaType.series;
    return MediaType.movie;
  }

  static Future<ImportResult> importCsv(String content) async {
    int imported = 0;
    int skipped = 0;
    int errors = 0;
    int unresolved = 0;

    final existingTitles =
        DatabaseService.getAll().map((m) => _normalizeTitle(m.title)).toSet();

    final decoder = CsvDecoder();
    final rows = decoder.convert(content);

    if (rows.isEmpty) {
      return const ImportResult(imported: 0, skipped: 0, errors: 0);
    }

    final headerRaw = rows[0].isNotEmpty ? rows[0][0].toString().trim().toLowerCase() : '';
    final isNewFormat = headerRaw == 'type';
    final int c = isNewFormat ? 1 : 0;

    for (int i = 0; i < rows.length; i++) {
      if (i == 0) continue;
      final row = rows[i];
      final minCols = isNewFormat ? 9 : 8;
      if (row.length < minCols) {
        errors++;
        continue;
      }
      try {
        final mediaType = isNewFormat ? _parseMediaType(row[0]) : MediaType.movie;
        final tmdbIdRaw = row[0 + c];
        final tmdbId = tmdbIdRaw is int ? tmdbIdRaw : int.tryParse(tmdbIdRaw.toString());
        final title = row[1 + c].toString().trim();
        if (title.isEmpty) {
          errors++;
          continue;
        }

        if (tmdbId != null && tmdbId > 0 && DatabaseService.exists(tmdbId)) {
          skipped++;
          continue;
        }

        if (tmdbId == null || tmdbId <= 0) {
          final normalized = _normalizeTitle(title);
          if (existingTitles.contains(normalized)) {
            skipped++;
            continue;
          }
        }

        final resolvedTmdbId = (tmdbId != null && tmdbId > 0) ? tmdbId : 0;
        if (resolvedTmdbId == 0) unresolved++;

        List<int> genreIds;
        final genreCol = 8 + c;
        if (row.length > genreCol) {
          genreIds = _decodeIntList(row[genreCol].toString());
        } else {
          genreIds = [];
        }

        await DatabaseService.addMedia(StoredMedia(
          type: mediaType,
          tmdbId: resolvedTmdbId,
          title: title,
          posterPath: row[2 + c].toString().isNotEmpty ? row[2 + c].toString() : null,
          status: row[3 + c].toString(),
          notes: row[4 + c].toString(),
          addedDate: DateTime.tryParse(row[5 + c].toString()) ?? DateTime.now(),
          tmdbRating: double.tryParse(row[6 + c].toString()) ?? 0,
          actors: _decodeList(row[7 + c].toString()),
          genreIds: genreIds,
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
      withData: kIsWeb, // Important pour le web
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.single;
  }

  static Future<void> shareCsv(String csvContent) async {
    if (kIsWeb) {
      // Sur Web, on télécharge le fichier directement
      final bytes = utf8.encode(csvContent);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "PopCornList_export.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Sur Mobile/Desktop, on utilise le partage natif
      final dir = await getTemporaryDirectory();
      final file = io.File('${dir.path}/PopCornList_export.csv');
      await file.writeAsString(csvContent);
      await Share.shareXFiles([XFile(file.path)], text: 'PopCornList - Mes listes de films');
    }
  }
}
