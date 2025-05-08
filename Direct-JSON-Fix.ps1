# Direct-JSON-Fix.ps1
# This script uses direct string manipulation to remove BOM characters from all JSON files

# List of all project.json files to fix
$jsonFiles = @(
    "clean-default.project.json",
    "clean-plugin.project.json",
    "DataStore-plugin.project.json",
    "default.project.json",
    "enhanced.project.json",
    "main.project.json",
    "rojo-plugin-detailed.project.json",
    "rojo-plugin-standard.project.json",
    "rojo-plugin.project.json",
    "rojo-plugin2.project.json"
)

Write-Host "Starting direct JSON fix for Argon..." -ForegroundColor Cyan

foreach ($file in $jsonFiles) {
    $filePath = Join-Path -Path $PSScriptRoot -ChildPath $file
    
    if (Test-Path $filePath) {
        Write-Host "Processing $file..." -ForegroundColor Yellow
        
        # Read the file as a binary stream to detect and handle the BOM
        try {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            
            # Check if file has UTF-8 BOM (EF BB BF)
            $hasBOM = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
            
            if ($hasBOM) {
                # Create backup
                $backupPath = "$filePath.before_direct_fix"
                Copy-Item -Path $filePath -Destination $backupPath -Force
                Write-Host "  Created backup at $backupPath" -ForegroundColor Gray
                
                # Remove BOM by taking all bytes except the first three
                $newBytes = $bytes[3..($bytes.Length - 1)]
                
                # Write the file back without the BOM
                [System.IO.File]::WriteAllBytes($filePath, $newBytes)
                Write-Host "  Removed BOM successfully" -ForegroundColor Green
                
                # Verify the file is valid JSON
                try {
                    $content = Get-Content -Path $filePath -Raw
                    $null = ConvertFrom-Json -InputObject $content -ErrorAction Stop
                    Write-Host "  JSON validation passed" -ForegroundColor Green
                }
                catch {
                    Write-Host "  JSON validation failed after BOM removal: $_" -ForegroundColor Red
                    
                    # Try a more aggressive approach - read the file and manually format it
                    try {
                        $content = Get-Content -Path $filePath -Raw
                        
                        # Attempt to clean and reformat the JSON content
                        $content = $content.Replace("﻿", "").Trim()
                        
                        # Write the clean content back
                        [System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)
                        Write-Host "  Applied aggressive cleaning" -ForegroundColor Yellow
                    }
                    catch {
                        Write-Host "  Aggressive cleaning failed: $_" -ForegroundColor Red
                    }
                }
            }
            else {
                Write-Host "  No BOM detected" -ForegroundColor Green
                
                # Verify the file is valid JSON anyway
                try {
                    $content = Get-Content -Path $filePath -Raw
                    $null = ConvertFrom-Json -InputObject $content -ErrorAction Stop
                    Write-Host "  JSON validation passed" -ForegroundColor Green
                }
                catch {
                    Write-Host "  JSON validation failed: $_" -ForegroundColor Red
                    
                    # Try to clean the content
                    try {
                        $content = Get-Content -Path $filePath -Raw
                        
                        # Create backup
                        $backupPath = "$filePath.before_cleaning"
                        Copy-Item -Path $filePath -Destination $backupPath -Force
                        
                        # Clean any potential invisible characters at the start
                        $cleanContent = $content -replace "^\s*", ""
                        $cleanContent = $cleanContent -replace "^[^{]*", ""
                        
                        # Ensure the file starts with a proper opening brace
                        if (-not $cleanContent.StartsWith("{")) {
                            $cleanContent = "{" + $cleanContent.Substring($cleanContent.IndexOf("{") + 1)
                        }
                        
                        # Write the cleaned content back
                        [System.IO.File]::WriteAllText($filePath, $cleanContent, [System.Text.Encoding]::UTF8)
                        Write-Host "  Applied content cleaning" -ForegroundColor Yellow
                    }
                    catch {
                        Write-Host "  Content cleaning failed: $_" -ForegroundColor Red
                    }
                }
            }
        }
        catch {
            Write-Host "Error processing $file : $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "File not found: $file" -ForegroundColor Gray
    }
}

Write-Host "`nDirect JSON fix completed" -ForegroundColor Cyan
Write-Host "You can now try running Argon again" -ForegroundColor Yellow
