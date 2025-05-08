# Validation script for DataStore Manager Pro Plugin
Write-Host "Validating plugin structure..."

# Check if the rbxmx file exists
if (!(Test-Path "DataStoreManagerPro.rbxmx")) {
    Write-Host "Error: DataStoreManagerPro.rbxmx not found"
    exit 1
}

# Check if all required directories exist
$requiredDirs = @(
    "src/shared",
    "src/server",
    "src/clientScripts"
)

foreach ($dir in $requiredDirs) {
    if (!(Test-Path $dir)) {
        Write-Host "Error: Required directory not found: $dir"
        exit 1
    }
}

# Check if critical files exist
$criticalFiles = @(
    "plugin.luau",
    "src/server/init.server.luau",
    "src/server/DataStoreManager.server.luau",
    "src/server/DataExplorer.server.luau"
)

foreach ($file in $criticalFiles) {
    if (!(Test-Path $file)) {
        Write-Host "Error: Critical file not found: $file"
        exit 1
    }
}

# Try to parse the rbxmx file as XML
try {
    [xml]$pluginXml = Get-Content "DataStoreManagerPro.rbxmx"
    
    # Check for Plugin class
    $pluginNodes = $pluginXml.SelectNodes("//Item[@class='Plugin']")
    if ($pluginNodes.Count -eq 0) {
        Write-Host "Error: No Plugin class found in rbxmx"
        exit 1
    }
    
    Write-Host "Plugin structure validation passed!"
} catch {
    Write-Host "Error: Failed to parse rbxmx file as XML"
    Write-Host $_.Exception.Message
    exit 1
} 