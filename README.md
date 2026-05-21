# 🍿 PopCornList

Application Android de gestion de listes de films, connectée à l'API TMDB.

## Fonctionnalités

- **Recherche de films** via l'API TMDB (titre, tri par note/nom/durée/date)
- **Deux listes** : "À regarder" et "Vus" (stockage local Hive)
- **Fiche détail** : synopsis, note, année, acteurs, durée
- **Notes personnelles** par film
- **Filtre acteur** par cases à cocher (recherche + sélection multiple)
- **Tri** sur tous les écrans (nom, note, durée, date, date d'ajout)
- **Import/Export CSV** des listes
- **Thème sombre Material 3**
- **Fonctionnement hors-ligne** pour les listes sauvegardées

## Stack technique

- **Framework** : Flutter 3.44+ / Dart 3.12+
- **API** : TMDB (The Movie Database)
- **Base de données** : Hive (locale, sur l'appareil)
- **HTTP** : Dio

## Prérequis

- Flutter SDK ≥ 3.44
- JDK 21
- Android SDK 36+
- Clé API TMDB

## Configuration

1. Obtenez une clé API sur [themoviedb.org](https://www.themoviedb.org)
2. Modifiez `lib/config/api_config.dart` :
   ```dart
   static const String tmdbApiKey = 'VOTRE_CLE';
   ```

## Build

```bash
flutter pub get
flutter build apk --debug
```

L'APK se trouve dans `build/app/outputs/flutter-apk/app-debug.apk`.

## Structure du projet

```
lib/
├── config/          # Configuration API, thème
├── models/          # TmdbMovie, LocalMovie
├── services/        # TMDB (Dio), Hive, CSV, FilmFilter
├── screens/         # Recherche, Détail, Listes, Paramètres
└── widgets/         # MovieCard, SortBar, ActorFilter, EmptyState
```

## CSV — Structure d'export/import

```
tmdbId,title,posterPath,status,notes,addedDate,tmdbRating,actors
```

Les acteurs sont séparés par `|`. Les doublons (tmdbId existant) sont ignorés à l'import.
