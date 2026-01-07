@echo off
REM Script pour générer la somme de contrôle SHA256 d'un APK
REM Compatible: Windows

setlocal enabledelayedexpansion

echo =========================================
echo   Génération de la somme de contrôle
echo =========================================
echo.

REM Vérifier si une version est passée en argument
if "%~1"=="" (
    set /p VERSION="Entrez le numéro de version (ex: 1.2.0 ou v1.2.0): "
) else (
    set VERSION=%~1
)

REM Ajouter le préfixe 'v' si absent
if not "!VERSION:~0,1!"=="v" (
    set VERSION=v!VERSION!
)

REM Vérifier si le répertoire existe
if not exist "releases\!VERSION!" (
    echo ❌ Erreur: Le répertoire releases\!VERSION! n'existe pas
    echo    Exécutez d'abord: scripts\create-version.bat
    pause
    exit /b 1
)

REM Chercher l'APK dans le répertoire
set APK_FILE=
for %%f in (releases\!VERSION!\*.apk) do (
    set APK_FILE=%%f
    goto :found
)

:found
if "!APK_FILE!"=="" (
    echo ❌ Erreur: Aucun fichier APK trouvé dans releases\!VERSION!
    echo    Copiez votre APK dans ce répertoire et renommez-le en: amopi-scan-!VERSION!-release.apk
    pause
    exit /b 1
)

echo 📦 APK trouvé: !APK_FILE!
echo.

REM Générer le checksum
echo 🔐 Calcul de la somme de contrôle SHA256...

REM Utiliser CertUtil pour calculer le SHA256 (disponible nativement sur Windows)
certutil -hashfile "!APK_FILE!" SHA256 > temp_checksum.txt

REM Extraire uniquement le hash (ligne 2 du output de certutil)
set LINE_NUM=0
for /f "skip=1 tokens=*" %%a in (temp_checksum.txt) do (
    set /a LINE_NUM+=1
    if !LINE_NUM!==1 (
        set CHECKSUM=%%a
        REM Supprimer les espaces
        set CHECKSUM=!CHECKSUM: =!
    )
)

REM Créer le fichier .sha256
echo !CHECKSUM! *!APK_FILE! > "!APK_FILE!.sha256"

REM Nettoyer le fichier temporaire
del temp_checksum.txt

echo ✅ Checksum généré: !APK_FILE!.sha256
echo.
echo 📋 SHA256: !CHECKSUM!
echo.
echo 📝 Prochaine étape:
echo    Exécutez: scripts\update-latest.bat !VERSION!
echo.

pause
