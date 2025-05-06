# Using Rojo Instead of Argon for Plugin Sync

It appears that **Rojo** is the proper tool to use for this project, not Argon. Here's what we've learned:

## Why Rojo Instead of Argon?

1. Rojo is already installed in your environment
2. Rojo is configured in your aftman.toml file
3. The project structure is compatible with Rojo
4. Argon appears to be unavailable or deprecated

## Working Project Configuration

The following project file structure works correctly with Rojo:

```json
{
  "name": "DataStore Manager Pro",
  "tree": {
    "$className": "Folder",
    "DataStorePlugin": {
      "$path": "DataStore Plugin"
    }
  }
}
```

This has been saved as `rojo-plugin-detailed.project.json`.

## Building and Syncing the Plugin

We've created a batch file `Sync-Plugin-Rojo.bat` that will:

1. Build the plugin into an RBXMX file (DataStorePlugin.rbxmx)
2. Start a Rojo server that you can connect to from Studio

## How to Use

1. Run `Sync-Plugin-Rojo.bat`
2. Open Roblox Studio
3. Use the Rojo plugin in Studio to connect to the local server
4. Your plugin will be synchronized to Studio

## Notes on JSON Files

The earlier errors were caused by:
1. UTF-8 BOM characters at the start of JSON files
2. Comments in JSON files (not supported in standard JSON)
3. Incorrect plugin structure for Rojo format

The new approach uses clean, BOM-free JSON files with the correct Rojo structure.

## Previous files

You can keep the other project files for reference, but use the new `rojo-plugin-detailed.project.json` for Rojo synchronization.