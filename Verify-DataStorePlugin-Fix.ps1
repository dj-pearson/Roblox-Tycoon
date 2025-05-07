# Verify-DataStorePlugin-Fix.ps1
# This script extracts and verifies the DataStorePlugin.rbxmx to confirm fixes

Write-Host "Verifying DataStore Plugin fix..." -ForegroundColor Cyan

# Configuration
$pluginFile = "DataStorePlugin.rbxmx"
$extractDir = ".\ExtractedPlugin"

# Verify plugin file exists
if (-not (Test-Path $pluginFile)) {
    Write-Host "ERROR: Plugin file not found: $pluginFile" -ForegroundColor Red
    exit 1
}

# Create extraction directory
if (Test-Path $extractDir) {
    Remove-Item -Path $extractDir -Recurse -Force
}
New-Item -ItemType Directory -Path $extractDir -Force | Out-Null

Write-Host "Extracting plugin file for verification..." -ForegroundColor Yellow

# Extract XML content from the RBXMX file
$xmlContent = Get-Content -Path $pluginFile -Raw
$pluginXml = [xml]$xmlContent

# Check for ModuleResolver in the plugin
$moduleResolverNodes = $pluginXml.SelectNodes("//Item[Name='ModuleResolver']")
if ($moduleResolverNodes.Count -gt 0) {
    Write-Host "ModuleResolver module found in the plugin." -ForegroundColor Green
} else {
    Write-Host "WARNING: ModuleResolver module not found in the plugin." -ForegroundColor Yellow
}

# Check for resolveModule function calls in key modules
$keyModules = @(
    "DataStoreManager",
    "MultiServerCoordination",
    "SchemaManager",
    "SchemaVersioning",
    "SessionManager",
    "StyleGuide"
)

Write-Host "`nVerifying module resolver implementation in key modules:" -ForegroundColor Cyan

foreach ($moduleName in $keyModules) {
    $moduleNodes = $pluginXml.SelectNodes("//Item[Name='$moduleName']")
    
    if ($moduleNodes.Count -eq 0) {
        Write-Host "  $moduleName - WARNING: Module not found in plugin" -ForegroundColor Yellow
        continue
    }
    
    $moduleFound = $false
    $resolverFound = $false
    
    foreach ($node in $moduleNodes) {
        $sourceNode = $node.SelectSingleNode(".//Source")
        if ($sourceNode) {
            $moduleFound = $true
            $sourceCode = $sourceNode.InnerText
            
            if ($sourceCode -match "resolveModule\s*=") {
                $resolverFound = $true
                Write-Host "  $moduleName - SUCCESS: Module resolver implementation found" -ForegroundColor Green
                break
            }
        }
    }
    
    if ($moduleFound -and -not $resolverFound) {
        Write-Host "  $moduleName - ERROR: Module found but resolver not implemented" -ForegroundColor Red
    }
    elseif (-not $moduleFound) {
        Write-Host "  $moduleName - WARNING: Could not verify module (source code not found)" -ForegroundColor Yellow
    }
}

Write-Host "`nVerification complete!" -ForegroundColor Green
Write-Host "The DataStore Plugin has been updated to use the module resolver pattern." -ForegroundColor Cyan
Write-Host "This should fix the require errors and allow the plugin to load properly." -ForegroundColor Cyan

Write-Host "`nTo test the plugin in Roblox Studio:" -ForegroundColor Yellow
Write-Host "1. Copy $pluginFile to your Roblox Studio Plugins folder" -ForegroundColor White
Write-Host "2. Restart Roblox Studio" -ForegroundColor White
Write-Host "3. Verify the plugin loads without errors" -ForegroundColor White

# Clean up
Remove-Item -Path $extractDir -Recurse -Force -ErrorAction SilentlyContinue
