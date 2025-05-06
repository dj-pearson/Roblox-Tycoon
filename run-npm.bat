@echo off
echo Setting up Node.js environment for Roblox project...
echo.

REM Set the known Node.js path directly
set NODE_PATH=C:\Program Files\nodejs
set NODE_CMD="%NODE_PATH%\node.exe"
set NPM_CMD="%NODE_PATH%\npm.cmd"
set PATH=%NODE_PATH%;%PATH%

if exist %NODE_CMD% (
    echo Found Node.js at: %NODE_PATH%
) else (
    echo ERROR: Node.js not found at %NODE_PATH%
    exit /b 1
)

if exist %NPM_CMD% (
    echo Found npm at: %NODE_PATH%
) else (
    echo ERROR: npm not found at %NODE_PATH%
    
    REM Try in AppData
    set NPM_CMD="%APPDATA%\npm\npm.cmd"
    if exist %NPM_CMD% (
        echo Found npm at: %APPDATA%\npm
    ) else (
        echo ERROR: npm not found in common locations
        exit /b 1
    )
)

echo.
echo Node.js version:
%NODE_CMD% -v

echo.
echo NPM version:
%NPM_CMD% -v

echo.
echo Running npm command: %*
echo.

REM Run the npm command
%NPM_CMD% %*

echo.
echo Done!
pause
