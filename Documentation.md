# 📚 Documentation Technique — PopCornList

## 🎬 Présentation
PopCornList est une application Flutter permettant de gérer une collection personnelle de films et séries. L'application se distingue par son intégration de l'IA (Mistral) pour aider l'utilisateur à choisir quoi regarder dans sa propre liste, et par son fonctionnement hybride (données locales via Hive + métadonnées via TMDB).

---

## 🏗️ Architecture Technique

### 💉 Injection de Dépendances & Configuration
Les secrets (clés API) ne sont jamais stockés en dur. Ils sont injectés à la compilation via des variables d'environnement (`--dart-define-from-file=.env`).
- **Fichier clé** : `lib/config/api_config.dart`
- **Variable TMDB** : `TMDB_API_KEY`
- **Variable Mistral** : `MISTRAL_API_KEY`

### 💾 Stockage Local (Hive)
L'application utilise **Hive**, une base de données NoSQL ultra-rapide pour Dart.
- **Box** : `movies`
- **Format** : Les objets sont stockés sous forme de `Map<String, dynamic>` (JSON).
- **Migration** : Un mécanisme de migration automatique (`DatabaseService._migrateIfNeeded`) assure la compatibilité ascendante (ajout du type "série", passage des IDs numériques aux UUIDs).

---

## 🛠️ Services Principaux

### 📡 TMDB Service (`tmdb_service.dart`)
Gère toute la communication avec [The Movie Database](https://www.themoviedb.org/).
- **Optimisation** : Utilise `append_to_response=credits` pour récupérer les détails et le casting en une seule requête.
- **Multi-Support** : Endpoints séparés pour `/movie` et `/tv`.

### 🧠 Mistral Service (`mistral_service.dart`)
Moteur de recommandation intelligent.
- **Logique** : L'IA ne propose pas de nouveaux films, elle analyse la liste locale de l'utilisateur (titres, notes, acteurs) et sélectionne 1 à 3 contenus correspondant à l'humeur et aux critères (durée, genre) saisis.
- **Prompt Engineering** : Utilise un prompt système strict pour garantir une réponse au format JSON pur.
- **Fallback** : En cas d'erreur ou d'absence de clé, un système de recommandation aléatoire prend le relais.

### 📄 CSV Service (`csv_service.dart`)
Gère l'import et l'export des données pour garantir la portabilité.
- **Structure** : `tmdbId,title,posterPath,status,notes,addedDate,tmdbRating,actors,genreIds`
- **Gestion des conflits** : Lors de l'import, les doublons sont détectés par `tmdbId` ou par titre normalisé.

---

## 📊 Modèles de Données

### `StoredMedia`
C'est le modèle pivot de l'application.
- `id` (UUID) : Identifiant unique local.
- `tmdbId` (int) : Identifiant de référence TMDB (0 si manuel).
- `type` (enum) : `movie` ou `series`.
- `status` (String) : `to_watch` ou `watched`.
- `notes` (String) : Notes personnelles de l'utilisateur.
- `actors` & `genreIds` : Stockés localement pour permettre le filtrage/tri hors-ligne.

---

## 🔍 Filtrage et Tri

La logique de filtrage est centralisée dans `lib/services/film_filter.dart`.
- **Tri Multi-critères** : Permet de combiner plusieurs critères (ex: Trier par note DESC, puis par date d'ajout DESC).
- **Intersection de Genres** : Le filtre par genre fonctionne en mode "ET" (le média doit posséder TOUS les genres sélectionnés).

---

## 🛠️ Pipeline de Compilation

PopCornList dispose d'un pipeline de compilation automatisé pour deux cibles principales : Android (APK) et Web (Docker).

### 📱 Android (APK Release)
Le script `./scripts/build-release.sh` automatise la génération de l'APK de production.
- **Processus** : Charge les clés depuis `.env`, injecte les variables via `--dart-define` et lance `flutter build apk`.
- **Résultat** : `build/app/outputs/flutter-apk/app-release.apk`.
- **Usage** :
  ```bash
  chmod +x scripts/build-release.sh
  ./scripts/build-release.sh
  ```

### 🐳 Docker (Web)
Le script `./scripts/build-docker.sh` permet de créer une image Docker prête à l'emploi.
- **Architecture** : Utilise un build multi-étapes (Flutter SDK pour la compilation, Nginx Alpine pour la distribution).
- **Persistence** : Utilise IndexedDB dans le navigateur de l'utilisateur (via Hive). Aucune configuration de base de données externe n'est requise.
- **Usage** :
  ```bash
  chmod +x scripts/build-docker.sh
  ./scripts/build-docker.sh
  ```
- **Lancement du conteneur** :
  ```bash
  docker run -d -p 8080:80 popcornlist:web
  ```
  L'application est alors accessible sur `http://localhost:8080`.

---

## 🚀 CI/CD (GitHub Actions)

Voici un exemple de configuration pour un pipeline automatisé sur GitHub Actions (`.github/workflows/main.yml`) :

```yaml
name: Build PopCornList
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
      - run: flutter pub get
      - run: flutter build apk --release --dart-define=TMDB_API_KEY=${{ secrets.TMDB_KEY }}
```
