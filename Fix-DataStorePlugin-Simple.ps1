# Fix-DataStorePlugin-Simple.ps1
# This script applies a simpler fix to the DataStore Plugin to prevent stack overflows

Set-Location "c:\Users\pears\OneDrive\Documents\RobloxProject\DataStore Plugin"

Write-Host "DataStore Plugin Simple Fix" -ForegroundColor Green
Write-Host "-------------------------" -ForegroundColor Green

# Step 1: Remove BOM characters from all Lua files
Write-Host "Step 1: Checking for and removing BOM markers..." -ForegroundColor Cyan
$luaFiles = Get-ChildItem -Path "src" -Filter "*.luau" -Recurse
$bomRemoved = 0

foreach ($file in $luaFiles) {
    try {
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        if ($bytes.Length -gt 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
            Write-Host "  - Removing BOM from $($file.Name)" -ForegroundColor Yellow
            $noBomBytes = $bytes[3..($bytes.Length-1)]
            [System.IO.File]::WriteAllBytes($file.FullName, $noBomBytes)
            $bomRemoved++
        }
    } catch {
        Write-Host "  - Error processing $($file.Name): $_" -ForegroundColor Red
    }
}

Write-Host "  - Removed BOM from $bomRemoved files" -ForegroundColor Yellow

# Step 2: Update server scripts to use direct references without .server
Write-Host "`nStep 2: Updating server scripts to use direct references..." -ForegroundColor Cyan
$serverFiles = Get-ChildItem -Path "src" -Filter "*.server.luau" -Recurse
$serverUpdated = 0

foreach ($file in $serverFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $updated = $false
    
    # Fix references with .server suffix
    $newContent = $content -replace 'require\(script\.Parent\.(\w+)\.server\)', 'require(script.Parent.$1)'
    if ($newContent -ne $content) {
        $updated = $true
        $content = $newContent
    }
    
    # Fix references with :FindFirstChild
    $newContent = $content -replace 'require\(script\.Parent:FindFirstChild\("(\w+)"\)\)', 'require(script.Parent.$1)'
    if ($newContent -ne $content) {
        $updated = $true
        $content = $newContent
    }
    
    if ($updated) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8
        $serverUpdated++
        Write-Host "  - Updated requires in $($file.Name)" -ForegroundColor Yellow
    }
}

Write-Host "  - Updated $serverUpdated server scripts" -ForegroundColor Yellow

# Step 3: Update init.server.luau to use direct references
Write-Host "`nStep 3: Updating init.server.luau..." -ForegroundColor Cyan
$initPath = "src\init.server.luau"
if (Test-Path $initPath) {
    $content = Get-Content -Path $initPath -Raw
    $updated = $false
    
    # Fix references with .server suffix
    $newContent = $content -replace 'require\(script\.(\w+)\.server\)', 'require(script.$1)'
    if ($newContent -ne $content) {
        $updated = $true
        $content = $newContent
    }
    
    # Fix references with :FindFirstChild
    $newContent = $content -replace 'require\(script:FindFirstChild\("(\w+)"\)\)', 'require(script.$1)'
    if ($newContent -ne $content) {
        $updated = $true
        $content = $newContent
    }
    
    if ($updated) {
        Set-Content -Path $initPath -Value $content -Encoding UTF8
        Write-Host "  - Updated requires in init.server.luau" -ForegroundColor Yellow
    } else {
        Write-Host "  - No updates needed for init.server.luau" -ForegroundColor Yellow
    }
}

# Step 4: Update non-server scripts to be simple re-export files
Write-Host "`nStep 4: Simplifying non-server scripts to prevent circular dependencies..." -ForegroundColor Cyan

$nonServerFiles = Get-ChildItem -Path "src" -Filter "*.luau" -Recurse | 
    Where-Object { $_.Name -notlike "*.server.luau" -and $_.Name -notlike "*.client.luau" }

$updated = 0
$created = 0
$skipped = 0

foreach ($file in $nonServerFiles) {
    $baseName = $file.BaseName
    $serverFile = Join-Path $file.Directory.FullName "$baseName.server.luau"
    
    if (Test-Path $serverFile) {
        # Simple re-export template
        $reexportContent = @"
-- DataStore Plugin/$baseName.luau
-- Simple re-export to server version

-- This module simply returns the server version which will be available
-- when Roblox syncs the files (with no extension)
return require(script.server)
"@
        
        # Check if this is already a re-export file
        $content = Get-Content -Path $file.FullName -Raw
        if ($content -match "return require\(script\.server\)") {
            $skipped++
            continue
        }
        
        # Check if this has actual code that doesn't look like a re-export
        if ($content.Length -gt 200 -and $content -notmatch "return require\(") {
            $skipped++
            Write-Host "  - Skipping $($file.Name) - appears to be a full module" -ForegroundColor Yellow
            continue
        }
        
        Set-Content -Path $file.FullName -Value $reexportContent -Encoding UTF8
        $updated++
        Write-Host "  - Updated re-export in $($file.Name)" -ForegroundColor Yellow
    }
}

Write-Host "  - Updated $updated re-export files, skipped $skipped files" -ForegroundColor Yellow

Write-Host "`nDataStore Plugin fix completed!" -ForegroundColor Green
Write-Host "The plugin should now work properly in Argon without stack overflows." -ForegroundColor Green
