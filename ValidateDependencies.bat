@echo off
echo Validating DataStore Plugin dependencies...
echo.

set PLUGIN_DIR=c:\Users\dpearson\OneDrive\Documents\RobloxProject\DataStore Plugin
set MISSING_COUNT=0

REM List of required dependencies from init.server.luau
set DEPS=DataStoreManager PerformanceMonitor SchemaManager SessionManager CacheManager SchemaValidator SecurityManager DataVisualization StyleGuide SchemaEditor MonitoringDashboard MonitoringDashboardUI DataMigrationTools MultiServerCoordination MultiServerCoordinationUI PerformanceAnalyzer PerformanceAnalyzerUI CachingSystemUI LoadTesting CodeGenerator AccessControl APIIntegration

echo Checking dependencies:
echo -------------------

for %%d in (%DEPS%) do (
    if exist "%PLUGIN_DIR%\%%d.server.luau" (
        echo [FOUND] %%d.server.luau
    ) else (
        if exist "%PLUGIN_DIR%\%%d.luau" (
            echo [WARNING] %%d.luau exists but %%d.server.luau is missing
        ) else (
            echo [MISSING] Neither %%d.server.luau nor %%d.luau exists
            set /a MISSING_COUNT+=1
        )
    )
)

echo.
echo Validation complete.
if %MISSING_COUNT% GTR 0 (
    echo [WARNING] %MISSING_COUNT% dependencies are missing. Please check the output above.
) else (
    echo [SUCCESS] All dependencies appear to be available.
)

echo.
echo Note: For any .luau files without corresponding .server.luau versions,
echo you may need to rename them or create server versions.
echo.
pause
