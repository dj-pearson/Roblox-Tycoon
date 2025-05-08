# Fix-ServerModules.ps1
# This script fixes the "server is not a valid member" errors in .server.luau files

$srcFolder = "c:\Users\pears\OneDrive\Documents\RobloxProject\DataStore Plugin\src"

Write-Host "=== DataStore Plugin Server Module Fix Script ===" -ForegroundColor Cyan
Write-Host "This script fixes 'server is not a valid member' errors in .server.luau files." -ForegroundColor Gray

# 1. Get list of files with "server is not a valid member" errors
$problematicFiles = @(
    "SchemaManager", 
    "SchemaValidator", 
    "PerformanceMonitor", 
    "DataVisualization", 
    "BulkOperationsManager", 
    "BulkOperationsUI", 
    "SchemaBuilderUI", 
    "SchemaEditor", 
    "SchemaVersionViewer", 
    "SessionManagementUI", 
    "DataMigrationUI", 
    "CodeGeneratorIntegration", 
    "AccessControlIntegration", 
    "DataMigrationTools", 
    "SchemaVersioning"
)

Write-Host "`nChecking for 'script.server' usage in server modules..." -ForegroundColor White
$fixedCount = 0

foreach ($baseFile in $problematicFiles) {
    $serverFile = "$baseFile.server.luau"
    $serverPath = Join-Path $srcFolder $serverFile
    
    if (Test-Path $serverPath) {
        $content = Get-Content $serverPath -Raw
        
        # Check if file contains script.server references
        $patternA = "require\(script\.server\)"
        $patternB = "script\.server\b"
        
        if ($content -match $patternA -or $content -match $patternB) {
            Write-Host "  - Found script.server reference in $serverFile" -ForegroundColor Yellow
            
            # Replace all script.server references with appropriate pattern
            $updatedContent = $content -replace "require\(script\.server\)", "require(script)"
            $updatedContent = $updatedContent -replace "script\.server\b", "script"
            
            Set-Content $serverPath $updatedContent -NoNewline
            Write-Host "    - Fixed script.server references in $serverFile" -ForegroundColor Green
            $fixedCount++
        }
    }
    else {
        Write-Host "  - File not found: $serverFile" -ForegroundColor Red
    }
}

Write-Host "`nFixed $fixedCount files with script.server references" -ForegroundColor Cyan

# 2. Now examine the .luau re-export files to ensure they're correctly forwarding
Write-Host "`nChecking re-export files for correct forwarding pattern..." -ForegroundColor White
$reexportFixedCount = 0

foreach ($baseFile in $problematicFiles) {
    $reexportFile = "$baseFile.luau"
    $reexportPath = Join-Path $srcFolder $reexportFile
    
    if (Test-Path $reexportPath) {
        $content = Get-Content $reexportPath -Raw
        $correctPattern = "return require\(script\.Parent:FindFirstChild\(`"$baseFile\.server`"\)\)"
        
        if ($content -notmatch [regex]::Escape($correctPattern)) {
            # Create proper re-export content
            $newContent = @"
--luau
-- DataStore Plugin/$reexportFile
-- This is a re-export file that forwards to the server version

-- Use direct reference to the server script instead of script.server
return require(script.Parent:FindFirstChild("$baseFile.server"))
"@
            Set-Content $reexportPath $newContent -NoNewline
            Write-Host "  - Updated re-export file: $reexportFile" -ForegroundColor Green
            $reexportFixedCount++
        }
    }
    else {
        # Create new re-export file
        $newContent = @"
--luau
-- DataStore Plugin/$reexportFile
-- This is a re-export file that forwards to the server version

-- Use direct reference to the server script instead of script.server
return require(script.Parent:FindFirstChild("$baseFile.server"))
"@
        Set-Content $reexportPath $newContent -NoNewline
        Write-Host "  - Created new re-export file: $reexportFile" -ForegroundColor Green
        $reexportFixedCount++
    }
}

Write-Host "`nFixed $reexportFixedCount re-export files" -ForegroundColor Cyan

# 3. Add special handling for files that might require extra attention
Write-Host "`nApplying special fixes for specific modules..." -ForegroundColor White

# Look for any modules that might have custom require patterns
$serverFiles = Get-ChildItem -Path $srcFolder -Filter "*.server.luau"
$specialFixCount = 0

foreach ($file in $serverFiles) {
    $content = Get-Content $file.FullName -Raw
    
    # Look for complex script.server patterns that might be missed
    if ($content -match "script\.server\.[\w]+") {
        Write-Host "  - Found complex script.server reference in $($file.Name)" -ForegroundColor Yellow
        
        # Replace with appropriate pattern
        $updatedContent = $content -replace "script\.server\.([\w]+)", "script.`$1"
        Set-Content $file.FullName $updatedContent -NoNewline
        Write-Host "    - Fixed complex script.server references in $($file.Name)" -ForegroundColor Green
        $specialFixCount++
    }
}

Write-Host "`nApplied special fixes to $specialFixCount files" -ForegroundColor Cyan

Write-Host "`n=== Server module fixes completed! ===" -ForegroundColor Cyan
Write-Host "Total fixes:" -ForegroundColor White
Write-Host "  - Server module fixes: $fixedCount" -ForegroundColor White
Write-Host "  - Re-export file fixes: $reexportFixedCount" -ForegroundColor White
Write-Host "  - Special pattern fixes: $specialFixCount" -ForegroundColor White
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Rebuild and test the plugin in Roblox Studio" -ForegroundColor Yellow
Write-Host "2. Check for any remaining errors in the output log" -ForegroundColor Yellow
