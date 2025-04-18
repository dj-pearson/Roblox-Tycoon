-- SaunaSystem.luau
-- Core system for managing saunas, temperature effects, and wellness benefits
-- Place in ServerScriptService/Core

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

-- System Dependencies
local CoreRegistry
local EventBridge
local DataManager

-- Configuration
local CONFIG = {
    -- Room settings
    identifyRoomsByModel = true, -- If true, looks for models named "Sauna"
    saunaTag = "SaunaRoom",      -- Tag for sauna rooms
    heaterTag = "SaunaHeater",   -- Tag for sauna heaters
    doorTag = "SaunaDoor",       -- Tag for sauna doors
    
    -- Temperature settings
    minTemperature = 20,         -- Minimum temperature (room temperature)
    maxTemperature = 100,        -- Maximum temperature (highest sauna can reach)
    defaultStartingTemp = 30,    -- Default starting temperature
    heatingRate = 5,             -- Degrees per minute gained with heaters on
    coolingRate = 2,             -- Degrees per minute lost with heaters off
    doorCoolingRate = 10,        -- Additional cooling when door is open
    
    -- Health effects
    healthRestoreEnabled = true, -- Whether saunas restore health
    healthRestoreRate = 5,       -- Health per minute restored in optimal temperature
    optimalTemperature = 80,     -- Temperature with maximum benefits
    
    -- Debug
    debug = true                 -- Show debug messages
}

-- Module table
local SaunaSystem = {
    _name = "SaunaSystem",
    _version = "1.0.0",
    _dependencies = {"CoreRegistry", "EventBridge", "DataManager"},
    
    -- Internal state
    _rooms = {},
    _heaters = {},
    _doors = {},
    _playerData = {},
    _updateLoop = nil
}

-- Debug function
local function debugPrint(...)
    if CONFIG.debug then
        print("[SaunaSystem]", ...)
    end
end

--[[ Core Functions ]]--

-- Find all sauna heaters in the workspace
function SaunaSystem:_findSaunaHeaters()
    local heaters = {}
    
    -- Find by tag
    for _, heater in pairs(CollectionService:GetTagged(CONFIG.heaterTag)) do
        table.insert(heaters, heater)
    end
    
    -- Find by name
    if #heaters == 0 then
        for _, instance in pairs(Workspace:GetDescendants()) do
            if instance.Name == "SaunaHeater" and (instance:IsA("BasePart") or instance:IsA("Model")) then
                table.insert(heaters, instance)
            end
        end
    end
    
    return heaters
end

-- Find all sauna doors in the workspace
function SaunaSystem:_findSaunaDoors()
    local doors = {}
    
    -- Find by tag
    for _, door in pairs(CollectionService:GetTagged(CONFIG.doorTag)) do
        table.insert(doors, door)
    end
    
    -- Find by name
    if #doors == 0 then
        for _, instance in pairs(Workspace:GetDescendants()) do
            if instance.Name:match("SaunaDoor") and (instance:IsA("BasePart") or instance:IsA("Model")) then
                table.insert(doors, instance)
            end
        end
    end
    
    return doors
end

