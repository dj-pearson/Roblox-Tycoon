@echo off
echo Checking for stack overflow issues...
powershell -ExecutionPolicy Bypass -File "Fix-StackOverflow.ps1"
pause
