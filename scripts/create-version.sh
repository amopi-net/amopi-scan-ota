#!/bin/bash
# Script pour créer un nouveau répertoire de version
# Compatible: Linux / macOS

set -e

echo "========================================="
echo "  Création d'un nouveau répertoire OTA  "
echo "========================================="
echo ""

# Demander le numéro de version
read -p "Entrez le numéro de version (ex: 1.2.0): " VERSION

if [ -z "$VERSION" ]; then
    echo "❌ Erreur: Le numéro de version ne peut pas être vide"
    exit 1
fi

# Ajouter le préfixe 'v' si absent
if [[ ! $VERSION =~ ^v ]]; then
    VERSION="v$VERSION"
fi

# Vérifier si le répertoire existe déjà
if [ -d "releases/$VERSION" ]; then
    echo "⚠️  Le répertoire releases/$VERSION existe déjà"
    read -p "Voulez-vous le recréer ? (y/N): " CONFIRM
    if [[ ! $CONFIRM =~ ^[yY]$ ]]; then
        echo "❌ Opération annulée"
        exit 1
    fi
    rm -rf "releases/$VERSION"
fi

# Créer le répertoire
mkdir -p "releases/$VERSION"

# Créer un fichier changelog vide
cat > "releases/$VERSION/changelog-fr.txt" << EOF
# Changelog - $VERSION

## Nouvelles fonctionnalités
-

## Corrections de bugs
-

## Améliorations
-
EOF

echo "✅ Répertoire créé: releases/$VERSION"
echo "✅ Fichier changelog créé: releases/$VERSION/changelog-fr.txt"
echo ""
echo "📝 Prochaines étapes:"
echo "   1. Copiez votre APK dans: releases/$VERSION/"
echo "   2. Renommez-le en: amopi-scan-$VERSION-release.apk"
echo "   3. Exécutez: ./scripts/generate-checksum.sh $VERSION"
echo "   4. Exécutez: ./scripts/update-latest.sh $VERSION"
echo ""
