#!/bin/bash

# =============================================================================
# Script de Déploiement OTA Automatique
# =============================================================================
# Ce script est conçu pour être exécuté dans GitHub Actions
# Il crée automatiquement une nouvelle release dans le dépôt OTA
#
# Prérequis :
#   - L'APK doit être construit dans build/app/outputs/flutter-apk/app-release.apk
#   - Les variables d'environnement doivent être définies :
#       * GITHUB_REF : Référence du tag (ex: refs/tags/v1.2.0)
#       * GITHUB_REPOSITORY : Nom du dépôt (ex: amopi-net/amopi-scan-ota)
#       * VERSION_CODE : Code de version incrémentiel (ex: 5)
#       * MANDATORY_UPDATE : true/false (optionnel, défaut: false)
#       * RELEASE_NOTES : Notes de version (optionnel)
# =============================================================================

set -e  # Arrêter en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# =============================================================================
# 1. EXTRACTION DE LA VERSION DEPUIS LE TAG
# =============================================================================

log_info "Extraction de la version depuis le tag..."

# Extraire la version depuis GITHUB_REF (ex: refs/tags/v1.2.0 -> 1.2.0)
if [ -z "$GITHUB_REF" ]; then
    log_error "GITHUB_REF n'est pas défini. Ce script doit être exécuté dans GitHub Actions."
    exit 1
fi

VERSION_NAME=$(echo "$GITHUB_REF" | sed 's|refs/tags/v||')
log_info "Version détectée: $VERSION_NAME"

# Vérifier que VERSION_CODE est défini
if [ -z "$VERSION_CODE" ]; then
    log_error "VERSION_CODE n'est pas défini. Veuillez définir cette variable d'environnement."
    exit 1
fi
log_info "Version code: $VERSION_CODE"

# =============================================================================
# 2. CONFIGURATION DU DÉPÔT OTA
# =============================================================================

log_info "Configuration du dépôt OTA..."

# Cloner ou utiliser le dépôt OTA
OTA_REPO_DIR="amopi-scan-ota"
OTA_REPO_URL="https://${PAT}@github.com/${OTA_REPO}.git"

if [ ! -d "$OTA_REPO_DIR" ]; then
    log_info "Clonage du dépôt OTA: $OTA_REPO"
    git clone "$OTA_REPO_URL" "$OTA_REPO_DIR"
else
    log_info "Le dépôt OTA existe déjà, mise à jour..."
    cd "$OTA_REPO_DIR"
    git pull
    cd ..
fi

cd "$OTA_REPO_DIR"

# Configuration Git
git config user.name "GitHub Actions Bot"
git config user.email "actions@github.com"

# =============================================================================
# 3. CRÉATION DU DOSSIER DE VERSION
# =============================================================================

log_info "Création du dossier de version..."

VERSION_DIR="releases/v${VERSION_NAME}"
mkdir -p "$VERSION_DIR"

# =============================================================================
# 4. COPIE DE L'APK
# =============================================================================

log_info "Copie de l'APK..."

APK_SOURCE="../build/app/outputs/flutter-apk/app-release.apk"
APK_DEST="$VERSION_DIR/amopi-scan-v${VERSION_NAME}-release.apk"

if [ ! -f "$APK_SOURCE" ]; then
    log_error "L'APK source n'existe pas: $APK_SOURCE"
    log_error "Assurez-vous que 'flutter build apk --release' a été exécuté."
    exit 1
fi

cp "$APK_SOURCE" "$APK_DEST"
log_info "APK copié vers: $APK_DEST"

# =============================================================================
# 5. CALCUL DU CHECKSUM SHA256
# =============================================================================

log_info "Calcul du checksum SHA256..."

CHECKSUM=$(sha256sum "$APK_DEST" | awk '{print $1}')
echo "$CHECKSUM  $(basename $APK_DEST)" > "$APK_DEST.sha256"
log_info "Checksum: $CHECKSUM"

# =============================================================================
# 6. RÉCUPÉRATION DE LA TAILLE DE L'APK
# =============================================================================

log_info "Récupération de la taille de l'APK..."

