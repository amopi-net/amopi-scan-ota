#!/bin/bash
# Script pour générer la somme de contrôle SHA256 d'un APK
# Compatible: Linux / macOS

set -e

echo "========================================="
echo "  Génération de la somme de contrôle    "
echo "========================================="
echo ""

# Vérifier si une version est passée en argument
if [ -z "$1" ]; then
    read -p "Entrez le numéro de version (ex: 1.2.0 ou v1.2.0): " VERSION
else
    VERSION="$1"
fi

# Ajouter le préfixe 'v' si absent
if [[ ! $VERSION =~ ^v ]]; then
    VERSION="v$VERSION"
fi

# Vérifier si le répertoire existe
if [ ! -d "releases/$VERSION" ]; then
    echo "❌ Erreur: Le répertoire releases/$VERSION n'existe pas"
    echo "   Exécutez d'abord: ./scripts/create-version.sh"
    exit 1
fi

# Chercher l'APK dans le répertoire
APK_FILE=$(find "releases/$VERSION" -name "*.apk" -type f | head -n 1)

if [ -z "$APK_FILE" ]; then
    echo "❌ Erreur: Aucun fichier APK trouvé dans releases/$VERSION"
    echo "   Copiez votre APK dans ce répertoire et renommez-le en: amopi-scan-$VERSION-release.apk"
    exit 1
fi

echo "📦 APK trouvé: $APK_FILE"
echo ""

# Générer le checksum
echo "🔐 Calcul de la somme de contrôle SHA256..."
CHECKSUM_FILE="${APK_FILE}.sha256"

if command -v sha256sum &> /dev/null; then
    # Linux
    sha256sum "$APK_FILE" > "$CHECKSUM_FILE"
    CHECKSUM=$(sha256sum "$APK_FILE" | awk '{print $1}')
elif command -v shasum &> /dev/null; then
    # macOS
    shasum -a 256 "$APK_FILE" > "$CHECKSUM_FILE"
    CHECKSUM=$(shasum -a 256 "$APK_FILE" | awk '{print $1}')
else
    echo "❌ Erreur: Aucune commande sha256sum ou shasum trouvée"
    exit 1
fi

echo "✅ Checksum généré: $CHECKSUM_FILE"
echo ""
echo "📋 SHA256: $CHECKSUM"
echo ""
echo "📝 Prochaine étape:"
echo "   Exécutez: ./scripts/update-latest.sh $VERSION"
echo ""
