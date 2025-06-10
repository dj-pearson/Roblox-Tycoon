# DataStore Manager Pro - Build and Install Script
# Builds the plugin using Argon and installs it to Roblox Studio

Write-Host "Building DataStore Manager Pro Plugin..." -ForegroundColor Green

# Build the plugin using Argon
Write-Host "Running argon build..." -ForegroundColor Yellow
argon build argon.project.json --output "DataStoreManagerPro.rbxm"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build successful!" -ForegroundColor Green
    
    # Check file size
    $file = Get-Item "DataStoreManagerPro.rbxm"
    Write-Host "Plugin file size: $($file.Length) bytes" -ForegroundColor Cyan
    
    if ($file.Length -gt 1000) {
        # Install to Roblox Plugins folder
        $pluginPath = "$env:LOCALAPPDATA\Roblox\Plugins\DataStoreManagerPro.rbxm"
        Write-Host "Installing to: $pluginPath" -ForegroundColor Yellow
        
        Copy-Item "DataStoreManagerPro.rbxm" $pluginPath -Force
        
        Write-Host "Plugin installed successfully!" -ForegroundColor Green
        Write-Host "Restart Roblox Studio to load the plugin" -ForegroundColor Cyan
        Write-Host "Look for 'DataStore Manager Pro' toolbar button" -ForegroundColor Cyan
    }
    else {
        Write-Host "Build file seems too small, check for errors" -ForegroundColor Red
    }
}
else {
    Write-Host "Build failed!" -ForegroundColor Red
}

Write-Host "Done." -ForegroundColor Green 