import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'list_screen.dart';
import 'settings_screen.dart';
import 'serie_screen.dart';
import '../models/stored_media.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    SearchScreen(),
    ListScreen(key: ValueKey('to_watch'), status: 'to_watch', title: 'À regarder', mediaType: MediaType.movie),
    ListScreen(key: ValueKey('watched'), status: 'watched', title: 'Vus', mediaType: MediaType.movie),
    SettingsScreen(),
    SerieScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Recherche'),
          NavigationDestination(icon: Icon(Icons.bookmark_border), label: 'À regarder'),
          NavigationDestination(icon: Icon(Icons.check_circle_outline), label: 'Vus'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Paramètres'),
          NavigationDestination(icon: Icon(Icons.live_tv), label: 'Séries'),
        ],
      ),
    );
  }
}
