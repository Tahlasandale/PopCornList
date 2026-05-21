import 'package:flutter/material.dart';
import '../config/theme.dart';

class ActorFilterSheet extends StatefulWidget {
  final List<String> allActors;
  final List<String> selectedActors;

  const ActorFilterSheet({
    super.key,
    required this.allActors,
    required this.selectedActors,
  });

  @override
  State<ActorFilterSheet> createState() => _ActorFilterSheetState();
}

class _ActorFilterSheetState extends State<ActorFilterSheet> {
  late List<String> _selected;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedActors);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredActors {
    if (_searchQuery.isEmpty) return widget.allActors;
    final q = _searchQuery.toLowerCase();
    return widget.allActors.where((a) => a.toLowerCase().contains(q)).toList();
  }

  void _toggleActor(String actor) {
    setState(() {
      if (_selected.contains(actor)) {
        _selected.remove(actor);
      } else {
        _selected.add(actor);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uniqueActors = _filteredActors.toSet().toList()..sort();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: ticket,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Filtrer par acteur',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Chercher un acteur...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: uniqueActors.isEmpty
                    ? Center(
                        child: Text('Aucun acteur trouvé', style: TextStyle(color: ticket)),
                      )
                    : ListView(
                        controller: scrollController,
                        children: uniqueActors
                            .map((actor) => CheckboxListTile(
                                  title: Text(actor),
                                  value: _selected.contains(actor),
                                  onChanged: (_) => _toggleActor(actor),
                                  dense: true,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  activeColor: popcorn,
                                  checkColor: onyx,
                                ))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() => _selected.clear());
                    },
                    child: const Text('Tout effacer'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    child: Text('Filtrer (${_selected.length})'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
