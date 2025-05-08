# Fix-All-JSON-Files.ps1
# This script aggressively removes BOM characters from all JSON files in the directory and subdirectories

Write-Host "Starting aggressive JSON fix process..." -ForegroundColor Cyan

$bomRemovalCount = 0
$processedFileCount = 0

function Remove-BOMFromFile {
    param (
        [string]$FilePath
    )
    
    try {
        # Read the file content as bytes to detect BOM
        $content = [System.IO.File]::ReadAllBytes($FilePath)
        
        # Check if the file has a BOM (0xEF, 0xBB, 0xBF for UTF-8)
        if ($content.Length -ge 3 -and $content[0] -eq 0xEF -and $content[1] -eq 0xBB -and $content[2] -eq 0xBF) {
            Write-Host "Removing BOM from $FilePath" -ForegroundColor Yellow
            
            # Create a backup with timestamp
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $backupPath = "$FilePath.bak_$timestamp"
            Copy-Item -Path $FilePath -Destination $backupPath -Force
            
            # Read the content as string, skipping the BOM
            $contentWithoutBOM = [System.Text.Encoding]::UTF8.GetString($content, 3, $content.Length - 3)
            
            # Write the content back without the BOM
            [System.IO.File]::WriteAllText($FilePath, $contentWithoutBOM, [System.Text.Encoding]::UTF8)
            
            return $true
        }
        return $false
    }
    catch {
        Write-Host "Error processing $FilePath : $_" -ForegroundColor Red
        return $false
    }
}

function Process-JSONFiles {
    param (
        [string]$Directory,
        [bool]$Recursive = $true
    )
    
    $searchOption = if ($Recursive) { [System.IO.SearchOption]::AllDirectories } else { [System.IO.SearchOption]::TopDirectoryOnly }
    
    # Find all JSON files in the directory
    $jsonFiles = [System.IO.Directory]::GetFiles($Directory, "*.json", $searchOption)
    
    Write-Host "Found $($jsonFiles.Count) JSON files to check" -ForegroundColor Cyan
    
    foreach ($file in $jsonFiles) {
        $script:processedFileCount++
        
        # Remove BOM if present
        $bomRemoved = Remove-BOMFromFile -FilePath $file
        
        if ($bomRemoved) {
            $script:bomRemovalCount++
        }
    }
}

# Start processing from the current directory
$startDir = $PSScriptRoot
Process-JSONFiles -Directory $startDir

# Report results
Write-Host "`nProcessing complete!" -ForegroundColor Cyan
Write-Host "Processed $processedFileCount JSON files" -ForegroundColor Green
Write-Host "Removed BOM from $bomRemovalCount files" -ForegroundColor Yellow

# Extra validation step to ensure files are fixed
$problematicFiles = @()
foreach ($file in (Get-ChildItem -Path $startDir -Filter "*.json" -Recurse)) {
    try {
        # Try to parse each JSON file with .NET methods
        $content = Get-Content -Path $file.FullName -Raw
        $null = ConvertFrom-Json -InputObject $content -ErrorAction Stop
    }
    catch {
        $problematicFiles += $file.FullName
        Write-Host "JSON validation failed for: $($file.FullName)" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        
        # Try to fix the file with a more aggressive approach
        Write-Host "  Attempting more aggressive fix..." -ForegroundColor Yellow
        
        # Read as binary, convert to string, and carefully rewrite
        try {
            $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
            
            # Skip any BOM or other problematic characters
            $offset = 0
            while ($offset -lt $bytes.Length -and $bytes[$offset] -lt 32) {
                $offset++
            }
            
            if ($offset -gt 0) {
                $cleanContent = [System.Text.Encoding]::UTF8.GetString($bytes, $offset, $bytes.Length - $offset)
                
                # Create backup
                $timestamp = Get-Date -Format "yyyyMMddHHmmss"
                $backupPath = "$($file.FullName).aggressive_bak_$timestamp"
                Copy-Item -Path $file.FullName -Destination $backupPath -Force
                
                # Write cleansed content
                [System.IO.File]::WriteAllText($file.FullName, $cleanContent, [System.Text.Encoding]::UTF8)
                Write-Host "  Applied aggressive fix - skipped $offset bytes" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "  Aggressive fix failed: $_" -ForegroundColor Red
        }
    }
}

if ($problematicFiles.Count -gt 0) {
    Write-Host "`nWarning: $($problematicFiles.Count) files still have JSON validation issues." -ForegroundColor Red
}
else {
    Write-Host "`nAll JSON files now pass validation." -ForegroundColor Green
}

Write-Host "`nYou can now try running Argon again." -ForegroundColor Cyan
