@echo off
SETLOCAL EnableDelayedExpansion

echo ====================================================
echo    Simple Plugin Sync with Argon
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
        set PATH=!NODE_PATH!;!PATH!
        echo Added Node.js to PATH for this session
    ) else (
        REM Try to find Node.js in Program Files (x86)
        set NODE_PATH=C:\Program Files (x86)\nodejs
        
        if exist "!NODE_PATH!\node.exe" (
            echo Found Node.js at !NODE_PATH!
            set NODE_CMD="!NODE_PATH!\node.exe"
            set NPM_CMD="!NODE_PATH!\npm.cmd"
            set PATH=!NODE_PATH!;!PATH!
            echo Added Node.js to PATH for this session
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

echo.
echo Running with simple plugin configuration...
echo.

REM Run Argon with the simplified plugin project file
call npx @argon/cli sync --project-file="DataStore-plugin.project.json"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Sync failed. Try running the Fix-JsonFiles-NoBOM.ps1 script first:
    echo powershell -ExecutionPolicy Bypass -File Fix-JsonFiles-NoBOM.ps1
    echo.
)

echo.
pause
