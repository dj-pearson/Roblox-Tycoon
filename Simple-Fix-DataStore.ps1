# Simple-Fix-DataStore.ps1
# This script applies a simpler fix to the DataStore Plugin that won't cause stack overflows

Write-Host "=== DataStore Plugin Simple Fix Script ===" -ForegroundColor Cyan
Write-Host "Applying minimal fixes to make the plugin work without creating stack overflows..." -ForegroundColor Cyan

# Step 1: Remove any re-export .luau files that might cause circular references
Write-Host "`nStep 1: Removing re-export files that might cause circular references..." -ForegroundColor Green

$reexportPattern = 'return require\(script\.Parent(:FindFirstChild\("\w+"\)|\.\w+)\)'
$reexportFiles = Get-ChildItem -Path ".\DataStore Plugin\src" -Filter "*.luau" -Recurse | 
Where-Object { 
    $_.Name -notlike "*.server.luau" -and 
    $_.Name -notlike "*.client.luau" -and
    (Get-Content -Path $_.FullName -Raw) -match $reexportPattern
}

foreach ($file in $reexportFiles) {
    Remove-Item -Path $file.FullName -Force
    Write-Host "  Removed re-export file: $($file.Name)" -ForegroundColor Yellow
}

# Step 2: Fix require statements in server scripts to not use .server
Write-Host "`nStep 2: Fixing require statements in server scripts..." -ForegroundColor Green

$serverFiles = Get-ChildItem -Path ".\DataStore Plugin\src" -Filter "*.server.luau" -Recurse
$updatedFiles = 0

foreach ($file in $serverFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $updated = $false
    
    # Replace any references to .server in require statements
    $serverPattern = 'require\(script\.Parent\.(\w+)\.server\)'
    if ($content -match $serverPattern) {
        $newContent = $content -replace $serverPattern, 'require(script.Parent.$1)'
        if ($newContent -ne $content) {
            Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
            $updated = $true
        }
    }
    
    if ($updated) {
        $updatedFiles++
        Write-Host "  Updated requires in $($file.Name)" -ForegroundColor Yellow
    }
}

# Step 3: Update init.server.luau to use simple require statements
Write-Host "`nStep 3: Updating init.server.luau..." -ForegroundColor Green

$initPath = ".\DataStore Plugin\src\init.server.luau"
if (Test-Path $initPath) {
    $content = Get-Content -Path $initPath -Raw
    $updated = $false
    
    # Replace server extensions in require statements
    $serverPattern = 'require\(script\.(\w+)\.server\)'
    if ($content -match $serverPattern) {
        $newContent = $content -replace $serverPattern, 'require(script.$1)'
        if ($newContent -ne $content) {
            Set-Content -Path $initPath -Value $newContent -Encoding UTF8
            $updated = $true
            Write-Host "  Updated requires in init.server.luau" -ForegroundColor Yellow
        }
    }
    
    if (-not $updated) {
        Write-Host "  No updates needed for init.server.luau" -ForegroundColor Yellow
    }
}

# Step 4: Create documentation
Write-Host "`nStep 4: Creating simplified documentation..." -ForegroundColor Green

$docPath = ".\DataStore Plugin\DataStore-Plugin-Simple-Fix.md"
$docContent = @"
# DataStore Plugin Simple Fix Documentation

## Overview
This document explains the simple fix applied to the DataStore Plugin to work properly in Roblox Studio after syncing from VS Code.

## Fix Summary

The plugin had several issues:
1. Files using `.server` in require statements, which doesn't work in Roblox
2. BOM (Byte Order Mark) characters causing syntax errors
3. Possible circular dependencies causing stack overflows

## Applied Fixes

### 1. Removed `.server` References in Require Statements
Changed all require statements to not use `.server` extension:

```lua
-- Before
local Module = require(script.Parent.ModuleName.server)

-- After
local Module = require(script.Parent.ModuleName)
```

### 2. Simplified Module Structure
Rather than creating complex re-export files that can cause circular dependencies and stack overflows, we simplified the approach to use direct references.

### File Naming Convention
- Keep all files with their current extensions in VS Code:
  - `ModuleName.server.luau` for server scripts
  - `ModuleName.client.luau` for client scripts
  - `ModuleName.luau` for regular modules

### BOM Characters
If you encounter syntax errors related to BOM characters, use this command to remove them:

```powershell
Get-ChildItem -Path ".\DataStore Plugin\src" -Filter "*.luau" -Recurse | ForEach-Object {
    $content = Get-Content -Path $_.FullName -Raw
    if ($content.Length -gt 3 -and [byte[]]($content[0..2]) -eq @(239, 187, 191)) {
        $newContent = $content.Substring(3)
        Set-Content -Path $_.FullName -Value $newContent -Encoding UTF8
    }
}
```

## Roblox Sync Behavior
When files are synced to Roblox:
- `ModuleName.server.luau` becomes a ServerScript named `ModuleName` (no `.server`)
- `ModuleName.luau` becomes a ModuleScript named `ModuleName`
- `ModuleName.client.luau` becomes a LocalScript named `ModuleName` (no `.client`)

This means you don't need the `.server` part in require statements.

---

*Created: May 7, 2025*
"@

Set-Content -Path $docPath -Value $docContent -Encoding UTF8
Write-Host "  Created documentation: DataStore-Plugin-Simple-Fix.md" -ForegroundColor Green

# Step 5: Check for BOM characters
Write-Host "`nStep 5: Checking for BOM characters in Lua files..." -ForegroundColor Green

$bomFiles = Get-ChildItem -Path ".\DataStore Plugin\src" -Filter "*.luau" -Recurse | ForEach-Object {
    $content = Get-Content -Path $_.FullName -Raw -Encoding Byte
    # Check for BOM
    if ($content.Length -gt 3 -and $content[0] -eq 239 -and $content[1] -eq 187 -and $content[2] -eq 191) {
        Write-Host "  Found BOM in $($_.Name) - removing..." -ForegroundColor Yellow
        $newContent = [System.Text.Encoding]::UTF8.GetString($content[3..$content.Length])
        Set-Content -Path $_.FullName -Value $newContent -Encoding UTF8 -NoNewline
    }
}

Write-Host "`n=== Simple fix completed! ===" -ForegroundColor Cyan
Write-Host "The DataStore Plugin should now work properly without causing stack overflows." -ForegroundColor Cyan
