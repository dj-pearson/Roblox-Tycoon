# Recreate-JSON-Files.ps1
# This script recreates project.json files from scratch with valid JSON content

# Function to create a clean project.json file
function Create-CleanJSON {
    param(
        [string]$FileName,
        [string]$Content
    )
    
    $filePath = Join-Path -Path $PSScriptRoot -ChildPath $FileName
    
    # Create a backup if the file exists
    if (Test-Path $filePath) {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $backupPath = "$filePath.original_$timestamp"
        Copy-Item -Path $filePath -Destination $backupPath -Force
        Write-Host "Created backup at $backupPath" -ForegroundColor Yellow
    }
    
    # Write new content with explicit UTF-8 encoding without BOM
    [System.IO.File]::WriteAllText($filePath, $Content, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Created clean file: $FileName" -ForegroundColor Green
    
    # Verify JSON validity
    try {
        $null = Get-Content -Path $filePath -Raw | ConvertFrom-Json
        Write-Host "JSON validation passed for $FileName" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "JSON validation failed for $FileName: $_" -ForegroundColor Red
        return $false
    }
}

# Main script execution
Write-Host "Starting JSON file recreation process..." -ForegroundColor Cyan

# Recreate default.project.json
$defaultContent = @'
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
Create-CleanJSON -FileName "default.project.json" -Content $defaultContent

# Recreate clean-default.project.json
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
Create-CleanJSON -FileName "clean-default.project.json" -Content $cleanDefaultContent

# Recreate DataStore-plugin.project.json
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
Create-CleanJSON -FileName "DataStore-plugin.project.json" -Content $dataStorePluginContent

# Recreate clean-plugin.project.json
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
Create-CleanJSON -FileName "clean-plugin.project.json" -Content $cleanPluginContent

# Recreate enhanced.project.json
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
Create-CleanJSON -FileName "enhanced.project.json" -Content $enhancedContent

Write-Host "`nJSON recreation process complete!" -ForegroundColor Cyan
Write-Host "You can now try running Argon again." -ForegroundColor Yellow
