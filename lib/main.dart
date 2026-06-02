import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  assert(
    ApiConfig.tmdbApiKey.isNotEmpty,
    'API TMDB non configurée. Lancer avec :\n'
    '  flutter run --dart-define-from-file=.env\n'
    'Voir .env.example pour la configuration.',
  );

  await Hive.initFlutter();
  await Hive.openBox('movies');
  runApp(const PopCornList());
}
