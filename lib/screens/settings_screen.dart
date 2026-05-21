import 'dart:io';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/csv_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _toWatchCount = 0;
  int _watchedCount = 0;
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  void _refreshStats() {
    setState(() {
      _toWatchCount = DatabaseService.getByStatus('to_watch').length;
      _watchedCount = DatabaseService.getByStatus('watched').length;
    });
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      final csv = CsvService.exportAll();
      await CsvService.shareCsv(csv);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur export: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importCsv() async {
    setState(() => _isImporting = true);
    try {
      final file = await CsvService.pickCsvFile();
      if (file == null) {
        if (mounted) setState(() => _isImporting = false);
        return;
      }
      final bytes = file.bytes ?? File(file.path!).readAsBytesSync();
      final content = String.fromCharCodes(bytes);
      final result = await CsvService.importCsv(content);
      _refreshStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${result.imported} importé(s)'
              '${result.skipped > 0 ? ', ${result.skipped} ignoré(s)' : ''}'
              '${result.errors > 0 ? ', ${result.errors} erreur(s)' : ''}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur import: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'PopCornList',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v1.0.0',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatColumn(label: 'À regarder', count: _toWatchCount, icon: Icons.bookmark_border),
                  _StatColumn(label: 'Vus', count: _watchedCount, icon: Icons.check_circle_outline),
                  _StatColumn(label: 'Total', count: _toWatchCount + _watchedCount, icon: Icons.movie_outlined),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isExporting ? null : _exportCsv,
            icon: _isExporting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.upload),
            label: const Text('Exporter en CSV'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _isImporting ? null : _importCsv,
            icon: _isImporting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download),
            label: const Text('Importer depuis CSV'),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;

  const _StatColumn({required this.label, required this.count, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[400], size: 28),
        const SizedBox(height: 8),
        Text('$count', style: Theme.of(context).textTheme.headlineMedium),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ],
    );
  }
}
