import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SearchScreen(),
    ListScreen(status: 'to_watch', title: 'À regarder'),
    ListScreen(status: 'watched', title: 'Vus'),
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
        ],
      ),
    );
  }
}
