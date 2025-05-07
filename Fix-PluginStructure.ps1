# Fix-PluginStructure.ps1
# This script helps ensure the plugin structure is correctly set up for Roblox Studio

$srcFolder = "c:\Users\pears\OneDrive\Documents\RobloxProject\DataStore Plugin\src"

Write-Host "=== DataStore Plugin Structure Fix Script ===" -ForegroundColor Cyan
Write-Host "This script prepares the DataStore Plugin for proper Roblox Studio integration." -ForegroundColor Gray

# 1. Ensure all .luau files are simple re-exports that correctly reference their server versions
Write-Host "`nStep 1: Checking all re-export files..." -ForegroundColor White

$serverFiles = Get-ChildItem -Path $srcFolder -Filter "*.server.luau" | Select-Object -ExpandProperty Name
$count = 0

foreach ($serverFile in $serverFiles) {
    $baseName = $serverFile -replace '\.server\.luau$', ''
    $luauFile = "$baseName.luau"
    $luauPath = Join-Path $srcFolder $luauFile
    
    if (Test-Path $luauPath) {
        $content = Get-Content $luauPath -Raw
        
        if ($content -notmatch "return require\(script\.Parent:FindFirstChild\(`"$baseName\.server`"\)\)") {
            $newContent = @"
--luau
-- DataStore Plugin/$luauFile
-- This is a re-export file that forwards to the server version

-- Use direct reference to the server script instead of script.server
return require(script.Parent:FindFirstChild("$baseName.server"))
"@
            Set-Content $luauPath $newContent -NoNewline
            Write-Host "  - Updated re-export file: $luauFile" -ForegroundColor Green
            $count++
        }
    }
    else {
        $newContent = @"
--luau
-- DataStore Plugin/$luauFile
-- This is a re-export file that forwards to the server version

-- Use direct reference to the server script instead of script.server
return require(script.Parent:FindFirstChild("$baseName.server"))
"@
        Set-Content $luauPath $newContent -NoNewline
        Write-Host "  - Created new re-export file: $luauFile" -ForegroundColor Green
        $count++
    }
}

Write-Host "`nUpdated $count re-export files" -ForegroundColor Cyan

# 2. Document what we've learned about the module organization in Roblox Studio
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
\`\`\`

"@

Set-Content $docPath $docContent
Write-Host "`nCreated documentation at $docPath" -ForegroundColor Green

Write-Host "`n=== Plugin structure fix completed! ===" -ForegroundColor Cyan
Write-Host "Recommendations:" -ForegroundColor Yellow
Write-Host "1. Review the documentation file for future maintenance" -ForegroundColor Yellow
Write-Host "2. Test the plugin in Roblox Studio" -ForegroundColor Yellow
Write-Host "3. If errors persist, check the plugin output log for specific modules that need attention" -ForegroundColor Yellow
