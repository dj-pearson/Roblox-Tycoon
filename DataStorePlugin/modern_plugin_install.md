# Modern Roblox Studio Plugin Installation (0.676.x+)

## Method 1: Direct File Installation
1. Copy `DataStorePlugin-Simple.rbxmx` to:
   ```
   %LOCALAPPDATA%\Roblox\Plugins\DataStoreManager.rbxmx
   ```
2. Restart Studio completely
3. Look for "DataStore Tools" toolbar

## Method 2: Marketplace Installation (If Available)
1. Open Studio
2. Go to **Avatar** → **Marketplace** 
3. Search for DataStore plugins
4. Install from there

## Method 3: Create as LocalScript in ServerStorage
If plugins don't work, create a LocalScript in ServerStorage with the plugin code

## Method 4: Studio Developer Console
1. Press F9 to open Developer Console
2. Go to Server tab
3. Paste the plugin code and run it manually

## Troubleshooting Modern Studio

### Common Issues:
- **Plugin loading disabled**: Check Studio Settings → Security
- **Antivirus blocking**: Whitelist Roblox plugins folder
- **Permissions**: Run Studio as administrator once

### Success Indicators:
```
DataStore Manager Plugin Loading...
Plugin object type: Plugin
✓ Plugin context detected successfully
✓ Toolbar created: DataStore Tools
✓ Button created successfully
```

### Failed Installation Signs:
```
Plugin object type: Instance  ← Should be "Plugin"
Script is not running as a plugin
```

## Alternative: In-Game Testing
1. Create a new place
2. Add a Script to ServerScriptService
3. Paste the plugin code (without plugin-specific functions)
4. Test DataStore functionality directly 