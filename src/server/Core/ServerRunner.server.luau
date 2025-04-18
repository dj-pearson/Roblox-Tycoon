-- ServerRunner.server.luau
-- Entry point script that kicks off our system architecture
-- Place in ServerScriptService/Core

local ServerScriptService = game:GetService("ServerScriptService")

-- Print startup message
print("==================================================")
print("Starting Gym Tycoon System Architecture v2.0")
print("==================================================")

-- Ensure required folders exist
local function ensureFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end
    return folder
end

local CoreFolder = ensureFolder(ServerScriptService, "Core")
local ConnectorsFolder = ensureFolder(ServerScriptService, "Connectors")
local DataFolder = ensureFolder(ServerScriptService, "Data")

-- Load and run the bootstrap
local function loadBootstrap()
    local bootstrap = CoreFolder:FindFirstChild("SystemBootstrap")
    
    if not bootstrap then
        warn("SystemBootstrap.luau not found in ServerScriptService/Core")
        return false
    end
    
    -- Load and run the bootstrap module
    local bootstrapModule = require(bootstrap)
    print("SystemBootstrap loaded successfully")
    
    return true
end

-- Start everything
loadBootstrap()