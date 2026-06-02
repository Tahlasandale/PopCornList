import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (ApiConfig.tmdbApiKey.isEmpty) {
    throw FlutterError(
      'API TMDB non configurée. Voir .env.example.\n'
      'Build : flutter build apk --dart-define=TMDB_API_KEY=xxx',
    );
  }
  if (ApiConfig.mistralApiKey.isEmpty) {
    debugPrint('⚠️  Clé Mistral non configurée — recommendations IA désactivées.');
  }

  await Hive.initFlutter();
  await Hive.openBox('movies');
  runApp(const PopCornList());
}
