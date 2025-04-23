--[[
    AnalyzeGymStructure.server.luau
    
    Analyzes the GymParts structure in workspace and generates a text summary
    of the organization by floors, rooms, and other elements.
    
    Run this script in Roblox Studio to get a comprehensive breakdown of
    your gym's organizational structure to help with automating the BuyTileSystem.
    
    Author: Created April 2025
]]

local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

-- Configuration
local EXPORT_TO_OUTPUT = true   -- Print structure to output window
local EXPORT_TO_FILE = true     -- Save structure to a StringValue in ServerStorage
local MAX_DEPTH = 10            -- Maximum depth to traverse in the hierarchy

-- Find GymParts folder
local function findGymPartsFolder()
    local gymParts = Workspace:FindFirstChild("GymParts")
    if not gymParts then
        -- Try to find it in other common locations
        local serverStorage = game:GetService("ServerStorage")
        gymParts = serverStorage:FindFirstChild("GymParts")
        
        if not gymParts then
            -- Look for it in replicated storage
            local replicatedStorage = game:GetService("ReplicatedStorage")
            gymParts = replicatedStorage:FindFirstChild("GymParts")
        end
    end
    
    return gymParts
end

-- Helper function to get floor number from string
local function getFloorNumber(floorName)
    if not floorName or typeof(floorName) ~= "string" then return nil end
    
    -- Extract digit from floor name
    local num = floorName:match("(%d+)[stndrh]")
    if num then
        return tonumber(num)
    end
    
    -- Check for specific floor names
    if floorName:lower():find("ground") or floorName:lower():find("first") or floorName:lower():find("1st") then
        return 1
    elseif floorName:lower():find("second") or floorName:lower():find("2nd") then
        return 2
    elseif floorName:lower():find("third") or floorName:lower():find("3rd") then
        return 3
    elseif floorName:lower():find("fourth") or floorName:lower():find("4th") then
        return 4
    elseif floorName:lower():find("roof") then
        return 5
    elseif floorName:lower():find("outside") or floorName:lower():find("exterior") then
        return 6
    end
    
    return nil
end

-- Format instance attributes for display
local function formatAttributes(instance)
    local result = {}
    
    for name, value in pairs(instance:GetAttributes()) do
        local valueStr = tostring(value)
        if typeof(value) == "string" then
            valueStr = '"' .. valueStr .. '"'
        elseif typeof(value) == "Vector3" then
            valueStr = string.format("Vector3(%.1f, %.1f, %.1f)", value.X, value.Y, value.Z)
        end
        
        table.insert(result, name .. ": " .. valueStr)
    end
    
    if #result > 0 then
        return " [" .. table.concat(result, ", ") .. "]"
    else
        return ""
    end
end

