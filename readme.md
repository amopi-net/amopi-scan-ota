# Dépôt de Mises à Jour OTA : amopi-scan-ota

Dépôt privé pour la distribution sécurisée des mises à jour de l'application amopi_scan.

**CE DÉPÔT DOIT RESTER PRIVÉ – Il contient les versions exécutables de l'application.**

## Structure du Dépôt

```
amopi-scan-ota/
├── releases/                               # Toutes les versions publiées
│   ├── v1/
│   │   ├── amopi-scan-v1-release.apk       # APK signé
│   │   ├── amopi-scan-v1-release.apk.sha256 # Somme de contrôle
│   │   └── changelog-fr.txt                # Notes de version
│   ├── v2/
│   └── .../
├── latest.json                              # MÉTA-DONNÉES DE LA DERNIÈRE VERSION
├── .github/workflows/                       # Automatisation CI/CD (Optionnel)
└── scripts/                                 # Scripts utilitaires
```

## Fichier latest.json (Le Point Central)

Ce fichier, situé à la racine du dépôt, est interrogé par l'application pour détecter les mises à jour.

Contenu Obligatoire :

```json
{
  "version_code": 5,
  "version_name": "1.2.0",
  "apk_url": "https://raw.githubusercontent.com/TON_COMPTE/amopi-scan-ota/main/releases/v1.2.0/amopi-scan-v1.2.0-release.apk",
  "apk_size": 15728640,
  "checksum_sha256": "a1b2c3d4e5f67890abcdef1234567890...",
  "release_notes": "• Correction du bug critique de scan\n• Amélioration des performances",
  "mandatory": false
}
```

### Variables à Modifier à Chaque Version

| Champ             | Description                                            | Exemple                |
| ----------------- | ------------------------------------------------------ | ---------------------- |
| `version_code`    | Numéro interne de version (incrémentiel)               | `5`                    |
| `version_name`    | Nom de version lisible                                 | `"1.2.0"`              |
| `apk_url`         | URL COMPLÈTE de l'APK sur GitHub (avec ?raw=true)      | Voir exemple ci-dessus |
| `checksum_sha256` | Empreinte de sécurité de l'APK (générée par sha256sum) | Obtenue via terminal   |

## Publication d'une Nouvelle Version

### Publication Automatisée (Recommandé)

Des scripts sont disponibles pour automatiser le processus de publication. Ils sont compatibles Windows, Linux et macOS.

#### Sur Linux / macOS

```bash
# 1. Créer le répertoire de version
./scripts/create-version.sh
# Entrez la version quand demandé (ex: 1.2.0)

# 2. Copiez votre APK Flutter signé dans le répertoire créé
# L'APK Flutter se trouve dans : build/app/outputs/flutter-apk/app-release.apk
cp build/app/outputs/flutter-apk/app-release.apk releases/v1.2.0/amopi-scan-v1.2.0-release.apk

# 3. Générer le checksum SHA256
./scripts/generate-checksum.sh v1.2.0

# 4. Mettre à jour latest.json
./scripts/update-latest.sh v1.2.0
# Le script demandera :
# - Le version_code (nombre incrémentiel : 1, 2, 3...)
# - Si la mise à jour est obligatoire (y/N)
# - Les notes de version (ou les lira depuis changelog-fr.txt)
# - Votre nom de compte GitHub

# 5. Valider et pousser
git add .
git commit -m "🚀 Publication de amopi_scan v1.2.0"
git tag v1.2.0
git push origin main --tags
```

#### Sur Windows

```cmd
REM 1. Créer le répertoire de version
scripts\create-version.bat
REM Entrez la version quand demandé (ex: 1.2.0)

REM 2. Copiez votre APK Flutter signé dans le répertoire créé
REM L'APK Flutter se trouve dans : build\app\outputs\flutter-apk\app-release.apk
copy build\app\outputs\flutter-apk\app-release.apk releases\v1.2.0\amopi-scan-v1.2.0-release.apk

REM 3. Générer le checksum SHA256
scripts\generate-checksum.bat v1.2.0

REM 4. Mettre à jour latest.json
scripts\update-latest.bat v1.2.0
REM Le script demandera :
REM - Le version_code (nombre incrémentiel : 1, 2, 3...)
REM - Si la mise à jour est obligatoire (y/N)
REM - Les notes de version (tapez END pour terminer)
REM - Votre nom de compte GitHub

REM 5. Valider et pousser
git add .
git commit -m "🚀 Publication de amopi_scan v1.2.0"
git tag v1.2.0
git push origin main --tags
```

### 📋 Description des Scripts

| Script                     | Description                                                             |
| -------------------------- | ----------------------------------------------------------------------- |
| `create-version.sh/bat`    | Crée le répertoire `releases/vX.X.X` et génère un template de changelog |
| `generate-checksum.sh/bat` | Calcule automatiquement le SHA256 de l'APK                              |
| `update-latest.sh/bat`     | Génère le fichier `latest.json` avec toutes les métadonnées             |

### 🔧 Publication Manuelle (Sans Scripts)

Si vous préférez tout faire manuellement :

<details>
<summary>Cliquez pour voir les étapes manuelles</summary>

#### 1. Préparer le répertoire de version

```bash
VERSION="v1.2.0"  # À ADAPTER
mkdir -p releases/$VERSION
```

#### 2. Copier et renommer l'APK signé

```bash
cp build/app/outputs/flutter-apk/app-release.apk releases/$VERSION/amopi-scan-$VERSION-release.apk
```

#### 3. Générer l'empreinte de sécurité (CRITIQUE)

