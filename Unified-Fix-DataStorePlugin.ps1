# Unified-Fix-DataStorePlugin.ps1
# A comprehensive solution for all DataStore Plugin issues

$srcFolder = "c:\Users\pears\OneDrive\Documents\RobloxProject\DataStore Plugin\src"
$pluginFolder = "$env:LOCALAPPDATA\Roblox\Plugins"

function Write-ColorLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Color = "White"
    )
    
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorLog "=== DataStore Plugin Unified Fix Script ===" "Cyan"
Write-ColorLog "This script implements all fixes needed for the DataStore Plugin." "Gray"

# Stats tracking
$stats = @{
    ReexportFilesFixed = 0
    ServerModulesFixed = 0
    SyntaxErrorsFixed = 0
    CircularReferencesFixed = 0
}

#------------------------------------------------
# 1. Fix all re-export .luau files
#------------------------------------------------
Write-ColorLog "`nStep 1: Fixing re-export files..." "White"

$serverFiles = Get-ChildItem -Path $srcFolder -Filter "*.server.luau" | Select-Object -ExpandProperty Name

foreach ($serverFile in $serverFiles) {
    $baseName = $serverFile -replace '\.server\.luau$', ''
    $luauFile = "$baseName.luau"
    $luauPath = Join-Path $srcFolder $luauFile
    
    # Prepare the correct content for the re-export file
    $correctContent = @"
--luau
-- DataStore Plugin/$luauFile
-- This is a re-export file that forwards to the server version

-- Use direct reference to the server script instead of script.server
return require(script.Parent:FindFirstChild("$baseName.server"))
"@
    
    # Create or update the file
    if (Test-Path $luauPath) {
        $currentContent = Get-Content $luauPath -Raw
        
        # Only update if it's different
        if ($currentContent -ne $correctContent) {
            Set-Content $luauPath $correctContent -NoNewline
            Write-ColorLog "  - Fixed re-export file: $luauFile" "Green"
            $stats.ReexportFilesFixed++
        }
    }
    else {
        # Create new file
        Set-Content $luauPath $correctContent -NoNewline
        Write-ColorLog "  - Created re-export file: $luauFile" "Green"
        $stats.ReexportFilesFixed++
    }
}

#------------------------------------------------
# 2. Fix "script.server" references in server modules
#------------------------------------------------
Write-ColorLog "`nStep 2: Fixing server modules..." "White"

$serverFiles = Get-ChildItem -Path $srcFolder -Filter "*.server.luau"

foreach ($file in $serverFiles) {
    $content = Get-Content $file.FullName -Raw
    $modified = $false
    
    # Check for direct script.server references
    if ($content -match "script\.server\b") {
        $updatedContent = $content -replace "script\.server\b", "script"
        $content = $updatedContent
        $modified = $true
        Write-ColorLog "  - Fixed direct script.server references in $($file.Name)" "Green"
    }
    
    # Check for require(script.server) pattern
    if ($content -match "require\(script\.server\)") {
        $updatedContent = $content -replace "require\(script\.server\)", "require(script)"
        $content = $updatedContent
        $modified = $true
        Write-ColorLog "  - Fixed require(script.server) in $($file.Name)" "Green"
    }
    
    # Check for script.server.Name pattern (complex accesses)
    if ($content -match "script\.server\.[\w]+") {
        $updatedContent = $content -replace "script\.server\.([\w]+)", "script.`$1"
        $content = $updatedContent
        $modified = $true
        Write-ColorLog "  - Fixed complex script.server references in $($file.Name)" "Green"
    }
    
    # Save changes if modifications were made
    if ($modified) {
        Set-Content $file.FullName $content -NoNewline
        $stats.ServerModulesFixed++
    }
}

#------------------------------------------------
# 3. Fix syntax errors in init.server.luau
#------------------------------------------------
Write-ColorLog "`nStep 3: Fixing syntax errors in init.server.luau..." "White"

$initPath = Join-Path $srcFolder "init.server.luau"
if (Test-Path $initPath) {
    $initContent = Get-Content $initPath -Raw
    $modified = $false
    
    # Check for elif -> elseif
    if ($initContent -match "elif type\(DataMigrationTools\)") {
        $initContent = $initContent -replace "elif type\(DataMigrationTools\)", "elseif type(DataMigrationTools)"
        $modified = $true
        Write-ColorLog "  - Fixed 'elif' to 'elseif' syntax error" "Green"
        $stats.SyntaxErrorsFixed++
    }
    
    # Check other syntax errors here...
    
    # Update module resolver if needed
    $simpleResolverPattern = 'local moduleScript = script.Parent:FindFirstChild\(moduleName\)'
    $enhancedResolverPattern = 'Try multiple approaches to find the module'
    
    if ($initContent -match $simpleResolverPattern -and !($initContent -match $enhancedResolverPattern)) {
        $resolverReplacement = @"
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
        $initContent = $initContent -replace $simpleResolverPattern, $resolverReplacement
        $modified = $true
        Write-ColorLog "  - Enhanced module resolver" "Green"
    }
    
    # Save changes if any were made
    if ($modified) {
        Set-Content $initPath $initContent -NoNewline
    }
}
else {
    Write-ColorLog "  - init.server.luau not found!" "Red"
}

