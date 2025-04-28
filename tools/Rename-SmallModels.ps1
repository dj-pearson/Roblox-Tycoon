# Roblox Model Renamer - PowerShell Wrapper
# This script runs the Python model renamer with user-friendly options

# Check if Python is installed
$pythonCommand = "python"
try {
    $pythonVersion = & $pythonCommand --version
} catch {
    Write-Host "Python not found. Please ensure Python is installed and in your PATH."
    Write-Host "You can download Python from https://www.python.org/downloads/"
    exit 1
}

# Set the path to the Python script
$scriptPath = Join-Path $PSScriptRoot "rename_small_models.py"

# Check if the script exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "Error: Could not find the rename_small_models.py script at:"
    Write-Host $scriptPath
    exit 1
}

# Ask if this is a dry run
$dryRunChoice = Read-Host "Do you want to do a dry run (only show changes without making them)? (y/n)"
$dryRunFlag = if ($dryRunChoice.ToLower() -eq "y") { "--dry-run" } else { "" }

# Run the Python script
Write-Host "Running model renamer script..."
Write-Host "----------------------------------------"

& $pythonCommand $scriptPath $dryRunFlag

Write-Host "----------------------------------------"
Write-Host "Script execution completed."

# Keep window open
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
