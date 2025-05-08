@echo off
REM Start-Rojo.bat - Wrapper to run the PowerShell script

echo Starting Rojo Server...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Start-Rojo.ps1"
pause
