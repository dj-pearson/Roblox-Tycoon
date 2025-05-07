@echo off
REM BuildDataStorePlugin.bat
REM This script builds the DataStore Plugin for Roblox Studio

echo Building DataStore Plugin...

REM Configuration
set SOURCE_FOLDER=DataStore Plugin
set OUTPUT_FILE=DataStorePlugin.rbxmx

REM Try to use Rojo if available
where rojo >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo Using Rojo to build the plugin...
    
    REM Create a simple project file
    echo {                                       > temp_project.json
    echo   "name": "DataStorePlugin",           >> temp_project.json
    echo   "tree": {                            >> temp_project.json
    echo     "$": {                             >> temp_project.json
    echo       "path": "%SOURCE_FOLDER%"        >> temp_project.json
    echo     }                                  >> temp_project.json
    echo   }                                    >> temp_project.json
    echo }                                      >> temp_project.json
    
    rojo build temp_project.json --output %OUTPUT_FILE%
    del temp_project.json
) else (
    echo Rojo not found, using alternate build method...
    
    REM Use PowerShell to package the plugin
    powershell -Command "& {Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::CreateFromDirectory('%SOURCE_FOLDER%', 'temp.zip'); Move-Item -Force 'temp.zip' '%OUTPUT_FILE%'}"
    
    echo Warning: For best results, install Rojo (https://rojo.space)
)

echo Copying to Roblox Plugins folder...
set PLUGINS_FOLDER=%LOCALAPPDATA%\Roblox\Plugins

if exist "%PLUGINS_FOLDER%" (
    copy /Y %OUTPUT_FILE% "%PLUGINS_FOLDER%\"
    echo Plugin installed to Roblox Plugins folder.
) else (
    echo Roblox Plugins folder not found at: %PLUGINS_FOLDER%
    echo You'll need to manually copy %OUTPUT_FILE% to your Roblox Plugins folder.
)

echo Build complete! Plugin file created: %OUTPUT_FILE%
echo.
echo To use the plugin:
echo 1. Open Roblox Studio
echo 2. The plugin should be available in the Plugins tab
echo.
echo If the plugin doesn't appear, restart Roblox Studio.

pause
