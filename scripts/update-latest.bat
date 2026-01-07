@echo off
REM Script pour générer/mettre à jour le fichier latest.json
REM Compatible: Windows

setlocal enabledelayedexpansion

echo =========================================
echo   Mise à jour de latest.json
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

REM Extraire la version sans le 'v' pour version_name
set VERSION_NAME=!VERSION:~1!

REM Vérifier si le répertoire existe
if not exist "releases\!VERSION!" (
    echo ❌ Erreur: Le répertoire releases\!VERSION! n'existe pas
    pause
    exit /b 1
)

REM Chercher l'APK
set APK_FILE=
for %%f in (releases\!VERSION!\*.apk) do (
    set APK_FILE=%%f
    goto :found_apk
)

:found_apk
if "!APK_FILE!"=="" (
    echo ❌ Erreur: Aucun fichier APK trouvé dans releases\!VERSION!
    pause
    exit /b 1
)

REM Vérifier si le fichier checksum existe
set CHECKSUM_FILE=!APK_FILE!.sha256
if not exist "!CHECKSUM_FILE!" (
    echo ❌ Erreur: Fichier checksum non trouvé: !CHECKSUM_FILE!
    echo    Exécutez d'abord: scripts\generate-checksum.bat !VERSION!
    pause
    exit /b 1
)

REM Lire le checksum (première ligne du fichier)
set /p CHECKSUM_LINE=<"!CHECKSUM_FILE!"
REM Extraire uniquement le hash (avant l'espace)
for /f "tokens=1" %%a in ("!CHECKSUM_LINE!") do set CHECKSUM=%%a

REM Obtenir la taille du fichier
for %%A in ("!APK_FILE!") do set APK_SIZE=%%~zA

REM Demander le version_code
echo ℹ️  Le version_code doit être un nombre entier incrémentiel (ex: 1, 2, 3...)
set /p VERSION_CODE="Entrez le version_code: "

REM Vérifier que c'est un nombre
echo !VERSION_CODE! | findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo ❌ Erreur: Le version_code doit être un nombre entier
    pause
    exit /b 1
)

REM Demander si la mise à jour est obligatoire
set /p MANDATORY="Cette mise à jour est-elle obligatoire ? (y/N): "
if /i "!MANDATORY!"=="y" (
    set MANDATORY_VALUE=true
) else (
    set MANDATORY_VALUE=false
)

REM Lire le changelog s'il existe
set CHANGELOG_FILE=releases\!VERSION!\changelog-fr.txt
set RELEASE_NOTES=

if exist "!CHANGELOG_FILE!" (
    REM Extraire les notes de version (lignes commençant par -)
    for /f "tokens=*" %%a in ('findstr "^- " "!CHANGELOG_FILE!"') do (
        set LINE=%%a
        set LINE=!LINE:~2!
        if "!RELEASE_NOTES!"=="" (
            set RELEASE_NOTES=• !LINE!
        ) else (
            set RELEASE_NOTES=!RELEASE_NOTES!\n• !LINE!
        )
    )
)

if "!RELEASE_NOTES!"=="" (
    echo.
    echo 📝 Entrez les notes de version (tapez END sur une ligne seule pour terminer):
    set NOTES_TEMP=
    :read_notes
    set /p NOTE_LINE="  "
    if "!NOTE_LINE!"=="END" goto :notes_done
    if "!NOTE_LINE!"=="" goto :notes_done
    if "!NOTES_TEMP!"=="" (
        set NOTES_TEMP=• !NOTE_LINE!
    ) else (
        set NOTES_TEMP=!NOTES_TEMP!\n• !NOTE_LINE!
    )
    goto :read_notes
    :notes_done
    set RELEASE_NOTES=!NOTES_TEMP!
)

REM Demander le nom du compte GitHub
set /p GITHUB_ACCOUNT="Entrez votre nom de compte/organisation GitHub: "

if "!GITHUB_ACCOUNT!"=="" (
    echo ❌ Erreur: Le nom de compte GitHub est requis
    pause
    exit /b 1
)

REM Construire l'URL de l'APK
for %%f in (!APK_FILE!) do set APK_FILENAME=%%~nxf
set APK_URL=https://raw.githubusercontent.com/!GITHUB_ACCOUNT!/amopi-scan-ota/main/releases/!VERSION!/!APK_FILENAME!

REM Générer le fichier latest.json
(
echo {
echo   "version_code": !VERSION_CODE!,
echo   "version_name": "!VERSION_NAME!",
echo   "apk_url": "!APK_URL!",
echo   "apk_size": !APK_SIZE!,
echo   "checksum_sha256": "!CHECKSUM!",
echo   "release_notes": "!RELEASE_NOTES!",
echo   "mandatory": !MANDATORY_VALUE!
echo }
) > latest.json

echo.
echo ✅ Fichier latest.json généré avec succès !
echo.
echo 📋 Contenu:
type latest.json
echo.
echo 📝 Prochaines étapes:
echo    1. Vérifiez le contenu de latest.json
echo    2. git add .
echo    3. git commit -m "🚀 Publication de amopi_scan !VERSION!"
echo    4. git tag !VERSION!
echo    5. git push origin main --tags
echo.

pause
