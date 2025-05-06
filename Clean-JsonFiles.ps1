# Clean-JsonFiles.ps1
# This script provides a more aggressive cleanup of JSON project files
# It completely recreates the files with known good content

# Define file paths
$defaultProjectFile = "c:\Users\dpearson\OneDrive\Documents\RobloxProject\default.project.json"
$pluginProjectFile = "c:\Users\dpearson\OneDrive\Documents\RobloxProject\DataStore-plugin.project.json"
$mainProjectFile = "c:\Users\dpearson\OneDrive\Documents\RobloxProject\main.project.json"

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
      }
    },
    "ServerScriptService": {
      "server": {
        "$path": "src/server"
      }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "Client": {
          "$path": "src/client"
        }
      }
    },
    "Plugins": {
      "DataStore Plugin": {
        "$path": "DataStore Plugin",
        "$ignoreUnknownInstances": true,
        "$ignoreFiles": [
          "*.png",
          "Backups/*",
          "*.backup*"
        ]
      }
    }
  }
}'

# Known good content for DataStore-plugin.project.json
$pluginProjectContent = '{
  "name": "DataStore Manager Pro",
  "tree": {
    "$className": "Plugin",
    "$properties": {
      "RunContext": "Server"
    },
    "DataStore Plugin": {
      "$path": "DataStore Plugin",
      "$ignoreUnknownInstances": true,
      "$ignoreFiles": [
        "*.png",
        "Backups/*",
        "*.backup*"
      ]
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
    },
    "Plugins": {
      "DataStore Plugin": {
        "$path": "DataStore Plugin",
        "$ignoreUnknownInstances": true,
        "$ignoreFiles": [
          "*.png",
          "Backups/*",
          "*.backup*"
        ]
      }
    }
  }
}'

# Create backup directory if it doesn't exist
$backupDir = "c:\Users\dpearson\OneDrive\Documents\RobloxProject\JsonBackups"
if (-not (Test-Path $backupDir)) {
    New-Item -Path $backupDir -ItemType Directory | Out-Null
    Write-Host "Created backup directory: $backupDir" -ForegroundColor Yellow
}

# Timestamp for backups
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Process default.project.json
Write-Host "Processing default.project.json..." -ForegroundColor Yellow
if (Test-Path $defaultProjectFile) {
    # Create backup
    $backupPath = Join-Path $backupDir "default.project.json.backup.$timestamp"
    Copy-Item -Path $defaultProjectFile -Destination $backupPath
    Write-Host "Created backup at: $backupPath" -ForegroundColor Green
    
    # Remove old file
    Remove-Item -Path $defaultProjectFile
    
    # Create new file
    $defaultProjectContent | Set-Content -Path $defaultProjectFile -NoNewline
    Write-Host "Recreated default.project.json with clean content" -ForegroundColor Green
}
else {
    Write-Host "default.project.json not found, creating new file" -ForegroundColor Yellow
    $defaultProjectContent | Set-Content -Path $defaultProjectFile -NoNewline
    Write-Host "Created default.project.json with clean content" -ForegroundColor Green
}

# Process DataStore-plugin.project.json
Write-Host "`nProcessing DataStore-plugin.project.json..." -ForegroundColor Yellow
if (Test-Path $pluginProjectFile) {
    # Create backup
    $backupPath = Join-Path $backupDir "DataStore-plugin.project.json.backup.$timestamp"
    Copy-Item -Path $pluginProjectFile -Destination $backupPath
    Write-Host "Created backup at: $backupPath" -ForegroundColor Green
    
    # Remove old file
    Remove-Item -Path $pluginProjectFile
    
    # Create new file
    $pluginProjectContent | Set-Content -Path $pluginProjectFile -NoNewline
    Write-Host "Recreated DataStore-plugin.project.json with clean content" -ForegroundColor Green
}
else {
    Write-Host "`nWarning: DataStore-plugin.project.json not found, creating it..." -ForegroundColor Yellow
    $pluginProjectContent | Set-Content -Path $pluginProjectFile -NoNewline
    Write-Host "Created DataStore-plugin.project.json with clean content" -ForegroundColor Green
}

# Process main.project.json
Write-Host "`nProcessing main.project.json..." -ForegroundColor Yellow
if (Test-Path $mainProjectFile) {
    # Create backup
    $backupPath = Join-Path $backupDir "main.project.json.backup.$timestamp"
    Copy-Item -Path $mainProjectFile -Destination $backupPath
    Write-Host "Created backup at: $backupPath" -ForegroundColor Green
    
    # Remove old file
    Remove-Item -Path $mainProjectFile
    
    # Create new file
    $mainProjectContent | Set-Content -Path $mainProjectFile -NoNewline
    Write-Host "Recreated main.project.json with clean content" -ForegroundColor Green
}
else {
    Write-Host "`nWarning: main.project.json not found, creating it..." -ForegroundColor Yellow
    $mainProjectContent | Set-Content -Path $mainProjectFile -NoNewline
    Write-Host "Created main.project.json with clean content" -ForegroundColor Green
}

# Verify files
Write-Host "`nVerifying files..." -ForegroundColor Yellow
$files = @($defaultProjectFile, $pluginProjectFile, $mainProjectFile)
$allValid = $true

foreach ($file in $files) {
    $fileName = Split-Path $file -Leaf
    
    try {
        $fileContent = Get-Content -Path $file -Raw
        $null = $fileContent | ConvertFrom-Json
        Write-Host "? $fileName - Valid JSON" -ForegroundColor Green
    }
    catch {
        Write-Host "? $fileName - Invalid JSON: $($_.Exception.Message)" -ForegroundColor Red
        $allValid = $false
    }
}

Write-Host "`nSummary:" -ForegroundColor Cyan
if ($allValid) {
    Write-Host "? All files have been cleaned and validated successfully." -ForegroundColor Green
    Write-Host "? You can now try syncing with Argon." -ForegroundColor Green
}
else {
    Write-Host "? Some issues were detected. Further investigation may be needed." -ForegroundColor Red
}

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Run run-argon-sync.bat to sync the DataStore plugin" -ForegroundColor White
Write-Host "2. Run run-argon-sync.bat main to sync the main Roblox project" -ForegroundColor White

Read-Host "`nPress Enter to exit..."
