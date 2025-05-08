# Fix-Git-Index.ps1
# This script repairs a corrupted Git index file by backing up and recreating it

Write-Host "Starting Git index repair process..." -ForegroundColor Cyan

# Get the repository root directory
$repoRoot = Split-Path -Parent $PSScriptRoot
$gitDir = Join-Path -Path $repoRoot -ChildPath ".git"
$indexFile = Join-Path -Path $gitDir -ChildPath "index"

# Verify we're in a Git repository
if (-not (Test-Path $gitDir)) {
    Write-Host "Error: Not in a Git repository. Cannot find .git directory at $gitDir" -ForegroundColor Red
    exit 1
}

# Create a backup of the corrupted index file
if (Test-Path $indexFile) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "$indexFile.backup_$timestamp"
    Copy-Item -Path $indexFile -Destination $backupFile -Force
    Write-Host "Backed up corrupted index file to $backupFile" -ForegroundColor Yellow
    
    # Remove the corrupted index file
    Remove-Item -Path $indexFile -Force
    Write-Host "Removed corrupted index file" -ForegroundColor Yellow
}

# Recreate the index by resetting the repository
Write-Host "Recreating Git index..." -ForegroundColor Cyan

# First try with git reset
try {
    Push-Location $repoRoot
    Write-Host "Running 'git reset'" -ForegroundColor Yellow
    git reset
    
    # Make sure the index is working now
    $indexTestResult = git status
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Git index successfully repaired!" -ForegroundColor Green
        Write-Host "You can now commit your changes with the following commands:" -ForegroundColor Cyan
        Write-Host "git add -A" -ForegroundColor Yellow
        Write-Host "git commit -m 'Your commit message'" -ForegroundColor Yellow
    } else {
        throw "Git index still has issues after reset"
    }
} catch {
    Write-Host "First repair attempt failed, trying more aggressive approach..." -ForegroundColor Yellow
    
    # If resetting didn't work, try to recreate the repository state
    try {
        # Create a temporary branch to save the current state
        git checkout -b temp_recovery_branch
        
        # Force reset to HEAD
        git reset --hard HEAD
        
        # Then checkout the original branch
        $originalBranch = git branch --show-current
        if ($originalBranch -ne "temp_recovery_branch") {
            git checkout $originalBranch
            git branch -D temp_recovery_branch
        }
        
        Write-Host "Git repository has been reset to recover from corrupted index" -ForegroundColor Green
        Write-Host "NOTE: You may need to reapply your recent uncommitted changes" -ForegroundColor Yellow
    } catch {
        Write-Host "Error during repair process: $_" -ForegroundColor Red
        Write-Host "You may need to try a more advanced repair approach:" -ForegroundColor Yellow
        Write-Host "1. Backup your work (copy files outside the Git repository)" -ForegroundColor Yellow
        Write-Host "2. Delete the .git folder and reinitialize the repository" -ForegroundColor Yellow
        Write-Host "3. Or clone a fresh copy of the repository and copy your changes over" -ForegroundColor Yellow
    }
}

Pop-Location
Write-Host "Git index repair process completed" -ForegroundColor Cyan
