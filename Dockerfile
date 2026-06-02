# Étape 1 : Build de l'application Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Arguments de build pour les clés API
ARG TMDB_API_KEY
ARG MISTRAL_API_KEY

# Copier les fichiers de configuration pour le cache des dépendances
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copier le reste du code
COPY . .

# Build pour le Web en injectant les clés API
# Si les arguments ne sont pas fournis, les valeurs par défaut d'ApiConfig seront utilisées
RUN flutter build web --release \
    --dart-define=TMDB_API_KEY=${TMDB_API_KEY} \
    --dart-define=MISTRAL_API_KEY=${MISTRAL_API_KEY}

# Étape 2 : Serveur Nginx pour distribuer les fichiers statiques
FROM nginx:alpine

# Copier la configuration Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copier les fichiers compilés de l'étape précédente
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
