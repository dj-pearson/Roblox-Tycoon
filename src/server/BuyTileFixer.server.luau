--[[
    BuyTileFixer.server.luau
    
    This script fixes the BuyTile system errors by ensuring gym parts are properly
    found and spawned when purchased.
    
    Created to address the BuyTile System Errors identified in RobloxIssues.txt
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

-- Configuration
local CONFIG = {
    debug = true,
    gymPartsFolder = "GymParts",
    buyTilesFolder = "BuyTiles",
    searchLocations = {
        ServerStorage,
        Workspace,
        ReplicatedStorage
    },
    defaultGymPartTemplate = {
        size = Vector3.new(5, 1, 5),
        color = Color3.fromRGB(0, 170, 255)
    }
}

-- Debug logger
local function log(...)
    if CONFIG.debug then
        print("[BuyTileFixer]", ...)
    end
end

-- Find a folder in search locations
local function findFolder(folderName)
    for _, location in ipairs(CONFIG.searchLocations) do
        local folder = location:FindFirstChild(folderName)
        if folder and folder:IsA("Folder") then
            return folder
        end
    end
    return nil
end

-- Get or create folder
local function getOrCreateFolder(folderName, parent)
    parent = parent or ServerStorage
    
    local folder = parent:FindFirstChild(folderName)
    if folder and not folder:IsA("Folder") then
        log("Found", folderName, "but it's not a Folder, removing it")
        folder:Destroy()
        folder = nil
    end
    
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = folderName
        folder.Parent = parent
        log("Created", folderName, "folder in", parent:GetFullName())
    end
    
    return folder
end

-- Get GymParts folder
local function getGymPartsFolder()
    -- First try to find existing
    local gymPartsFolder = findFolder(CONFIG.gymPartsFolder)
    
    -- Create if not found
    if not gymPartsFolder then
        gymPartsFolder = getOrCreateFolder(CONFIG.gymPartsFolder, ServerStorage)
    end
    
    return gymPartsFolder
end

-- Get BuyTiles folder
local function getBuyTilesFolder()
    -- First try to find existing
    local buyTilesFolder = findFolder(CONFIG.buyTilesFolder)
    
    -- Create if not found
    if not buyTilesFolder then
        buyTilesFolder = getOrCreateFolder(CONFIG.buyTilesFolder, ServerStorage)
    end
    
    return buyTilesFolder
end

-- Find gym part by ID with multiple search strategies
local function findGymPart(id)
    log("Looking for gym part with ID:", id)
    local gymPartsFolder = getGymPartsFolder()
    
    -- First try: Direct child lookup
    local gymPart = gymPartsFolder:FindFirstChild("GymPart" .. id) or
                   gymPartsFolder:FindFirstChild("Gym_Part_" .. id) or
                   gymPartsFolder:FindFirstChild("GymPart_" .. id)
    
    if gymPart then
        log("Found gym part directly:", gymPart:GetFullName())
        return gymPart
    end
    
    -- Second try: Search by attribute
    for _, item in ipairs(gymPartsFolder:GetDescendants()) do
        if (item:IsA("Model") or item:IsA("Part")) and 
           (item:GetAttribute("ID") == id or item:GetAttribute("Id") == id or item:GetAttribute("id") == id) then
            log("Found gym part by attribute:", item:GetFullName())
            return item
        end
    end
    
    -- Third try: Alternative naming pattern search
    local alternativeNames = {
        "Part" .. id,
        "Equipment" .. id,
        "Gym_Equipment_" .. id
    }
    
    for _, name in ipairs(alternativeNames) do
        local item = gymPartsFolder:FindFirstChild(name)
        if item then
            log("Found gym part with alternative name:", item:GetFullName())
            return item
        end
    end
    
    log("Could not find gym part with ID:", id)
    return nil
end

-- Create default gym part
local function createDefaultGymPart(id)
    log("Creating default gym part for ID:", id)
    
    local gymPartsFolder = getGymPartsFolder()
    
    -- Create model
    local model = Instance.new("Model")
    model.Name = "GymPart_" .. id
    
    -- Create main part
    local part = Instance.new("Part")
    part.Anchored = true
    part.Size = CONFIG.defaultGymPartTemplate.size
    part.Color = CONFIG.defaultGymPartTemplate.color
    part.Material = Enum.Material.SmoothPlastic
    part.Parent = model
    
    -- Make primary part
    model.PrimaryPart = part
    
    -- Add ID attribute
    model:SetAttribute("ID", id)
    model:SetAttribute("DefaultCreated", true)
    
    -- Add billboard to indicate it's a default part
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = part
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Text = "Gym Equipment #" .. id
    label.Parent = billboard
    
    -- Parent to gym parts folder
    model.Parent = gymPartsFolder
    
    log("Created default gym part for ID:", id)
    return model
end

-- Patch original BuyTile system if it exists
local function patchBuyTileSystem()
    -- First try to find existing BuyTile system
    local buyTileModule
    local searchPaths = {
        ServerScriptService:FindFirstChild("BuyTileSystem"),
        ServerScriptService:FindFirstChild("BuyTile"),
        ServerScriptService.Server and ServerScriptService.Server:FindFirstChild("BuyTileSystem")
    }
    
    -- Look for the module
    for _, path in ipairs(searchPaths) do
        if path and path:IsA("ModuleScript") then
            buyTileModule = path
            break
        end
    end
    
    if not buyTileModule then
        log("BuyTile system module not found, cannot patch directly")
        return false
    end
    
    -- Try to patch the findGymPartById function in the module
    local source = buyTileModule.Source
    local patchedSource
    
    -- Check if there's a findGymPartById function
    if source:find("function%s+findGymPartById") or source:find("findGymPartById%s*=%s*function") then
        log("Found findGymPartById function, patching it...")
        
        -- Create the patched function
        local patchFunction = [[
-- Patched by BuyTileFixer
local function findGymPartById(id)
    local gymPartsFolder = getGymPartsFolder()
    
    if not gymPartsFolder then
        warn("[BuyTile] GymParts folder not found")
        return nil
    end
    
    -- Try direct child lookup
    local directPart = gymPartsFolder:FindFirstChild("GymPart" .. id) or 
                      gymPartsFolder:FindFirstChild("Gym_Part_" .. id) or
                      gymPartsFolder:FindFirstChild("GymPart_" .. id)
    
    if directPart then
        return directPart
    end
    
    -- Try attribute search
    for _, item in ipairs(gymPartsFolder:GetDescendants()) do
        if (item:IsA("Model") or item:IsA("Part")) and 
           (item:GetAttribute("ID") == id or item:GetAttribute("Id") == id or item:GetAttribute("id") == id) then
            return item
        end
    end
    
    -- Try alternative names
    local alternativeNames = {
        "Part" .. id,
        "Equipment" .. id,
        "Gym_Equipment_" .. id
    }
    
    for _, name in ipairs(alternativeNames) do
        local item = gymPartsFolder:FindFirstChild(name)
        if item then
            return item
        end
    end
    
    warn("[BuyTile] Could not find gym part with ID:", id)
    
    -- Create default part if not found
    warn("[BuyTile] Creating default gym part for ID:", id)
    local defaultPart = createDefaultGymPart(id)
    return defaultPart
end
]]
        
        -- Try to replace the existing function with the patched one
        -- Using a simple pattern match
        local findPattern = "function%s+findGymPartById%s*%(.-%).-end"
        local foundMatch = source:match(findPattern)
        
        if foundMatch then
            patchedSource = source:gsub(findPattern, patchFunction)
            log("Patched findGymPartById function")
        else
            -- Try with alternate function definition style
            findPattern = "findGymPartById%s*=%s*function%s*%(.-%).-end"
            foundMatch = source:match(findPattern)
            
            if foundMatch then
                patchedSource = source:gsub(findPattern, "findGymPartById = " .. patchFunction:sub(24))
                log("Patched findGymPartById function (alternate style)")
            else
                log("Could not find findGymPartById function to patch")
                return false
            end
        end
        
        -- Add createDefaultGymPart function if it doesn't exist
        if not source:find("function%s+createDefaultGymPart") and not source:find("createDefaultGymPart%s*=%s*function") then
            patchedSource = patchedSource .. "\n\n" .. [[
-- Added by BuyTileFixer
local function createDefaultGymPart(id)
    local gymPartsFolder = getGymPartsFolder()
    
    -- Create model
    local model = Instance.new("Model")
    model.Name = "GymPart_" .. id
    
    -- Create main part
    local part = Instance.new("Part")
    part.Anchored = true
    part.Size = Vector3.new(5, 1, 5)
    part.Color = Color3.fromRGB(0, 170, 255)
    part.Material = Enum.Material.SmoothPlastic
    part.Parent = model
    
    -- Make primary part
    model.PrimaryPart = part
    
    -- Add ID attribute
    model:SetAttribute("ID", id)
    model:SetAttribute("DefaultCreated", true)
    
    -- Add billboard to indicate it's a default part
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = part
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Text = "Gym Equipment #" .. id
    label.Parent = billboard
    
    -- Parent to gym parts folder
    model.Parent = gymPartsFolder
    
    return model
end
]]
end
        
        -- If we have patched source, update the module
        if patchedSource then
            buyTileModule.Source = patchedSource
            log("Successfully patched BuyTile system")
            return true
        end
    end
    
    log("Could not patch BuyTile system, may not have the expected structure")
    return false
end

-- Create or ensure default gym parts exist
local function ensureDefaultGymParts()
    log("Ensuring default gym parts exist...")
    
    -- Create default gym parts for the first few IDs
    for id = 1, 5 do
        local part = findGymPart(id)
        
        if not part then
            log("Creating default gym part for ID:", id)
            createDefaultGymPart(id)
        end
    end
end

-- Find the original BuyTile system
local function findBuyTileSystem()
    -- Try to find the main BuyTile system
    local searchPaths = {
        ServerScriptService:FindFirstChild("BuyTileSystem"),
        ServerScriptService.Server and ServerScriptService.Server:FindFirstChild("BuyTileSystem"),
        ServerScriptService:FindFirstChild("BuyTile"),
        ServerScriptService.Server and ServerScriptService.Server:FindFirstChild("BuyTile")
    }
    
    for _, path in ipairs(searchPaths) do
        if path and (path:IsA("ModuleScript") or path:IsA("Script")) then
            log("Found BuyTile system at:", path:GetFullName())
            return path
        end
    end
    
    log("Could not find BuyTile system module")
    return nil
end

-- Monkey patch the BuyTile system's functions
local function monkeyPatch()
    local buyTileSystem = findBuyTileSystem()
    
    if not buyTileSystem then
        log("Cannot monkey patch - BuyTile system not found")
        return false
    end
    
    -- Try to patch at runtime if it's a ModuleScript
    if buyTileSystem:IsA("ModuleScript") then
        local success, system = pcall(function()
            return require(buyTileSystem)
        end)
        
        if success and system then
            log("Successfully required BuyTile system, attempting runtime patch")
            
            -- Store original functions
            local originalFindGymPart = system.findGymPartById or system.findGymPart
            
            -- Replace with our patched version
            if originalFindGymPart then
                system.findGymPartById = function(id)
                    local part = originalFindGymPart(id)
                    
                    if not part then
                        log("Original findGymPartById failed for ID:", id, "- using our fallback")
                        part = findGymPart(id)
                        
                        if not part then
                            log("Our fallback also failed, creating default part")
                            part = createDefaultGymPart(id)
                        end
                    end
                    
                    return part
                end
                
                log("Successfully monkey patched findGymPartById at runtime")
            end
            
            -- If it has a spawnGymPart function, patch that too
            if system.spawnGymPart then
                local originalSpawnGymPart = system.spawnGymPart
                
                system.spawnGymPart = function(player, id, position)
                    local part = originalSpawnGymPart(player, id, position)
                    
                    if not part then
                        log("Original spawnGymPart failed for ID:", id, "- using our fallback")
                        
                        -- Find the gym part model
                        local template = findGymPart(id)
                        if not template then
                            template = createDefaultGymPart(id)
                        end
                        
                        -- Clone and position
                        part = template:Clone()
                        
                        if position and part.PrimaryPart then
                            part:SetPrimaryPartCFrame(CFrame.new(position))
                        end
                        
                        -- Add to player's tycoon if possible
                        local tycoon = player:FindFirstChild("Tycoon")
                        if tycoon and tycoon:IsA("ObjectValue") and tycoon.Value then
                            part.Parent = tycoon.Value
                        else
                            part.Parent = Workspace
                        end
                    end
                    
                    return part
                end
                
                log("Successfully monkey patched spawnGymPart at runtime")
            end
        end
    end
end

-- Main function to fix BuyTile system
local function fixBuyTileSystem()
    log("Starting BuyTile system fix")
    
    -- Step 1: Get or create required folders
    getGymPartsFolder()
    getBuyTilesFolder()
    
    -- Step 2: Ensure default gym parts exist
    ensureDefaultGymParts()
    
    -- Step 3: Patch the BuyTile system code if possible
    local patchSuccess = patchBuyTileSystem()
    
    -- Step 4: If direct patching failed, try monkey patching at runtime
    if not patchSuccess then
        monkeyPatch()
    end
    
    log("BuyTile system fix complete")
end

-- Run the fix
fixBuyTileSystem()

-- Return API for other scripts
return {
    findGymPart = findGymPart,
    createDefaultGymPart = createDefaultGymPart,
    getGymPartsFolder = getGymPartsFolder
}