APK_SIZE=$(stat -f%z "$APK_DEST" 2>/dev/null || stat -c%s "$APK_DEST" 2>/dev/null)
log_info "Taille de l'APK: $APK_SIZE bytes"

# =============================================================================
# 7. GÉNÉRATION DES NOTES DE VERSION
# =============================================================================

log_info "Génération des notes de version..."

# Créer le fichier changelog
CHANGELOG_FILE="$VERSION_DIR/changelog-fr.txt"

if [ -n "$RELEASE_NOTES" ]; then
    echo "$RELEASE_NOTES" > "$CHANGELOG_FILE"
else
    # Notes par défaut
    cat > "$CHANGELOG_FILE" << EOF
Version ${VERSION_NAME}
========================

• Améliorations de performance
• Corrections de bugs
• Améliorations de stabilité

Date de publication: $(date +"%Y-%m-%d")
EOF
fi

log_info "Notes de version créées: $CHANGELOG_FILE"

# Lire les notes pour latest.json (échapper les caractères spéciaux pour JSON)
RELEASE_NOTES_ESCAPED=$(cat "$CHANGELOG_FILE" | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

# =============================================================================
# 8. GÉNÉRATION DE L'URL DE L'APK
# =============================================================================

log_info "Génération de l'URL de l'APK..."

# Extraire le nom du compte et du dépôt
GITHUB_ACCOUNT=$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f1)
GITHUB_REPO_NAME=$(echo "$OTA_REPO" | cut -d'/' -f2)

APK_URL="https://raw.githubusercontent.com/${GITHUB_ACCOUNT}/${GITHUB_REPO_NAME}/main/releases/v${VERSION_NAME}/amopi-scan-v${VERSION_NAME}-release.apk"
log_info "URL de l'APK: $APK_URL"

# =============================================================================
# 9. MISE À JOUR DU FICHIER latest.json
# =============================================================================

log_info "Mise à jour du fichier latest.json..."

# Déterminer si la mise à jour est obligatoire
MANDATORY="${MANDATORY_UPDATE:-false}"

# Générer latest.json
cat > latest.json << EOF
{
  "version_code": ${VERSION_CODE},
  "version_name": "${VERSION_NAME}",
  "apk_url": "${APK_URL}",
  "apk_size": ${APK_SIZE},
  "checksum_sha256": "${CHECKSUM}",
  "release_notes": "${RELEASE_NOTES_ESCAPED}",
  "mandatory": ${MANDATORY}
}
EOF

log_info "Fichier latest.json mis à jour."

# Afficher le contenu pour vérification
log_info "Contenu de latest.json:"
cat latest.json

# =============================================================================
# 10. COMMIT ET PUSH DES CHANGEMENTS
# =============================================================================

log_info "Validation et envoi des changements..."

git add .
git commit -m "🚀 Publication de amopi_scan v${VERSION_NAME}

- Version code: ${VERSION_CODE}
- Taille de l'APK: ${APK_SIZE} bytes
- Checksum SHA256: ${CHECKSUM}
- Mise à jour obligatoire: ${MANDATORY}
- Publié automatiquement via GitHub Actions
"

git tag "v${VERSION_NAME}" || log_warning "Le tag v${VERSION_NAME} existe déjà"

log_info "Push des changements vers GitHub..."
git push origin main
git push origin --tags || log_warning "Le tag existe déjà sur GitHub"

# =============================================================================
# 11. RÉSUMÉ FINAL
# =============================================================================

log_info "=========================================="
log_info "✅ Déploiement OTA terminé avec succès !"
log_info "=========================================="
log_info ""
log_info "📦 Version: v${VERSION_NAME} (code: ${VERSION_CODE})"
log_info "📁 Dossier: $VERSION_DIR"
log_info "🔐 Checksum: $CHECKSUM"
log_info "📏 Taille: $APK_SIZE bytes"
log_info "🌐 URL: $APK_URL"
log_info "⚠️  Obligatoire: $MANDATORY"
log_info ""
log_info "Les appareils pourront maintenant télécharger cette mise à jour."
log_info "=========================================="

cd ..
