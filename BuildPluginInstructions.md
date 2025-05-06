# Manual Plugin Building and Deployment Instructions

If you're having trouble with the automated scripts, you can follow these manual steps to build and deploy the DataStore Plugin.

## Prerequisites

1. Make sure Argon is installed. If not, run `Argon-Setup.bat` first.

## Using PowerShell Script (Easiest)

1. Open PowerShell or command prompt.
2. Navigate to your project directory.
3. Run `.\BuildAndDeployPlugin.bat` or directly run `powershell -ExecutionPolicy Bypass -File BuildDataStorePlugin.ps1`.

## Using Python Script (Alternative)

1. Make sure Python is installed.
2. Navigate to your project directory.
3. Run `.\BuildAndDeployPlugin-Python.bat` or directly run `python BuildDataStorePlugin.py`.

## Manual Steps (If all else fails)

1. Create a temporary directory for building the plugin (e.g., "DataStorePluginTemp").
2. Create a `plugin.project.json` file in the temporary directory with the following content:

```json
{
    "name": "DataStore Manager Pro",
    "tree": {
        "$className": "Plugin",
        "$properties": {
            "RunContext": "Server"
        },
        "$children": [
            {
                "$className": "Script",
                "$name": "Main",
                "$properties": {
                    "Source": "-- DataStore Plugin Main Entry Point\nlocal plugin = plugin -- Use the global plugin variable\n\n-- This is a Roblox plugin for managing DataStore data\nlocal toolbar = plugin:CreateToolbar('DataStore Manager Pro')\nlocal button = toolbar:CreateButton('Open DataStore Manager', 'Open the DataStore Manager Pro Interface', 'rbxassetid://7634658388')\n\n-- Set up event handlers\nbutton.Click:Connect(function()\n    -- Implement plugin functionality here\nend)\n"
                }
            },
            {
                "$className": "Folder",
                "$name": "Modules",
                "$path": "DataStore Plugin"
            }
        ]
    }
}
```

3. Use Argon to build the plugin:
   ```
   argon build .\DataStorePluginTemp\plugin.project.json -o DataStorePlugin.rbxm
   ```

4. Copy the resulting `DataStorePlugin.rbxm` file to your Roblox Plugins folder:
   ```
   %LOCALAPPDATA%\Roblox\Plugins
   ```

## Troubleshooting

If you encounter problems:

1. Make sure Argon is properly installed and in your PATH.
2. Check the structure of your "DataStore Plugin" folder.
3. Make sure you have proper permissions to write to your Plugins folder.
4. If using the scripts, run them with administrator privileges if needed.

Remember to restart Roblox Studio after deploying the plugin for changes to take effect.

```lua
-- DataStore Plugin Main Entry Point
local plugin = plugin -- Use the global plugin variable

-- This is a Roblox plugin for managing DataStore data
local toolbar = plugin:CreateToolbar("DataStore Manager Pro")
local button = toolbar:CreateButton("Open DataStore Manager", "Open the DataStore Manager Pro Interface", "rbxassetid://7634658388")

-- Load all the modules
local dataStorePlugin = require(script.Parent)

-- Set up event handlers
button.Click:Connect(function()
    -- Implement plugin functionality here
end)

return dataStorePlugin
```

4. Update the Argon project file to mark this as a plugin. Add the following to the end of `argon.toml`:
   ```toml
   [plugin]
   enabled = true
   ```

5. Use Argon to build the plugin:
   ```
   argon build DataStorePluginTemp -o DataStorePlugin.rbxm
   ```

6. Copy the resulting `DataStorePlugin.rbxm` file to your Roblox Plugins folder:
   ```
   %LOCALAPPDATA%\Roblox\Plugins
   ```

6. Clean up the temporary directory.

## Troubleshooting

If you encounter problems:

1. Make sure Argon is properly installed and in your PATH.
2. Check the structure of your "DataStore Plugin" folder.
3. Make sure you have proper permissions to write to your Plugins folder.
4. If using the scripts, run them with administrator privileges if needed.

Remember to restart Roblox Studio after deploying the plugin for changes to take effect.
