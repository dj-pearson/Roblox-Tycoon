@echo off
REM Start-Rojo-Fixed.bat - Wrapper to run the PowerShell script

echo Starting Rojo Server...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Start-Rojo-Fixed.ps1"
pause
