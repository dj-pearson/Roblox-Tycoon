@echo off
echo Running aggressive JSON fixer for Argon...
powershell -ExecutionPolicy Bypass -File "Fix-All-JSON-Files.ps1"
echo.
echo Process complete. Press any key to exit.
pause > nul
