# Fix-DataStorePluginComplete.ps1
# This is a comprehensive script that applies all fixes to the DataStore Plugin

Write-Host "=== DataStore Plugin Complete Fix Script ===" -ForegroundColor Cyan
Write-Host "This script will apply all fixes to make the plugin work properly in Roblox" -ForegroundColor Cyan
Write-Host "Starting fixes..." -ForegroundColor Yellow

# Step 1: Remove BOM characters from all Lua files
Write-Host "`nStep 1: Removing BOM characters from all Lua files..." -ForegroundColor Green

$bomFiles = Get-ChildItem -Path ".\DataStore Plugin\src" -Filter "*.luau" -Recurse | ForEach-Object {
    $content = Get-Content -Path $_.FullName -Raw
    # Check for BOM
    if ($content.Length -gt 3 -and [byte[]]($content[0..2]) -eq @(239, 187, 191)) {
        # Remove BOM
        $newContent = $content.Substring(3)
        Set-Content -Path $_.FullName -Value $newContent -Encoding UTF8
        Write-Host "  Removed BOM from $($_.Name)" -ForegroundColor Yellow
    }
}

# Step 2: Create re-export files for any server scripts that don't have them
Write-Host "`nStep 2: Creating re-export files for server scripts..." -ForegroundColor Green

$serverFiles = Get-ChildItem -Path ".\DataStore Plugin\src" -Filter "*.server.luau" -Recurse
foreach ($serverFile in $serverFiles) {
    $baseName = $serverFile.BaseName -replace "\.server$", ""
    $baseFilePath = Join-Path $serverFile.Directory.FullName "$baseName.luau"
    
    if (-not (Test-Path $baseFilePath)) {
        $reexportContent = @"
--luau
-- DataStore Plugin/$baseName.luau
-- This is a re-export file that properly references the server script in Roblox

-- In Roblox, the server script will be named "$baseName" 
-- without the .server extension
return require(script.Parent:FindFirstChild("$baseName"))
"@
        Set-Content -Path $baseFilePath -Value $reexportContent -Encoding UTF8
        Write-Host "  Created re-export file: $baseName.luau" -ForegroundColor Yellow
    }
}

# Step 3: Fix all require statements in server scripts to use FindFirstChild
Write-Host "`nStep 3: Fixing all require statements in server scripts..." -ForegroundColor Green

$allFiles = Get-ChildItem -Path ".\DataStore Plugin\src" -Filter "*.luau" -Recurse
$updatedFiles = 0

foreach ($file in $allFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $updated = $false
    
    # Fix requires using dot notation to module names without extensions
    $pattern = 'require\(script\.Parent\.([^\.:\)]+)\)'
    if ($content -match $pattern) {
        $newContent = $content -replace $pattern, 'require(script.Parent:FindFirstChild("$1"))'
        if ($newContent -ne $content) {
            Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
            $updated = $true
        }
    }
    
    # Fix requires in init.server.luau which reference script directly
    $pattern = 'require\(script\.([^\.:\)]+)\)'
    if ($content -match $pattern) {
        $newContent = $content -replace $pattern, 'require(script:FindFirstChild("$1"))'
        if ($newContent -ne $content) {
            Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
            $updated = $true
        }
    }
    
    if ($updated) {
        $updatedFiles++
        Write-Host "  Updated imports in $($file.Name)" -ForegroundColor Yellow
    }
}

Write-Host "  Updated imports in $updatedFiles files" -ForegroundColor Yellow

# Step 4: Create documentation
Write-Host "`nStep 4: Checking if documentation exists..." -ForegroundColor Green

$docPath = ".\DataStore Plugin\DataStore-Plugin-Module-Structure.md"
if (-not (Test-Path $docPath)) {
    Write-Host "  Creating documentation file..." -ForegroundColor Yellow
    
    $docContent = @"
# DataStore Plugin Module Structure Documentation

## Overview
This document explains the module structure of the DataStore Plugin and how the files are organized to work properly in Roblox Studio after syncing from VS Code.

## File Structure Conventions

### VS Code to Roblox Mapping
When files are synced from VS Code to Roblox Studio, the following transformations occur:

| VS Code File | Roblox Script Type |
|--------------|-------------------|
| `ModuleName.server.luau` | ServerScript named `ModuleName` |
| `ModuleName.luau` | ModuleScript named `ModuleName` |
| `ModuleName.client.luau` | LocalScript named `ModuleName` |

### Module Structure
The DataStore Plugin uses a dual-file approach for each module:

1. **Server Implementation Files** (`*.server.luau`):
   - These contain the actual implementation of the module functionality
   - In Roblox, they become ServerScripts named without the `.server` extension

2. **Re-export Files** (`*.luau`):
   - These are lightweight wrapper files that import and re-export the server implementation
   - They allow other files to refer to modules without having to know if a module is a server script
   - They use `script.Parent:FindFirstChild()` to locate the server script with the same base name

## Import Pattern

### Server-to-Server Imports
When a server script needs to import another server script, it should use:

```lua
local Module = require(script.Parent:FindFirstChild("ModuleName"))
```

This pattern works because:
1. It looks for the script in the same parent folder
2. It uses the base name without the `.server` extension (which is how the script appears in Roblox)
3. `FindFirstChild()` makes it resilient to changes in script type (ModuleScript/ServerScript)

### Module-to-Server Imports
When a module script needs to import a server script, it should use the same pattern:

```lua
local Module = require(script.Parent:FindFirstChild("ModuleName"))
```

### Re-export Pattern
All re-export files follow this pattern:

```lua
--luau
-- DataStore Plugin/ModuleName.luau
-- This is a re-export file that properly references the server script in Roblox

-- In Roblox, the server script will be named "ModuleName" 
-- without the .server extension
return require(script.Parent:FindFirstChild("ModuleName"))
```

## Common Issues and Solutions

### "server is not a valid member" Error
This error occurs when code tries to reference `.server` on a script, which doesn't exist in Roblox:

```lua
-- Incorrect:
local Module = require(script.Parent.ModuleName.server)

-- Correct:
local Module = require(script.Parent:FindFirstChild("ModuleName"))
```

### Nil Reference Errors
These occur when code tries to use a module before it's properly imported:

```lua
-- Incorrect:
function DataExplorer.initMultiServerCoordinationUI()
    -- DataExplorer wasn't imported

-- Correct:
local DataExplorer = require(script.Parent:FindFirstChild("DataExplorer"))
function DataExplorer.initMultiServerCoordinationUI()
```

### UTF-8 BOM Issues
Files with BOM markers can cause syntax errors in Luau. These can be fixed by running:

```powershell
.\Remove-BOM.ps1
```

## Maintenance Guidelines

1. Always create both `.server.luau` and `.luau` versions for each module
2. Use the re-export pattern consistently
3. When importing modules, use the `:FindFirstChild()` pattern
4. Avoid hardcoding `.server` in require statements
5. When adding new modules, follow the existing pattern
6. Regularly run the validation scripts to ensure consistency

---

*Created: May 7, 2025*
"@

    Set-Content -Path $docPath -Value $docContent -Encoding UTF8
    Write-Host "  Documentation created: DataStore-Plugin-Module-Structure.md" -ForegroundColor Green
} else {
    Write-Host "  Documentation already exists" -ForegroundColor Green
}

Write-Host "`n=== All fixes completed successfully! ===" -ForegroundColor Cyan
Write-Host "The DataStore Plugin should now work properly when synced to Roblox Studio." -ForegroundColor Cyan
