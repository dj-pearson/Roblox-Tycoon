# Comprehensive-JSON-Fix.ps1
# This script performs a comprehensive check and fix of all JSON files
# focusing on encoding issues and providing detailed diagnostics

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Starting comprehensive JSON file diagnostics and repair..." -ForegroundColor Cyan

# Function to examine file encoding and check for BOM markers and other issues
function Examine-FileEncoding {
    param (
        [string]$FilePath
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "File not found: $FilePath" -ForegroundColor Red
        return $null
    }
    
    try {
        # Read file as binary to detect encoding
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        
        # Check file length
        if ($bytes.Length -eq 0) {
            Write-Host "$FilePath is empty" -ForegroundColor Red
            return @{ IsEmpty = $true }
        }
        
        # Check for BOM markers
        $encoding = $null
        $hasBom = $false
        $bomLength = 0
        
        # UTF-8 BOM (EF BB BF)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            $encoding = "UTF-8 with BOM"
            $hasBom = $true
            $bomLength = 3
        }
        # UTF-16 LE BOM (FF FE)
        elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
            $encoding = "UTF-16 LE with BOM"
            $hasBom = $true
            $bomLength = 2
        }
        # UTF-16 BE BOM (FE FF)
        elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
            $encoding = "UTF-16 BE with BOM"
            $hasBom = $true
            $bomLength = 2
        }
        # UTF-32 LE BOM (FF FE 00 00)
        elseif ($bytes.Length -ge 4 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00) {
            $encoding = "UTF-32 LE with BOM"
            $hasBom = $true
            $bomLength = 4
        }
        # UTF-32 BE BOM (00 00 FE FF)
        elseif ($bytes.Length -ge 4 -and $bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
            $encoding = "UTF-32 BE with BOM"
            $hasBom = $true
            $bomLength = 4
        }
        else {
            # No BOM detected
            # Try to guess encoding based on content
            if (Test-UTF8WithoutBOM -Bytes $bytes) {
                $encoding = "UTF-8 without BOM"
            }
            else {
                $encoding = "Unknown (possibly ASCII or other)"
            }
        }

        # Now check if the file actually starts with a proper JSON opening character
        $firstNonBomChar = if ($hasBom) { $bytes[$bomLength] } else { $bytes[0] }
        $firstRealChar = [char]$firstNonBomChar
        
        $jsonStartsCorrectly = $firstRealChar -eq '{' -or $firstRealChar -eq '['
        
        # Check for other problematic bytes at the start
        $firstFewBytes = ""
        for ($i = 0; $i -lt [Math]::Min(10, $bytes.Length); $i++) {
            $firstFewBytes += [String]::Format("0x{0:X2} ", $bytes[$i])
        }
        
        # Return diagnostic information
        return @{
            FilePath = $FilePath
            Encoding = $encoding
            HasBom = $hasBom
            BomLength = $bomLength
            FirstRealChar = $firstRealChar
            JsonStartsCorrectly = $jsonStartsCorrectly
            FirstFewBytes = $firstFewBytes
        }
    }
    catch {
        Write-Host "Error examining $FilePath : $_" -ForegroundColor Red
        return $null
    }
}

# Function to detect UTF-8 without BOM
function Test-UTF8WithoutBOM {
    param (
        [byte[]]$Bytes
    )
    
    # UTF-8 detection algorithm (simplified)
    for ($i = 0; $i -lt $Bytes.Length; $i++) {
        # Check for multi-byte UTF-8 sequences
        if ($Bytes[$i] -gt 127) {
            # Determine the number of bytes in the sequence
            $bytesInSequence = 0
            $mask = 0x80
            $currentByte = $Bytes[$i]
            
            while (($currentByte -band $mask) -ne 0) {
                $bytesInSequence++
                $mask = $mask -shr 1
            }
            
            # Check if we have a valid UTF-8 sequence
            if ($bytesInSequence -gt 1) {
                # Check if we have enough bytes left
                if ($i + $bytesInSequence > $Bytes.Length) {
                    return $false
                }
                
                # Check that following bytes start with the pattern 10xxxxxx
                for ($j = 1; $j -lt $bytesInSequence; $j++) {
                    if (($Bytes[$i + $j] -band 0xC0) -ne 0x80) {
                        return $false
                    }
                }
                
                # Skip the multi-byte sequence
                $i += $bytesInSequence - 1
            }
        }
    }
    
    return $true
}

