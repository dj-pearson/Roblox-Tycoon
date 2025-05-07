# Fix-ReexportFilesComprehensive.ps1
# This script identifies and fixes all re-export files in the DataStore Plugin
# Sets up proper module resolution patterns

$srcFolder = "c:\Users\pears\OneDrive\Documents\RobloxProject\DataStore Plugin\src"

# Function to update a re-export file
function Update-ReexportFile {
    param (
        [string]$fileName
    )

    $moduleName = $fileName -replace '\.luau$', ''
    $filePath = Join-Path $srcFolder $fileName
    $serverFilePath = Join-Path $srcFolder "$moduleName.server.luau"
    
    # Only proceed if the server file exists
    if (Test-Path $serverFilePath) {
        $content = @"
--luau
-- DataStore Plugin/$fileName
-- This is a re-export file that forwards to the server version

-- Use direct reference to the server script instead of script.server
return require(script.Parent:FindFirstChild("$moduleName.server"))
"@
        
        # Check if the file already exists
        if (Test-Path $filePath) {
            $currentContent = Get-Content $filePath -Raw
            
            # Only update if the file doesn't already have the correct pattern
            if ($currentContent -notmatch "return require\(script\.Parent:FindFirstChild\(`"$moduleName\.server`"\)\)") {
                Set-Content $filePath $content -NoNewline
                Write-Host "Updated re-export file: $fileName" -ForegroundColor Green
            }
            else {
                Write-Host "File already has correct pattern: $fileName" -ForegroundColor Yellow
            }
        }
        else {
            # Create new file
            Set-Content $filePath $content -NoNewline
            Write-Host "Created new re-export file: $fileName" -ForegroundColor Green
        }
    }
    else {
        Write-Host "Server file not found for: $fileName" -ForegroundColor Red
    }
}

# Find all .server.luau files and create/update corresponding .luau re-export files
$serverFiles = Get-ChildItem -Path $srcFolder -Filter "*.server.luau" | Select-Object -ExpandProperty Name

foreach ($serverFile in $serverFiles) {
    $baseName = $serverFile -replace '\.server\.luau$', ''
    $reexportFileName = "$baseName.luau"
    
    Update-ReexportFile -fileName $reexportFileName
}

# Update the init.server.luau module resolver
$initFilePath = Join-Path $srcFolder "init.server.luau"
if (Test-Path $initFilePath) {
    $initContent = Get-Content $initFilePath -Raw
    
    $moduleResolverPattern = 'local moduleScript = script\.Parent:FindFirstChild\(moduleName\)'
    $improvedResolver = @"
    -- Try multiple approaches to find the module
    local moduleScript = nil
    
    -- Try direct reference first
    moduleScript = script.Parent:FindFirstChild(moduleName)
    
    -- If not found, try with .server suffix
    if not moduleScript then
        moduleScript = script.Parent:FindFirstChild(moduleName .. ".server")
    end
    
    -- If not found, try with .luau suffix
    if not moduleScript then
        moduleScript = script.Parent:FindFirstChild(moduleName .. ".luau")
    end
    
    -- If still not found, try with .server.luau suffix
    if not moduleScript then
        moduleScript = script.Parent:FindFirstChild(moduleName .. ".server.luau")
    end
"@
    
    # Only update if the pattern exists and hasn't been updated already
    if ($initContent -match $moduleResolverPattern -and $initContent -notmatch "Try multiple approaches to find the module") {
        $updatedContent = $initContent -replace $moduleResolverPattern, $improvedResolver
        Set-Content $initFilePath $updatedContent -NoNewline
        Write-Host "Updated init.server.luau module resolver" -ForegroundColor Green
    }
    else {
        Write-Host "Module resolver already updated or pattern not found in init.server.luau" -ForegroundColor Yellow
    }
    
    # Ensure 'elif' is replaced with 'elseif'
    $elifPattern = 'elif type\(DataMigrationTools\) == "function" then'
    if ($initContent -match $elifPattern) {
        $updatedContent = $initContent -replace $elifPattern, 'elseif type(DataMigrationTools) == "function" then'
        Set-Content $initFilePath $updatedContent -NoNewline
        Write-Host "Fixed 'elif' to 'elseif' in init.server.luau" -ForegroundColor Green
    }
}

Write-Host "`nAll re-export files have been updated!" -ForegroundColor Cyan
