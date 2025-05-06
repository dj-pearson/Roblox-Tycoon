# DataStore Manager Pro Plugin

## Installation Instructions

### Using Argon
1. Open Roblox Studio
2. Install the Argon plugin if you haven't already
3. In Argon:
   - Select "Open Project"
   - Navigate to the RobloxProject directory
   - Select the `DataStore-plugin.project.json` file (not the default.project.json)
   - Click "Open"
4. The plugin should now sync to your Roblox Studio Plugin folder
5. If prompted to overwrite files, choose "Yes"

### Quick Setup (Windows)
1. Double-click the `SyncWithArgon.bat` file in the RobloxProject folder
2. This will attempt to automatically open Roblox Studio with the Argon plugin
3. Follow any on-screen prompts to complete the synchronization

### Important Notes
- This plugin contains files close to the 100KB limit (DataExplorer.server.luau: 97.32KB, BulkOperationsUI.server.luau: 94.48KB)
- Large image files have been moved to the Backups folder to prevent sync issues
- The main entry point is `init.server.luau`
- We're using the server version of DataExplorer (DataExplorer.server.luau) instead of the non-server version

### Utility Scripts
Several utility scripts are available in the RobloxProject directory to help manage this plugin:

1. **SyncWithArgon.bat** - Automatically opens Roblox Studio with the Argon plugin to sync the DataStore plugin
2. **ValidateDataStorePlugin.ps1** - PowerShell script to check for common issues with the plugin files
3. **Analyze-LuauFile.ps1** - PowerShell script to analyze large Luau scripts and suggest optimizations

To use the file analyzer:
```powershell
# Example: Analyze DataExplorer.server.luau
powershell -ExecutionPolicy Bypass -File .\Analyze-LuauFile.ps1 -FilePath ".\DataStore Plugin\DataExplorer.server.luau"
```

### Troubleshooting
- If the plugin doesn't appear in Roblox Studio after syncing, check the Output window for any errors
- If you see messages about file size limits, verify that all large files (>100KB) have been properly excluded in the project file
- The asset ID for the toolbar button is set to "rbxassetid://7634658388" - if the button has no icon, you may need to use a different asset ID
- Run the ValidateDataStorePlugin.ps1 script to check for common issues:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\ValidateDataStorePlugin.ps1
  ```

## Troubleshooting
If you experience sync issues:
1. Check that no files exceed 100KB
2. Try using DataStore-plugin.project.json file specifically created for this plugin
3. Make sure your Argon plugin is updated to the latest version