# Function to fix a JSON file with encoding issues
function Fix-JSONFile {
    param (
        [string]$FilePath,
        [hashtable]$Diagnostics
    )
    
    try {
        Write-Host "Fixing $FilePath..." -ForegroundColor Yellow
        
        # Create a backup
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $backupPath = "$FilePath.comp_bak_$timestamp"
        Copy-Item -Path $FilePath -Destination $backupPath -Force
        Write-Host "  Created backup at $backupPath" -ForegroundColor Gray
        
        # Read the content from the file
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        
        # Clean up the content
        if ($Diagnostics.HasBom) {
            # Skip the BOM
            $cleanBytes = $bytes[$Diagnostics.BomLength..($bytes.Length - 1)]
            Write-Host "  Removed BOM ($($Diagnostics.BomLength) bytes)" -ForegroundColor Green
        }
        else {
            $cleanBytes = $bytes
        }
        
        # Convert to string
        $content = [System.Text.Encoding]::UTF8.GetString($cleanBytes)
        
        # Clean up any additional issues
        # Remove any leading non-printing characters
        $content = $content -replace '^\s*', ''
        
        # If the file doesn't start with { or [, try to find where the JSON actually starts
        if ($content[0] -ne '{' -and $content[0] -ne '[') {
            $jsonStartIndex = $content.IndexOfAny(@('{', '['))
            if ($jsonStartIndex -gt 0) {
                Write-Host "  Found JSON start at position $jsonStartIndex" -ForegroundColor Yellow
                $content = $content.Substring($jsonStartIndex)
            }
        }
        
        # Try to parse the content as JSON to validate it
        try {
            $jsonObject = ConvertFrom-Json -InputObject $content -ErrorAction Stop
            Write-Host "  JSON content is valid" -ForegroundColor Green
            
            # Convert back to a properly formatted JSON string
            $formattedJson = ConvertTo-Json -InputObject $jsonObject -Depth 100
            
            # Write the content back with UTF-8 encoding without BOM
            [System.IO.File]::WriteAllText($FilePath, $formattedJson, [System.Text.Encoding]::UTF8)
            Write-Host "  Wrote formatted JSON content" -ForegroundColor Green
            
            return $true
        }
        catch {
            Write-Host "  JSON parsing failed: $_" -ForegroundColor Red
            
            # Write the content back anyway, without BOM
            [System.IO.File]::WriteAllText($FilePath, $content, [System.Text.Encoding]::UTF8)
            Write-Host "  Wrote content without BOM but JSON may still be invalid" -ForegroundColor Yellow
            
            return $false
        }
    }
    catch {
        Write-Host "Error fixing $FilePath : $_" -ForegroundColor Red
        return $false
    }
}

# Function to recreate a clean JSON file with known good content
function Recreate-JSONFile {
    param (
        [string]$FilePath,
        [string]$Content
    )
    
    try {
        Write-Host "Recreating $FilePath with clean content..." -ForegroundColor Yellow
        
        # Create a backup first
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $backupPath = "$FilePath.recreate_bak_$timestamp"
        if (Test-Path $FilePath) {
            Copy-Item -Path $FilePath -Destination $backupPath -Force
            Write-Host "  Created backup at $backupPath" -ForegroundColor Gray
        }
        
        # Write clean content with UTF-8 encoding without BOM
        [System.IO.File]::WriteAllText($FilePath, $Content, [System.Text.Encoding]::UTF8)
        
        # Verify the file is valid JSON
        try {
            $null = Get-Content -Path $FilePath -Raw | ConvertFrom-Json -ErrorAction Stop
            Write-Host "  Created valid JSON file" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host "  Failed to verify JSON: $_" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Error recreating $FilePath : $_" -ForegroundColor Red
        return $false
    }
}

# Known good content for project files
$defaultProjectContent = @'
{
  "name": "RobloxProject",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "shared": {
        "$path": "src/shared"
      },
      "DataStorePlugin": {
        "$path": "DataStore Plugin"
      }
    },
    "ServerScriptService": {
      "server": {
        "$path": "src/server"
      }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "client": {
          "$path": "src/client"
        }
      }
    }
  }
}
'@

