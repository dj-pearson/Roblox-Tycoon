-- Towel Interaction System
-- Allows players to interact with towels, placing them around their neck or in inventory

local TowelSystem = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")

-- Constants
local TOWEL_WEAR_DURATION = 300 -- 5 minutes
local INVENTORY_KEY = "PlayerInventory"
local SAVED_ITEMS_STORE = DataStoreService:GetDataStore("SavedItems")

-- References
local TowelModels = {
    Regular = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Towels"):WaitForChild("Regular"),
    Premium = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Towels"):WaitForChild("Premium")
}

-- Track active towel instances
local activeTowels = {}
local playerInventories = {}

-- Initialize the system
function TowelSystem.init()
    -- Create the proximity prompts for all towel racks
    local towelRacks = workspace:GetDescendants()
    for _, rack in ipairs(towelRacks) do
        if rack.Name == "Towels" then
            TowelSystem.setupTowelRack(rack)
        end
    end
    
    -- Handle player joining to load their inventory
    Players.PlayerAdded:Connect(function(player)
        TowelSystem.loadPlayerInventory(player)
        
        -- Set up a backpack GUI for the player
        TowelSystem.setupInventoryGui(player)
    end)
    
    -- Handle player leaving to save their inventory
    Players.PlayerRemoving:Connect(function(player)
        TowelSystem.savePlayerInventory(player)
    end)
    
    print("Towel System Initialized")
end

-- Set up interaction for a towel rack
function TowelSystem.setupTowelRack(rack)
    -- Create proximity prompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.ObjectText = "Towel Rack"
    prompt.ActionText = "Take Towel"
    prompt.HoldDuration = 0.5
    prompt.RequiresLineOfSight = true
    prompt.MaxActivationDistance = 8
    prompt.Parent = rack.PrimaryPart or rack:FindFirstChildWhichIsA("BasePart")
    
    -- Connect to the triggered event
    prompt.Triggered:Connect(function(player)
        TowelSystem.giveTowelToPlayer(player, rack)
    end)
end

-- Give a towel to a player from a specific rack
function TowelSystem.giveTowelToPlayer(player, rack)
    -- Determine towel type based on rack
    local towelType = rack:GetAttribute("TowelType") or "Regular"
    
    -- Check if player already has a towel
    if activeTowels[player.UserId] then
        -- Notify player they already have a towel
        TowelSystem.notifyPlayer(player, "You already have a towel!")
        return
    end
    
    -- Check cooldown
    local lastTowelTime = rack:GetAttribute("LastTowelTime") or 0
    local cooldown = rack:GetAttribute("Cooldown") or 10
    if (os.time() - lastTowelTime) < cooldown then
        TowelSystem.notifyPlayer(player, "Please wait before taking another towel.")
        return
    end
    
    -- Create the towel and add to inventory
    TowelSystem.addToInventory(player, "Towel", towelType)
    
    -- Update cooldown
    rack:SetAttribute("LastTowelTime", os.time())
    
    -- Notify player
    TowelSystem.notifyPlayer(player, "Towel added to inventory!")
end

-- Add an item to player's inventory
function TowelSystem.addToInventory(player, itemType, itemVariant)
    if not playerInventories[player.UserId] then
        playerInventories[player.UserId] = {}
    end
    
    -- Create inventory item entry
    local newItem = {
        type = itemType,
        variant = itemVariant,
        id = game:GetService("HttpService"):GenerateGUID(false),
        acquired = os.time()
    }
    
    -- Add to inventory
    table.insert(playerInventories[player.UserId], newItem)
    
    -- Fire client event to update inventory UI
    local inventoryEvent = ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("InventoryUpdate")
    if inventoryEvent then
        inventoryEvent:FireClient(player, playerInventories[player.UserId])
    end
end

