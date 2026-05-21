import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/home_screen.dart';

class PopCornList extends StatelessWidget {
  const PopCornList({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PopCornList',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
