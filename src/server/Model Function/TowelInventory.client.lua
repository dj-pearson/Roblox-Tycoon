-- TowelInventory.client.lua
-- Client-side code for Towel System

local player = game.Players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for the remote events to exist
local events = replicatedStorage:WaitForChild("Events")
local inventoryUpdateEvent = events:WaitForChild("InventoryUpdate")
local notificationEvent = events:WaitForChild("Notification")

-- Listen for inventory updates
inventoryUpdateEvent.OnClientEvent:Connect(function(inventory)
    updateInventoryDisplay(inventory)
end)

-- Listen for notifications
notificationEvent.OnClientEvent:Connect(function(message)
    -- Display notification using your preferred UI method
    -- For this example, we'll just print to output
    print("NOTIFICATION: " .. message)
end)

-- Function to update inventory display
function updateInventoryDisplay(inventory)
    local playerGui = player:WaitForChild("PlayerGui")
    local inventoryGui = playerGui:FindFirstChild("InventoryGui")
    if not inventoryGui then return end
    
    local mainFrame = inventoryGui:FindFirstChild("MainFrame")
    local itemsFrame = mainFrame:FindFirstChild("ItemsFrame")
    
    -- Clear existing items
    for _, child in pairs(itemsFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Add each inventory item
    for i, item in ipairs(inventory) do
        -- Create item button
        local itemButton = Instance.new("Frame")
        itemButton.Name = "Item_" .. item.id
        itemButton.Size = UDim2.new(0.9, 0, 0, 60)
        itemButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        itemButton.BorderSizePixel = 0
        
        -- Item icon
        local itemIcon = Instance.new("ImageLabel")
        itemIcon.Name = "Icon"
        itemIcon.Size = UDim2.new(0, 50, 0, 50)
        itemIcon.Position = UDim2.new(0, 5, 0, 5)
        itemIcon.BackgroundTransparency = 1
        
        -- Set icon image based on item type
        if item.type == "Towel" then
            itemIcon.Image = "rbxassetid://7522533403" -- Replace with actual towel icon
        end
        
        itemIcon.Parent = itemButton
        
        -- Item name
        local itemName = Instance.new("TextLabel")
        itemName.Name = "Name"
        itemName.Size = UDim2.new(1, -70, 0, 30)
        itemName.Position = UDim2.new(0, 65, 0, 5)
        itemName.BackgroundTransparency = 1
        itemName.TextColor3 = Color3.fromRGB(255, 255, 255)
        itemName.TextXAlignment = Enum.TextXAlignment.Left
        itemName.Font = Enum.Font.GothamSemibold
        itemName.TextSize = 16
        itemName.Text = item.variant .. " " .. item.type
        itemName.Parent = itemButton
        
        -- Use button
        local useButton = Instance.new("TextButton")
        useButton.Name = "UseButton"
        useButton.Size = UDim2.new(0, 60, 0, 25)
        useButton.Position = UDim2.new(1, -130, 0, 30)
        useButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        useButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        useButton.Text = "Use"
        useButton.TextSize = 14
        useButton.Font = Enum.Font.GothamBold
        
        -- Round the button corners
        local corner1 = Instance.new("UICorner")
        corner1.CornerRadius = UDim.new(0, 5)
        corner1.Parent = useButton
        
        useButton.MouseButton1Click:Connect(function()
            local inventoryActionEvent = replicatedStorage:WaitForChild("Events"):WaitForChild("InventoryAction")
            inventoryActionEvent:FireServer("use", item.id)
        end)
        
        useButton.Parent = itemButton
        
        -- Drop button
        local dropButton = Instance.new("TextButton")
        dropButton.Name = "DropButton"
        dropButton.Size = UDim2.new(0, 60, 0, 25)
        dropButton.Position = UDim2.new(1, -65, 0, 30)
        dropButton.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
        dropButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        dropButton.Text = "Drop"
        dropButton.TextSize = 14
        dropButton.Font = Enum.Font.GothamBold
        
        -- Round the button corners
        local corner2 = Instance.new("UICorner")
        corner2.CornerRadius = UDim.new(0, 5)
        corner2.Parent = dropButton
        
        dropButton.MouseButton1Click:Connect(function()
            local inventoryActionEvent = replicatedStorage:WaitForChild("Events"):WaitForChild("InventoryAction")
            inventoryActionEvent:FireServer("drop", item.id)
        end)
        
        dropButton.Parent = itemButton
        
        -- Add to frame
        itemButton.LayoutOrder = i
        itemButton.Parent = itemsFrame
    end
    
    -- Update scroll frame canvas size
    local listLayout = itemsFrame:FindFirstChildOfClass("UIListLayout")
    if listLayout then
        itemsFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end
end
