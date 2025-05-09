# UI System Migration Implementation & Testing Script

This document provides a step-by-step approach to safely migrate from the old UI scripts to the new modular UI system.

## Verification Checklist

Before beginning elimination, verify the new UI system is fully functional:

- [ ] UIBootstrap.client.luau exists in StarterPlayerScripts or is properly referenced
- [ ] All core modules (UISystem, UIManager, UIUtils, UIConstants) exist and are free of errors
- [ ] All UI components are implemented and functional
- [ ] The systems (ClientRegistry, ClientEventBridge) required by UIBootstrap exist

## Migration Phase 1: Preparation

1. **Create a backup script to save all current UI scripts**

```lua
-- BackupUIScripts.server.lua - Place in ServerScriptService to run once
local ServerStorage = game:GetService("ServerStorage")

-- Create backup folder
local backupFolder = Instance.new("Folder")
backupFolder.Name = "Legacy_UI_Backup"
backupFolder.Parent = ServerStorage

-- Function to clone scripts from a location
local function backupScriptsFrom(location, targetFolder)
    local folder = Instance.new("Folder")
    folder.Name = location.Name
    folder.Parent = targetFolder
    
    for _, child in ipairs(location:GetChildren()) do
        if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") then
            if child.Name:find("UI") then -- Only backup UI-related scripts
                local clone = child:Clone()
                clone.Parent = folder
            end
        elseif child:IsA("Folder") or child:IsA("Configuration") then
            backupScriptsFrom(child, folder)
        end
    end
end

-- Create specific backup folders and perform backups
local sgFolder = Instance.new("Folder")
sgFolder.Name = "StarterGui"
sgFolder.Parent = backupFolder
backupScriptsFrom(game:GetService("StarterGui"), sgFolder)

local spsFolder = Instance.new("Folder")
spsFolder.Name = "StarterPlayerScripts"
spsFolder.Parent = backupFolder
backupScriptsFrom(game:GetService("StarterPlayer").StarterPlayerScripts, spsFolder)

local rsFolder = Instance.new("Folder")
rsFolder.Name = "ReplicatedStorage"
rsFolder.Parent = backupFolder
-- Only backup client/UI folder content from ReplicatedStorage
if game:GetService("ReplicatedStorage"):FindFirstChild("src") and 
   game:GetService("ReplicatedStorage").src:FindFirstChild("client") and
   game:GetService("ReplicatedStorage").src.client:FindFirstChild("UI") then
    backupScriptsFrom(game:GetService("ReplicatedStorage").src.client.UI, rsFolder)
end

print("UI Script backup complete! Backup stored in ServerStorage.Legacy_UI_Backup")
```

2. **Create a flag system to enable/disable old UI temporarily**

```lua
-- UIToggle.lua - Place as a ModuleScript in ReplicatedStorage
local UIToggle = {
    UseNewUISystem = true, -- Set to true to use the new UI system, false to use old
}

return UIToggle
```

## Migration Phase 2: Disabling Old UI

Modify each old UI script to respect the toggle flag. This allows for quick switching between systems during testing:

1. **Example modification to an old UI script:**

```lua
-- Add to the top of each old UI script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIToggle = require(ReplicatedStorage:WaitForChild("UIToggle"))

-- Skip this script if using new UI
if UIToggle.UseNewUISystem then
    return
end

-- Original script content continues below...
```

2. **Place the new UIBootstrap in the correct location**

Ensure UIBootstrap.client.luau is placed as a LocalScript in StarterPlayerScripts and also respects the toggle:

```lua
-- Add to the top of UIBootstrap.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage") 
local UIToggle = require(ReplicatedStorage:WaitForChild("UIToggle"))

-- Skip this script if using old UI
if not UIToggle.UseNewUISystem then
    return
end

-- Rest of UIBootstrap code...
```

## Migration Phase 3: Testing With Toggle

1. Test with `UseNewUISystem = true` (should use only new UI)
2. Test with `UseNewUISystem = false` (should use only old UI)
3. Verify all UI functionality works correctly in both modes
4. Document any issues or missing features in the new UI system

## Migration Phase 4: Final Elimination

Once testing confirms the new UI system fully replaces the old one:

1. **Create an elimination script:**

```lua
-- EliminateOldUI.server.lua - Run once to remove old UI scripts
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- List of scripts to eliminate
local scriptsToEliminate = {
    {StarterGui, "MainMenuUI"}, 
    {StarterGui, "SettingsUI"},
    {StarterGui, "StatsGui"},
    {StarterGui, "RebirthUI"},
    {StarterGui, "RebirthUI_Enhanced"},
    {StarterGui, "RebirthMenuUI"},
    {StarterGui, "RebirthUIFixes"},
    {StarterGui, "TemperatureDisplay"},
    {StarterGui, "DoubleMemberPurchaseGui"},
    {StarterGui, "BuilderBoostPurchaseGui"},
    {StarterGui, "CloseButtonFactory"},
    {StarterPlayer.StarterPlayerScripts, "UIComponentDemo"},
    -- Add other scripts from your elimination list
}

-- Eliminate scripts
local eliminatedCount = 0
for _, scriptInfo in ipairs(scriptsToEliminate) do
    local parent, scriptName = scriptInfo[1], scriptInfo[2]
    
    local script = parent:FindFirstChild(scriptName)
    if script then
        script:Destroy()
        eliminatedCount = eliminatedCount + 1
        print("Eliminated: " .. scriptName)
    else
        print("Not found: " .. scriptName)
    end
end

print("Eliminated " .. eliminatedCount .. " old UI scripts")
```

2. **Remove the UIToggle system**

3. **Final test with only the new UI system active**

## Migration Phase 5: Documentation

1. Update all documentation to reference only the new UI system
2. Document eliminated scripts for future reference
3. Create a guide for adding new UI components using the modular system

## Summary

This phased approach allows for:
- Safely testing the new UI system alongside the old
- Easy rollback if issues are discovered
- Complete validation before final elimination
- Documentation of the migration process

After this migration, you should have a cleaner, more modular, and more maintainable UI system that follows best practices.
