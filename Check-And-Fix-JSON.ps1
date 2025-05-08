# Check-And-Fix-JSON.ps1
# This script checks for BOM in JSON files and removes it

$filePath = Join-Path -Path $PSScriptRoot -ChildPath "default.project.json"

# Function to check if a file has a BOM marker
function Test-BOM {
    param (
        [string]$FilePath
    )
    
    try {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        
        # Check for UTF-8 BOM (EF BB BF)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            return $true
        }
        
        # Check for UTF-16 LE BOM (FF FE)
        if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
            return $true
        }
        
        # Check for UTF-16 BE BOM (FE FF)
        if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
            return $true
        }
        
        return $false
    }
    catch {
        Write-Error "Error checking BOM: $_"
        return $false
    }
}

if (Test-Path $filePath) {
    $hasBOM = Test-BOM -FilePath $filePath
    
    if ($hasBOM) {
        Write-Host "BOM detected in $filePath. Removing..." -ForegroundColor Yellow
        
        # Read the content (skipping the BOM if present)
        $content = Get-Content -Path $filePath -Raw
        
        # Create a UTF-8 encoder without BOM
        $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
        
        # Write the content back without BOM
        [System.IO.File]::WriteAllText($filePath, $content, $utf8NoBomEncoding)
        
        Write-Host "BOM removed successfully!" -ForegroundColor Green
    }
    else {
        Write-Host "No BOM detected in $filePath. File is good!" -ForegroundColor Green
    }
    
    # Additionally, let's check if the file has any comments
    $content = Get-Content -Path $filePath -Raw
    if ($content -match "//|/\*") {
        Write-Host "Comments detected in JSON file. JSON doesn't support comments!" -ForegroundColor Red
        
        # Remove comments
        $noComments = $content -replace "//.*?(\r?\n|$)", "`$1" -replace "/\*.*?\*/", ""
        
        # Write back the content without comments
        [System.IO.File]::WriteAllText($filePath, $noComments, $utf8NoBomEncoding)
        
        Write-Host "Comments removed successfully!" -ForegroundColor Green
    }
}
else {
    Write-Host "File not found: $filePath" -ForegroundColor Red
}