-- Function to analyze the hierarchy and return structured data
local function analyzeHierarchy(instance, depth, maxDepth, parent)
    if depth > maxDepth then return "..." end
    
    local result = {}
    local indent = string.rep("  ", depth)
    
    -- Add this instance to the result
    local floorNum = nil
    if instance:GetAttribute("Floor") then
        floorNum = instance:GetAttribute("Floor")
    elseif parent and parent:GetAttribute("Floor") then
        floorNum = parent:GetAttribute("Floor")
    elseif instance.Name:match("%dst") or instance.Name:match("%dnd") or instance.Name:match("%drd") or instance.Name:match("%dth") then
        floorNum = getFloorNumber(instance.Name)
    end
    
    local floorStr = floorNum and (" (Floor " .. floorNum .. ")") or ""
    table.insert(result, indent .. "- " .. instance.Name .. " [" .. instance.ClassName .. "]" .. floorStr .. formatAttributes(instance))
    
    -- Process children
    local childrenByType = {}
    
    -- Group children by class
    for _, child in pairs(instance:GetChildren()) do
        local className = child.ClassName
        if not childrenByType[className] then
            childrenByType[className] = {}
        end
        table.insert(childrenByType[className], child)
    end
    
    -- Process each type
    for className, children in pairs(childrenByType) do
        -- If there are more than 5 of the same type, summarize
        if #children > 5 and depth > 1 then
            table.insert(result, indent .. "  • " .. #children .. " " .. className .. " objects")
            
            -- Sample a few
            for i = 1, math.min(3, #children) do
                local childAnalysis = analyzeHierarchy(children[i], depth + 1, maxDepth, instance)
                for _, line in ipairs(childAnalysis) do
                    table.insert(result, line)
                end
            end
            
            if #children > 3 then
                table.insert(result, indent .. "    ... and " .. (#children - 3) .. " more " .. className .. " objects")
            end
        else
            -- Process each child individually
            for _, child in ipairs(children) do
                local childAnalysis = analyzeHierarchy(child, depth + 1, maxDepth, instance)
                for _, line in ipairs(childAnalysis) do
                    table.insert(result, line)
                end
            end
        end
    end
    
    return result
end

-- Function to extract room types from the structure
local function extractRoomTypes(gymParts)
    local roomTypes = {}
    
    -- Find all folders/models that could be rooms
    for _, floor in pairs(gymParts:GetChildren()) do
        -- Check if this is a floor folder
        local floorNum = getFloorNumber(floor.Name)
        if floorNum then
            -- Look for rooms folder
            local roomsFolder = floor:FindFirstChild("Rooms")
            if roomsFolder then
                -- Extract room types from this floor
                for _, room in pairs(roomsFolder:GetChildren()) do
                    roomTypes[room.Name] = roomTypes[room.Name] or {}
                    table.insert(roomTypes[room.Name], floorNum)
                end
            else
                -- Try to identify room-like folders directly under the floor
                for _, child in pairs(floor:GetChildren()) do
                    if child:IsA("Folder") or child:IsA("Model") then
                        -- Skip structural elements
                        if not (child.Name:lower():match("wall") or 
                                child.Name:lower():match("floor") or 
                                child.Name:lower():match("ceiling")) then
                            roomTypes[child.Name] = roomTypes[child.Name] or {}
                            table.insert(roomTypes[child.Name], floorNum)
                        end
                    end
                end
            end
        end
    end
    
    return roomTypes
end

-- Function to generate room prerequisites based on structure
local function generateRoomPrerequisites(gymParts)
    local prerequisites = {}
    
    -- Find all floors
    for _, floor in pairs(gymParts:GetChildren()) do
        local floorNum = getFloorNumber(floor.Name)
        if floorNum then
            local floorData = {
                floorNum = floorNum,
                requiredFloors = (floorNum > 1) and { floorNum - 1 } or {},
                baseStructure = {"Walls", "Floor"},
                roomOrder = {}
            }
    
            -- Check for "Rooms" folder to maintain structure
            local roomsFolder = floor:FindFirstChild("Rooms")
            if roomsFolder then
                floorData.roomsFolder = true
            end
            
            -- Each floor should have base structure completed first
            prerequisites[floorNum].baseStructure = {"Walls", "Floor"}
            
            -- Room order
            local roomsFolder = floor:FindFirstChild("Rooms")
            if roomsFolder then -- If rooms are in a dedicated folder
                for _, room in ipairs(roomsFolder:GetChildren()) do
                    table.insert(floorData.roomOrder, room.Name)
                end
            end
    
            -- Assign the collected data to the floor
            prerequisites[floorNum] = floorData
        end
    end
    
    return prerequisites
end

-- Main function to analyze the entire structure
local function analyzeGymStructure()
    local gymParts = findGymPartsFolder()
    if not gymParts then
        warn("GymParts folder not found in workspace or storage")
        return nil
    end
    
    print("Analyzing GymParts structure...")
    
    -- Gather general structure information
    local structure = {
        name = gymParts.Name,
        className = gymParts.ClassName,
        childCount = #gymParts:GetChildren(),
        floors = {},
        floorCount = 0,
        roomTypes = extractRoomTypes(gymParts),
        prerequisites = generateRoomPrerequisites(gymParts),
        hierarchy = analyzeHierarchy(gymParts, 0, MAX_DEPTH)
    }
    
    -- Analyze floors
    for _, child in pairs(gymParts:GetChildren()) do
        local floorNum = getFloorNumber(child.Name)
        if floorNum then
            structure.floorCount = structure.floorCount + 1
            
            local floor = {
                name = child.Name,
                number = floorNum,
                childCount = #child:GetChildren(),
                hasRoomsFolder = child:FindFirstChild("Rooms") ~= nil,
                hasWalls = child:FindFirstChild("Walls") ~= nil,
                hasFloor = child:FindFirstChild("Floor") ~= nil,
                hasCeiling = child:FindFirstChild("Ceiling") ~= nil,
                attributes = child:GetAttributes()
            }
            
            -- Count room types if rooms folder exists
            if floor.hasRoomsFolder then
                floor.rooms = {}
                for _, room in pairs(child:FindFirstChild("Rooms"):GetChildren()) do
                    table.insert(floor.rooms, {
                        name = room.Name,
                        childCount = #room:GetChildren(),
                        attributes = room:GetAttributes()
                    })
                end
            end
            
            structure.floors[floorNum] = floor
        end
    end
    
    return structure
end

-- Function to generate a text summary of the structure
local function generateStructureSummary(structure)
    if not structure then return "No structure data available" end
    
    local lines = {
        "GymParts Structure Analysis",
        "=========================="
    }
    
    -- Basic info
    table.insert(lines, string.format("Name: %s (%s)", structure.name, structure.className))
    table.insert(lines, string.format("Total Floors: %d", structure.floorCount))
    table.insert(lines, string.format("Total Child Elements: %d", structure.childCount))
    table.insert(lines, "")
    
    -- Floor information
    table.insert(lines, "Floor Overview")
    table.insert(lines, "-------------")
    
    -- Sort floors by number
    local sortedFloors = {}
    for num, floor in pairs(structure.floors) do
        table.insert(sortedFloors, {number = num, data = floor})
    end
    table.sort(sortedFloors, function(a, b) return a.number < b.number end)
    
    for _, floorData in ipairs(sortedFloors) do
        local floor = floorData.data
        table.insert(lines, string.format("Floor %d: %s (%d child elements)", 
            floor.number, floor.name, floor.childCount))
        
            -- Check if rooms are in a dedicated folder or directly under the floor
            if floor.hasRoomsFolder then
                table.insert(lines, "  Rooms Folder: Present")
            else
                table.insert(lines, "  Rooms: Directly under the floor")
            end
            
        local structureElements = {}
        if floor.hasWalls then table.insert(structureElements, "Walls") end
        if floor.hasFloor then table.insert(structureElements, "Floor") end
        if floor.hasCeiling then table.insert(structureElements, "Ceiling") end
        
        if #structureElements > 0 then
            table.insert(lines, "  Structure Elements: " .. table.concat(structureElements, ", "))
        end
        
        -- Display room info
        if floor.hasRoomsFolder and floor.rooms then
            table.insert(lines, string.format("  Rooms (%d):", #floor.rooms))
            for _, room in ipairs(floor.rooms) do
                table.insert(lines, string.format("    - %s (%d elements)", room.name, room.childCount))
            end
        end
    end
    table.insert(lines, "")
    
    -- Room types across floors
    table.insert(lines, "Room Types")
    table.insert(lines, "----------")
    
    local sortedRoomTypes = {}
    for roomName, floors in pairs(structure.roomTypes) do
        table.insert(sortedRoomTypes, {name = roomName, floors = floors})
    end
    table.sort(sortedRoomTypes, function(a, b) return a.name < b.name end)
    
    for _, roomType in ipairs(sortedRoomTypes) do
        table.sort(roomType.floors)
        table.insert(lines, string.format("- %s: Found on floor(s) %s", 
            roomType.name, table.concat(roomType.floors, ", ")))
    end
    table.insert(lines, "")
    
    -- Prerequisites
    table.insert(lines, "Prerequisites Structure")
    table.insert(lines, "---------------------")
    
    -- Sort prerequisites by floor number
    local sortedPrerequisites = {}
    for floorNum, data in pairs(structure.prerequisites) do
        table.insert(sortedPrerequisites, {number = floorNum, data = data})
    end
    table.sort(sortedPrerequisites, function(a, b) return a.number < b.number end)
    
    -- Display prerequisites for each floor
    for _, entry in ipairs(sortedPrerequisites) do
        local floorNum = entry.number
        local prereq = entry.data
    
        table.insert(lines, string.format("Floor %d:", floorNum))
        if #prereq.requiredFloors > 0 then
            table.insert(lines, "  Required Floors: " .. table.concat(prereq.requiredFloors, ", "))
        end
        table.insert(lines, "  Base Structure: " .. table.concat(prereq.baseStructure, ", "))
        table.insert(lines, "  Room Order: " .. ((#prereq.roomOrder > 0) and table.concat(prereq.roomOrder, " → ") or "None"))
    end
    
    table.insert(lines, "")
    
    -- Full hierarchy
    table.insert(lines, "Full Hierarchy")
    table.insert(lines, "-------------")
    for _, line in ipairs(structure.hierarchy) do
        table.insert(lines, line)
    end
    
    return table.concat(lines, "\n")
end

-- Main execution
local function main()
    local structure = analyzeGymStructure()
    local summary = generateStructureSummary(structure)
    
    -- Export to output
    if EXPORT_TO_OUTPUT then
        print("\n\n" .. summary)
    end
    
    -- Export to file
    if EXPORT_TO_FILE then
        local serverStorage = game:GetService("ServerStorage")
        
        -- Create or get StringValue object
        local structureData = serverStorage:FindFirstChild("GymStructureAnalysis")
        if not structureData then
            structureData = Instance.new("StringValue")
            structureData.Name = "GymStructureAnalysis"
            structureData.Parent = serverStorage
        end
        
        -- Save the data
        structureData.Value = summary
        
        -- Also create a JSON version for potential use in other scripts
        local jsonData = serverStorage:FindFirstChild("GymStructureJSON")
        if not jsonData then
            jsonData = Instance.new("StringValue")
            jsonData.Name = "GymStructureJSON"
            jsonData.Parent = serverStorage
        end
        
        -- Save as JSON
        local structureJson = HttpService:JSONEncode(structure)
        jsonData.Value = structureJson
        
        print("Structure analysis saved to ServerStorage.GymStructureAnalysis")
        print("JSON data saved to ServerStorage.GymStructureJSON")
    end
    
    return summary
end

-- Execute the analysis
main()