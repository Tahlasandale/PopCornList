import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/theme_notifier.dart';
import '../models/stored_media.dart';
import '../services/database_service.dart';
import '../services/csv_service.dart';
import '../services/tmdb_service.dart';
import '../services/movie_resolver.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _toWatchCount = 0;
  int _watchedCount = 0;
  List<StoredMedia> _unresolvedMovies = [];
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isResolving = false;
  int _resolveProgress = 0;
  int _resolveTotal = 0;
  String _resolveTitle = '';

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  void _refreshStats() {
    final unresolved = DatabaseService.getUnresolved();
    setState(() {
      _toWatchCount = DatabaseService.getByStatus('to_watch').length;
      _watchedCount = DatabaseService.getByStatus('watched').length;
      _unresolvedMovies = unresolved;
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
      
      final List<int> bytes;
      if (kIsWeb) {
        bytes = file.bytes!;
      } else {
        bytes = await io.File(file.path!).readAsBytes();
      }

      String content;
      try {
        content = utf8.decode(bytes);
      } catch (_) {
        content = latin1.decode(bytes);
      }
      if (content.isNotEmpty && content.codeUnitAt(0) == 0xFEFF) {
        content = content.substring(1);
      }
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

      if (result.unresolved > 0) {
        await _resolveAll();
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

  Future<void> _resolveAll() async {
    setState(() {
      _isResolving = true;
      _resolveProgress = 0;
    });

    final resolver = MovieResolverService(TmdbService());
    final resolved = await resolver.resolveAll(
      onProgress: (done, total, title) {
        if (mounted) {
          setState(() {
            _resolveProgress = done;
            _resolveTotal = total;
            _resolveTitle = title;
          });
        }
      },
    );

    _refreshStats();

    if (mounted) {
      setState(() => _isResolving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resolved > 0
                ? '✅ $resolved film(s) synchronisé(s) avec TMDB'
                : 'Aucun film trouvé sur TMDB',
          ),
        ),
      );
    }
  }

  Future<void> _dismissUnresolved(StoredMedia movie) async {
    await DatabaseService.removeById(movie.id);
    _refreshStats();
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
                  const Icon(Icons.movie, size: 48, color: popcorn),
                  const SizedBox(height: 8),
                  Text(
                    'PopCornList',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  const Text('v2.0.0', style: TextStyle(color: ticket, fontSize: 13)),
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
                  _StatColumn(label: 'À regarder', count: _toWatchCount, icon: Icons.bookmark_border, color: popcorn),
                  _StatColumn(label: 'Vus', count: _watchedCount, icon: Icons.check_circle_outline, color: siege),
                  _StatColumn(label: 'Total', count: _toWatchCount + _watchedCount, icon: Icons.movie_outlined, color: ticket),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Theme controls
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thème',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ecran),
                  ),
                  const SizedBox(height: 4),
                  ListenableBuilder(
                    listenable: ThemeNotifier.instance,
                    builder: (context, _) {
                      final notifier = ThemeNotifier.instance;
                      return Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              notifier.isDark ? 'Mode sombre' : 'Mode clair',
                              style: const TextStyle(color: ecran, fontSize: 15),
                            ),
                            subtitle: const Text(
                              'Changer l\'apparence de l\'application',
                              style: TextStyle(color: ticket, fontSize: 13),
                            ),
                            value: notifier.isDark,
                            onChanged: (_) => notifier.toggleDark(),
                            activeThumbColor: popcorn,
                          ),
                          const Divider(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                            child: Row(
                              children: [
                                const Text(
                                  'Couleur d\'accent',
                                  style: TextStyle(color: ticket, fontSize: 13),
                                ),
                                const Spacer(),
                                _AccentDot(
                                  color: popcorn,
                                  label: 'Jaune',
                                  isSelected: notifier.accent == AccentColor.popcorn,
                                  onTap: () => notifier.setAccent(AccentColor.popcorn),
                                ),
                                const SizedBox(width: 8),
                                _AccentDot(
                                  color: siege,
                                  label: 'Rouge',
                                  isSelected: notifier.accent == AccentColor.siege,
                                  onTap: () => notifier.setAccent(AccentColor.siege),
                                ),
                                const SizedBox(width: 8),
                                _AccentDot(
                                  color: ocean,
                                  label: 'Bleu',
                                  isSelected: notifier.accent == AccentColor.ocean,
                                  onTap: () => notifier.setAccent(AccentColor.ocean),
                                ),
                                const SizedBox(width: 8),
                                _AccentDot(
                                  color: forest,
                                  label: 'Vert',
                                  isSelected: notifier.accent == AccentColor.forest,
                                  onTap: () => notifier.setAccent(AccentColor.forest),
                                ),
                                const SizedBox(width: 8),
                                _AccentDot(
                                  color: lavender,
                                  label: 'Violet',
                                  isSelected: notifier.accent == AccentColor.lavender,
                                  onTap: () => notifier.setAccent(AccentColor.lavender),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_isResolving) ...[
            const SizedBox(height: 16),
            Card(
              color: projecteur,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Synchronisation avec TMDB... ($_resolveProgress/$_resolveTotal)',
                      style: const TextStyle(fontSize: 13, color: ticket),
                    ),
                    if (_resolveTitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Film en cours : $_resolveTitle',
                        style: const TextStyle(fontSize: 12, color: ticket),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (_unresolvedMovies.isNotEmpty && !_isResolving) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline, size: 18, color: popcorn),
                        const SizedBox(width: 8),
                        Text(
                          '${_unresolvedMovies.length} film(s) non identifié(s)',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: ecran),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Cochez pour retirer de la liste',
                      style: TextStyle(fontSize: 12, color: ticket),
                    ),
                    const Divider(),
                    ..._unresolvedMovies.map((movie) => CheckboxListTile(
                          dense: true,
                          value: false,
                          onChanged: (_) => _dismissUnresolved(movie),
                          title: Text(movie.title, style: const TextStyle(fontSize: 14, color: ecran)),
                          subtitle: Text(
                            movie.status == 'to_watch' ? 'À regarder' : 'Vu',
                            style: TextStyle(fontSize: 12, color: movie.status == 'to_watch' ? popcorn : siege),
                          ),
                          activeColor: siege,
                          controlAffinity: ListTileControlAffinity.trailing,
                        )),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _resolveAll,
                        icon: const Icon(Icons.sync, size: 18),
                        label: const Text('Tout résoudre via TMDB'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isExporting ? null : _exportCsv,
            icon: _isExporting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.upload),
            label: const Text('Exporter en CSV'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
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
  final Color color;

  const _StatColumn({required this.label, required this.count, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text('$count', style: Theme.of(context).textTheme.headlineMedium),
        Text(label, style: const TextStyle(color: ticket, fontSize: 13)),
      ],
    );
  }
}

class _AccentDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccentDot({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 2.5)
                  : Border.all(color: Colors.transparent, width: 1),
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
                  : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: ticket),
          ),
        ],
      ),
    );
  }
}
