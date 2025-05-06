# Testing the DataStore Plugin with Argon

This document provides instructions for testing the DataStore Plugin as a standalone Roblox plugin using Argon.

## Prerequisites

Before testing, ensure you have:

1. Node.js installed (v14 or newer)
2. Argon CLI installed globally (`npm install -g @argon/cli`)
3. Roblox Studio installed and logged in

## Files Overview

- `DataStore-plugin.project.json`: The standalone plugin project file
- `Test-PluginSync.bat`: A utility script to synchronize just the plugin

## Plugin Structure

The DataStore plugin is structured as follows:

```
DataStore Plugin/
├── init.server.luau (Entry point)
├── Various module scripts (.luau files)
├── Backups/ (Contains large image files)
└── Documentation files
```

## Testing Steps

1. **Run the Test Script**:
   - Double-click on `Test-PluginSync.bat`
   - This will synchronize only the DataStore Plugin to Roblox Studio

2. **Verify in Roblox Studio**:
   - Open Roblox Studio
   - Check the Plugins tab to see if "DataStore Manager Pro" appears
   - Click on the plugin icon to open the interface

3. **Troubleshooting**:
   - If the plugin doesn't appear, check the console output for any errors
   - Ensure large image files are excluded in the project file
   - Verify that init.server.luau correctly requires all necessary modules

## Plugin Synchronization

The standalone plugin is configured to:

1. Ignore large PNG files (exceeding Argon's 100KB limit)
2. Ignore backup files (with .backup extension)
3. Include all necessary Luau scripts

The plugin is set with `RunContext: "Server"` as required for a server-side plugin.

## Additional Notes

- The plugin uses asset ID `7634658388` for its icon
- Large images have been backed up to the Backups folder
- Multiple .server.luau and .luau files are included and properly linked
