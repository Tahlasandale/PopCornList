#!/usr/bin/env bash
set -euo pipefail

# build-release.sh — Build release APK avec injection des secrets via dart-define
#
# Usage:
#   ./scripts/build-release.sh                  # Lit TMDB_API_KEY depuis .env
#   TMDB_API_KEY=xxx ./scripts/build-release.sh # Surcharge directe
#
# Prérequis : fichier .env à la racine avec TMDB_API_KEY=*** (voir .env.example)

cd "$(dirname "$0")/.."

# Charger .env silencieusement si présent
if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

# Vérification
if [ -z "${TMDB_API_KEY:-}" ]; then
  echo "❌ TMDB_API_KEY non défini."
  echo "   Crée un fichier .env à la racine :"
  echo "   TMDB_API_KEY=ta_cle_api"
  echo "   Voir .env.example pour le format."
  exit 1
fi

if [ -z "${MISTRAL_API_KEY:-}" ]; then
  echo "⚠️  MISTRAL_API_KEY non défini — recommendations IA désactivées dans le build."
fi

echo "🔨 Build release APK..."
echo "   TMDB_API_KEY: ${TMDB_API_KEY:0:8}... (${#TMDB_API_KEY} chars)"
echo "   MISTRAL_API_KEY: ${MISTRAL_API_KEY:0:8}... (${#MISTRAL_API_KEY} chars)"

export PATH="$HOME/development/flutter/bin:$PATH"
export ANDROID_HOME="$HOME/development/android-sdk"
export ANDROID_SDK_ROOT="$HOME/development/android-sdk"

flutter build apk --release \
  --dart-define="TMDB_API_KEY=$TMDB_API_KEY" \
  --dart-define="MISTRAL_API_KEY=$MISTRAL_API_KEY" \
  "$@"

echo ""
echo "✅ APK générée : build/app/outputs/flutter-apk/app-release.apk"
ls -lh build/app/outputs/flutter-apk/app-release.apk
