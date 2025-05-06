@echo off
echo Starting Argon synchronization for DataStore Manager Pro plugin...
echo.
echo Checking for JSON issues before syncing...
echo.

REM Run the Fix-JsonFiles script if it exists
if exist "%~dp0Fix-JsonFiles.ps1" (
    powershell -ExecutionPolicy Bypass -File "%~dp0Fix-JsonFiles.ps1"
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo There was an issue with the JSON files. Please fix the issues before continuing.
        echo.
        pause
        exit /b 1
    )
)

echo.
echo This will open Roblox Studio with Argon and attempt to sync your plugin.
echo Make sure Roblox Studio is installed and Argon plugin is installed.
echo.
echo Project file: %~dp0DataStore-plugin.project.json
echo.
start roblox-studio://roblox/argon/sync?path=%~dp0DataStore-plugin.project.json
echo.
echo If Roblox Studio doesn't open automatically, please:
echo 1. Open Roblox Studio manually
echo 2. In the Argon plugin, click "Open Project"
echo 3. Navigate to: %~dp0
echo 4. Select "DataStore-plugin.project.json"
echo.
pause
