--!strict
--[[
    BuildOrderVisualizer.server.luau
    Tool for visualizing build order progression and prerequisites
    Part of Phase 4: Testing & Validation
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Only run in Studio
if not RunService:IsStudio() then
    warn("BuildOrderVisualizer is designed to run only in Studio mode")
    return
end

-- Try to find modules
local function TryRequire(path)
    local success, result = pcall(function()
        return require(path)
    end)
    return success and result or nil
end

-- Find CoreRegistry to access all systems
local CoreRegistry
local coreFolder = ServerScriptService:FindFirstChild("Core") 
    or ServerScriptService:FindFirstChild("Systems")
    or ServerScriptService:FindFirstChild("server")
    
if coreFolder then
    for _, module in ipairs(coreFolder:GetDescendants()) do
        if module:IsA("ModuleScript") and module.Name == "CoreRegistry" then
            CoreRegistry = TryRequire(module)
            break
        end
    end
end

-- Get modules from CoreRegistry
local BuyTileProgressionManager = CoreRegistry and CoreRegistry:GetSystem("BuyTileProgressionManager")
local TileDataGenerator = CoreRegistry and CoreRegistry:GetSystem("TileDataGenerator")

-- Configuration
local Config = {
    Colors = {
        Available = Color3.fromRGB(85, 255, 127),    -- Green
        Unavailable = Color3.fromRGB(255, 128, 128), -- Red
        Purchased = Color3.fromRGB(85, 170, 255),    -- Blue
        Selected = Color3.fromRGB(255, 255, 85),     -- Yellow
        Connection = Color3.fromRGB(255, 255, 255)   -- White
    },
    Transparency = {
        Available = 0.4,
        Unavailable = 0.7,
        Purchased = 0.4,
        Selected = 0.2,
        Connection = 0.5
    },
    LineThickness = 0.2,
    VisualizationDuration = 30, -- How long to keep visualization active (seconds)
    ShowLineConnections = true,
    ShowFloorColors = true,
    ShowLabels = true,
    GroupByFloor = true,
    AutomaticallyCleanup = true
}

-- Main visualizer
local BuildOrderVisualizer = {
    ActiveVisualizations = {},
    VisualizationFolder = nil,
    CurrentTycoon = nil
}

-- Create or get the visualization folder
function BuildOrderVisualizer:GetVisualizationFolder()
    if self.VisualizationFolder and self.VisualizationFolder.Parent then
        return self.VisualizationFolder
    end
    
    -- Clean up any existing folders
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Folder") and child.Name == "BuildOrderVisualization" then
            child:Destroy()
        end
    end
    
    -- Create new folder
    self.VisualizationFolder = Instance.new("Folder")
    self.VisualizationFolder.Name = "BuildOrderVisualization"
    self.VisualizationFolder.Parent = Workspace
    
    return self.VisualizationFolder
end

-- Clean up visualizations
function BuildOrderVisualizer:CleanupVisualizations()
    -- Remove all visualization objects
    for _, visual in ipairs(self.ActiveVisualizations) do
        if visual.Instance and visual.Instance.Parent then
            visual.Instance:Destroy()
        end
    end
    
    self.ActiveVisualizations = {}
    
    -- Remove visualization folder
    if self.VisualizationFolder and self.VisualizationFolder.Parent then
        self.VisualizationFolder:Destroy()
        self.VisualizationFolder = nil
    end
    
    print("Cleaned up build order visualization")
end

-- Create a visual highlight for a tile
function BuildOrderVisualizer:CreateTileHighlight(tile, status, buildOrderIndex)
    if not tile then return nil end
    
    -- Determine color and transparency based on status
    local color = Config.Colors[status] or Config.Colors.Unavailable
    local transparency = Config.Transparency[status] or Config.Transparency.Unavailable
    
    -- Create highlight part
    local highlight
    
    if tile:IsA("BasePart") then
        -- For simple parts
        highlight = Instance.new("Part")
        highlight.Size = tile.Size + Vector3.new(0.05, 0.05, 0.05) -- Slightly larger
        highlight.Position = tile.Position
        highlight.Rotation = tile.Rotation
        highlight.Anchored = true
        highlight.CanCollide = false
        highlight.Material = Enum.Material.Neon
    else
        -- For models, get bounding box
        local minX, minY, minZ = math.huge, math.huge, math.huge
        local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
        
        -- Find all parts in the model
        local parts = {}
        if tile:IsA("Model") then
            for _, descendant in ipairs(tile:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    table.insert(parts, descendant)
                end
            end
        end
        
        -- If no parts found, return nil
        if #parts == 0 then return nil end
        
        -- Calculate bounding box
        for _, part in ipairs(parts) do
            local size = part.Size
            local pos = part.Position
            
            minX = math.min(minX, pos.X - size.X/2)
            minY = math.min(minY, pos.Y - size.Y/2)
            minZ = math.min(minZ, pos.Z - size.Z/2)
            
            maxX = math.max(maxX, pos.X + size.X/2)
            maxY = math.max(maxY, pos.Y + size.Y/2)
            maxZ = math.max(maxZ, pos.Z + size.Z/2)
        end
        
        -- Create highlight part based on bounding box
        highlight = Instance.new("Part")
        highlight.Size = Vector3.new(maxX - minX, maxY - minY, maxZ - minZ) + Vector3.new(0.1, 0.1, 0.1)
        highlight.Position = Vector3.new((minX + maxX)/2, (minY + maxY)/2, (minZ + maxZ)/2)
        highlight.Anchored = true
        highlight.CanCollide = false
        highlight.Material = Enum.Material.Neon
    end
    
    highlight.Color = color
    highlight.Transparency = transparency
    highlight.Parent = self:GetVisualizationFolder()
    
    -- Add label if configured
    if Config.ShowLabels then
        local label = Instance.new("BillboardGui")
        label.Size = UDim2.new(0, 100, 0, 40)
        label.StudsOffset = Vector3.new(0, highlight.Size.Y/2 + 1, 0) -- Position above the part
        label.AlwaysOnTop = true
        label.Parent = highlight
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextStrokeTransparency = 0
        textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        textLabel.TextColor3 = color
        textLabel.Text = buildOrderIndex and ("#" .. buildOrderIndex) or tile.Name
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextScaled = true
        textLabel.Parent = label
    end
    
    -- Store visualization
    table.insert(self.ActiveVisualizations, {
        Instance = highlight,
        TileRef = tile,
        Status = status,
        BuildOrderIndex = buildOrderIndex
    })
    
    return highlight
end

-- Create a visual connection between two tiles
function BuildOrderVisualizer:CreateConnection(fromTile, toTile)
    if not Config.ShowLineConnections then return end
    if not fromTile or not toTile then return end
    
    -- Find visualization objects
    local fromVisual, toVisual
    for _, visual in ipairs(self.ActiveVisualizations) do
        if visual.TileRef == fromTile then
            fromVisual = visual.Instance
        elseif visual.TileRef == toTile then
            toVisual = visual.Instance
        end
    end
    
    if not fromVisual or not toVisual then return end
    
    -- Create line between tiles
    local fromPos = fromVisual.Position
    local toPos = toVisual.Position
    
    -- Calculate line properties
    local distance = (toPos - fromPos).Magnitude
    local direction = (toPos - fromPos).Unit
    local midPoint = fromPos + direction * (distance / 2)
    
    -- Create line part
    local line = Instance.new("Part")
    line.Size = Vector3.new(Config.LineThickness, Config.LineThickness, distance)
    line.CFrame = CFrame.lookAt(fromPos, toPos) * CFrame.new(0, 0, -distance/2)
    line.Anchored = true
    line.CanCollide = false
    line.Material = Enum.Material.Neon
    line.Color = Config.Colors.Connection
    line.Transparency = Config.Transparency.Connection
    line.Parent = self:GetVisualizationFolder()
    
    -- Add to active visualizations
    table.insert(self.ActiveVisualizations, {
        Instance = line,
        FromTile = fromTile,
        ToTile = toTile,
        Type = "Connection"
    })
    
    return line
end

-- Generate build order visualization
function BuildOrderVisualizer:VisualizeBuildOrder(tycoon)
    -- Clean up existing visualizations
    self:CleanupVisualizations()
    
    -- Ensure we have required modules
    if not BuyTileProgressionManager then
        warn("BuildOrderVisualizer requires BuyTileProgressionManager to work")
        return false
    end
    
    -- Store current tycoon
    self.CurrentTycoon = tycoon
    
    -- Get build order
    local buildOrder = BuyTileProgressionManager:GetBuildOrder(tycoon)
    if not buildOrder or #buildOrder == 0 then
        warn("Failed to get build order for tycoon:", tycoon.Name)
        return false
    end
    
    print("Visualizing build order with " .. #buildOrder .. " steps")
    
    -- Get tile instances
    local allTiles = {}
    local purchasedTiles = {}
    local tileById = {}
    
    -- Collect all tiles from the tycoon
    for _, descendant in ipairs(tycoon:GetDescendants()) do
        if descendant:GetAttribute("TileType") then
            local tileId = descendant:GetAttribute("TileId") or descendant:GetAttribute("TileType")
            
            if tileId then
                tileById[tileId] = descendant
                table.insert(allTiles, descendant)
                
                if descendant:GetAttribute("Purchased") then
                    table.insert(purchasedTiles, descendant)
                end
            end
        end
    end
    
    -- First pass: Create highlights for all tiles in build order
    for i, buildStep in ipairs(buildOrder) do
        local tileId = buildStep.id or buildStep.tileId or buildStep
        local tile = tileById[tileId]
        
        if tile then
            local status = "Unavailable"
            
            -- Determine status
            if tile:GetAttribute("Purchased") then
                status = "Purchased"
            else
                -- Check if all prerequisites are met
                local allPrereqsMet = true
                local prerequisites = buildStep.prerequisites or BuyTileProgressionManager:GetTilePrerequisites(tile)
                
                if prerequisites and #prerequisites > 0 then
                    for _, prereqId in ipairs(prerequisites) do
                        local prereqTile = tileById[prereqId]
                        if prereqTile and not prereqTile:GetAttribute("Purchased") then
                            allPrereqsMet = false
                            break
                        end
                    end
                end
                
                status = allPrereqsMet and "Available" or "Unavailable"
            end
            
            -- Create highlight with build order index
            self:CreateTileHighlight(tile, status, i)
        end
    end
    
    -- Second pass: Create connections between prerequisites
    for i, buildStep in ipairs(buildOrder) do
        local tileId = buildStep.id or buildStep.tileId or buildStep
        local tile = tileById[tileId]
        
        if tile then
            local prerequisites = buildStep.prerequisites or BuyTileProgressionManager:GetTilePrerequisites(tile)
            
            if prerequisites and #prerequisites > 0 then
                for _, prereqId in ipairs(prerequisites) do
                    local prereqTile = tileById[prereqId]
                    if prereqTile then
                        self:CreateConnection(prereqTile, tile)
                    end
                end
            end
        end
    end
    
    -- Set up auto-cleanup
    if Config.AutomaticallyCleanup then
        task.delay(Config.VisualizationDuration, function()
            if self.VisualizationFolder then
                self:CleanupVisualizations()
            end
        end)
    end
    
    return true
end

-- Show the progression for a specific tile
function BuildOrderVisualizer:VisualizeTileProgression(targetTile)
    -- Clean up existing visualizations
    self:CleanupVisualizations()
    
    if not targetTile then
        warn("No target tile specified for visualization")
        return false
    end
    
    -- Ensure we have required modules
    if not BuyTileProgressionManager then
        warn("BuildOrderVisualizer requires BuyTileProgressionManager to work")
        return false
    end
    
    -- Find tycoon
    local tycoon = targetTile
    while tycoon.Parent ~= nil and tycoon.Parent ~= Workspace do
        tycoon = tycoon.Parent
    end
    
    self.CurrentTycoon = tycoon
    
    -- Get prerequisites for this tile
    local prerequisites = BuyTileProgressionManager:GetTilePrerequisites(targetTile)
    if not prerequisites or #prerequisites == 0 then
        print("This tile has no prerequisites")
    end
    
    -- Highlight target tile
    self:CreateTileHighlight(targetTile, "Selected")
    
    -- Find tiles that this is a prerequisite for
    local tilesWithPrereqs = {}
    for _, descendant in ipairs(tycoon:GetDescendants()) do
        if descendant:GetAttribute("TileType") and descendant ~= targetTile then
            local descendantPrereqs = BuyTileProgressionManager:GetTilePrerequisites(descendant)
            
            if descendantPrereqs then
                for _, prereqId in ipairs(descendantPrereqs) do
                    local targetId = targetTile:GetAttribute("TileId") or targetTile:GetAttribute("TileType")
                    if prereqId == targetId then
                        table.insert(tilesWithPrereqs, descendant)
                        break
                    end
                end
            end
        end
    end
    
    -- Collect tile info
    local tileById = {}
    
    -- Build tile ID lookup
    for _, descendant in ipairs(tycoon:GetDescendants()) do
        if descendant:GetAttribute("TileType") then
            local tileId = descendant:GetAttribute("TileId") or descendant:GetAttribute("TileType")
            if tileId then
                tileById[tileId] = descendant
            end
        end
    end
    
    -- Highlight prerequisites
    if prerequisites then
        for _, prereqId in ipairs(prerequisites) do
            local prereqTile = tileById[prereqId]
            if prereqTile then
                local status = prereqTile:GetAttribute("Purchased") and "Purchased" or "Unavailable"
                self:CreateTileHighlight(prereqTile, status)
                self:CreateConnection(prereqTile, targetTile)
            end
        end
    end
    
    -- Highlight tiles that have this as a prerequisite
    for _, dependentTile in ipairs(tilesWithPrereqs) do
        local status = dependentTile:GetAttribute("Purchased") and "Purchased" or "Available"
        self:CreateTileHighlight(dependentTile, status)
        self:CreateConnection(targetTile, dependentTile)
    end
    
    -- Set up auto-cleanup
    if Config.AutomaticallyCleanup then
        task.delay(Config.VisualizationDuration, function()
            if self.VisualizationFolder then
                self:CleanupVisualizations()
            end
        end)
    end
    
    return true
end

-- Visualize floor unlocking progression
function BuildOrderVisualizer:VisualizeFloorProgression(tycoon)
    -- Clean up existing visualizations
    self:CleanupVisualizations()
    
    if not tycoon then
        warn("No tycoon specified for visualization")
        return false
    end
    
    self.CurrentTycoon = tycoon
    
    -- Find all floors
    local floors = {}
    for _, child in ipairs(tycoon:GetChildren()) do
        if child:IsA("Model") and child.Name:match("Floor") then
            table.insert(floors, child)
        end
    end
    
    -- Sort floors by number
    table.sort(floors, function(a, b)
        local aNum = tonumber(a.Name:match("%d+")) or 0
        local bNum = tonumber(b.Name:match("%d+")) or 0
        return aNum < bNum
    end)
    
    if #floors == 0 then
        warn("No floors found in tycoon")
        return false
    end
    
    print("Visualizing progression for " .. #floors .. " floors")
    
    -- Visualize each floor's prerequisites
    for i = 2, #floors do -- Skip floor 1 as it's always available
        local floor = floors[i]
        
        -- Get floor prerequisites
        local prerequisites = BuyTileProgressionManager:GetFloorPrerequisites(floor)
        
        -- Create floor outline
        local floorOutline = self:CreateFloorOutline(floor, prerequisites and #prerequisites > 0)
        
        -- If we have prerequisites, visualize them
        if prerequisites and #prerequisites > 0 then
            local tileById = {}
            
            -- Build tile ID lookup
            for _, descendant in ipairs(tycoon:GetDescendants()) do
                if descendant:GetAttribute("TileType") then
                    local tileId = descendant:GetAttribute("TileId") or descendant:GetAttribute("TileType")
                    if tileId then
                        tileById[tileId] = descendant
                    end
                end
            end
            
            -- Highlight prerequisites
            for _, prereqId in ipairs(prerequisites) do
                local prereqTile = tileById[prereqId]
                if prereqTile then
                    local status = prereqTile:GetAttribute("Purchased") and "Purchased" or "Available"
                    self:CreateTileHighlight(prereqTile, status)
                    
                    -- Connect to floor
                    if floorOutline then
                        self:CreateConnection(prereqTile, floorOutline)
                    end
                end
            end
        end
    end
    
    -- Set up auto-cleanup
    if Config.AutomaticallyCleanup then
        task.delay(Config.VisualizationDuration, function()
            if self.VisualizationFolder then
                self:CleanupVisualizations()
            end
        end)
    end
    
    return true
end

-- Create an outline for a floor
function BuildOrderVisualizer:CreateFloorOutline(floor, isLocked)
    if not floor then return nil end
    
    -- Find floor bounds
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    
    -- Find all parts in the floor
    for _, descendant in ipairs(floor:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local corners = {
                descendant.CFrame * CFrame.new(-descendant.Size.X/2, -descendant.Size.Y/2, -descendant.Size.Z/2),
                descendant.CFrame * CFrame.new(descendant.Size.X/2, -descendant.Size.Y/2, -descendant.Size.Z/2),
                descendant.CFrame * CFrame.new(-descendant.Size.X/2, descendant.Size.Y/2, -descendant.Size.Z/2),
                descendant.CFrame * CFrame.new(descendant.Size.X/2, descendant.Size.Y/2, -descendant.Size.Z/2),
                descendant.CFrame * CFrame.new(-descendant.Size.X/2, -descendant.Size.Y/2, descendant.Size.Z/2),
                descendant.CFrame * CFrame.new(descendant.Size.X/2, -descendant.Size.Y/2, descendant.Size.Z/2),
                descendant.CFrame * CFrame.new(-descendant.Size.X/2, descendant.Size.Y/2, descendant.Size.Z/2),
                descendant.CFrame * CFrame.new(descendant.Size.X/2, descendant.Size.Y/2, descendant.Size.Z/2)
            }
            
            for _, corner in ipairs(corners) do
                local pos = corner.Position
                minX = math.min(minX, pos.X)
                minY = math.min(minY, pos.Y)
                minZ = math.min(minZ, pos.Z)
                maxX = math.max(maxX, pos.X)
                maxY = math.max(maxY, pos.Y)
                maxZ = math.max(maxZ, pos.Z)
            end
        end
    end
    
    -- If we couldn't find any parts, return nil
    if minX == math.huge then return nil end
    
    -- Create outline part
    local outline = Instance.new("Part")
    outline.Size = Vector3.new(maxX - minX, 1, maxZ - minZ) -- Flat box representing floor area
    outline.Position = Vector3.new((minX + maxX)/2, minY - 0.5, (minZ + maxZ)/2) -- Position just below floor
    outline.Anchored = true
    outline.CanCollide = false
    outline.Material = Enum.Material.Neon
    outline.Transparency = 0.7
    outline.Color = isLocked and Config.Colors.Unavailable or Config.Colors.Available
    outline.Parent = self:GetVisualizationFolder()
    
    -- Add floor label
    local label = Instance.new("BillboardGui")
    label.Size = UDim2.new(0, 150, 0, 50)
    label.StudsOffset = Vector3.new(0, 2, 0) -- Position above the floor outline
    label.AlwaysOnTop = true
    label.Parent = outline
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 0.3
    textLabel.BackgroundColor3 = Color3.new(0, 0, 0)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.TextColor3 = isLocked and Config.Colors.Unavailable or Config.Colors.Available
    textLabel.Text = floor.Name
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextScaled = true
    textLabel.Parent = label
    
    -- Store in active visualizations
    table.insert(self.ActiveVisualizations, {
        Instance = outline,
        FloorRef = floor,
        Type = "FloorOutline"
    })
    
    return outline
end

-- Register global functions for Studio use
if RunService:IsStudio() then
    _G.ShowBuildOrder = function(tycoon)
        -- Find tycoon if not specified
        if not tycoon then
            local tycoons = {}
            for _, child in ipairs(Workspace:GetChildren()) do
                if child:IsA("Model") and (child.Name:match("Tycoon") or child.Name:match("Gym")) then
                    table.insert(tycoons, child)
                end
            end
            
            if #tycoons > 0 then
                tycoon = tycoons[1]
                print("Using tycoon: " .. tycoon.Name)
            else
                warn("No tycoon found in workspace")
                return false
            end
        end
        
        return BuildOrderVisualizer:VisualizeBuildOrder(tycoon)
    end
    
    _G.ShowTileProgression = function(tile)
        if not tile then
            warn("No tile specified")
            return false
        end
        
        return BuildOrderVisualizer:VisualizeTileProgression(tile)
    end
    
    _G.ShowFloorProgression = function(tycoon)
        -- Find tycoon if not specified
        if not tycoon then
            local tycoons = {}
            for _, child in ipairs(Workspace:GetChildren()) do
                if child:IsA("Model") and (child.Name:match("Tycoon") or child.Name:match("Gym")) then
                    table.insert(tycoons, child)
                end
            end
            
            if #tycoons > 0 then
                tycoon = tycoons[1]
                print("Using tycoon: " .. tycoon.Name)
            else
                warn("No tycoon found in workspace")
                return false
            end
        end
        
        return BuildOrderVisualizer:VisualizeFloorProgression(tycoon)
    end
    
    _G.ClearBuildOrderVisualization = function()
        return BuildOrderVisualizer:CleanupVisualizations()
    end
    
    _G.ConfigureVisualizer = function(config)
        -- Apply config overrides
        if type(config) == "table" then
            for key, value in pairs(config) do
                if Config[key] ~= nil then
                    Config[key] = value
                end
            end
        end
        
        print("BuildOrderVisualizer configuration updated")
        return Config
    end
    
    print("Build Order Visualizer initialized. Available commands:")
    print("- _G.ShowBuildOrder([tycoon]) - Visualize the full build order")
    print("- _G.ShowTileProgression(tile) - Visualize progression for a specific tile")
    print("- _G.ShowFloorProgression([tycoon]) - Visualize floor unlocking progression")
    print("- _G.ClearBuildOrderVisualization() - Clear all visualizations")
    print("- _G.ConfigureVisualizer({...}) - Configure visualization settings")
end

return BuildOrderVisualizer
