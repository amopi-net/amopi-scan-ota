#!/bin/bash
# Script pour générer/mettre à jour le fichier latest.json
# Compatible: Linux / macOS

set -e

echo "========================================="
echo "  Mise à jour de latest.json            "
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

# Extraire la version sans le 'v' pour version_name
VERSION_NAME="${VERSION#v}"

# Vérifier si le répertoire existe
if [ ! -d "releases/$VERSION" ]; then
    echo "❌ Erreur: Le répertoire releases/$VERSION n'existe pas"
    exit 1
fi

# Chercher l'APK
APK_FILE=$(find "releases/$VERSION" -name "*.apk" -type f | head -n 1)
if [ -z "$APK_FILE" ]; then
    echo "❌ Erreur: Aucun fichier APK trouvé dans releases/$VERSION"
    exit 1
fi

# Vérifier si le fichier checksum existe
CHECKSUM_FILE="${APK_FILE}.sha256"
if [ ! -f "$CHECKSUM_FILE" ]; then
    echo "❌ Erreur: Fichier checksum non trouvé: $CHECKSUM_FILE"
    echo "   Exécutez d'abord: ./scripts/generate-checksum.sh $VERSION"
    exit 1
fi

# Lire le checksum
if command -v sha256sum &> /dev/null; then
    CHECKSUM=$(cat "$CHECKSUM_FILE" | awk '{print $1}')
elif command -v shasum &> /dev/null; then
    CHECKSUM=$(cat "$CHECKSUM_FILE" | awk '{print $1}')
fi

# Obtenir la taille du fichier
APK_SIZE=$(stat -f%z "$APK_FILE" 2>/dev/null || stat -c%s "$APK_FILE" 2>/dev/null)

# Demander le version_code
echo "ℹ️  Le version_code doit être un nombre entier incrémentiel (ex: 1, 2, 3...)"
read -p "Entrez le version_code: " VERSION_CODE

if ! [[ "$VERSION_CODE" =~ ^[0-9]+$ ]]; then
    echo "❌ Erreur: Le version_code doit être un nombre entier"
    exit 1
fi

# Demander si la mise à jour est obligatoire
read -p "Cette mise à jour est-elle obligatoire ? (y/N): " MANDATORY
if [[ $MANDATORY =~ ^[yY]$ ]]; then
    MANDATORY_VALUE="true"
else
    MANDATORY_VALUE="false"
fi

# Lire le changelog s'il existe
CHANGELOG_FILE="releases/$VERSION/changelog-fr.txt"
RELEASE_NOTES=""
if [ -f "$CHANGELOG_FILE" ]; then
    # Extraire les notes de version (ignorer les lignes de titre)
    RELEASE_NOTES=$(grep "^- " "$CHANGELOG_FILE" | sed 's/^- /• /' | tr '\n' '\\n' | sed 's/\\n$//')
fi

if [ -z "$RELEASE_NOTES" ]; then
    echo ""
    echo "📝 Entrez les notes de version (une par ligne, tapez une ligne vide pour terminer):"
    NOTES_ARRAY=()
    while IFS= read -r line; do
        [ -z "$line" ] && break
        NOTES_ARRAY+=("$line")
    done

    # Construire la chaîne avec \n
    FIRST=true
    for note in "${NOTES_ARRAY[@]}"; do
        if [ "$FIRST" = true ]; then
            RELEASE_NOTES="• $note"
            FIRST=false
        else
            RELEASE_NOTES="$RELEASE_NOTES\n• $note"
        fi
    done
fi

# Demander le nom du compte GitHub
read -p "Entrez votre nom de compte/organisation GitHub: " GITHUB_ACCOUNT

if [ -z "$GITHUB_ACCOUNT" ]; then
    echo "❌ Erreur: Le nom de compte GitHub est requis"
    exit 1
fi

# Construire l'URL de l'APK
APK_FILENAME=$(basename "$APK_FILE")
APK_URL="https://raw.githubusercontent.com/${GITHUB_ACCOUNT}/amopi-scan-ota/main/releases/${VERSION}/${APK_FILENAME}"

# Générer le fichier latest.json
cat > latest.json << EOF
{
  "version_code": ${VERSION_CODE},
  "version_name": "${VERSION_NAME}",
  "apk_url": "${APK_URL}",
  "apk_size": ${APK_SIZE},
  "checksum_sha256": "${CHECKSUM}",
  "release_notes": "${RELEASE_NOTES}",
  "mandatory": ${MANDATORY_VALUE}
}
EOF

echo ""
echo "✅ Fichier latest.json généré avec succès !"
echo ""
echo "📋 Contenu:"
cat latest.json
echo ""
echo "📝 Prochaines étapes:"
echo "   1. Vérifiez le contenu de latest.json"
echo "   2. git add ."
echo "   3. git commit -m \"🚀 Publication de amopi_scan $VERSION\""
echo "   4. git tag $VERSION"
echo "   5. git push origin main --tags"
echo ""
