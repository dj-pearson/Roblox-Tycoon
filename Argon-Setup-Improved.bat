@echo off
setlocal enabledelayedexpansion
echo Roblox Argon Setup and Sync Utility - Improved Version
echo ===================================================
echo.

REM Set default Node.js paths to check
set PATHS_TO_CHECK=^
"C:\Program Files\nodejs" ^
"C:\Program Files (x86)\nodejs" ^
"%USERPROFILE%\AppData\Roaming\npm" ^
"%USERPROFILE%\scoop\apps\nodejs\current" ^
"%LOCALAPPDATA%\Programs\nodejs"

set NODE_FOUND=0
set NODE_PATH=

REM Check for Node.js in common locations
echo Searching for Node.js installation...
for %%p in (%PATHS_TO_CHECK%) do (
    if exist "%%~p\node.exe" (
        set NODE_PATH=%%~p
        set NODE_FOUND=1
        echo Found Node.js at: %%~p
        goto :node_found
    )
)

:node_check_path
REM If not found in common locations, check PATH
where node.exe >nul 2>&1
if %ERRORLEVEL% equ 0 (
    for /f "tokens=*" %%i in ('where node.exe') do (
        set NODE_EXE=%%i
        for %%p in ("!NODE_EXE!\..\..") do set NODE_PATH=%%~dp
        set NODE_PATH=!NODE_PATH:~0,-1!
        set NODE_FOUND=1
        echo Found Node.js in PATH: !NODE_PATH!
        goto :node_found
    )
)

:node_not_found
if %NODE_FOUND% equ 0 (
    echo ERROR: Node.js not found.
    echo Please install Node.js from https://nodejs.org/ (LTS version recommended)
    echo After installation, run this script again.
    echo.
    echo Would you like to open the Node.js download page?
    choice /c YN /m "Open download page (Y/N)? "
    if %ERRORLEVEL% equ 1 start https://nodejs.org/en/download/
    pause
    exit /b 1
)

:node_found
set NODE_CMD="%NODE_PATH%\node.exe"
set NPM_CMD="%NODE_PATH%\npm.cmd"

REM Temporarily add Node.js to PATH for this session
set PATH=%NODE_PATH%;%PATH%

echo.
echo Node.js version:
%NODE_CMD% -v

echo.
echo NPM version:
%NPM_CMD% -v

echo.
echo Checking if Argon is installed...

REM Verify if Argon is installed
%NPM_CMD% list -g @argonlua/cli >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Argon CLI not found. Installing...
    %NPM_CMD% install -g @argonlua/cli
    if %ERRORLEVEL% neq 0 (
        echo ERROR: Failed to install Argon CLI.
        echo Please run this command manually: npm install -g @argonlua/cli
        pause
        exit /b 1
    ) else (
        echo Argon CLI installed successfully!
    )
) else (
    echo Argon CLI is already installed.
)

REM Create a permanent PATH entry for Node.js if not already there
echo.
echo Checking if Node.js is in system PATH...
echo !PATH! | findstr /i /c:"!NODE_PATH!" >nul 2>&1
if !ERRORLEVEL! equ 0 (
    echo Node.js is already in your system PATH.
) else (
    echo Adding Node.js to system PATH...
    setx PATH "!NODE_PATH!;%PATH%" /M
    echo Node.js has been added to your system PATH.
    echo Please restart any open command prompts for changes to take effect.
)

echo.
echo Creating Argon startup shortcut...
REM Create a .bat file that runs Argon in watch mode
echo @echo off > "Run-Argon-Watch.bat"
echo echo Starting Argon in watch mode... >> "Run-Argon-Watch.bat"
echo cd "%~dp0" >> "Run-Argon-Watch.bat"
echo set PATH=%NODE_PATH%;%%PATH%% >> "Run-Argon-Watch.bat"
echo npx @argonlua/cli watch >> "Run-Argon-Watch.bat"
echo pause >> "Run-Argon-Watch.bat"

echo.
echo Setup complete!
echo.
echo To start Argon sync:
echo 1. Make sure Roblox Studio is closed
echo 2. Run the "Run-Argon-Watch.bat" file
echo 3. Open Roblox Studio after Argon has started
echo.
pause