-- Find all sauna rooms in the workspace
function SaunaSystem:_findSaunaRooms()
    local rooms = {}
    
    -- Find by tag
    for _, roomModel in pairs(CollectionService:GetTagged(CONFIG.saunaTag)) do
        -- Create room data structure
        local room = {
            name = roomModel.Name,
            model = roomModel,
            parts = {},
            heaters = {},
            doors = {},
            players = {},
            temperature = CONFIG.defaultStartingTemp,
            boundingBox = {
                min = Vector3.new(math.huge, math.huge, math.huge),
                max = Vector3.new(-math.huge, -math.huge, -math.huge)
            }
        }
        
        -- Collect all physical parts of the room
        local parts = {}
        if roomModel:IsA("BasePart") then
            table.insert(parts, roomModel)
        else
            for _, part in pairs(roomModel:GetDescendants()) do
                if part:IsA("BasePart") and not part.Name:match("Door") and not part.Name:match("Heater") then
                    table.insert(parts, part)
                end
            end
        end
        
        room.parts = parts
        
        -- Calculate bounding box for the room
        for _, part in pairs(parts) do
            local partMin = part.Position - (part.Size / 2)
            local partMax = part.Position + (part.Size / 2)
            
            room.boundingBox.min = Vector3.new(
                math.min(room.boundingBox.min.X, partMin.X),
                math.min(room.boundingBox.min.Y, partMin.Y),
                math.min(room.boundingBox.min.Z, partMin.Z)
            )
            
            room.boundingBox.max = Vector3.new(
                math.max(room.boundingBox.max.X, partMax.X),
                math.max(room.boundingBox.max.Y, partMax.Y),
                math.max(room.boundingBox.max.Z, partMax.Z)
            )
        end
        
        table.insert(rooms, room)
    end
    
    -- Find by model name if no tagged rooms found
    if #rooms == 0 and CONFIG.identifyRoomsByModel then
        for _, instance in pairs(Workspace:GetDescendants()) do
            if instance.Name == "Sauna" and instance:IsA("Model") then
                -- Create room data structure
                local room = {
                    name = instance.Name .. "_" .. #rooms + 1,
                    model = instance,
                    parts = {},
                    heaters = {},
                    doors = {},
                    players = {},
                    temperature = CONFIG.defaultStartingTemp,
                    boundingBox = {
                        min = Vector3.new(math.huge, math.huge, math.huge),
                        max = Vector3.new(-math.huge, -math.huge, -math.huge)
                    }
                }
                
                -- Collect all physical parts of the room
                for _, part in pairs(instance:GetDescendants()) do
                    if part:IsA("BasePart") and not part.Name:match("Door") and not part.Name:match("Heater") then
                        table.insert(room.parts, part)
                        
                        -- Update bounding box
                        local partMin = part.Position - (part.Size / 2)
                        local partMax = part.Position + (part.Size / 2)
                        
                        room.boundingBox.min = Vector3.new(
                            math.min(room.boundingBox.min.X, partMin.X),
                            math.min(room.boundingBox.min.Y, partMin.Y),
                            math.min(room.boundingBox.min.Z, partMin.Z)
                        )
                        
                        room.boundingBox.max = Vector3.new(
                            math.max(room.boundingBox.max.X, partMax.X),
                            math.max(room.boundingBox.max.Y, partMax.Y),
                            math.max(room.boundingBox.max.Z, partMax.Z)
                        )
                    end
                end
                
                table.insert(rooms, room)
            end
        end
    end
    
    return rooms
end

-- Check if a position is inside a sauna room
function SaunaSystem:_isPositionInRoom(position, room)
    return position.X >= room.boundingBox.min.X and position.X <= room.boundingBox.max.X and
           position.Y >= room.boundingBox.min.Y and position.Y <= room.boundingBox.max.Y and
           position.Z >= room.boundingBox.min.Z and position.Z <= room.boundingBox.max.Z
end

-- Find which room a player is in
function SaunaSystem:_findPlayerRoom(player)
    local character = player.Character
    if not character then return nil end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    -- Check each room
    for _, room in pairs(self._rooms) do
        if self:_isPositionInRoom(humanoidRootPart.Position, room) then
            return room
        end
    end
    
    return nil
end

