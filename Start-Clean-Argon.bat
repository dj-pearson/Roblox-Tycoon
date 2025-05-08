@echo off
REM Start-Clean-Argon.bat - Wrapper to run the PowerShell script

echo Starting Clean Argon Server...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Start-Clean-Argon.ps1"
pause
