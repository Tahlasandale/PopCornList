# 🍿 PopCornList

Application mobile de gestion de listes de films et séries, connectée à l'API TMDB et boostée à l'IA avec Mistral.

## Fonctionnalités

- **Recherche de films et séries** via l'API TMDB (titre, tri par note/nom/durée/date).
- **Deux listes** : "À regarder" et "Vus" (stockage local Hive).
- **Fiche détail complète** : synopsis, note, année, acteurs, durée, genres.
- **Notes personnelles** par média.
- **✨ Aide-moi à choisir (IA)** : Recommandations personnalisées basées sur votre liste, votre humeur et vos envies via Mistral AI.
- **Filtre avancé** : Filtrage par acteur et par genre (intersection).
- **Tri multi-critères** : Tri par nom, note, durée, date de sortie, ou date d'ajout.
- **Import/Export CSV** des listes.
- **Thème sombre Material 3** respectant l'identité visuelle "salle obscure".
- **Fonctionnement hors-ligne** pour les listes sauvegardées.

## Stack technique

- **Framework** : Flutter 3.12+ / Dart 3.12+
- **API** : TMDB (The Movie Database) & Mistral AI
- **Base de données** : Hive (locale, sur l'appareil)
- **HTTP** : Dio

## Prérequis

- Flutter SDK ≥ 3.12
- Clé API TMDB
- Clé API Mistral AI

## Configuration

L'application utilise des variables d'environnement pour sécuriser les clés API.

1. Créez un fichier `.env` à la racine du projet à partir de `.env.example`.
2. Obtenez vos clés API :
   - [TMDB API Key](https://www.themoviedb.org)
   - [Mistral AI API Key](https://console.mistral.ai/)
3. Remplissez le fichier `.env` :
   ```env
   TMDB_API_KEY=votre_cle_tmdb
   MISTRAL_API_KEY=votre_cle_mistral
   ```

## Build & Lancement

Pour lancer l'application avec les clés API :

```bash
flutter run --dart-define-from-file=.env
```

Pour générer un APK de release :

```bash
./scripts/build-release.sh
```

## Structure du projet

```
lib/
├── config/          # Configuration API, thème
├── models/          # StoredMedia (Modèle unifié), TmdbMovie, TmdbSerie
├── services/        # TMDB, Mistral AI, Database (Hive), CSV, FilmFilter
├── screens/         # Home, Search, Detail, Listes, AI Recommendation, Settings
└── widgets/         # MovieCard, MovieGrid, SortBar, ActorFilter, GenreFilter
```

## CSV — Structure d'export/import

```
tmdbId,title,posterPath,status,notes,addedDate,tmdbRating,actors,genreIds
```

Les acteurs et les IDs de genres sont séparés par `|`. Les doublons sont gérés intelligemment à l'import.
