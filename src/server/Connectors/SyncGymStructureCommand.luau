--[[
    SyncGymStructureCommand.luau - 
    
    A command-line script to run the AnalyzeGymStructure functionality and 
    sync the structure with the BuyTileSystem. This script can be run from
    the command bar in the Roblox Studio to update the configuration after
    making physical changes to the gym.
    
    Usage:
    /syncGymStructure         - Analyze the gym structure and sync with BuyTileSystem
    /syncGymStructure verbose - Include detailed room information in the output
    
    Author: Created April 20, 2025
]]

local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

-- Try to get the Systems from CoreRegistry
local CoreRegistry = require(script.Parent.Parent:FindFirstChild("Core"):FindFirstChild("CoreRegistry") or {})
local BuyTileSystem = CoreRegistry and CoreRegistry:GetSystem("BuyTileSystem")
local GymStructureIntegration = CoreRegistry and CoreRegistry:GetSystem("GymStructureIntegration")

-- Function to analyze the gym structure
local function AnalyzeGymStructure(verbose)
    print("Analyzing gym structure...")
    
    -- Find the GymParts folder in the workspace
    local gymParts = workspace:FindFirstChild("GymParts")
    if not gymParts then
        warn("GymParts folder not found in workspace")
        return
    end
    
    -- Structure to store the analysis results
    local structure = {
        floors = {},
        roomTypes = {},
        roomCounts = {},
        prerequisites = {}
    }
    
    -- Helper function to normalize room names
    local function normalizeRoomName(name)
        return name:gsub("^%s*(.-)%s*$", "%1"):gsub("%s+", " ")
    end
    
    -- Analyze floor structure
    print("Finding floors...")
    for _, floorFolder in pairs(gymParts:GetChildren()) do
        if floorFolder:IsA("Folder") then
            local floorNumber = nil
            
            -- Try to get floor number from attribute
            local floorAttr = floorFolder:GetAttribute("Floor")
            if floorAttr and type(floorAttr) == "number" then
                floorNumber = floorAttr
            else
                -- Try to parse floor number from name
                local name = floorFolder.Name
                if name:match("^(%d+)[stndrh][tdht]%s+Floor$") then
                    floorNumber = tonumber(name:match("^(%d+)"))
                elseif name == "Roof" then
                    floorNumber = 5
                elseif name == "Outside" then
                    floorNumber = 6
                end
            end
            
            if floorNumber then
                print("Found floor: " .. floorFolder.Name .. " (Floor " .. floorNumber .. ")")
                
                -- Initialize floor structure
                structure.floors[floorNumber] = {
                    name = floorFolder.Name,
                    rooms = {},
                    roomCount = 0
                }
                
                -- Find all rooms on this floor
                local roomsFolder = floorFolder:FindFirstChild("Rooms")
                if roomsFolder and roomsFolder:IsA("Folder") then
                    for _, roomFolder in pairs(roomsFolder:GetChildren()) do
                        if roomFolder:IsA("Folder") then
                            local roomName = normalizeRoomName(roomFolder.Name)
                            
                            -- Add room to floor
                            table.insert(structure.floors[floorNumber].rooms, roomName)
                            structure.floors[floorNumber].roomCount = structure.floors[floorNumber].roomCount + 1
                            
                            -- Track room type across floors
                            if not structure.roomTypes[roomName] then
                                structure.roomTypes[roomName] = {}
                            end
                            table.insert(structure.roomTypes[roomName], floorNumber)
                            
                            -- Track room count
                            structure.roomCounts[roomName] = (structure.roomCounts[roomName] or 0) + 1
                            
                            if verbose then
                                print("  - Room: " .. roomName)
                            end
                        end
                    end
                end
                
                -- Sort rooms alphabetically
                table.sort(structure.floors[floorNumber].rooms)
                
                -- Set prerequisites (assumes sequential floor progression)
                if floorNumber > 1 then
                    structure.prerequisites[floorNumber] = {
                        floors = {floorNumber - 1}, -- Requires previous floor
                        baseStructure = {"Walls", "Floor", "Ceiling"}, -- Basic structure elements
                        roomOrder = {} -- Will fill this based on actual order in BuyTileSystem
                    }
                    
                    -- If we have access to BuyTileSystem, get actual order
                    if BuyTileSystem and BuyTileSystem.tileData then
                        -- Extract room order from build order
                        local roomItems = {}
                        for tileType, tileData in pairs(BuyTileSystem.tileData) do
                            if tileData.floor == floorNumber then
                                table.insert(roomItems, {
                                    tileType = tileType,
                                    buildOrder = tileData.buildOrder,
                                    description = tileData.description
                                })
                            end
                        end
                        
                        -- Sort by build order
                        table.sort(roomItems, function(a, b)
                            return a.buildOrder < b.buildOrder
                        end)
                        
                        -- Extract room names
                        for _, item in ipairs(roomItems) do
                            table.insert(structure.prerequisites[floorNumber].roomOrder, item.tileType)
                        end
                    end
                end
            end
        end
    end
    
    -- Count total rooms
    local totalRooms = 0
    for _, count in pairs(structure.roomCounts) do
        totalRooms = totalRooms + count
    end
    
    -- Generate summary
    local summary = "Gym Structure Analysis Summary:\n"
    summary = summary .. "- Found " .. #structure.floors .. " floors\n"
    summary = summary .. "- Found " .. totalRooms .. " total rooms\n"
    summary = summary .. "- Found " .. table.getn(structure.roomTypes) .. " unique room types\n"
    
    -- Add floor details
    summary = summary .. "\nFloor Details:\n"
    for floorNumber, floorData in pairs(structure.floors) do
        summary = summary .. "- Floor " .. floorNumber .. " (" .. floorData.name .. "): " .. floorData.roomCount .. " rooms\n"
        
        if verbose then
            for _, roomName in ipairs(floorData.rooms) do
                summary = summary .. "  - " .. roomName .. "\n"
            end
        end
    end
    
    -- Convert structure to JSON
    local structureJson = HttpService:JSONEncode(structure)
    
    -- Store results in ServerStorage
    local function storeStructureData(data, name, isJson)
        -- Create or update StringValue
        local stringValue = ServerStorage:FindFirstChild(name)
        if not stringValue then
            stringValue = Instance.new("StringValue")
            stringValue.Name = name
            stringValue.Parent = ServerStorage
        end
        
        -- Handle potential size limitations
        if #data > 200000 then
            warn("Warning: " .. name .. " data is large (" .. tostring(#data) .. " chars). Truncating...")
            data = data:sub(1, 200000) .. "\n...[truncated]..."
        end
        
        stringValue.Value = data
        
        print("Stored " .. name .. " data (" .. tostring(#data) .. " chars) in ServerStorage")
    end
    
    storeStructureData(summary, "GymStructureAnalysis", false)
    storeStructureData(structureJson, "GymStructureJSON", true)
    
    print("Gym structure analysis complete")
    print(summary)
    
    -- Return the structure for further processing
    return structure
end

-- Function to sync the gym structure with BuyTileSystem
local function SyncWithBuyTileSystem(structure)
    if not BuyTileSystem then
        warn("BuyTileSystem not found. Cannot sync gym structure.")
        return
    end
    
    if not GymStructureIntegration then
        warn("GymStructureIntegration not found. Cannot sync gym structure.")
        return
    end
    
    -- Ensure GymStructureIntegration has the latest structure data
    GymStructureIntegration:ProcessGymStructureData()
    
    print("Syncing gym structure with BuyTileSystem...")
    
    -- Validate floor unlock requirements
    local floorUnlocks = {}
    for floorNum, prereqs in pairs(structure.prerequisites) do
        if prereqs.floors and #prereqs.floors > 0 then
            -- Get the item that unlocks this floor
            local unlockItem = BuyTileSystem.floorUnlockItems[floorNum]
            if unlockItem then
                floorUnlocks[floorNum] = unlockItem
                print("Floor " .. floorNum .. " is unlocked by: " .. unlockItem)
            else
                warn("Floor " .. floorNum .. " has no unlock item defined in BuyTileSystem")
            end
        end
    end
    
    -- Print summary of findings
    print("Sync complete. Found:")
    print("- " .. #structure.floors .. " floors in structure")
    print("- " .. table.getn(structure.roomTypes) .. " unique room types")
    print("- " .. table.getn(floorUnlocks) .. " floor unlock items defined")
    
    return true
end

-- Command handler function
local function handleSyncGymStructureCommand(sender, args)
    local verbose = false
    if args[1] == "verbose" then
        verbose = true
    end
    
    -- Run the analysis
    local structure = AnalyzeGymStructure(verbose)
    if not structure then
        warn("Failed to analyze gym structure")
        return
    end
    
    -- Sync with BuyTileSystem
    local success = SyncWithBuyTileSystem(structure)
    if success then
        print("Successfully synced gym structure with BuyTileSystem")
    else
        warn("Failed to sync gym structure with BuyTileSystem")
    end
end

-- Register the command with CommandSystem if available
local CommandSystem = CoreRegistry and CoreRegistry:GetSystem("CommandSystem")
if CommandSystem then
    CommandSystem:RegisterCommand("syncGymStructure", handleSyncGymStructureCommand, "Analyze gym structure and sync with BuyTileSystem")
    print("SyncGymStructureCommand: Command registered with CommandSystem")
else
    -- Define a global function to run from the command bar if CommandSystem isn't available
    _G.SyncGymStructure = function(verbose)
        print("Running gym structure sync from global function...")
        handleSyncGymStructureCommand(nil, {verbose and "verbose" or ""})
    end
    
    print("SyncGymStructureCommand: CommandSystem not found. Use _G.SyncGymStructure() from the command bar.")
end