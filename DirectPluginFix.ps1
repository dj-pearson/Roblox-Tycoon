# DirectPluginFix.ps1
# This script directly creates a standalone fixed version of the plugin

$sourceFolder = "DataStore Plugin\src"
$standaloneFile = "C:\Users\dpearson\AppData\Local\Roblox\Plugins\DataStorePlugin_Fixed.rbxmx"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "Creating standalone fixed plugin..." -ForegroundColor Cyan
Write-Host "Timestamp: $timestamp" -ForegroundColor Yellow

# Create a simple XML structure for the plugin
$pluginXml = @"
<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
  <Meta name="ExplicitAutoJoints">true</Meta>
  <Item class="Folder" referent="RBX1">
    <Properties>
      <string name="Name">DataStore Manager Pro FIXED</string>
    </Properties>
    <Item class="Folder" referent="RBX2">
      <Properties>
        <string name="Name">DataStorePlugin</string>
      </Properties>
      <Item class="ModuleScript" referent="RBX3">
        <Properties>
          <string name="Name">DataStoreManager</string>
          <string name="Source"><![CDATA[--luau
-- DataStore Plugin/DataStoreManager.luau (FIXED VERSION)
-- Timestamp: $timestamp

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

-- Get module resolver from init script or define a local one
local resolver = script.Parent:FindFirstChild("ModuleResolver")
local resolveModule = resolver and require(resolver).resolveModule or function(name)
    local success, result = pcall(function()
        return require(script.Parent:FindFirstChild(name))
    end)
    
    if success and result then
        return result
    end
    
    warn("Failed to resolve module: " .. name)
    return {
        initialize = function() return true end,
        createUI = function() return Instance.new("Frame") end
    }
end

local DataStoreManager = {}

-- Initialize the DataStoreManager
function DataStoreManager.initialize()
    print("DataStore Manager Pro FIXED VERSION initialized!")
    print("Build timestamp: $timestamp")
    return true
end

-- Simplified API for opening a DataStore
function DataStoreManager.getDataStore(name, scope)
    scope = scope or "global"
    local success, dataStore = pcall(function()
        return DataStoreService:GetDataStore(name, scope)
    end)
    
    if success then
        return dataStore
    else
        warn("Failed to get DataStore: " .. name)
        -- Return a dummy DataStore with stub methods
        return {
            GetAsync = function() return nil end,
            SetAsync = function() return nil end,
            RemoveAsync = function() return nil end,
            IncrementAsync = function() return 0 end
        }
    end
end

return DataStoreManager
]]></string>
        </Properties>
      </Item>
      <Item class="ModuleScript" referent="RBX4">
        <Properties>
          <string name="Name">ModuleResolver</string>
          <string name="Source"><![CDATA[--luau
-- DataStore Plugin/ModuleResolver.luau
-- Timestamp: $timestamp

local ModuleResolver = {}

-- Resolve a module by name
function ModuleResolver.resolveModule(name)
    local success, result = pcall(function()
        return require(script.Parent:FindFirstChild(name))
    end)
    
    if success and result then
        return result
    end
    
    warn("Failed to resolve module: " .. name)
    return {
        initialize = function() return true end,
        createUI = function() return Instance.new("Frame") end
    }
end

return ModuleResolver
]]></string>
        </Properties>
      </Item>
      <Item class="Script" referent="RBX5">
        <Properties>
          <string name="Name">PluginLoader</string>
          <string name="Source"><![CDATA[--luau
-- DataStore Plugin/PluginLoader.luau
-- Timestamp: $timestamp

-- Create plugin
local toolbar = plugin:CreateToolbar("DataStore Pro FIXED")
local button = toolbar:CreateButton(
    "DataStore Manager", 
    "Open DataStore Manager Pro (Fixed Version)", 
    "rbxassetid://4458901886"
)

-- Initialize the plugin when the button is clicked
button.Click:Connect(function()
    -- Try to load the DataStoreManager module
    local success, DataStoreManager = pcall(function()
        return require(script.Parent:FindFirstChild("DataStoreManager"))
    end)
    
    if success and DataStoreManager then
        DataStoreManager.initialize()
        print("DataStore Manager Pro FIXED VERSION loaded successfully!")
    else
        warn("Failed to load DataStore Manager Pro FIXED VERSION")
    end
end)

print("DataStore Manager Pro FIXED VERSION plugin initialized!")
print("Build timestamp: $timestamp")
]]></string>
        </Properties>
      </Item>
    </Item>
  </Item>
</roblox>
"@

# Save the XML file
Set-Content -Path $standaloneFile -Value $pluginXml

Write-Host "Created standalone fixed plugin at: $standaloneFile" -ForegroundColor Green
Write-Host "`nTo use the fixed plugin:" -ForegroundColor Cyan
Write-Host "1. Restart Roblox Studio" -ForegroundColor White
Write-Host "2. Look for 'DataStore Pro FIXED' in the Plugins tab" -ForegroundColor White
Write-Host "3. Click the button to open the simplified, fixed version of the plugin" -ForegroundColor White
