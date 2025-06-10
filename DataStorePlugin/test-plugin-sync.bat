@echo off
echo Testing DataStorePlugin sync with Argon...
echo Using plugin.project.json instead of default.project.json

cd /d "%~dp0"
echo Current directory: %CD%

echo.
echo Starting Argon with plugin.project.json...
argon serve plugin.project.json --port 8000

pause 