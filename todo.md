# Todo

## 🔴 P0 — Bug
- [ ] **Doublons/suppressions** : `DatabaseService.get(tmdbId)` ne break pas au premier match → retourne le dernier doublon. `CsvService.importCsv()` n'a pas de détection par titre pour les films avec `tmdbId=0` → imports multiples créent des doublons silencieux.
- [ ] **Release APK Android buggée** : les versions release sur GitHub plantent à l'installation sur Android. Vérifier le signing, le target SDK, le versionCode, la compatibilité Android 14+.

## 🟡 P1 — Sécurité & Configuration
- [ ] **Externaliser les clés API** : la clé TMDB (`lib/config/api_config.dart`) est actuellement en dur dans le code. Utiliser `flutter_dotenv` ou un fichier `.env` pour ne pas exposer les secrets sur GitHub.
- [ ] **Sécuriser la clé Mistral AI** : la clé de l'API Mistral utilisée par le moteur de recommandation (P7) ne doit pas être en clair dans le code. Idem, passer par `.env` / `flutter_dotenv` ou une config chargée au runtime.

## 🟡 P2 — Landing page responsive (site vitrine)
- [ ] **Rendre `index.html` responsive mobile** : le site de présentation du projet (landing page) doit s'adapter aux écrans mobiles (meta viewport, media queries, flex layout au lieu de fixed widths).

## 🟡 P3 — Tri multi-critères
- [ ] Permettre le tri selon plusieurs critères (ex: note + titre) dans `FilmFilter.apply()`, `SortBy`, `SortBar`

## 🟡 P4 — Filtre genres (intersection)
- [ ] Persister les `genreIds` TMDB dans `LocalMovie` (actuellement jetés dans `list_screen.dart`)
- [ ] Créer un `GenreFilterSheet` (pattern `ActorFilterSheet` mais logique AND)
- [ ] Si 2 genres sélectionnés → intersection des 2

## 🟡 P5 — Prise en charge des séries TV
- [ ] **Modèle `LocalSerie`** : créer un modèle Hive pour les séries avec les champs spécifiques TMDB :
  - `tmdbId`, `name` (au lieu de `title`), `overview`, `posterPath`, `voteAverage`
  - `numberOfSeasons`, `numberOfEpisodes`, `firstAirDate`, `lastAirDate`
  - `status` (Ended / Returning / Canceled), `inProduction`
  - `genres`, `createdBy`, `networks`, `originCountry`
  - `personalRating`, `personalNote`, `listType` (À regarder / Vus), `dateAdded`
- [ ] **Service TMDB pour séries** :
  - `TvService` : endpoints `/tv/{id}`, `/search/tv`, `/trending/tv/week`, `/discover/tv`
  - Structure spécifique : gestion des saisons (`/tv/{id}/season/{num}`) et épisodes
- [ ] **UI liste séries dédiée** :
  - Onglet "Séries" dans `HomeScreen` (à côté de "Films")
  - `SerieCard` : affiche name, première date, nombre de saisons, statut (en cours/terminée)
  - `SerieDetailScreen` : infos complètes + liste des saisons dépliables
  - Marquer une saison comme "vue" (checkbox par saison)
- [ ] **Filtres spécifiques séries** :
  - Par statut (En cours / Terminée / Annulée)
  - Par nombre de saisons min/max
  - Par réseau (Netflix, HBO, etc.)
- [ ] **Search** : intégrer `/search/tv` dans la recherche existante (option "Films" / "Séries" / "Tout")
- [ ] **CSV séries** : support d'import/export CSV pour les séries (format adapté)

## 🔵 P6 — Catégories
- [ ] À définir : catégories utilisateur ? tags libres ? grouping par genre ?

## 🔵 P7 — Recommandations IA (Mistral)
- [ ] **Moteur de recommandation** :
  - Basé sur Mistral AI (une seule requête par recommandation — pas de chat multi-tours)
  - L'utilisateur renseigne : **humeur** (ex: "j'ai envie de rire", "soirée flippante", "feel-good"), **durée max** (minutes), **genre(s)** souhaité(s)
  - Mistral reçoit en contexte la liste complète des films de l'utilisateur (titre, durée, genre, note perso, synopsis) + les critères saisis
  - Mistral retourne une sélection de 1 à 3 films de **la liste personnelle** avec une courte justification personnalisée pour chaque
- [ ] **UI « Aide-moi à choisir »** :
  - Nouveau bouton/floating action "🎬 Choisir pour moi" sur l'écran d'accueil
  - Bottom sheet ou écran dédié avec :
    - Un champ texte pour l'humeur (libre)
    - Un slider ou input pour la durée max
    - Un sélecteur de genres (multi-select, depuis les genres disponibles dans la liste)
    - Un bouton "Proposer"
  - Résultat : carte(s) de film avec la justification Mistral et un bouton "Voir la fiche"
- [ ] **Gestion des erreurs** :
  - Timeout Mistral → message explicite, pas de crash
  - Si la liste est vide → dire "Ajoute déjà des films !"
  - Fallback si Mistral est injoignable → suggestion aléatoire depuis la liste
- [ ] **Configuration** : clé Mistral sécurisée via `.env` (cf. P1)

## ⚪ P8 — Build Web + Docker (secondaire)
- [ ] **Adapter `main.dart`** : wrapper plateforme pour Hive
  ```dart
  import 'package:flutter/foundation.dart' show kIsWeb;
  // ...
  if (kIsWeb) {
    await Hive.init();       // IndexedDB
  } else {
    await Hive.initFlutter(); // fichiers natifs
  }
  ```
- [ ] **Adapter `csv_service.dart` / `settings_screen.dart`** :
  - `file_picker` et `share_plus` ne marchent pas sur web → cacher les boutons CSV avec `kIsWeb` ou afficher un message "Non disponible sur le navigateur"
  - `path_provider` → remplacer par `universal_html` ou fallback web
  - Utiliser `dart:io` seulement si `!kIsWeb` (importer conditionnellement)
- [ ] **Build web** : `flutter build web --release` → produit `build/web/`
- [ ] **Créer `Dockerfile`** :
  ```dockerfile
  FROM nginx:alpine
  COPY build/web /usr/share/nginx/html
  COPY nginx.conf /etc/nginx/conf.d/default.conf
  EXPOSE 80
  CMD ["nginx", "-g", "daemon off;"]
  ```
- [ ] **Créer `nginx.conf`** (optionnel, si besoin de SPA fallback) :
  ```nginx
  server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;
    location / {
      try_files $uri $uri/ /index.html;
    }
  }
  ```
- [ ] **Créer `docker-compose.yml`** :
  ```yaml
  services:
    popcornlist:
      build: .
      ports:
        - "8080:80"
      restart: unless-stopped
  ```
- [ ] **UI responsive** :
  - Limiter la largeur max du grid (ex: `maxCrossAxisExtent: 280` au lieu de `crossAxisCount: 3` fixe → `SliverGridDelegateWithMaxCrossAxisExtent`)
  - `NavigationBar` déjà responsive
  - Tester les breakpoints mobile/tablette/desktop
- [ ] **Build & déploiement** :
  ```sh
  flutter build web --release
  docker compose up -d --build
  ```
  → accessible sur `http://IP_DU_SERVEUR:8080`
