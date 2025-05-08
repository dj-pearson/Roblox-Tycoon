@echo off
echo Recreating JSON files from scratch...
powershell -ExecutionPolicy Bypass -File "Recreate-JSON-Files.ps1"
echo.
echo Process complete. Press any key to exit.
pause > nul
