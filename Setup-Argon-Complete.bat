@echo off
setlocal enabledelayedexpansion
echo Roblox Argon Setup and Verification
echo ===================================
echo.

REM Check for PowerShell
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: PowerShell is required but not found.
    goto :error
)

REM Check for Node.js in various locations
echo Checking for Node.js installation...
set NODE_PATHS=^
"C:\Program Files\nodejs\node.exe" ^
"C:\Program Files (x86)\nodejs\node.exe" ^
"%USERPROFILE%\AppData\Roaming\npm\node.exe" ^
"%USERPROFILE%\scoop\apps\nodejs\current\node.exe" ^
"%LOCALAPPDATA%\Programs\nodejs\node.exe"

set NODE_FOUND=0
for %%p in (%NODE_PATHS%) do (
    if exist %%p (
        echo Found Node.js at: %%p
        set NODE_PATH=%%~dp
        set NODE_EXE=%%p
        set NODE_FOUND=1
        goto :node_found
    )
)

:node_found
if %NODE_FOUND% EQU 0 (
    echo ERROR: Node.js is not installed or not found.
    echo Please install Node.js from https://nodejs.org/
    echo After installation, run this script again.
    goto :error
)

REM Add Node.js to PATH for this session
echo Adding Node.js to PATH: %NODE_PATH%
set PATH=%NODE_PATH%;%PATH%

REM Check Node.js version
echo Checking Node.js version...
"%NODE_EXE%" --version
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to run Node.js
    goto :error
)

REM Check npm
echo Checking npm installation...
"%NODE_PATH%npm.cmd" --version
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: npm is not available. You may need to reinstall Node.js.
    goto :error
)

REM Run PowerShell script to fix JSON files
echo Running JSON fix script...
powershell -ExecutionPolicy Bypass -File "Fix-Argon-Issues.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: JSON fix script reported errors.
)

REM Check Aftman
echo Checking Aftman...
set AFTMAN_PATH=%USERPROFILE%\.aftman\bin\aftman.exe
if not exist "%AFTMAN_PATH%" (
    echo Installing Aftman...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/LPGhatguy/aftman/releases/download/v0.2.7/aftman-windows-x86_64.zip' -OutFile '%TEMP%\aftman.zip'"
    powershell -Command "Expand-Archive -Path '%TEMP%\aftman.zip' -DestinationPath '%USERPROFILE%\.aftman\bin' -Force"
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to install Aftman.
        goto :error
    )
)

REM Add Aftman to PATH
set PATH=%USERPROFILE%\.aftman\bin;%PATH%

REM Install tools via Aftman
echo Installing Rojo, Wally, and Argon via Aftman...
aftman install
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to install tools via Aftman.
    goto :error
)

REM Add Aftman bin to PATH
set PATH=%USERPROFILE%\.aftman\bin;%PATH%

REM Check if argon is installed
echo Checking for Argon...
where argon >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Argon is not found in PATH. Something went wrong with installation.
    goto :error
)

REM Start Argon
echo Starting Argon...
start cmd /k "argon serve & echo Argon is running... & echo Close this window to stop Argon."

echo.
echo Argon setup completed successfully!
echo If Argon is not working properly, try running this script again as administrator.
goto :end

:error
echo.
echo Setup failed. Please review the errors above.
pause
exit /b 1

:end
echo.
echo Setup completed.
pause
