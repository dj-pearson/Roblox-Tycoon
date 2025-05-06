@echo off
SETLOCAL EnableDelayedExpansion

echo ====================================================
echo    Syncing DataStore Plugin with Rojo
echo ====================================================
echo.

REM Check if Rojo is installed
where rojo >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Rojo is not available in the system PATH.
    echo Please install Rojo using Aftman or another method.
    pause
    exit /b 1
) else (
    echo Rojo found in PATH.
)

echo.
echo ====================================================
echo    Building DataStore Plugin with Rojo
echo ====================================================
echo.

rojo build "rojo-plugin-detailed.project.json" --output "DataStorePlugin.rbxmx"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Failed to build the plugin. See errors above.
    pause
    exit /b 1
)

echo.
echo ====================================================
echo    Serving the plugin project - Connect in Studio
echo ====================================================
echo.

echo The plugin project is now being served. Please:
echo 1. Open Roblox Studio
echo 2. Make sure the Rojo plugin is installed in Studio
echo 3. Connect to this server using the Rojo plugin in Studio
echo.
echo Press Ctrl+C to stop serving when done.
echo.

rojo serve "rojo-plugin-detailed.project.json"

echo.
echo Sync process completed.
echo.

pause