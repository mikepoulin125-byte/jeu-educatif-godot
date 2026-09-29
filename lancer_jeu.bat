@echo off
rem 1) Convertit les GIF fraichement deposes (creatures, decor du Hub...)
rem    en planches PNG (Godot ne lit pas les GIF animes nativement --
rem    voir assets/creatures/LISEZ-MOI.txt et scripts/tools/convertir_gifs.ps1).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\tools\convertir_gifs.ps1"

rem 2) Relance une (re)importation des assets avant de lancer le jeu compile,
rem    sinon un fichier fraichement depose dans assets/ (ex. logo_menu.png,
rem    fond_menu.png/.ogv, planches de creatures) n'a pas encore de
rem    metadonnees .import et load() echoue silencieusement au demarrage
rem    (retourne null -> le placeholder reste affiche, meme si le fichier
rem    est valide).
"%LOCALAPPDATA%\Microsoft\WinGet\Links\godot.exe" --headless --path "%~dp0." --import >nul 2>&1
"%LOCALAPPDATA%\Microsoft\WinGet\Links\godot.exe" --path "%~dp0."