-- Assign heaters to rooms based on proximity
function SaunaSystem:_assignHeatersToRooms()
    -- Assign heaters to their respective rooms based on position
    for _, heater in pairs(self._heaters) do
        local heaterPos
        if heater:IsA("BasePart") then
            heaterPos = heater.Position
        elseif heater:IsA("Model") and heater.PrimaryPart then
            heaterPos = heater.PrimaryPart.Position
        else
            -- Try to find any part to use as position
            for _, part in pairs(heater:GetDescendants()) do
                if part:IsA("BasePart") then
                    heaterPos = part.Position
                    break
                end
            end
        end
        
        if heaterPos then
            for _, room in pairs(self._rooms) do
                if self:_isPositionInRoom(heaterPos, room) then
                    table.insert(room.heaters, heater)
                    
                    -- Set initial heater state
                    local enabled = heater:GetAttribute("HeaterEnabled")
                    
                    -- If attribute doesn't exist, create it and default to true
                    if enabled == nil then
                        heater:SetAttribute("HeaterEnabled", true)
                    end
                    
                    break
                end
            end
        end
    end
    
    -- Print heater assignments
    for _, room in pairs(self._rooms) do
        debugPrint("Room " .. room.name .. " has " .. #room.heaters .. " heaters")
    end
end

-- Assign doors to rooms based on proximity
function SaunaSystem:_assignDoorsToRooms()
    -- Assign doors to their respective rooms based on position
    for _, door in pairs(self._doors) do
        local doorPos
        if door:IsA("BasePart") then
            doorPos = door.Position
        elseif door:IsA("Model") and door.PrimaryPart then
            doorPos = door.PrimaryPart.Position
        else
            -- Try to find any part to use as position
            for _, part in pairs(door:GetDescendants()) do
                if part:IsA("BasePart") then
                    doorPos = part.Position
                    break
                end
            end
        end
        
        if doorPos then
            for _, room in pairs(self._rooms) do
                if self:_isPositionInRoom(doorPos, room) then
                    table.insert(room.doors, door)
                    break
                end
            end
        end
    end
    
    -- Print door assignments
    for _, room in pairs(self._rooms) do
        debugPrint("Room " .. room.name .. " has " .. #room.doors .. " doors")
    end
end

-- Update room temperature based on heaters and doors
function SaunaSystem:_updateRoomTemperature(room, deltaTime)
    -- Count active heaters
    local activeHeaterCount = 0
    for _, heater in pairs(room.heaters) do
        local enabled = heater:GetAttribute("HeaterEnabled")
        if enabled == nil then enabled = true end -- Default to true if not set
        
        if enabled then
            activeHeaterCount = activeHeaterCount + 1
        end
    end
    
    -- Calculate temperature change per minute
    local temperatureChangePerMinute = 0
    
    -- Apply cooling if no heaters are active
    if activeHeaterCount == 0 then
        temperatureChangePerMinute = -CONFIG.coolingRate
    else
        -- Apply heating based on number of active heaters
        local heatingPower = activeHeaterCount * CONFIG.heatingRate
        
        -- Factor in the maximum temperature
        local tempDelta = CONFIG.maxTemperature - room.temperature
        local heatingFactor = math.clamp(tempDelta / 20, 0, 1) -- Slow down as approaching max
        
        temperatureChangePerMinute = heatingPower * heatingFactor
    end
    
    -- Apply door cooling effect
    local doorOpen = false
    for _, door in pairs(room.doors) do
        -- Check if door is open (you might need to adapt this based on how doors are implemented)
        local doorOpenValue = door:GetAttribute("DoorOpen")
        if doorOpenValue ~= nil and doorOpenValue then
            doorOpen = true
            break
        end
    end
    
    if doorOpen then
        temperatureChangePerMinute = temperatureChangePerMinute - CONFIG.doorCoolingRate
    end
    
    -- Calculate actual change for this time step
    local temperatureChange = (temperatureChangePerMinute / 60) * deltaTime
    
    -- Apply change and clamp temperature
    room.temperature = math.clamp(
        room.temperature + temperatureChange,
        CONFIG.minTemperature,
        CONFIG.maxTemperature
    )
    
    -- Apply health restoration effects to players in the room
    if CONFIG.healthRestoreEnabled then
        for player, _ in pairs(room.players) do
            local character = player.Character
            if not character then continue end
            
            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid then continue end
            
            -- Only restore health if not at max
            if humanoid.Health < humanoid.MaxHealth then
                -- Effectiveness based on how close to optimal temperature
                local tempEffectiveness = 1 - (math.abs(room.temperature - CONFIG.optimalTemperature) / 30)
                tempEffectiveness = math.clamp(tempEffectiveness, 0, 1)
                
                -- Wellness specialization bonus
                local tycoon = player:FindFirstChild("Tycoon")
                if tycoon and tycoon:GetAttribute("Specialization") == "Wellness" then
                    tempEffectiveness = tempEffectiveness * 1.5
                end
                
                -- Calculate and apply health restoration
                local regenAmount = CONFIG.healthRestoreRate * (deltaTime / 60) * tempEffectiveness
                if regenAmount > 0 then
                    humanoid.Health = math.min(humanoid.Health + regenAmount, humanoid.MaxHealth)
                
                    -- Add regeneration effect (visual feedback)
                    if EventBridge then
                        EventBridge:fireEvent("SaunaEffectApplied", player, {
                            effectType = "HealthRestore",
                            amount = regenAmount
                        })
                    end
                end
            end
        end
    end
    
    return temperatureChange
end

-- Update player positions and room status
function SaunaSystem:_updatePlayerRoomStatus()
    for _, player in pairs(Players:GetPlayers()) do
        -- Find which room the player is in currently
        local currentRoom = self:_findPlayerRoom(player)
        
        -- Initialize player data if needed
        if not self._playerData[player] then
            self._playerData[player] = {
                currentRoom = nil,
                timeInSauna = 0
            }
        end
        
        local data = self._playerData[player]
        
        -- Handle room transitions
        if currentRoom and data.currentRoom ~= currentRoom then
            -- If leaving a room
            if data.currentRoom then
                data.currentRoom.players[player] = nil
                if EventBridge then
                    EventBridge:fireEvent("ExitSauna", player)
                end
            end
            
            -- Enter new room
            data.currentRoom = currentRoom
            data.timeInSauna = 0
            currentRoom.players[player] = true
            if EventBridge then
                EventBridge:fireEvent("EnterSauna", player, {
                    roomName = currentRoom.name,
                    temperature = currentRoom.temperature
                })
            end
            
            -- Reset their sauna time
            data.timeInSauna = 0
            
        -- Player left a room
        elseif not currentRoom and data.currentRoom then
            data.currentRoom.players[player] = nil
            data.currentRoom = nil
            if EventBridge then
                EventBridge:fireEvent("ExitSauna", player)
            end
            
        -- Player is still in the same room
        elseif currentRoom and data.currentRoom == currentRoom then
            data.timeInSauna = data.timeInSauna + 1
        end
    end
end

-- Start the temperature update system
function SaunaSystem:_startTemperatureSystem()
    local lastUpdateTime = tick()
    
    self._updateLoop = task.spawn(function()
        while true do
            wait(1) -- Update every second
            
            local currentTime = tick()
            local deltaTime = currentTime - lastUpdateTime
            lastUpdateTime = currentTime
            
            -- Update player positions
            self:_updatePlayerRoomStatus()
            
            -- Update temperature in all rooms
            for _, room in pairs(self._rooms) do
                local temperatureChange = self:_updateRoomTemperature(room, deltaTime)
                
                -- Debug output
                if temperatureChange ~= 0 then
                    -- Only log significant changes
                    if math.abs(temperatureChange) > 0.1 and EventBridge then
                        EventBridge:fireEvent("TemperatureUpdated", {
                            roomName = room.name,
                            temperature = room.temperature,
                            change = temperatureChange
                        })
                    end
                end
            end
        end
    end)
end

-- Clean up when the system is stopped
function SaunaSystem:_cleanup()
    -- Stop update loop
    if self._updateLoop then
        task.cancel(self._updateLoop)
        self._updateLoop = nil
    end
    
    -- Clear player data
    for player, data in pairs(self._playerData) do
        -- Notify if they're in a sauna
        if data.currentRoom then
            if EventBridge then
                EventBridge:fireEvent("ExitSauna", player)
            end
        end
    end
    
    self._playerData = {}
    debugPrint("SaunaSystem cleaned up")
end

--[[ Public API Functions ]]--

-- Get information about all rooms
function SaunaSystem:GetRoomInfo(roomName)
    -- Get info for a specific room if name is provided
    if roomName then
        for _, room in pairs(self._rooms) do
            if room.name == roomName then
                return room.temperature
            end
        end
    end
    
    -- Otherwise return info for all rooms
    local roomInfos = {}
    for _, room in pairs(self._rooms) do
        table.insert(roomInfos, {
            name = room.name,
            temperature = room.temperature,
            playerCount = self:_getTableSize(room.players),
            activeHeaterCount = self:_getActiveHeaterCount(room)
        })
    end
    
    return roomInfos
end

-- Toggle a heater on or off
function SaunaSystem:ToggleHeater(heaterName)
    for _, heater in pairs(self._heaters) do
        if heater.Name == heaterName then
            local currentState = heater:GetAttribute("HeaterEnabled")
            if currentState == nil then currentState = true end
            
            heater:SetAttribute("HeaterEnabled", not currentState)
            
            return true, not currentState
        end
    end
    
    return false
end

-- Get the number of active heaters in a room
function SaunaSystem:_getActiveHeaterCount(room)
    local active = 0
    
    for _, heater in pairs(room.heaters) do
        local enabled = heater:GetAttribute("HeaterEnabled")
        if enabled == nil or enabled then
            active = active + 1
        end
    end
    
    return active
end

-- Count table size (used for player count)
function SaunaSystem:_getTableSize(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Trigger steam effect at a door
function SaunaSystem:TriggerDoorSteam(door, intensity)
    if not CONFIG.doorSteamEffect then return end
    
    -- Default intensity
    intensity = intensity or 1
    
    -- Fire event for clients to handle visual effect
    if EventBridge then
        EventBridge:fireEvent("SaunaDoorSteam", {
            door = door,
            intensity = intensity,
            duration = 3
        })
    end
end

--[[ Initialization and Event Handling ]]--

function SaunaSystem:initialize()
    debugPrint("Initializing SaunaSystem v" .. self._version)
    
    -- Get dependencies
    CoreRegistry = self.CoreRegistry
    EventBridge = CoreRegistry:getSystem("EventBridge")
    DataManager = CoreRegistry:getSystem("DataManager")
    
    -- Find sauna rooms, heaters, and doors
    self._heaters = self:_findSaunaHeaters()
    self._doors = self:_findSaunaDoors()
    self._rooms = self:_findSaunaRooms()
    
    debugPrint("Found " .. #self._rooms .. " sauna rooms")
    debugPrint("Found " .. #self._heaters .. " sauna heaters")
    debugPrint("Found " .. #self._doors .. " sauna doors")
    
    -- Initialize player data table
    self._playerData = {}
    
    -- Assign heaters and doors to their respective rooms
    self:_assignHeatersToRooms()
    self:_assignDoorsToRooms()
    
    -- Register door events
    if EventBridge then
        EventBridge:registerEvent("DoorOpened", function(door)
            -- Find which room this door belongs to
            for _, room in pairs(self._rooms) do
                for _, roomDoor in pairs(room.doors) do
                    if roomDoor == door then
                        self:TriggerDoorSteam(door, 1)
                        break
                    end
                end
            end
        end)
        
        -- Register client request events
        EventBridge:registerClientEvent("RequestToggleHeater", function(player, heaterName)
            local success, newState = self:ToggleHeater(heaterName)
            
            EventBridge:fireEvent("HeaterToggleResponse", player, {
                success = success,
                newState = newState,
                message = success and "Heater toggled" or "Heater not found"
            })
        end)
        
        EventBridge:registerClientEvent("RequestSaunaInfo", function(player, roomName)
            local info = self:GetRoomInfo(roomName)
            EventBridge:fireEvent("SaunaInfoResponse", player, info)
        end)
    end
    
    -- Handle player removal
    Players.PlayerRemoving:Connect(function(player)
        -- Handle player leaving a sauna
        if self._playerData[player] and self._playerData[player].currentRoom then
            local room = self._playerData[player].currentRoom
            room.players[player] = nil
        end
        
        -- Clean up player data
        self._playerData[player] = nil
    end)
    
    -- Set up door open/close detection
    for _, door in pairs(self._doors) do
        -- Check if this is implemented as a MeshPart, Part or hinged door
        -- This depends on your specific door implementation
        task.spawn(function()
            -- For demonstration, we'll just listen for attribute changes
            local isSaunaDoor = false
            
            -- Check if this is a sauna door by verifying it's in one of our rooms
            for _, room in pairs(self._rooms) do
                for _, roomDoor in pairs(room.doors) do
                    if roomDoor == door then
                        isSaunaDoor = true
                    end
                end
            end
            
            if isSaunaDoor then
                -- Monitor for attribute changes that could indicate door state
                door:GetAttributeChangedSignal("DoorOpen"):Connect(function()
                    if door:GetAttribute("DoorOpen") then
                        self:TriggerDoorSteam(door)
                        
                        if EventBridge then
                            EventBridge:fireEvent("DoorOpened", door)
                        end
                    end
                end)
                
                -- For doors without attributes, try other methods
                -- This would depend on the specific door implementation
            end
        end)
    end
    
    -- Start the temperature update loop
    self:_startTemperatureSystem()
    
    debugPrint("SaunaSystem initialized successfully")
    return true
end

-- Public API table
local PublicAPI = {
    GetRoomInfo = function(roomName)
        return SaunaSystem:GetRoomInfo(roomName)
    end,
    
    ToggleHeater = function(heaterName)
        return SaunaSystem:ToggleHeater(heaterName)
    end,
    
    TriggerDoorSteam = function(door, intensity)
        return SaunaSystem:TriggerDoorSteam(door, intensity)
    end
}

-- Register with CoreRegistry
return CoreRegistry.registerSystem("SaunaSystem", PublicAPI, {"EventBridge", "DataManager"})
