# Analyze-JSON-Files.ps1
# This script analyzes the exact bytes present in the JSON files to diagnose BOM issues

function Analyze-File {
    param (
        [string]$FilePath
    )
    
    if (Test-Path $FilePath) {
        Write-Host "Analyzing file: $FilePath" -ForegroundColor Cyan
        
        # Read as bytes
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        
        Write-Host "File size: $($bytes.Length) bytes" -ForegroundColor Yellow
        
        # Check for BOM
        $hasBOM = $false
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            $hasBOM = $true
            Write-Host "BOM detected: UTF-8 BOM (EF BB BF)" -ForegroundColor Red
        }
        elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
            $hasBOM = $true
            Write-Host "BOM detected: UTF-16 LE BOM (FF FE)" -ForegroundColor Red
        }
        elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
            $hasBOM = $true
            Write-Host "BOM detected: UTF-16 BE BOM (FE FF)" -ForegroundColor Red
        }
        else {
            Write-Host "No BOM detected" -ForegroundColor Green
        }
        
        # Show first 20 bytes
        Write-Host "First 20 bytes:" -ForegroundColor Yellow
        for ($i = 0; $i -lt [Math]::Min(20, $bytes.Length); $i++) {
            $byteValue = $bytes[$i]
            $hexValue = $byteValue.ToString("X2")
            $charValue = if ($byteValue -ge 32 -and $byteValue -le 126) { [char]$byteValue } else { "." }
            Write-Host "Byte $i : $hexValue (Decimal: $byteValue) ASCII: $charValue" -ForegroundColor Gray
        }
        
        # Try to display file content as text
        Write-Host "`nFile content (first 100 characters):" -ForegroundColor Yellow
        $content = [System.IO.File]::ReadAllText($FilePath)
        if ($content.Length -gt 100) {
            Write-Host $content.Substring(0, 100) -ForegroundColor Gray
        }
        else {
            Write-Host $content -ForegroundColor Gray
        }
        
        # Attempt to parse as JSON
        try {
            $null = Get-Content -Path $FilePath -Raw | ConvertFrom-Json -ErrorAction Stop
            Write-Host "`nJSON validation: PASSED" -ForegroundColor Green
        }
        catch {
            Write-Host "`nJSON validation: FAILED - $_" -ForegroundColor Red
        }
        
        Write-Host "`n" -ForegroundColor Gray
        
        # Return the analysis result
        return @{
            HasBOM = $hasBOM
            FilePath = $FilePath
            FileSize = $bytes.Length
            FirstFewBytes = $bytes[0..9]
        }
    }
    else {
        Write-Host "File not found: $FilePath" -ForegroundColor Red
        return $null
    }
}

# Analyze project files
$files = @(
    "default.project.json",
    "DataStore-plugin.project.json",
    "clean-default.project.json",
    "clean-plugin.project.json",
    "enhanced.project.json"
)

foreach ($file in $files) {
    $filePath = Join-Path -Path $PSScriptRoot -ChildPath $file
    $result = Analyze-File -FilePath $filePath
}

# Create new default.project.json directly with hex values to ensure proper format
$newFile = Join-Path -Path $PSScriptRoot -ChildPath "new-default.project.json"

# ASCII values for JSON content (no BOM, just ASCII characters)
$byteArray = @(
    # { 
    123,
    # "name": "RobloxProject",
    34, 110, 97, 109, 101, 34, 58, 32, 34, 82, 111, 98, 108, 111, 120, 80, 114, 111, 106, 101, 99, 116, 34, 44, 
    # "tree": {
    34, 116, 114, 101, 101, 34, 58, 32, 123, 
    # "$className": "DataModel",
    34, 36, 99, 108, 97, 115, 115, 78, 97, 109, 101, 34, 58, 32, 34, 68, 97, 116, 97, 77, 111, 100, 101, 108, 34, 
    # }
    125, 
    # }
    125
)

# Write the bytes directly to file
[System.IO.File]::WriteAllBytes($newFile, $byteArray)
Write-Host "Created minimal JSON file: $newFile" -ForegroundColor Green
Write-Host "Try running: argon serve $($newFile.Replace('\', '/'))" -ForegroundColor Yellow
