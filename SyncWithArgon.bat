@echo off
echo Starting Argon synchronization for DataStore Manager Pro plugin...
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
