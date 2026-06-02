#!/usr/bin/env bash
set -euo pipefail

# build-docker.sh — Build image Docker Web avec injection des secrets
#
# Usage:
#   ./scripts/build-docker.sh                  # Lit les clés depuis .env
#   TMDB_API_KEY=xxx ./scripts/build-docker.sh # Surcharge directe
#
# L'image générée est tagguée popcornlist:web

cd "$(dirname "$0")/.."

# Charger .env si présent
if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

# Vérification
if [ -z "${TMDB_API_KEY:-}" ]; then
  echo "❌ TMDB_API_KEY non défini. Crée un fichier .env ou passe la variable."
  exit 1
fi

echo "🐳 Construction de l'image Docker (PopCornList Web)..."

docker build -t popcornlist:web \
  --build-arg TMDB_API_KEY="$TMDB_API_KEY" \
  --build-arg MISTRAL_API_KEY="${MISTRAL_API_KEY:-}" \
  .

echo ""
echo "✅ Image Docker générée : popcornlist:web"
echo "🚀 Pour lancer : docker run -d -p 8080:80 popcornlist:web"
