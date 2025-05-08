@echo off
echo NodeJS JSON Creator
echo =================
echo.

echo This tool will use Node.js to create clean JSON files without BOM characters
echo.

REM Check if Node.js is available
where node >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Node.js not found in PATH!
    echo.
    
    REM Try to find Node.js in common locations
    set NODE_PATHS=^
    "C:\Program Files\nodejs\node.exe" ^
    "C:\Program Files (x86)\nodejs\node.exe" ^
    "%USERPROFILE%\AppData\Roaming\npm\node.exe" ^
    "%LOCALAPPDATA%\Programs\nodejs\node.exe"
    
    set NODE_FOUND=0
    
    for %%p in (%NODE_PATHS%) do (
        if exist %%p (
            echo Found Node.js at: %%p
            set NODE_PATH=%%p
            set NODE_FOUND=1
            goto node_found
        )
    )
    
    :node_found
    if %NODE_FOUND% EQU 0 (
        echo ERROR: Cannot find Node.js installation.
        echo Please install Node.js from https://nodejs.org/
        pause
        exit /b 1
    ) else (
        echo Adding Node.js to PATH for this session...
        set "PATH=%NODE_PATH:~0,-8%;%PATH%"
    )
)

REM Run the Node.js script
echo Running Node.js script to create clean JSON files...
node create-json-files.js

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to create JSON files with Node.js
    echo.
    echo Trying direct approach with echo commands instead...
    echo.
    
    echo Fixing default.project.json...
    echo { > default.project.json
    echo   "name": "RobloxProject", >> default.project.json
    echo   "tree": { >> default.project.json
    echo     "$className": "DataModel", >> default.project.json
    echo     "ReplicatedStorage": { >> default.project.json
    echo       "shared": { >> default.project.json
    echo         "$path": "src/shared" >> default.project.json
    echo       }, >> default.project.json
    echo       "DataStorePlugin": { >> default.project.json
    echo         "$path": "DataStore Plugin" >> default.project.json
    echo       } >> default.project.json
    echo     }, >> default.project.json
    echo     "ServerScriptService": { >> default.project.json
    echo       "server": { >> default.project.json
    echo         "$path": "src/server" >> default.project.json
    echo       } >> default.project.json
    echo     }, >> default.project.json
    echo     "StarterPlayer": { >> default.project.json
    echo       "StarterPlayerScripts": { >> default.project.json
    echo         "client": { >> default.project.json
    echo           "$path": "src/client" >> default.project.json
    echo         } >> default.project.json
    echo       } >> default.project.json
    echo     } >> default.project.json
    echo   } >> default.project.json
    echo } >> default.project.json
    
    echo Fixing DataStore-plugin.project.json...
    echo { > DataStore-plugin.project.json
    echo   "name": "DataStorePlugin", >> DataStore-plugin.project.json
    echo   "tree": { >> DataStore-plugin.project.json
    echo     "$className": "DataModel", >> DataStore-plugin.project.json
    echo     "ReplicatedStorage": { >> DataStore-plugin.project.json
    echo       "DataStorePlugin": { >> DataStore-plugin.project.json
    echo         "$path": "DataStore Plugin" >> DataStore-plugin.project.json
    echo       } >> DataStore-plugin.project.json
    echo     } >> DataStore-plugin.project.json
    echo   } >> DataStore-plugin.project.json
    echo } >> DataStore-plugin.project.json
    
    echo Fixing clean-default.project.json...
    echo { > clean-default.project.json
    echo   "name": "RobloxProject-Clean", >> clean-default.project.json
    echo   "tree": { >> clean-default.project.json
    echo     "$className": "DataModel", >> clean-default.project.json
    echo     "ReplicatedStorage": { >> clean-default.project.json
    echo       "shared": { >> clean-default.project.json
    echo         "$path": "src/shared" >> clean-default.project.json
    echo       } >> clean-default.project.json
    echo     }, >> clean-default.project.json
    echo     "ServerScriptService": { >> clean-default.project.json
    echo       "server": { >> clean-default.project.json
    echo         "$path": "src/server" >> clean-default.project.json
    echo       } >> clean-default.project.json
    echo     }, >> clean-default.project.json
    echo     "StarterPlayer": { >> clean-default.project.json
    echo       "StarterPlayerScripts": { >> clean-default.project.json
    echo         "client": { >> clean-default.project.json
    echo           "$path": "src/client" >> clean-default.project.json
    echo         } >> clean-default.project.json
    echo       } >> clean-default.project.json
    echo     } >> clean-default.project.json
    echo   } >> clean-default.project.json
    echo } >> clean-default.project.json
    
    echo Fixing clean-plugin.project.json...
    echo { > clean-plugin.project.json
    echo   "name": "CleanPlugin", >> clean-plugin.project.json
    echo   "tree": { >> clean-plugin.project.json
    echo     "$className": "DataModel", >> clean-plugin.project.json
    echo     "ReplicatedStorage": { >> clean-plugin.project.json
    echo       "DataStorePlugin": { >> clean-plugin.project.json
    echo         "$path": "DataStore Plugin/clean" >> clean-plugin.project.json
    echo       } >> clean-plugin.project.json
    echo     } >> clean-plugin.project.json
    echo   } >> clean-plugin.project.json
    echo } >> clean-plugin.project.json
    
    echo Fixing enhanced.project.json...
    echo { > enhanced.project.json
    echo     "name": "RobloxProject-Enhanced", >> enhanced.project.json
    echo     "tree": { >> enhanced.project.json
    echo         "$className": "DataModel", >> enhanced.project.json
    echo         "ReplicatedStorage": { >> enhanced.project.json
    echo             "shared": { >> enhanced.project.json
    echo                 "$path": "src/shared" >> enhanced.project.json
    echo             }, >> enhanced.project.json
    echo             "DataStorePlugin": { >> enhanced.project.json
    echo                 "$path": "DataStore Plugin" >> enhanced.project.json
    echo             } >> enhanced.project.json
    echo         }, >> enhanced.project.json
    echo         "ServerScriptService": { >> enhanced.project.json
    echo             "server": { >> enhanced.project.json
    echo                 "$path": "src/server" >> enhanced.project.json
    echo             } >> enhanced.project.json
    echo         }, >> enhanced.project.json
    echo         "StarterPlayer": { >> enhanced.project.json
    echo             "StarterPlayerScripts": { >> enhanced.project.json
    echo                 "client": { >> enhanced.project.json
    echo                     "$path": "src/client" >> enhanced.project.json
    echo                 } >> enhanced.project.json
    echo             } >> enhanced.project.json
    echo         }, >> enhanced.project.json
    echo         "Workspace": { >> enhanced.project.json
    echo             "$properties": { >> enhanced.project.json
    echo                 "FilteringEnabled": true >> enhanced.project.json
    echo             } >> enhanced.project.json
    echo         } >> enhanced.project.json
    echo     } >> enhanced.project.json
    echo } >> enhanced.project.json
)

echo.
echo Files created. 
echo Trying to run Argon...
echo.

REM Get Node.js path
where node >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Node.js is still not in PATH
    pause
    exit /b 1
)

REM Add aftman to PATH
set PATH=%USERPROFILE%\.aftman\bin;%PATH%

REM Start Argon
echo Starting Argon...
argon serve

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to start Argon
    echo.
    echo Please check:
    echo 1. Is Node.js properly installed?
    echo 2. Is Argon installed via aftman?
    echo 3. Are your JSON files valid?
    echo.
)

pause
