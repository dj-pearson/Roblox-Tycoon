@echo off
echo Setting up environment for Argon...
echo.

REM Set the known Node.js path directly
set NODE_PATH=C:\Program Files\nodejs
set NODE_CMD="%NODE_PATH%\node.exe"
set PATH=%NODE_PATH%;%PATH%

echo Checking Node.js installation...

if exist %NODE_CMD% (
    echo Found Node.js at: %NODE_PATH%
    goto :FOUND_NODE
) else (
    echo ERROR: Node.js not found at %NODE_PATH%
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

:FOUND_NODE
echo NODE_PATH set to: %NODE_PATH%
echo Node.js version:
%NODE_CMD% -v

REM Also add Argon bin to PATH
set PATH=%NODE_PATH%;%USERPROFILE%\.argon\bin;%PATH%
echo PATH updated with Node.js and Argon paths.

echo.
echo Starting Argon sync with proper environment...
echo Current directory: %CD%
echo Project directory: %~dp0
echo.

REM Check for blank project files and fix them if needed
if exist "%~dp0Fix-JsonFiles.ps1" (
    echo Checking and fixing JSON files...
    powershell -ExecutionPolicy Bypass -File "%~dp0Fix-JsonFiles.ps1"
)

REM Check which project file to use
if "%1"=="main" (
    echo Syncing main project with: %~dp0main.project.json
    start roblox-studio://roblox/argon/sync?path=%~dp0main.project.json
) else if "%1"=="default" (
    echo Syncing default project with: %~dp0default.project.json
    start roblox-studio://roblox/argon/sync?path=%~dp0default.project.json
) else (
    echo Syncing DataStore plugin with: %~dp0DataStore-plugin.project.json
    start roblox-studio://roblox/argon/sync?path=%~dp0DataStore-plugin.project.json
)

echo.
echo Argon sync initiated!
echo If Roblox Studio doesn't open automatically, please:
echo 1. Open Roblox Studio manually
echo 2. In the Argon plugin, click "Open Project"
echo 3. Navigate to: %~dp0
echo 4. Select the appropriate project.json file
echo.
pause