```bash
cd releases/$VERSION
sha256sum amopi-scan-$VERSION-release.apk > amopi-scan-$VERSION-release.apk.sha256
cd ../..

# Copiez la valeur du checksum pour l'étape suivante
cat releases/$VERSION/amopi-scan-$VERSION-release.apk.sha256
```

#### 4. Mettre à jour le fichier latest.json à la racine

Mettre à jour tous les champs manuellement, surtout `version_code`, `version_name`, `apk_url` et `checksum_sha256`.

#### 5. Valider et pousser les changements

```bash
git add .
git commit -m "🚀 Publication de amopi_scan $VERSION"
git tag $VERSION
git push origin main --tags
```

</details>

## 🔐 Sécurité (À LIRE ABSOLUMENT)

### RÈGLES D'OR

- **Dépôt PRIVÉ** : Vérifiez que Settings > General > Visibility est bien sur Private.
- **Jamais de clés** : Ne stockez JAMAIS le fichier `.keystore` ou `.jks` de signature ici.
- **Accès limité** : Utilisez un Personal Access Token (PAT) avec uniquement le scope `repo` (en lecture) pour l'application.

### Création du Token (PAT)

1. Allez sur GitHub > Settings > Developer settings > Personal access tokens.
2. Créez un token nommé `amopi-scan-ota-reader`.
3. Sélectionnez uniquement : `repo` (pour un dépôt privé).
4. Copiez-le et gardez-le secret ! Il ne sera plus affiché.

## 📱 Intégration dans l'Application Flutter amopi_scan

L'application Flutter doit implémenter cette logique. Voici l'essentiel en Dart :

```dart
// 1. URL fixe pour récupérer les infos de mise à jour
const String OTA_LATEST_URL =
    "https://raw.githubusercontent.com/TON_COMPTE/amopi-scan-ota/main/latest.json";

// 2. Dans votre OTAManager ou service de mise à jour
Future<void> checkAndUpdate() async {
  // Récupérer les informations de la dernière version
  final latestInfo = await fetchLatestInfo(OTA_LATEST_URL);  // Ajouter le token dans les headers

  // Obtenir la version actuelle de l'app
  final packageInfo = await PackageInfo.fromPlatform();
  final currentVersionCode = int.parse(packageInfo.buildNumber);

  if (latestInfo.versionCode > currentVersionCode) {
    // 3. TÉLÉCHARGER
    final apkFile = await downloadFile(latestInfo.apkUrl);

    // 4. VÉRIFIER (SÉCURITÉ CRITIQUE)
    final calculatedChecksum = await calculateSHA256(apkFile);
    if (calculatedChecksum != latestInfo.checksumSha256) {
      throw Exception("L'intégrité du fichier est compromise.");
    }

    // 5. INSTALLER (utiliser un plugin comme ota_update ou install_plugin)
    await installApk(apkFile.path);
  }
}
```

### Packages Flutter recommandés

Ajoutez ces dépendances dans votre `pubspec.yaml` :

```yaml
dependencies:
  http: ^1.1.0 # Pour télécharger le JSON et l'APK
  package_info_plus: ^5.0.0 # Pour obtenir la version actuelle
  path_provider: ^2.1.0 # Pour gérer les chemins de fichiers
  crypto: ^3.0.3 # Pour calculer le SHA256
  ota_update: ^6.0.0 # Pour installer l'APK (Android uniquement)
  permission_handler: ^11.0.0 # Pour gérer les permissions
```

## Automatisation (Optionnel avec GitHub Actions)

Pour automatiser les étapes 1 à 4 de la publication, créez ce fichier :

`.github/workflows/publish-release.yml`

```yaml
name: Build and Publish OTA Release

on:
  push:
    tags:
      - 'v*' # Se déclenche quand vous poussez un tag comme v1.2.0

jobs:
  build-and-release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout le code de l'app
        uses: actions/checkout@v3
        with:
          repository: 'TON_COMPTE/amopi_scan' # VOTRE REPO DE CODE SOURCE
          token: ${{ secrets.REPO_ACCESS_TOKEN }}

      - name: 🔧 Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x' # Adapter selon votre version
          channel: 'stable'

      - name: Installer les dépendances
        run: flutter pub get

      - name: Build l'APK
        run: |
          flutter build apk --release
          # L'APK signé sera dans build/app/outputs/flutter-apk/app-release.apk
          # Assurez-vous d'avoir configuré la signature dans android/key.properties

      - name: Publier sur le dépôt OTA
        env:
          OTA_REPO: 'amopi-net/amopi-scan-ota'
          PAT: ${{ secrets.OTA_DEPLOY_TOKEN }} # Token avec accès en écriture au repo OTA
        run: |
          # Script pour créer le dossier, copier l'APK, calculer le checksum
          # et mettre à jour latest.json automatiquement
          ./scripts/deploy-to-ota.sh
```

## 🆘 Dépannage Rapide

| Problème                         | Cause probable                    | Solution                                                                   |
| -------------------------------- | --------------------------------- | -------------------------------------------------------------------------- |
| L'app ne détecte pas la MAJ      | `latest.json` mal formé           | Vérifier avec JSONLint                                                     |
| Échec du téléchargement          | `apk_url` incorrecte              | L'URL doit finir par `?raw=true` ou être l'URL `raw.githubusercontent.com` |
| Vérification de signature échoue | APK signé avec une clé différente | TOUJOURS utiliser la même clé de signature (`.jks`)                        |

## 📞 Contact & Support

En cas de problème, vérifiez d'abord :

1. La visibilité du dépôt (Privé)
2. La validité du token
3. L'exactitude de l'URL dans `latest.json`
