# Clean-JsonFiles-Fixed.ps1
# This script provides a more aggressive cleanup of JSON project files
# It completely recreates the files with known good content

# Define file paths using $PSScriptRoot to make them dynamic
$defaultProjectFile = Join-Path -Path $PSScriptRoot -ChildPath "default.project.json"
$pluginProjectFile = Join-Path -Path $PSScriptRoot -ChildPath "DataStore-plugin.project.json"
$mainProjectFile = Join-Path -Path $PSScriptRoot -ChildPath "main.project.json"
$cleanDefaultProjectFile = Join-Path -Path $PSScriptRoot -ChildPath "clean-default.project.json"
$cleanPluginProjectFile = Join-Path -Path $PSScriptRoot -ChildPath "clean-plugin.project.json"
$enhancedProjectFile = Join-Path -Path $PSScriptRoot -ChildPath "enhanced.project.json"

Write-Host "Argon JSON Project Files Deep Clean" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Known good content for default.project.json
$defaultProjectContent = '{
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
}'

# Known good content for DataStore-plugin.project.json
$pluginProjectContent = '{
  "name": "DataStorePlugin",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "DataStorePlugin": {
        "$path": "DataStore Plugin"
      }
    }
  }
}'

# Known good content for main.project.json
$mainProjectContent = '{
  "name": "RobloxProject",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$path": "src/shared"
    },
    "ServerScriptService": {
      "$path": "src/server"
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "$path": "src/client"
      }
    }
  }
}'

# Known good content for clean-default.project.json
$cleanDefaultProjectContent = '{
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
}'

# Known good content for clean-plugin.project.json
$cleanPluginProjectContent = '{
  "name": "CleanPlugin",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "DataStorePlugin": {
        "$path": "DataStore Plugin/clean"
      }
    }
  }
}'

# Known good content for enhanced.project.json
$enhancedProjectContent = '{
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
}'

# Create backup directory if it doesn't exist
$backupDir = Join-Path -Path $PSScriptRoot -ChildPath "JsonBackups"
if (-not (Test-Path $backupDir)) {
    New-Item -Path $backupDir -ItemType Directory | Out-Null
    Write-Host "Created backup directory: $backupDir" -ForegroundColor Yellow
}

# Timestamp for backups
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Function to process a file with known good content
function Process-JsonFile {
    param (
        [string]$FilePath,
        [string]$Content,
        [string]$FileName
    )
    
    Write-Host "Processing $FileName..." -ForegroundColor Yellow
    
    if (Test-Path $FilePath) {
        # Create backup
        $backupPath = Join-Path $backupDir "$FileName.backup.$timestamp"
        Copy-Item -Path $FilePath -Destination $backupPath
        Write-Host "Created backup at: $backupPath" -ForegroundColor Green
        
        # Remove old file
        Remove-Item -Path $FilePath
        
        # Create new file - explicitly with NO BOM
        $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($FilePath, $Content, $utf8NoBomEncoding)
        
        Write-Host "Recreated $FileName with clean content (UTF-8 without BOM)" -ForegroundColor Green
    }
    else {
        Write-Host "$FileName not found, creating new file" -ForegroundColor Yellow
        
        # Create new file - explicitly with NO BOM
        $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($FilePath, $Content, $utf8NoBomEncoding)
        
        Write-Host "Created $FileName with clean content (UTF-8 without BOM)" -ForegroundColor Green
    }
    
    # Verify the file is valid JSON
    try {
        $null = Get-Content -Path $FilePath -Raw | ConvertFrom-Json -ErrorAction Stop
        Write-Host "✓ JSON validation passed for $FileName" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ JSON validation failed for $FileName: $_" -ForegroundColor Red
        return $false
    }
}

# Process all files
Process-JsonFile -FilePath $defaultProjectFile -Content $defaultProjectContent -FileName "default.project.json"
Process-JsonFile -FilePath $pluginProjectFile -Content $pluginProjectContent -FileName "DataStore-plugin.project.json"
Process-JsonFile -FilePath $mainProjectFile -Content $mainProjectContent -FileName "main.project.json"
Process-JsonFile -FilePath $cleanDefaultProjectFile -Content $cleanDefaultProjectContent -FileName "clean-default.project.json"
Process-JsonFile -FilePath $cleanPluginProjectFile -Content $cleanPluginProjectContent -FileName "clean-plugin.project.json"
Process-JsonFile -FilePath $enhancedProjectFile -Content $enhancedProjectContent -FileName "enhanced.project.json"

Write-Host "`nAll JSON files have been processed." -ForegroundColor Cyan
Write-Host "You can now try running Argon again." -ForegroundColor Yellow
Write-Host "Command: argon serve" -ForegroundColor Gray
