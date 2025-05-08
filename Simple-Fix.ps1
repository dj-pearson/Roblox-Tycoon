# Simple-Fix.ps1
# Create clean JSON files directly using Set-Content

$defaultJson = @'
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

# Write directly to files with UTF-8 encoding (no BOM)
$utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText("$PSScriptRoot\default.project.json", $defaultJson, $utf8NoBomEncoding)

Write-Host "Created clean default.project.json" -ForegroundColor Green
