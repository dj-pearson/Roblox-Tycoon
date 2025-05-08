# Start-Argon.ps1
# This script ensures Node.js is in PATH and then starts Argon

# Get Node.js path
$nodePath = "C:\Program Files\nodejs"
$nodeExe = Join-Path -Path $nodePath -ChildPath "node.exe"

# Verify Node.js exists
if (-not (Test-Path $nodeExe)) {
    Write-Host "Node.js not found at $nodeExe" -ForegroundColor Red
    
    # Try to find Node.js in other common locations
    $alternativePaths = @(
        "C:\Program Files (x86)\nodejs",
        "$env:USERPROFILE\AppData\Roaming\npm",
        "$env:LOCALAPPDATA\Programs\nodejs"
    )
    
    foreach ($path in $alternativePaths) {
        $altNodeExe = Join-Path -Path $path -ChildPath "node.exe"
        if (Test-Path $altNodeExe) {
            Write-Host "Found Node.js at $altNodeExe" -ForegroundColor Green
            $nodePath = $path
            $nodeExe = $altNodeExe
            break
        }
    }
    
    if (-not (Test-Path $nodeExe)) {
        Write-Host "Could not find Node.js. Please ensure it's installed." -ForegroundColor Red
        Write-Host "Download from: https://nodejs.org/en/download/" -ForegroundColor Yellow
        exit 1
    }
}

# Add Node.js to PATH for this session
$env:Path = "$nodePath;$env:Path"

# Verify Node.js is accessible
try {
    $nodeVersion = & $nodeExe --version
    Write-Host "Node.js version: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "Error running Node.js: $_" -ForegroundColor Red
    exit 1
}

# Check Aftman path
$aftmanPath = "$env:USERPROFILE\.aftman\bin"
if (Test-Path $aftmanPath) {
    Write-Host "Adding Aftman to PATH" -ForegroundColor Yellow
    $env:Path = "$aftmanPath;$env:Path"
} else {
    Write-Host "Aftman not found at $aftmanPath" -ForegroundColor Yellow
    Write-Host "You may need to install Aftman first" -ForegroundColor Yellow
}

# Check if argon is available
$argonCommand = Get-Command argon -ErrorAction SilentlyContinue
if ($argonCommand) {
    Write-Host "Argon found at: $($argonCommand.Source)" -ForegroundColor Green
    
    # Start Argon
    Write-Host "Starting Argon..." -ForegroundColor Cyan
    & $argonCommand.Source serve
} else {
    Write-Host "Argon not found in PATH" -ForegroundColor Red
    Write-Host "Trying to install Argon using Aftman..." -ForegroundColor Yellow
    
    # Run aftman install
    $aftmanCommand = Get-Command aftman -ErrorAction SilentlyContinue
    if ($aftmanCommand) {
        Write-Host "Running aftman install..." -ForegroundColor Yellow
        & $aftmanCommand.Source install
        
        # Check if argon is now available
        $argonCommand = Get-Command argon -ErrorAction SilentlyContinue
        if ($argonCommand) {
            Write-Host "Argon installed successfully" -ForegroundColor Green
            Write-Host "Starting Argon..." -ForegroundColor Cyan
            & $argonCommand.Source serve
        } else {
            Write-Host "Failed to install Argon" -ForegroundColor Red
        }
    } else {
        Write-Host "Aftman not found. Please install Aftman first." -ForegroundColor Red
    }
}
