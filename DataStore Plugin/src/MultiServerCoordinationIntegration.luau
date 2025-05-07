--luau
-- DataStore Plugin/MultiServerCoordinationIntegration.luau

-- Add module resolver at the beginning of the file
local ModuleResolver
local success, result = pcall(function()
    return require(script.Parent:FindFirstChild("ModuleResolver"))
end)

if success and result then
    ModuleResolver = result
else
    -- Inline minimal resolver as fallback
    ModuleResolver = {
        resolveModule = function(moduleName)
            local success, result = pcall(function() 
                return require(script.Parent:FindFirstChild(moduleName)) 
            end)
            if success then return result else return {} end
        end
    }
end

local MultiServerCoordinationIntegration = {}

-- Initialize the Multi-Server Coordination Integration
function MultiServerCoordinationIntegration.initialize()
    print("MultiServerCoordinationIntegration: Initializing module...")
    return true
end

-- Initialize the Multi-Server Coordination UI in the provided container
function MultiServerCoordinationIntegration.initMultiServerCoordinationUI(DataExplorer)
    print("MultiServerCoordinationIntegration: Initializing UI...")
    
    if not DataExplorer then
        warn("MultiServerCoordinationIntegration: DataExplorer not provided for UI initialization")
        return false
    end
    
    local mainFrame = DataExplorer.mainFrame
    if not mainFrame then return end
    
    -- Create a button to open multi-server coordination UI
    local coordinationButton = Instance.new("TextButton")
    coordinationButton.Size = UDim2.new(0, 150, 0, 28)
    coordinationButton.Position = UDim2.new(1, -600, 0, 10) -- Position it to the left of other buttons
    coordinationButton.BackgroundColor3 = Color3.fromRGB(52, 152, 219) -- Blue color for coordination
    coordinationButton.BorderSizePixel = 0
    coordinationButton.Text = "Server Coordination"
    coordinationButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    coordinationButton.Font = Enum.Font.SourceSansSemibold
    coordinationButton.TextSize = 14
    coordinationButton.ZIndex = 5
    coordinationButton.Parent = mainFrame
    
    -- Add rounded corners
    local coordinationButtonCorner = Instance.new("UICorner")
    coordinationButtonCorner.CornerRadius = UDim.new(0, 4)
    coordinationButtonCorner.Parent = coordinationButton
    
    -- Create a container for the multi-server coordination UI (initially invisible)
    local coordinationContainer = Instance.new("Frame")
    coordinationContainer.Size = UDim2.new(1, 0, 1, 0)
    coordinationContainer.Position = UDim2.new(0, 0, 0, 0)
    coordinationContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    coordinationContainer.Visible = false
    coordinationContainer.Name = "MultiServerCoordinationContainer"
    coordinationContainer.Parent = mainFrame
    DataExplorer.coordinationContainer = coordinationContainer
    
    -- Create the multi-server coordination UI
    local MultiServerCoordinationUI
    
    -- Use ModuleResolver if available
    if ModuleResolver and ModuleResolver.resolveModule then
        MultiServerCoordinationUI = ModuleResolver.resolveModule("MultiServerCoordinationUI")
    else
        -- Fallback to traditional require
        MultiServerCoordinationUI = require(script.Parent.MultiServerCoordinationUI)
    end
    
    MultiServerCoordinationUI.createUI(coordinationContainer)
    
    -- Toggle visibility when coordination button is clicked
    coordinationButton.MouseButton1Click:Connect(function()
        local contentPane = DataExplorer.contentPane
        local navPane = DataExplorer.navigationPane
        
        if DataExplorer.coordinationContainer.Visible then
            -- Hide coordination UI and show normal UI
            DataExplorer.coordinationContainer.Visible = false
            contentPane.Visible = true
            navPane.Visible = true
            coordinationButton.Text = "Server Coordination"
            coordinationButton.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
            
            -- Also ensure other containers are hidden
            if DataExplorer.schemaBuilderContainer then
                DataExplorer.schemaBuilderContainer.Visible = false
            end
            
            if DataExplorer.bulkOperationsContainer then
                DataExplorer.bulkOperationsContainer.Visible = false
            end
            
            if DataExplorer.monitoringDashboardContainer then
                DataExplorer.monitoringDashboardContainer.Visible = false
            end
            
            if DataExplorer.dataMigrationContainer then
                DataExplorer.dataMigrationContainer.Visible = false
            end
        else
            -- Show coordination UI and hide normal UI
            DataExplorer.coordinationContainer.Visible = true
            contentPane.Visible = false
            navPane.Visible = false
            coordinationButton.Text = "Back to Explorer"
            coordinationButton.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
            
            -- Also ensure other containers are hidden
            if DataExplorer.schemaBuilderContainer then
                DataExplorer.schemaBuilderContainer.Visible = false
            end
            
            if DataExplorer.bulkOperationsContainer then
                DataExplorer.bulkOperationsContainer.Visible = false
            end
            
            if DataExplorer.monitoringDashboardContainer then
                DataExplorer.monitoringDashboardContainer.Visible = false
            end
            
            if DataExplorer.dataMigrationContainer then
                DataExplorer.dataMigrationContainer.Visible = false
            end
        end
    end)
end

return MultiServerCoordinationIntegration
