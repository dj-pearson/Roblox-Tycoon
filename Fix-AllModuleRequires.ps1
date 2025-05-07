# Fix-AllModuleRequires.ps1
# This script fixes all module files in the DataStore Plugin by adding
# a module resolver to each file to handle require errors

# Configuration
$pluginFolder = Join-Path $PSScriptRoot "DataStore Plugin\src"

function Add-ModuleResolver {
    param (
        [string]$filePath
    )
    
    $fileName = Split-Path -Leaf $filePath
    
    # Skip files that don't need processing
    if ($fileName -eq "ModuleResolver.luau" -or 
        $fileName -eq "UpdateModuleRequires.luau" -or
        $fileName -eq "InstallModuleResolver.server.luau") {
        Write-Host "Skipping $fileName (utility file)" -ForegroundColor Gray
        return $false
    }
    
    # Read file content
    $content = Get-Content -Path $filePath -Raw
    
    # Skip if the file has no direct requires to fix
    if (-not ($content -match "require\(script\.Parent")) {
        Write-Host "Skipping $fileName (no direct requires to fix)" -ForegroundColor Gray
        return $false
    }
    
    Write-Host "Processing $fileName..." -ForegroundColor Cyan
    
    # Create backup if it doesn't exist
    $backupPath = "$filePath.backup"
    if (-not (Test-Path $backupPath)) {
        Copy-Item -Path $filePath -Destination $backupPath
        Write-Host "  Created backup at $backupPath" -ForegroundColor DarkGray
    }
    
    # Capture initial comments and service imports
    $commentPattern = "^(--[^\r\n]*\r?\n)+"
    $servicePattern = "(local [A-Za-z]+ = game:GetService\([^\)]+\)[^\r\n]*\r?\n)+"
    
    $hasComments = $content -match $commentPattern
    $commentBlock = if ($hasComments) { $Matches[0] } else { "" }
    
    $remainingContent = $content
    if ($hasComments) {
        $remainingContent = $content.Substring($commentBlock.Length)
    }
    
    $hasServices = $remainingContent -match "^$servicePattern"
    $serviceBlock = if ($hasServices) { $Matches[0] } else { "" }
    
    $requireBlock = ""
    $restOfContent = $remainingContent
    
    if ($hasServices) {
        $restOfContent = $remainingContent.Substring($serviceBlock.Length)
    }
    
    # Create resolver code
    $resolverCode = @"

-- Get module resolver from init script or define a local one
local resolver = script.Parent:FindFirstChild("ModuleResolver")
local resolveModule = resolver and require(resolver).resolveModule or function(name)
    local success, result = pcall(function()
        return require(script.Parent:FindFirstChild(name))
    end)
    
    if success and result then
        return result
    end
    
    warn("Failed to resolve module: " .. name)
    return {
        initialize = function() return true end,
        createUI = function() return Instance.new("Frame") end
    }
end

"@

    # Extract existing require statements
    $requirePattern = "local ([A-Za-z0-9_]+) = require\(script\.Parent\.([A-Za-z0-9_]+)\)[^\r\n]*\r?\n"
    $matches = [regex]::Matches($restOfContent, $requirePattern)
    
    $requireDict = @{}
    foreach ($match in $matches) {
        $moduleName = $match.Groups[1].Value
        $requirePath = $match.Groups[2].Value
        $requireDict[$moduleName] = $requirePath
    }
    
    # Generate new require statements using resolveModule
    if ($requireDict.Count -gt 0) {
        $newRequires = ""
        foreach ($key in $requireDict.Keys) {
            $newRequires += "local $key = resolveModule('$($requireDict[$key])')`n"
        }
        
        # Replace the original requires with our new ones
        $restOfContent = [regex]::Replace($restOfContent, "(?:local [A-Za-z0-9_]+ = require\(script\.Parent\.[A-Za-z0-9_]+\)[^\r\n]*\r?\n)+", $newRequires)
    }
    
    # Rebuild the file content
    $newContent = $commentBlock + $serviceBlock + $resolverCode + $restOfContent
    
    # Save the modified content
    Set-Content -Path $filePath -Value $newContent
    Write-Host "  Updated module requires in $fileName" -ForegroundColor Green
    
    return $true
}

function Process-Directory {
    param (
        [string]$dir
    )
    
    $changedFiles = 0
    
    # Process all Luau files in the directory
    Get-ChildItem -Path $dir -Filter "*.luau" | ForEach-Object {
        $changed = Add-ModuleResolver -filePath $_.FullName
        if ($changed) {
            $changedFiles++
        }
    }
    
    # Process subdirectories
    Get-ChildItem -Path $dir -Directory | ForEach-Object {
        $changedFiles += Process-Directory -dir $_.FullName
    }
    
    return $changedFiles
}

# Main execution
Write-Host "Starting comprehensive DataStore Plugin module fix..." -ForegroundColor Cyan
Write-Host "Plugin folder: $pluginFolder" -ForegroundColor Gray

if (-not (Test-Path $pluginFolder)) {
    Write-Host "ERROR: Plugin folder not found at: $pluginFolder" -ForegroundColor Red
    exit 1
}

$totalChanged = Process-Directory -dir $pluginFolder

Write-Host "`nFix complete! Updated $totalChanged files." -ForegroundColor Green
Write-Host "Now rebuild the plugin with: powershell -ExecutionPolicy Bypass -File .\BuildDataStorePlugin.ps1.new" -ForegroundColor Cyan