#------------------------------------------------
# 4. Build plugin package
#------------------------------------------------
Write-ColorLog "`nStep 4: Building plugin package..." "White"

# Create output folder
$outputFolder = Join-Path $pluginFolder "DataStoreManagerPro"
if (!(Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
    Write-ColorLog "  - Created plugin folder: $outputFolder" "Green"
}

# Copy all Luau files
Copy-Item -Path "$srcFolder\*.luau" -Destination $outputFolder -Force
Copy-Item -Path "$srcFolder\*.server.luau" -Destination $outputFolder -Force
Write-ColorLog "  - Copied Luau files to plugin folder" "Green"

# Create plugin manifest
$manifestContent = @"
{
  "name": "DataStore Manager Pro",
  "description": "Advanced DataStore management, monitoring, and development tools",
  "version": "1.0.0",
  "author": "Pearson"
}
"@

Set-Content -Path (Join-Path $outputFolder "plugin.json") -Value $manifestContent
Write-ColorLog "  - Created plugin manifest" "Green"

#------------------------------------------------
# 5. Create documentation
#------------------------------------------------
Write-ColorLog "`nStep 5: Creating documentation..." "White"

$docPath = "c:\Users\pears\OneDrive\Documents\RobloxProject\DataStore Plugin\DataStore-Plugin-Fix-Documentation.md"
$docContent = @"
# DataStore Plugin Fix Documentation

## Module Organization in Roblox Studio

When the DataStore Plugin is loaded into Roblox Studio, there are important differences in how modules are organized compared to the filesystem:

1. The .server.luau extension gets converted to just .server
2. Modules are directly accessed by name rather than path
3. Some common module resolution patterns don't work in Roblox Studio's environment

### Proper Module Reference Patterns

When referencing other modules in your code, use these patterns:

\`\`\`lua
-- CORRECT: Use FindFirstChild to reference server modules
local SomeModule = require(script.Parent:FindFirstChild("SomeModule.server"))

-- CORRECT: For re-export files (.luau that export .server.luau modules)
return require(script.Parent:FindFirstChild("ModuleName.server"))
\`\`\`

### Incorrect Patterns to Avoid

\`\`\`lua
-- INCORRECT: Direct .server access doesn't work 
local SomeModule = require(script.Parent.SomeModule.server)

-- INCORRECT: This pattern causes circular reference issues
return require(script.server)
\`\`\`

## How to Maintain This Plugin

1. Always use the FindFirstChild pattern for module references
2. Create proper re-export files that follow the pattern above
3. Test in both local environment and Roblox Studio
4. When adding new modules, make sure to update both .server.luau and .luau files
5. Use the included fix scripts when issues arise

## Common Issues and Solutions

### Module Not Found Errors
- Check that you're using FindFirstChild pattern
- Ensure both .server.luau and .luau files exist
- Verify file names match exactly

### Circular References
- Never use return require(script.server) pattern
- Always use return require(script.Parent:FindFirstChild("ModuleName.server"))

### Multiple Values Returned
- Make sure your module only returns one value at the end
- Check for syntax errors that might cause multiple returns
\`\`\`

"@

Set-Content $docPath $docContent
Write-ColorLog "  - Created documentation at $docPath" "Green"

# Display summary
Write-ColorLog "`n=== Fix Summary ===" "Cyan"
Write-ColorLog "Re-export files fixed: $($stats.ReexportFilesFixed)" "White"
Write-ColorLog "Server modules fixed: $($stats.ServerModulesFixed)" "White"
Write-ColorLog "Syntax errors fixed: $($stats.SyntaxErrorsFixed)" "White"
Write-ColorLog "Circular references fixed: $($stats.CircularReferencesFixed)" "White"
Write-ColorLog "`nTotal changes: $($stats.ReexportFilesFixed + $stats.ServerModulesFixed + $stats.SyntaxErrorsFixed + $stats.CircularReferencesFixed)" "Cyan"

Write-ColorLog "`n=== Unified fix completed! ===" "Cyan"
Write-ColorLog "The plugin has been deployed to: $outputFolder" "Green"
Write-ColorLog "`nNext steps:" "Yellow"
Write-ColorLog "1. Start Roblox Studio" "Yellow"
Write-ColorLog "2. Check for the plugin in the Plugins tab" "Yellow"
Write-ColorLog "3. Monitor the Output window for any remaining errors" "Yellow"
Write-ColorLog "4. If errors persist, check the specific module causing issues" "Yellow"