$dataStorePluginContent = @'
{
  "name": "DataStorePlugin",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "DataStorePlugin": {
        "$path": "DataStore Plugin"
      }
    }
  }
}
'@

$cleanDefaultContent = @'
{
  "name": "RobloxProject-Clean",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "shared": {
        "$path": "src/shared"
      }
    },
    "ServerScriptService": {
      "server": {
        "$path": "src/server"
      }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "client": {
          "$path": "src/client"
        }
      }
    }
  }
}
'@

$cleanPluginContent = @'
{
  "name": "CleanPlugin",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "DataStorePlugin": {
        "$path": "DataStore Plugin/clean"
      }
    }
  }
}
'@

$enhancedContent = @'
{
  "name": "RobloxProject-Enhanced",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "shared": {
        "$path": "src/shared"
      },
      "DataStorePlugin": {
        "$path": "DataStore Plugin"
      }
    },
    "ServerScriptService": {
      "server": {
        "$path": "src/server"
      }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "client": {
          "$path": "src/client"
        }
      }
    },
    "Workspace": {
      "$properties": {
        "FilteringEnabled": true
      }
    }
  }
}
'@

# Process all target JSON files
$targetFiles = @(
    @{ FilePath = "default.project.json"; Content = $defaultProjectContent },
    @{ FilePath = "DataStore-plugin.project.json"; Content = $dataStorePluginContent },
    @{ FilePath = "clean-default.project.json"; Content = $cleanDefaultContent },
    @{ FilePath = "clean-plugin.project.json"; Content = $cleanPluginContent },
    @{ FilePath = "enhanced.project.json"; Content = $enhancedContent }
)

# Process all specified files
foreach ($fileInfo in $targetFiles) {
    $filePath = Join-Path -Path $PSScriptRoot -ChildPath $fileInfo.FilePath
    
    Write-Host "`nProcessing $($fileInfo.FilePath)..." -ForegroundColor Cyan
    
    # First examine the file
    $diagnostics = Examine-FileEncoding -FilePath $filePath
    
    if ($null -eq $diagnostics) {
        # File doesn't exist or can't be read
        Write-Host "  Creating $($fileInfo.FilePath) as it doesn't exist or can't be read" -ForegroundColor Yellow
        Recreate-JSONFile -FilePath $filePath -Content $fileInfo.Content
    }
    elseif ($diagnostics.IsEmpty) {
        # File exists but is empty
        Write-Host "  $($fileInfo.FilePath) is empty, creating with known good content" -ForegroundColor Yellow
        Recreate-JSONFile -FilePath $filePath -Content $fileInfo.Content
    }
    else {
        # Display diagnostics
        Write-Host "  Encoding: $($diagnostics.Encoding)" -ForegroundColor Gray
        Write-Host "  Has BOM: $($diagnostics.HasBom)" -ForegroundColor Gray
        Write-Host "  First character: '$($diagnostics.FirstRealChar)'" -ForegroundColor Gray
        Write-Host "  JSON starts correctly: $($diagnostics.JsonStartsCorrectly)" -ForegroundColor Gray
        Write-Host "  First few bytes: $($diagnostics.FirstFewBytes)" -ForegroundColor Gray
        
        # If the file has issues, fix it
        if ($diagnostics.HasBom -or -not $diagnostics.JsonStartsCorrectly) {
            $fixResult = Fix-JSONFile -FilePath $filePath -Diagnostics $diagnostics
            
            if (-not $fixResult) {
                Write-Host "  Automatic fixing failed, recreating file with known good content" -ForegroundColor Yellow
                Recreate-JSONFile -FilePath $filePath -Content $fileInfo.Content
            }
        }
        else {
            Write-Host "  File appears to be correctly formatted" -ForegroundColor Green
        }
    }
}

Write-Host "`nFinished processing all target JSON files" -ForegroundColor Cyan
Write-Host "You can now try running Argon again" -ForegroundColor Yellow
