# Quick-Fix-Default-JSON.ps1
# This script creates a clean default.project.json file with the DataStore Plugin included

# Define the content for default.project.json
$jsonContent = @'
{
  "name": "RobloxProject",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "shared": {
        "$path": "src/shared"
      }
    },
    "ServerScriptService": {
      "$className": "ServerScriptService",
      "server": {
        "$path": "src/server"
      }
    },
    "StarterPlayer": {
      "$className": "StarterPlayer",
      "StarterPlayerScripts": {
        "$className": "StarterPlayerScripts",
        "client": {
          "$path": "src/client"
        }
      }
    }
  }
}
'@

# Path to the file
$filePath = Join-Path -Path $PSScriptRoot -ChildPath "default.project.json"

# Create a backup if the file exists
if (Test-Path $filePath) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = "$filePath.bak_$timestamp"
    Copy-Item -Path $filePath -Destination $backupPath -Force
    Write-Host "Created backup at $backupPath" -ForegroundColor Yellow
}

# Write the new content with explicit UTF-8 encoding WITHOUT BOM
$utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($filePath, $jsonContent, $utf8NoBomEncoding)

Write-Host "Created clean default.project.json with DataStore Plugin included" -ForegroundColor Green
Write-Host "Now try running: argon serve" -ForegroundColor Cyan
