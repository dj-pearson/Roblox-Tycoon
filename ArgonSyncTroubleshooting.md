# Argon Sync Troubleshooting Guide

## Common Sync Issues and Solutions

### JSON Format Issues

#### Problem: Comments in JSON Files
Argon requires standard JSON files without comments. The presence of comments (lines starting with `//`) will cause errors like:

```
ERROR: Failed to parse project at [...] invalid type: sequence, expected struct ProjectNode
```

#### Solution:
1. Use the provided `Fix-JsonFiles.ps1` script:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\Fix-JsonFiles.ps1
   ```
2. This will automatically remove comments from all project JSON files and validate their structure.

### File Size Issues

#### Problem: Files Larger Than 100KB
Argon has a 100KB file size limit for each file. Files exceeding this limit will cause sync errors.

#### Solution:
1. Use the `ValidateDataStorePlugin.ps1` script to identify large files:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\ValidateDataStorePlugin.ps1
   ```
2. Move large files to the Backups folder
3. Update your project file ignores to exclude large files:
   ```json
   "$ignoreFiles": [
       "*.png",
       "Backups/*",
       "*.backup*"
   ]
   ```

### Project Already Exists Error

#### Problem: "Project already exists" Error
This occurs when trying to open a project that's already open in Roblox Studio.

```
ERROR: Project [...] already exists!
```

#### Solution:
1. Close all instances of Roblox Studio
2. Restart Roblox Studio and try again
3. If that doesn't work, try manually deleting the project from Argon plugin in Studio and then re-adding it

## Validation and Testing Tools

### ValidateDataStorePlugin.ps1
This script checks for common issues with the DataStore plugin:
- Validates project file configurations
- Checks for files exceeding size limits
- Validates required files are present
- Checks for JSON comment issues

```powershell
powershell -ExecutionPolicy Bypass -File .\ValidateDataStorePlugin.ps1
```

### Fix-JsonFiles.ps1
This script automatically fixes JSON files by removing comments:
- Creates backups before making changes
- Validates JSON structure after removing comments
- Provides detailed error reports if validation fails

```powershell
powershell -ExecutionPolicy Bypass -File .\Fix-JsonFiles.ps1
```

### Analyze-LuauFile.ps1
This script analyzes large Luau scripts to help optimize them:
- Provides size breakdowns of code vs. comments
- Identifies large functions that can be split
- Suggests optimization strategies

```powershell
powershell -ExecutionPolicy Bypass -File .\Analyze-LuauFile.ps1 -FilePath ".\DataStore Plugin\DataExplorer.server.luau"
```

## Correctly Configured Project Files

### DataStore-plugin.project.json
This is properly configured for Argon sync with the DataStore plugin:

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
            "$ignoreFiles": [
                "*.png",
                "Backups/*",
                "*.backup*"
            ]
        }
    }
}
```

Key points:
- `$className` is set to "Plugin" (required for plugin sync)
- `$properties.RunContext` is set to "Server" (for server execution)
- `$ignoreFiles` excludes large files and backups

## Workflow for Successful Sync

1. Run `Fix-JsonFiles.ps1` to fix any JSON formatting issues
2. Run `ValidateDataStorePlugin.ps1` to check for any remaining issues
3. Run `SyncWithArgon.bat` to sync the plugin to Roblox Studio
4. Check Roblox Studio's output window for any sync errors
5. Test the plugin functionality after syncing

## Support Resources

If you encounter any issues not covered in this guide:
1. Check the [Argon plugin documentation](https://devforum.roblox.com/t/introducing-argon-plugin-to-code-editor/1460230)
2. Visit the [Roblox Developer Forum](https://devforum.roblox.com/) for community support
3. Review the full migration report in `Argon-Migration-Report.md`