-- Setup inventory GUI for player
function TowelSystem.setupInventoryGui(player)
    -- Create UI elements in StarterGui or directly to player
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Check if inventory GUI already exists
    if playerGui:FindFirstChild("InventoryGui") then return end
    
    -- Create main frame
    local inventoryGui = Instance.new("ScreenGui")
    inventoryGui.Name = "InventoryGui"
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 400)
    mainFrame.Position = UDim2.new(0.85, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BackgroundTransparency = 0.3
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = inventoryGui
    
    -- Create title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 50)
    titleLabel.Text = "Inventory"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.BackgroundTransparency = 0.5
    titleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    titleLabel.BorderSizePixel = 0
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 24
    titleLabel.Parent = mainFrame
    
    -- Create scroll frame for inventory items
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ItemsFrame"
    scrollFrame.Size = UDim2.new(1, 0, 1, -50)
    scrollFrame.Position = UDim2.new(0, 0, 0, 50)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated as items are added
    scrollFrame.Parent = mainFrame
    
    -- Create UIListLayout for scrolling items
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame
    
    -- Create toggle button
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "InventoryToggle"
    toggleButton.Size = UDim2.new(0, 50, 0, 50)
    toggleButton.Position = UDim2.new(0.95, 0, 0.5, 0)
    toggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
    toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Text = "🎒"
    toggleButton.TextSize = 24
    toggleButton.Font = Enum.Font.GothamBold
    
    -- Round the toggle button
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = toggleButton
    
    -- Connect toggle function
    toggleButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
    end)
    
    toggleButton.Parent = inventoryGui
    inventoryGui.Parent = playerGui
    
    -- Set up remote function to handle inventory actions
    local inventoryEvent = ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("InventoryAction")
    if not inventoryEvent then
        inventoryEvent = Instance.new("RemoteEvent")
        inventoryEvent.Name = "InventoryAction"
        inventoryEvent.Parent = ReplicatedStorage:FindFirstChild("Events") or ReplicatedStorage
    end
    
    -- Connect to inventory action event
    inventoryEvent.OnServerEvent:Connect(function(player, action, itemId)
        if action == "use" then
            TowelSystem.useInventoryItem(player, itemId)
        elseif action == "drop" then
            TowelSystem.dropInventoryItem(player, itemId)
        end
    end)
    
    -- Update the inventory UI initially
    TowelSystem.updateInventoryUI(player)
end

-- Update inventory UI for player
function TowelSystem.updateInventoryUI(player)
    local inventory = playerInventories[player.UserId] or {}
    
    -- Fire client event to update inventory UI
    local inventoryEvent = ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("InventoryUpdate")
    if inventoryEvent then
        inventoryEvent:FireClient(player, inventory)
    end
end

-- Use item from inventory
function TowelSystem.useInventoryItem(player, itemId)
    local inventory = playerInventories[player.UserId]
    if not inventory then return end
    
    -- Find the item in inventory
    local itemIndex, item
    for i, invItem in ipairs(inventory) do
        if invItem.id == itemId then
            itemIndex = i
            item = invItem
            break
        end
    end
    
    if not item then return end
    
    -- Handle different item types
    if item.type == "Towel" then
        TowelSystem.wearTowel(player, item.variant)
    end
    
    -- Don't remove towels from inventory when used
    -- If you want to remove items, uncomment this:
    -- table.remove(inventory, itemIndex)
    -- TowelSystem.updateInventoryUI(player)
end

-- Drop item from inventory
function TowelSystem.dropInventoryItem(player, itemId)
    local inventory = playerInventories[player.UserId]
    if not inventory then return end
    
    -- Find the item in inventory
    local itemIndex, item
    for i, invItem in ipairs(inventory) do
        if invItem.id == itemId then
            itemIndex = i
            item = invItem
            break
        end
    end
    
    if not item then return end
    
    -- Remove from inventory
    table.remove(inventory, itemIndex)
    
    -- Create physical item in world
    local character = player.Character
    if character and item.type == "Towel" then
        local towelModel = TowelModels[item.variant]:Clone()
        towelModel.Parent = workspace
        
        -- Position in front of player
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            towelModel:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(0, 0, -3))
        end
        
        -- Add interaction to pick up again
        local prompt = Instance.new("ProximityPrompt")
        prompt.ObjectText = item.variant .. " Towel"
        prompt.ActionText = "Pick Up"
        prompt.RequiresLineOfSight = true
        prompt.Parent = towelModel.PrimaryPart or towelModel:FindFirstChildWhichIsA("BasePart")
        
        prompt.Triggered:Connect(function(promptPlayer)
            TowelSystem.addToInventory(promptPlayer, "Towel", item.variant)
            towelModel:Destroy()
        end)
        
        -- Auto-cleanup after some time
        task.delay(300, function()
            if towelModel and towelModel.Parent then
                towelModel:Destroy()
            end
        end)
    end
    
    TowelSystem.updateInventoryUI(player)
