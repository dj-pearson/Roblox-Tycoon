@echo off
echo Roblox Argon Setup and Sync Utility
echo ==================================
echo.

REM Set the known Node.js path directly
set NODE_PATH=C:\Program Files\nodejs
set NODE_CMD="%NODE_PATH%\node.exe"
set NPM_CMD="%NODE_PATH%\npm.cmd"
set PATH=%NODE_PATH%;%PATH%

echo Checking Node.js installation...

if exist %NODE_CMD% (
    echo Found Node.js at: %NODE_PATH%
) else (
    echo ERROR: Node.js not found at %NODE_PATH%
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

echo Node.js version:
%NODE_CMD% -v

echo.
echo Checking npm installation...
if exist %NPM_CMD% (
    echo Found npm at: %NODE_PATH%
) else (
    echo ERROR: npm not found at %NODE_PATH%
    
    REM Try in AppData
    set NPM_CMD="%APPDATA%\npm\npm.cmd"
    if exist %NPM_CMD% (
        echo Found npm at: %APPDATA%\npm
    ) else {
        echo ERROR: npm not found in common locations
        echo Please repair your Node.js installation
        pause
        exit /b 1
    )
)

echo npm version:
%NPM_CMD% -v

echo.
echo Checking for Argon...
set ARGON_PATH=%USERPROFILE%\.argon\bin
if exist "%ARGON_PATH%" (
    echo Argon appears to be installed at: %ARGON_PATH%
) else (
    echo Argon does not appear to be installed.
    echo.
    set /p INSTALL_ARGON=Would you like to install Argon now? (Y/N): 
    if /i "%INSTALL_ARGON%"=="Y" (
        echo Installing Argon...
        %NPM_CMD% install -g @argon/cli
    ) else (
        echo Skipping Argon installation.
        echo Please install Argon manually with: npm install -g @argon/cli
    )
)

echo.
echo Setting up environment...
set PATH=%NODE_PATH%;%ARGON_PATH%;%PATH%

echo.
echo What would you like to sync?
echo 1. DataStore Plugin
echo 2. Main Project (main.project.json - Updated Plugins structure)
echo 3. Default Project (default.project.json - Original project)
echo 4. Exit
echo.
set /p CHOICE=Enter your choice (1-4): 

if "%CHOICE%"=="1" (
    echo.
    echo Cleaning and preparing DataStore Plugin project file...
    powershell -ExecutionPolicy Bypass -File "%~dp0Clean-JsonFiles.ps1"
    
    echo.
    echo Syncing DataStore Plugin...
    echo Project file: %~dp0DataStore-plugin.project.json
    start roblox-studio://roblox/argon/sync?path=%~dp0DataStore-plugin.project.json
) else if "%CHOICE%"=="2" (
    echo.
    echo Cleaning and preparing Main Project file...
    powershell -ExecutionPolicy Bypass -File "%~dp0Clean-JsonFiles.ps1"
    
    echo.
    echo Syncing Main Project...
    echo Project file: %~dp0main.project.json
    start roblox-studio://roblox/argon/sync?path=%~dp0main.project.json
) else if "%CHOICE%"=="3" (
    echo.
    echo Cleaning and preparing Default Project file...
    powershell -ExecutionPolicy Bypass -File "%~dp0Clean-JsonFiles.ps1"
    
    echo.
    echo Syncing Default Project...
    echo Project file: %~dp0default.project.json
    start roblox-studio://roblox/argon/sync?path=%~dp0default.project.json
) else (
    echo Exiting...
    exit /b 0
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
