@echo off
SETLOCAL EnableDelayedExpansion

echo ====================================================
echo    Testing DataStore Plugin Sync with Argon
echo ====================================================
echo.

REM Check if Node.js is installed and available
where node >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Node.js is not available in the system PATH.
    echo.
    
    REM Try to find Node.js in Program Files
    set NODE_PATH=C:\Program Files\nodejs
    
    if exist "!NODE_PATH!\node.exe" (
        echo Found Node.js at !NODE_PATH!
        set NODE_CMD="!NODE_PATH!\node.exe"
        set NPM_CMD="!NODE_PATH!\npm.cmd"
    ) else (
        REM Try to find Node.js in Program Files (x86)
        set NODE_PATH=C:\Program Files (x86)\nodejs
        
        if exist "!NODE_PATH!\node.exe" (
            echo Found Node.js at !NODE_PATH!
            set NODE_CMD="!NODE_PATH!\node.exe"
            set NPM_CMD="!NODE_PATH!\npm.cmd"
        ) else (
            echo Could not find Node.js installation. Please install Node.js or update your PATH.
            pause
            exit /b 1
        )
    )
) else (
    echo Node.js found in PATH
    set NODE_CMD=node
    set NPM_CMD=npm
)

REM Check if Argon is installed
echo.
echo Checking for Argon installation...
%NPM_CMD% list -g @argon/cli >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Argon CLI is not installed globally.
    echo.
    
    set /p installArgon=Do you want to install Argon CLI globally? (y/n): 
    if /i "!installArgon!"=="y" (
        echo Installing @argon/cli globally...
        %NPM_CMD% install -g @argon/cli
    ) else (
        echo Argon CLI installation skipped. Cannot proceed with synchronization.
        pause
        exit /b 1
    )
) else (
    echo Argon CLI is already installed.
)

echo.
echo ====================================================
echo    Synchronizing DataStore Plugin with Argon
echo ====================================================
echo.

echo Using project file: DataStore-plugin.project.json
echo.
echo This will synchronize ONLY the DataStore Plugin as a standalone plugin
echo.

REM Run Argon with the Plugin project file
call npx @argon/cli sync --project-file="DataStore-plugin.project.json" --watch=false

echo.
echo Synchronization completed. Check the output above for any errors.
echo.
echo If the plugin was successfully synchronized, you should be able to see it
echo in Roblox Studio under the Plugins tab.
echo.

pause