end

-- Wear a towel
function TowelSystem.wearTowel(player, variant)
    local character = player.Character
    if not character then return end
    
    -- Check if already wearing a towel
    if activeTowels[player.UserId] then
        -- Remove existing towel first
        TowelSystem.removeTowel(player)
    end
    
    -- Create towel accessory
    local towelModel = TowelModels[variant]:Clone()
    
    -- Find or create attachment point on character
    local neck = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    if not neck then return end
    
    -- Setup attachment if needed
    local attachment = neck:FindFirstChild("TowelAttachment")
    if not attachment then
        attachment = Instance.new("Attachment")
        attachment.Name = "TowelAttachment"
        attachment.Position = Vector3.new(0, 0.5, 0.1)
        attachment.Parent = neck
    end
    
    -- Position towel on character
    local towelPart = towelModel.PrimaryPart or towelModel:FindFirstChildWhichIsA("BasePart")
    if towelPart then
        -- Make towel non-collidable
        for _, part in pairs(towelModel:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
                part.Massless = true
                
                -- Create weld to attach to character
                if part == towelPart then
                    local weld = Instance.new("WeldConstraint")
                    weld.Name = "TowelWeld"
                    weld.Part0 = neck
                    weld.Part1 = part
                    weld.Parent = part
                    
                    -- Position relative to neck
                    part.CFrame = neck.CFrame * CFrame.new(0, 0, 0.1)
                end
            end
        end
    end
    
    -- Parent to character
    towelModel.Parent = character
    
    -- Store reference for later removal
    activeTowels[player.UserId] = {
        model = towelModel,
        variant = variant,
        timeEquipped = os.time()
    }
    
    -- Set a timer to auto-remove after duration
    task.delay(TOWEL_WEAR_DURATION, function()
        if activeTowels[player.UserId] and activeTowels[player.UserId].model == towelModel then
            TowelSystem.removeTowel(player)
            TowelSystem.notifyPlayer(player, "Your towel has been returned to your inventory.")
        end
    end)
    
    -- Notify player
    TowelSystem.notifyPlayer(player, "You've put on a towel. It will return to your inventory in 5 minutes.")
end

-- Remove a towel from player
function TowelSystem.removeTowel(player)
    local towelData = activeTowels[player.UserId]
    if not towelData then return end
    
    -- Remove the model
    if towelData.model and towelData.model.Parent then
        towelData.model:Destroy()
    end
    
    -- Clear from active towels
    activeTowels[player.UserId] = nil
end

-- Save player inventory to DataStore
function TowelSystem.savePlayerInventory(player)
    local inventory = playerInventories[player.UserId]
    if not inventory then return end
    
    local success, errorMessage = pcall(function()
        SAVED_ITEMS_STORE:SetAsync(player.UserId .. "_" .. INVENTORY_KEY, inventory)
    end)
    
    if not success then
        warn("Failed to save inventory for " .. player.Name .. ": " .. errorMessage)
    end
    
    -- Clear from memory
    playerInventories[player.UserId] = nil
end

-- Load player inventory from DataStore
function TowelSystem.loadPlayerInventory(player)
    local success, result = pcall(function()
        return SAVED_ITEMS_STORE:GetAsync(player.UserId .. "_" .. INVENTORY_KEY)
    end)
    
    if success and result then
        playerInventories[player.UserId] = result
    else
        -- Initialize empty inventory
        playerInventories[player.UserId] = {}
        
        -- Give a starter towel to new players
        TowelSystem.addToInventory(player, "Towel", "Regular")
    end
    
    -- Update UI
    TowelSystem.updateInventoryUI(player)
end

-- Notify a player with a message
function TowelSystem.notifyPlayer(player, message)
    -- Fire client notification event
    local notifyEvent = ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("Notification")
    if notifyEvent then
        notifyEvent:FireClient(player, message)
    else
        -- Fallback to chat notification
        local chatService = game:GetService("Chat")
        chatService:Chat(player.Character, message, Enum.ChatColor.Blue)
    end
end

-- Client-side code has been moved to TowelInventory.client.lua in StarterPlayerScripts

-- Return the module
return TowelSystem