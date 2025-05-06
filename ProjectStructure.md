# Roblox Project Structure Documentation

## Project JSON Files Overview

This document explains the different project JSON files available for synchronization with Roblox Studio using Argon.

### 1. `main.project.json` (Recommended)

This is the recommended project configuration with the proper structure for Plugins:

```json
{
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
        "$ignoreFiles": ["*.png", "Backups/*", "*.backup*"]
      }
    }
  }
}
```

Key features:
- The Plugins section is correctly placed within the DataModel tree (not as a root property)
- Follows standard Roblox service structure hierarchy
- Plain folder paths for code directories

### 2. `default.project.json` (Original)

This is the original project configuration:

```json
{
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
        "$ignoreFiles": ["*.png", "Backups/*", "*.backup*"]
      }
    }
  }
}
```

Key features:
- Each code section is inside a named container ("shared", "server", "Client")
- Plugins are correctly within the DataModel tree

### 3. `DataStore-plugin.project.json` (Plugin Only)

This project file is specifically for syncing just the DataStore plugin:

```json
{
  "name": "DataStore Manager Pro",
  "tree": {
    "$className": "Plugin",
    "$properties": {
      "RunContext": "Server"
    },
    "DataStore Plugin": {
      "$path": "DataStore Plugin",
      "$ignoreUnknownInstances": true,
      "$ignoreFiles": ["*.png", "Backups/*", "*.backup*"]
    }
  }
}
```

Key features:
- Creates a specific Plugin instance
- Sets the RunContext property to "Server"
- Only includes the DataStore Plugin content

## Recommended Usage

1. For working on the complete project (game + plugin): Use `main.project.json`
2. For working only on the DataStore plugin: Use `DataStore-plugin.project.json`
3. For maintaining compatibility with older workflows: Use `default.project.json`

## Synchronization Commands

To synchronize with different project files, use:

- **DataStore Plugin:**
  ```
  run-argon-sync.bat
  ```

- **Main Project (recommended):**
  ```
  run-argon-sync.bat main
  ```

- **Default Project (original):**
  ```
  run-argon-sync.bat default
  ```

Or use the comprehensive setup utility:
```
Argon-Setup.bat
```

## JSON File Maintenance

To clean and validate all JSON project files:
```powershell
powershell -ExecutionPolicy Bypass -File ".\Clean-JsonFiles.ps1"
```

This will ensure all project files are properly formatted and ready for Argon synchronization.
