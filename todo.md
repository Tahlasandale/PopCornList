# Todo

## ✅ P0 — Bug (Corrigés)

- [x] **Doublons CSV** : `CsvService.importCsv()` — fallback titre normalisé ajouté. Plus aucun doublon silencieux pour les films sans `tmdbId`. (`e3ec76a`)
- [x] **Release APK Android buggée** : keystore dédié « PopCornList » créé, signing release corrigé, ProGuard activé. APK signée (v1+v2+v3) valide 25 ans. (`1b62322`)

## ✅ P1 — Sécurité & Configuration

- [x] **Clé TMDB externalisée** : retirée d'`api_config.dart`, injectée via `--dart-define-from-file=.env`. Script `build-release.sh` créé. (`477577f`)
- [x] **Clé Mistral AI externalisée** : idem TMDB, dans `ApiConfig.mistralApiKey` via `String.fromEnvironment`, chargée depuis `.env` et `.env.example`. Assertion dans `main.dart`.

## ✅ P2 — Landing page responsive (site vitrine)

- [x] **`index.html` responsive mobile** : menu hamburger coulissant, grilles adaptatives, ASCII art réduit, breakpoints 900/640/400px. (`4ad5be4`)

## ✅ P3 — Tri multi-critères
- [x] `FilmFilter.apply()` accepte `List<SortCriteria>` (field + ascending)
- [x] `SortBar` refait en multi-sélection : ordre = priorité, chaque chip toggle ↑/↓/désactivé
- [x] Intégré dans `ListScreen` et `SearchScreen` (`v1.2.0`)

## ✅ P4 — Filtre genres (intersection)
- [x] `genreIds` persisté dans `LocalMovie` (Hive + CSV colonne 9 au pipe `|`)
- [x] `GenreFilterSheet` créé (recherche + checkboxes, logique AND)
- [x] Compatibilité ascendante : anciens CSV sans colonne 9 → fallback `[]`

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

## ✅ P7 — Recommandations IA (Mistral)

- [x] **Moteur de recommandation** (`lib/services/mistral_service.dart`) :
  - Basé sur Mistral AI (API `/chat/completions`, modèle `mistral-small-latest`)
  - L'utilisateur renseigne : **humeur** (texte libre), **durée max** (slider 30-240 min), **genre(s)** (multi-select parmi 18 genres TMDB)
  - Mistral reçoit la liste complète des films (titre, note, statut, acteurs) + les critères
  - Retourne 1 à 3 films de **la liste personnelle** avec justification personnalisée
- [x] **UI « Aide-moi à choisir »** (`lib/screens/ai_recommendation_screen.dart`) :
  - Bouton ✨ IA ajouté **à côté du champ de recherche** dans `SearchScreen`
  - Écran dédié avec : champ humeur, slider durée, chips genres multi-select, bouton "🎬 Proposer"
  - Résultat : cartes jolies avec poster, note, statut, justification Mistral dans une bulle, et bouton **"Voir la fiche"** → `MovieDetailScreen`
- [x] **Gestion des erreurs** :
  - Timeout / erreur réseau → fallback aléatoire avec message explicite
  - Liste vide → message "Ajoute déjà des films !"
  - Pas de clé Mistral → fallback aléatoire silencieux
- [x] **Configuration** : clé sécurisée via `.env` / `--dart-define-from-file` (P1)

## ✅ P8 — Build Web + Docker

- [x] **Adapter `main.dart`** : `Hive.initFlutter()` déjà compatible.
- [x] **Fichiers de configuration** : `Dockerfile`, `nginx.conf` et `.dockerignore` créés.
- [x] **Build Web** : Test local `flutter build web` réussi.
- [x] **Dockerisation** : Image Docker prête (basée sur nginx:alpine).

