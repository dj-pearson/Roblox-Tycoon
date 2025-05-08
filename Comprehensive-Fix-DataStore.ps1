# Comprehensive-Fix-DataStore.ps1
# A comprehensive fix for DataStore Plugin with better error tracking

$srcFolder = "c:\Users\pears\OneDrive\Documents\RobloxProject\DataStore Plugin\src"

function Write-ColorLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Color = "White"
    )
    
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorLog "=== DataStore Plugin Comprehensive Fix Script ===" "Cyan"
Write-ColorLog "Starting full repair of plugin structure..." "Gray"

# Track statistics
$stats = @{
    ReexportFilesFixed = 0
    ServerFilesFixed = 0
    CircularReferencesFixed = 0
    RequireStatementsFixed = 0
    SyntaxErrorsFixed = 0
}

# 1. Fix all re-export .luau files to properly reference their server versions
Write-ColorLog "`nStep 1: Fixing re-export files..." "White"

$serverFiles = Get-ChildItem -Path $srcFolder -Filter "*.server.luau" | Select-Object -ExpandProperty Name

foreach ($serverFile in $serverFiles) {
    $baseName = $serverFile -replace '\.server\.luau$', ''
    $luauFile = "$baseName.luau"
    $luauPath = Join-Path $srcFolder $luauFile
    
    # Create or update the re-export file
    $newContent = @"
--luau
-- DataStore Plugin/$luauFile
-- This is a re-export file that forwards to the server version

-- Use direct reference to the server script instead of script.server
return require(script.Parent:FindFirstChild("$baseName.server"))
"@
    
    $existing = ""
    if (Test-Path $luauPath) {
        $existing = Get-Content $luauPath -Raw
    }
    
    # Only update if content is different
    if ($existing -ne $newContent) {
        Set-Content $luauPath $newContent -NoNewline
        Write-ColorLog "  - Fixed re-export file: $luauFile" "Green"
        $stats.ReexportFilesFixed++
    }
    else {
        Write-ColorLog "  - Already correct: $luauFile" "Gray"
    }
}

# 2. Fix critical syntax errors in init.server.luau
Write-ColorLog "`nStep 2: Fixing syntax errors in init.server.luau..." "White"
$initPath = Join-Path $srcFolder "init.server.luau"
$initContent = Get-Content $initPath -Raw

# Check for elif -> elseif issue
if ($initContent -match "elif type\(DataMigrationTools\)") {
    $initContent = $initContent -replace "elif type\(DataMigrationTools\)", "elseif type(DataMigrationTools)"
    Write-ColorLog "  - Fixed 'elif' to 'elseif' in init.server.luau" "Green"
    $stats.SyntaxErrorsFixed++
}

# Fix any other syntax issues here...

# Save changes if any were made
Set-Content $initPath $initContent -NoNewline

# 3. Update module resolver to handle all common module patterns
Write-ColorLog "`nStep 3: Enhancing module resolver..." "White"
$resolverPattern = @"
    local moduleScript = script.Parent:FindFirstChild\(moduleName\)
"@

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

if ($initContent -match $resolverPattern) {
    $initContent = $initContent -replace $resolverPattern, $resolverReplacement
    Set-Content $initPath $initContent -NoNewline
    Write-ColorLog "  - Enhanced module resolver in init.server.luau" "Green"
    $stats.RequireStatementsFixed++
}
else {
    # Check if we already have the enhanced resolver
    if ($initContent -match "Try multiple approaches to find the module") {
        Write-ColorLog "  - Module resolver already enhanced" "Gray"
    }
    else {
        Write-ColorLog "  - Could not find standard module resolver pattern" "Yellow"
    }
}

# 4. Create documentation
Write-ColorLog "`nStep 4: Creating documentation..." "White"
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
Write-ColorLog "Server files fixed: $($stats.ServerFilesFixed)" "White"
Write-ColorLog "Circular references fixed: $($stats.CircularReferencesFixed)" "White"
Write-ColorLog "Require statements fixed: $($stats.RequireStatementsFixed)" "White"
Write-ColorLog "Syntax errors fixed: $($stats.SyntaxErrorsFixed)" "White"
Write-ColorLog "`nTotal changes: $($stats.ReexportFilesFixed + $stats.ServerFilesFixed + $stats.CircularReferencesFixed + $stats.RequireStatementsFixed + $stats.SyntaxErrorsFixed)" "Cyan"

Write-ColorLog "`n=== Comprehensive fix completed! ===" "Cyan"
Write-ColorLog "Next steps:" "Yellow"
Write-ColorLog "1. Test the plugin in Roblox Studio" "Yellow"
Write-ColorLog "2. Check for any remaining errors in the output log" "Yellow"
Write-ColorLog "3. Review the documentation for future maintenance" "Yellow"
