@echo off
REM Script pour créer un nouveau répertoire de version
REM Compatible: Windows

setlocal enabledelayedexpansion

echo =========================================
echo   Création d'un nouveau répertoire OTA
echo =========================================
echo.

REM Demander le numéro de version
set /p VERSION="Entrez le numéro de version (ex: 1.2.0): "

if "%VERSION%"=="" (
    echo ❌ Erreur: Le numéro de version ne peut pas être vide
    exit /b 1
)

REM Ajouter le préfixe 'v' si absent
if not "%VERSION:~0,1%"=="v" (
    set VERSION=v%VERSION%
)

REM Vérifier si le répertoire existe déjà
if exist "releases\%VERSION%" (
    echo ⚠️  Le répertoire releases\%VERSION% existe déjà
    set /p CONFIRM="Voulez-vous le recréer ? (y/N): "
    if /i not "!CONFIRM!"=="y" (
        echo ❌ Opération annulée
        exit /b 1
    )
    rmdir /s /q "releases\%VERSION%"
)

REM Créer le répertoire
mkdir "releases\%VERSION%"

REM Créer un fichier changelog vide
(
echo # Changelog - %VERSION%
echo.
echo ## Nouvelles fonctionnalités
echo -
echo.
echo ## Corrections de bugs
echo -
echo.
echo ## Améliorations
echo -
) > "releases\%VERSION%\changelog-fr.txt"

echo ✅ Répertoire créé: releases\%VERSION%
echo ✅ Fichier changelog créé: releases\%VERSION%\changelog-fr.txt
echo.
echo 📝 Prochaines étapes:
echo    1. Copiez votre APK dans: releases\%VERSION%\
echo    2. Renommez-le en: amopi-scan-%VERSION%-release.apk
echo    3. Exécutez: scripts\generate-checksum.bat %VERSION%
echo    4. Exécutez: scripts\update-latest.bat %VERSION%
echo.

pause
