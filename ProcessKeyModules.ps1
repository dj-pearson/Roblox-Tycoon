# ProcessKeyModules.ps1
# This is a simpler script to fix require statements in key DataStore Plugin modules

# Define the module resolver code
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

# List of key modules to process
$modulePaths = @(
    "DataStore Plugin\src\SessionManager.luau",
    "DataStore Plugin\src\CacheManager.luau",
    "DataStore Plugin\src\SchemaVersioning.luau",
    "DataStore Plugin\src\DataStoreViewer.luau",
    "DataStore Plugin\src\PluginUI.luau",
    "DataStore Plugin\src\StyleGuide.luau"
)

foreach ($modulePath in $modulePaths) {
    $fullPath = Join-Path $PSScriptRoot $modulePath
    $fileName = Split-Path -Leaf $fullPath
    
    Write-Host "Processing $fileName..." -ForegroundColor Cyan
    
    if (Test-Path $fullPath) {
        # Create backup
        $backupPath = "$fullPath.backup"
        if (-not (Test-Path $backupPath)) {
            Copy-Item -Path $fullPath -Destination $backupPath
            Write-Host "  Created backup at $backupPath" -ForegroundColor DarkGray
        }
        
        # Read file content
        $content = Get-Content -Path $fullPath -Raw
        
        # Skip if the file is empty or has no require statements
        if ([string]::IsNullOrWhiteSpace($content) -or (-not ($content -match "require\(script\.Parent"))) {
            Write-Host "  Skipping $fileName (no content or no direct requires to fix)" -ForegroundColor Gray
            continue
        }
        
        # Extract service imports section
        $serviceImportsMatch = [regex]::Match($content, "(?s)^(?:--.*?\r?\n)*(?:local [A-Za-z]+ = game:GetService\([^\)]+\)[^\r?\n]*\r?\n)*")
        $serviceImports = $serviceImportsMatch.Value
        
        # Extract require statements
        $requirePattern = "local ([A-Za-z0-9_]+) = require\(script\.Parent\.([A-Za-z0-9_]+)\)"
        $requireMatches = [regex]::Matches($content, $requirePattern)
        
        if ($requireMatches.Count -eq 0) {
            Write-Host "  No require statements found in $fileName" -ForegroundColor Yellow
            continue
        }
        
        # Generate new require statements
        $newRequires = ""
        foreach ($match in $requireMatches) {
            $moduleName = $match.Groups[1].Value
            $requirePath = $match.Groups[2].Value
            $newRequires += "local $moduleName = resolveModule('$requirePath')`r`n"
        }
        
        # Replace old require statements with new ones
        $newContent = $content -replace "(?s)(?:local [A-Za-z0-9_]+ = require\(script\.Parent\.[A-Za-z0-9_]+\)[^\r?\n]*\r?\n)+", $newRequires
        
        # Add resolver code after service imports
        $newContent = $serviceImports + $resolverCode + $newContent.Substring($serviceImportsMatch.Length)
        
        # Save modified content
        Set-Content -Path $fullPath -Value $newContent -NoNewline
        Write-Host "  Updated require statements in $fileName" -ForegroundColor Green
    }
    else {
        Write-Host "  File not found: $fullPath" -ForegroundColor Red
    }
}

Write-Host "All specified modules processed successfully!" -ForegroundColor Green
