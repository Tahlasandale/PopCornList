import 'package:flutter/material.dart';
import 'config/theme_notifier.dart';
import 'screens/home_screen.dart';

class PopCornList extends StatefulWidget {
  const PopCornList({super.key});

  @override
  State<PopCornList> createState() => _PopCornListState();
}

class _PopCornListState extends State<PopCornList> {
  @override
  void initState() {
    super.initState();
    ThemeNotifier.instance.addListener(_onThemeChange);
  }

  void _onThemeChange() => setState(() {});

  @override
  void dispose() {
    ThemeNotifier.instance.removeListener(_onThemeChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PopCornList',
      theme: ThemeNotifier.instance.value,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
