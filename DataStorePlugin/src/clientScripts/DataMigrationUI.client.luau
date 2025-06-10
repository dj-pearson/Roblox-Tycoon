--luau
-- DataMigrationUI.client.luau
-- Client-side UI module for DataMigration

local DataMigrationUI = {}

function DataMigrationUI.initialize()
    print("DataMigrationUI client initialized")
end

function DataMigrationUI.createUI(parent)
    local frame = Instance.new("Frame")
    frame.Name = "DataMigrationFrame"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    frame.BorderSizePixel = 0
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "D at aM ig ra ti on"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 16
    title.Parent = frame
    
    if parent then
        frame.Parent = parent
    end
    
    return frame
end

return DataMigrationUI
