@echo off
setlocal enabledelayedexpansion

echo Argon Diagnostic and Fix Utility
echo ================================
echo.

REM Set Node.js path - try to detect it first
set NODE_PATH=C:\Program Files\nodejs
if not exist "%NODE_PATH%\node.exe" (
    set NODE_PATH=C:\Program Files (x86)\nodejs
)
if not exist "%NODE_PATH%\node.exe" (
    set NODE_PATH=%USERPROFILE%\AppData\Roaming\npm
)
if not exist "%NODE_PATH%\node.exe" (
    set NODE_PATH=%LOCALAPPDATA%\Programs\nodejs
)

REM Set Path to include Node.js and Aftman
set PATH=%NODE_PATH%;%USERPROFILE%\.aftman\bin;%PATH%

echo Step 1: Checking JSON files for BOM characters
powershell -ExecutionPolicy Bypass -File "Quick-Fix-JSON.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Error encountered when fixing JSON files
)

echo.
echo Step 2: Testing Node.js installation
echo.
where node
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Node.js not found in PATH.
    echo Make sure Node.js is installed from https://nodejs.org/
    echo.
    echo Attempting to use detected Node.js at %NODE_PATH%...
    if exist "%NODE_PATH%\node.exe" (
        echo Found Node.js at %NODE_PATH%, adding to PATH
        "%NODE_PATH%\node.exe" --version
    ) else (
        echo Node.js not found. Please install it first.
        goto :end
    )
) else (
    node --version
    echo Node.js is properly installed and in PATH
)

echo.
echo Step 3: Checking Aftman and Argon installation
echo.
where aftman
if %ERRORLEVEL% NEQ 0 (
    echo Aftman not found in PATH.
    echo You may need to install Aftman first.
) else (
    aftman --version
    echo.
    echo Ensuring tools are installed with Aftman...
    aftman install
)

echo.
echo Step 4: Running stack overflow analysis
echo.
powershell -ExecutionPolicy Bypass -File "Fix-StackOverflow.ps1"

echo.
echo Step 5: Setup complete!
echo.
echo You can now try running Argon again:
echo 1. Use Start-Argon.bat to run Argon with proper Node.js config
echo 2. If issues persist, check the recommendations from the stack overflow analysis
echo.
echo NOTE: To run Argon directly, you should ensure Node.js is in your PATH:
echo    SET PATH="%NODE_PATH%;%%PATH%%"
echo    argon serve
echo.

:end
pause
