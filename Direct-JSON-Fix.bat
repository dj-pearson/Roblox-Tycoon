@echo off
echo Running direct JSON fix for Argon...
powershell -ExecutionPolicy Bypass -File "Direct-JSON-Fix.ps1"
echo.
echo Process complete. Press any key to exit.
pause > nul
