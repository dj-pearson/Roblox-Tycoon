--luau
-- DataStore Plugin/SchemaBuilderUI.luau

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local SchemaManager = require(script.Parent.SchemaManager)
local SchemaValidator = require(script.Parent.SchemaValidator)
local StyleGuide = require(script.Parent.StyleGuide)

local SchemaBuilderUI = {}

-- Schema Builder UI Component
function SchemaBuilderUI.createUI(parent)
    -- Main container for the schema builder
    local container = Instance.new("Frame")
    container.Name = "SchemaBuilderContainer"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
    container.BorderSizePixel = 0
    container.Visible = false
    container.Parent = parent
    
    -- Apply rounded corners
    local cornerRadius = Instance.new("UICorner")
    cornerRadius.CornerRadius = UDim.new(0, 8)
    cornerRadius.Parent = container

    -- Header section
    local headerFrame = Instance.new("Frame")
    headerFrame.Name = "HeaderFrame"
    headerFrame.Size = UDim2.new(1, 0, 0, 42)
    headerFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = container
    
    -- Header rounded corners
    local headerCorners = Instance.new("UICorner")
    headerCorners.CornerRadius = UDim.new(0, 8)
    headerCorners.Parent = headerFrame
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 6)
    title.BackgroundTransparency = 1 
    title.Text = "Schema Builder"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = headerFrame
    
    -- Content section with two panels: Schema Tree and Property Editor
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, 0, 1, -50)
    contentFrame.Position = UDim2.new(0, 0, 0, 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = container
    
    -- Left panel for schema structure tree
    local treePanel = Instance.new("Frame")
    treePanel.Name = "TreePanel"
    treePanel.Size = UDim2.new(0.4, -5, 1, 0)
    treePanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    treePanel.BorderSizePixel = 0
    treePanel.Parent = contentFrame
    
    -- Tree panel rounded corners
    local treePanelCorners = Instance.new("UICorner")
    treePanelCorners.CornerRadius = UDim.new(0, 6)
    treePanelCorners.Parent = treePanel
    
    local treePanelHeader = Instance.new("TextLabel")
    treePanelHeader.Name = "Header"
    treePanelHeader.Size = UDim2.new(1, 0, 0, 30)
    treePanelHeader.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    treePanelHeader.Text = "Schema Structure"
    treePanelHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
    treePanelHeader.TextSize = 14
    treePanelHeader.Font = Enum.Font.SourceSansSemibold
    treePanelHeader.BorderSizePixel = 0
    treePanelHeader.Parent = treePanel
    
    -- Header rounded corners (top only)
    local treeHeaderCorners = Instance.new("UICorner")
    treeHeaderCorners.CornerRadius = UDim.new(0, 6)
    treeHeaderCorners.Parent = treePanelHeader
    
    -- Tree view container for schema structure
    local treeContainer = Instance.new("ScrollingFrame")
    treeContainer.Name = "TreeContainer"
    treeContainer.Size = UDim2.new(1, -10, 1, -75)
    treeContainer.Position = UDim2.new(0, 5, 0, 35)
    treeContainer.BackgroundTransparency = 1
    treeContainer.BorderSizePixel = 0
    treeContainer.ScrollBarThickness = 6
    treeContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    treeContainer.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
    treeContainer.Parent = treePanel
    
    -- Add layout for tree items
    local treeLayout = Instance.new("UIListLayout")
    treeLayout.SortOrder = Enum.SortOrder.Name
    treeLayout.Padding = UDim.new(0, 2)
    treeLayout.Parent = treeContainer
    
    -- Controls for adding schema elements
    local treeControls = Instance.new("Frame")
    treeControls.Name = "Controls"
    treeControls.Size = UDim2.new(1, 0, 0, 30)
    treeControls.Position = UDim2.new(0, 0, 1, -35)
    treeControls.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    treeControls.BorderSizePixel = 0
    treeControls.Parent = treePanel
    
    -- Add button for adding new fields
    local addFieldBtn = Instance.new("TextButton")
    addFieldBtn.Name = "AddFieldButton"
    addFieldBtn.Size = UDim2.new(0, 120, 0, 24)
    addFieldBtn.Position = UDim2.new(0, 5, 0, 3)
    addFieldBtn.BackgroundColor3 = Color3.fromRGB(66, 133, 244) -- Google-style blue
    addFieldBtn.Text = "Add Field"
    addFieldBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    addFieldBtn.TextSize = 12
    addFieldBtn.Font = Enum.Font.SourceSansSemibold
    addFieldBtn.BorderSizePixel = 0
    addFieldBtn.Parent = treeControls
    
    -- Add button rounded corners
    local btnCorners = Instance.new("UICorner")
    btnCorners.CornerRadius = UDim.new(0, 4)
    btnCorners.Parent = addFieldBtn
    
    -- Right panel for property editor
    local editorPanel = Instance.new("Frame")
    editorPanel.Name = "EditorPanel"
    editorPanel.Size = UDim2.new(0.6, 0, 1, 0)
    editorPanel.Position = UDim2.new(0.4, 5, 0, 0)
    editorPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    editorPanel.BorderSizePixel = 0
    editorPanel.Parent = contentFrame
    
    -- Editor panel rounded corners
    local editorPanelCorners = Instance.new("UICorner")
    editorPanelCorners.CornerRadius = UDim.new(0, 6)
    editorPanelCorners.Parent = editorPanel
    
    local editorPanelHeader = Instance.new("TextLabel")
    editorPanelHeader.Name = "Header"
    editorPanelHeader.Size = UDim2.new(1, 0, 0, 30)
    editorPanelHeader.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    editorPanelHeader.Text = "Property Editor"
    editorPanelHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
    editorPanelHeader.TextSize = 14
    editorPanelHeader.Font = Enum.Font.SourceSansSemibold
    editorPanelHeader.BorderSizePixel = 0
    editorPanelHeader.Parent = editorPanel
    
    -- Header rounded corners (top only)
    local editorHeaderCorners = Instance.new("UICorner")
    editorHeaderCorners.CornerRadius = UDim.new(0, 6)
    editorHeaderCorners.Parent = editorPanelHeader
    
    -- Editor form container for property configuration
    local editorForm = Instance.new("ScrollingFrame")
    editorForm.Name = "EditorForm"
    editorForm.Size = UDim2.new(1, -10, 1, -75)
    editorForm.Position = UDim2.new(0, 5, 0, 35)
    editorForm.BackgroundTransparency = 1
    editorForm.BorderSizePixel = 0
    editorForm.ScrollBarThickness = 6
    editorForm.CanvasSize = UDim2.new(0, 0, 0, 600) -- Initial size, will be adjusted
    editorForm.Parent = editorPanel
    
    -- Add layout for form items
    local formLayout = Instance.new("UIListLayout")
    formLayout.SortOrder = Enum.SortOrder.LayoutOrder
    formLayout.Padding = UDim.new(0, 8)
    formLayout.Parent = editorForm
    
    -- Save and validation buttons
    local buttonBar = Instance.new("Frame")
    buttonBar.Name = "ButtonBar"
    buttonBar.Size = UDim2.new(1, 0, 0, 30)
    buttonBar.Position = UDim2.new(0, 0, 1, -35)
    buttonBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    buttonBar.BorderSizePixel = 0
    buttonBar.Parent = editorPanel
    
    -- Save button
    local saveBtn = Instance.new("TextButton")
    saveBtn.Name = "SaveButton"
    saveBtn.Size = UDim2.new(0, 120, 0, 24)
    saveBtn.Position = UDim2.new(1, -125, 0, 3)
    saveBtn.BackgroundColor3 = Color3.fromRGB(66, 133, 244) -- Google-style blue
    saveBtn.Text = "Save Schema"
    saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveBtn.TextSize = 12
    saveBtn.Font = Enum.Font.SourceSansSemibold
    saveBtn.BorderSizePixel = 0
    saveBtn.Parent = buttonBar
    
    -- Save button rounded corners
    local saveBtnCorners = Instance.new("UICorner")
    saveBtnCorners.CornerRadius = UDim.new(0, 4)
    saveBtnCorners.Parent = saveBtn
    
    -- Validate button
    local validateBtn = Instance.new("TextButton")
    validateBtn.Name = "ValidateButton"
    validateBtn.Size = UDim2.new(0, 120, 0, 24)
    validateBtn.Position = UDim2.new(1, -250, 0, 3)
    validateBtn.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- Green
    validateBtn.Text = "Validate"
    validateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    validateBtn.TextSize = 12
    validateBtn.Font = Enum.Font.SourceSansSemibold
    validateBtn.BorderSizePixel = 0
    validateBtn.Parent = buttonBar
    
    -- Validate button rounded corners
    local validateBtnCorners = Instance.new("UICorner")
    validateBtnCorners.CornerRadius = UDim.new(0, 4)
    validateBtnCorners.Parent = validateBtn
    
    -- Initialize the schema model
    local currentSchema = {}
    local selectedField = nil
    
    -- Function to create a tree item for a schema field
    local function createSchemaFieldItem(name, fieldType, parent, isRoot)
        local item = Instance.new("Frame")
        item.Name = name
        item.Size = UDim2.new(1, 0, 0, 24)
        item.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        item.BorderSizePixel = 0
        item.Parent = parent
        
        -- Item rounded corners
        local itemCorners = Instance.new("UICorner")
        itemCorners.CornerRadius = UDim.new(0, 4)
        itemCorners.Parent = item
        
        -- Indentation for nested items
        local indent = isRoot and 5 or 20
        
        -- Field icon based on type
        local typeIcon = Instance.new("TextLabel")
        typeIcon.Size = UDim2.new(0, 16, 0, 16)
        typeIcon.Position = UDim2.new(0, indent, 0.5, -8)
        typeIcon.BackgroundTransparency = 1
        typeIcon.Text = getTypeIcon(fieldType)
        typeIcon.TextColor3 = getTypeColor(fieldType)
        typeIcon.TextSize = 14
        typeIcon.Font = Enum.Font.SourceSans
        typeIcon.Parent = item
        
        -- Field name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.6, -indent-20, 1, 0)
        nameLabel.Position = UDim2.new(0, indent+20, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 12
        nameLabel.Font = Enum.Font.SourceSans
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = item
        
        -- Field type
        local typeLabel = Instance.new("TextLabel")
        typeLabel.Size = UDim2.new(0.4, -5, 1, 0)
        typeLabel.Position = UDim2.new(0.6, 0, 0, 0)
        typeLabel.BackgroundTransparency = 1
        typeLabel.Text = fieldType
        typeLabel.TextColor3 = getTypeColor(fieldType)
        typeLabel.TextSize = 12
        typeLabel.Font = Enum.Font.SourceSansBold
        typeLabel.TextXAlignment = Enum.TextXAlignment.Right
        typeLabel.Parent = item
        
        -- Button hover state
        item.MouseEnter:Connect(function()
            item.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        end)
        
        item.MouseLeave:Connect(function()
            if selectedField == name then
                item.BackgroundColor3 = Color3.fromRGB(66, 133, 244)
            else
                item.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
        end)
        
        -- Select on click
        item.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                selectField(name, fieldType)
                
                -- Update all items to show selection
                for _, child in pairs(treeContainer:GetChildren()) do
                    if child:IsA("Frame") then
                        if child.Name == name then
                            child.BackgroundColor3 = Color3.fromRGB(66, 133, 244)
                        else
                            child.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                        end
                    end
                end
            end
        end)
        
        return item
    end
    
    -- Function to get icon for data type
    function getTypeIcon(fieldType)
        if fieldType == "string" then
            return "Abc"
        elseif fieldType == "number" then
            return "123"
        elseif fieldType == "boolean" then
            return "✓"
        elseif fieldType == "table" or fieldType == "array" then
            return "{ }"
        else
            return "?"
        end
    end
    
    -- Function to get color for data type
    function getTypeColor(fieldType)
        if fieldType == "string" then
            return Color3.fromRGB(102, 187, 106) -- Green
        elseif fieldType == "number" then
            return Color3.fromRGB(255, 183, 77) -- Orange
        elseif fieldType == "boolean" then
            return Color3.fromRGB(120, 144, 238) -- Blue
        elseif fieldType == "table" then
            return Color3.fromRGB(179, 157, 219) -- Purple
        elseif fieldType == "array" then
            return Color3.fromRGB(233, 150, 122) -- Salmon
        else
            return Color3.fromRGB(189, 189, 189) -- Gray
        end
    end
    
    -- Function to select a field
    function selectField(name, fieldType)
        selectedField = name
        
        -- Clear existing form elements
        for _, child in pairs(editorForm:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- Create property editor form for selected field
        createFieldEditor(name, fieldType)
    end
    
    -- Function to create property editor for a field
    function createFieldEditor(name, fieldType)
        -- Field name section
        local nameSection = Instance.new("Frame")
        nameSection.Name = "NameSection"
        nameSection.Size = UDim2.new(1, 0, 0, 60)
        nameSection.BackgroundTransparency = 1
        nameSection.LayoutOrder = 1
        nameSection.Parent = editorForm
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0, 20)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = "Field Name"
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.SourceSansSemibold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = nameSection
        
        local nameInput = Instance.new("TextBox")
        nameInput.Size = UDim2.new(1, 0, 0, 30)
        nameInput.Position = UDim2.new(0, 0, 0, 25)
        nameInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        nameInput.Text = name
        nameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameInput.PlaceholderText = "Enter field name"
        nameInput.TextSize = 14
        nameInput.Font = Enum.Font.SourceSans
        nameInput.BorderSizePixel = 0
        nameInput.Parent = nameSection
        
        -- TextBox rounded corners
        local nameInputCorners = Instance.new("UICorner")
        nameInputCorners.CornerRadius = UDim.new(0, 4)
        nameInputCorners.Parent = nameInput
        
        -- Field type section
        local typeSection = Instance.new("Frame")
        typeSection.Name = "TypeSection"
        typeSection.Size = UDim2.new(1, 0, 0, 80)
        typeSection.BackgroundTransparency = 1
        typeSection.LayoutOrder = 2
        typeSection.Parent = editorForm
        
        local typeLabel = Instance.new("TextLabel")
        typeLabel.Size = UDim2.new(1, 0, 0, 20)
        typeLabel.BackgroundTransparency = 1
        typeLabel.Text = "Data Type"
        typeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        typeLabel.TextSize = 14
        typeLabel.Font = Enum.Font.SourceSansSemibold
        typeLabel.TextXAlignment = Enum.TextXAlignment.Left
        typeLabel.Parent = typeSection
        
        -- Create radio buttons for types
        local typeOptions = {"string", "number", "boolean", "table", "array"}
        local buttons = {}
        
        for i, option in ipairs(typeOptions) do
            local yPos = 25 + ((i-1) * 30)
            if i > 3 then
                yPos = 25 + ((i-4) * 30)
            end
            
            local xPos = i <= 3 and 0 or 0.5
            local width = i <= 3 and 0.33 or 0.5
            
            local typeOption = Instance.new("Frame")
            typeOption.Size = UDim2.new(width, -5, 0, 25)
            typeOption.Position = UDim2.new(xPos, i <= 3 and 0 or 5, 0, yPos)
            typeOption.BackgroundColor3 = fieldType == option and Color3.fromRGB(66, 133, 244) or Color3.fromRGB(50, 50, 50)
            typeOption.BorderSizePixel = 0
            typeOption.Parent = typeSection
            
            -- Option rounded corners
            local optionCorners = Instance.new("UICorner")
            optionCorners.CornerRadius = UDim.new(0, 4)
            optionCorners.Parent = typeOption
            
            local optionLabel = Instance.new("TextLabel")
            optionLabel.Size = UDim2.new(1, 0, 1, 0)
            optionLabel.BackgroundTransparency = 1
            optionLabel.Text = option
            optionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            optionLabel.TextSize = 14
            optionLabel.Font = Enum.Font.SourceSans
            optionLabel.Parent = typeOption
            
            typeOption.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    -- Update selection
                    for _, btn in pairs(buttons) do
                        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    end
                    typeOption.BackgroundColor3 = Color3.fromRGB(66, 133, 244)
                    
                    -- Update current field type
                    fieldType = option
                    
                    -- Refresh editor with new field type
                    createFieldEditor(name, option)
                end
            end)
            
            table.insert(buttons, typeOption)
        end
        
        -- Required field section
        local requiredSection = Instance.new("Frame")
        requiredSection.Name = "RequiredSection"
        requiredSection.Size = UDim2.new(1, 0, 0, 40)
        requiredSection.BackgroundTransparency = 1
        requiredSection.LayoutOrder = 3
        requiredSection.Parent = editorForm
        
        local requiredCheckbox = Instance.new("Frame")
        requiredCheckbox.Size = UDim2.new(0, 24, 0, 24)
        requiredCheckbox.Position = UDim2.new(0, 0, 0, 8)
        requiredCheckbox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        requiredCheckbox.BorderSizePixel = 0
        requiredCheckbox.Parent = requiredSection
        
        -- Checkbox rounded corners
        local checkboxCorners = Instance.new("UICorner")
        checkboxCorners.CornerRadius = UDim.new(0, 4)
        checkboxCorners.Parent = requiredCheckbox
        
        local checkmark = Instance.new("TextLabel")
        checkmark.Size = UDim2.new(1, 0, 1, 0)
        checkmark.BackgroundTransparency = 1
        checkmark.Text = "✓"
        checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
        checkmark.TextSize = 16
        checkmark.Font = Enum.Font.SourceSansBold
        checkmark.Visible = false -- Initially unchecked
        checkmark.Parent = requiredCheckbox
        
        local requiredLabel = Instance.new("TextLabel")
        requiredLabel.Size = UDim2.new(1, -40, 1, 0)
        requiredLabel.Position = UDim2.new(0, 35, 0, 0)
        requiredLabel.BackgroundTransparency = 1
        requiredLabel.Text = "Required Field"
        requiredLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        requiredLabel.TextSize = 14
        requiredLabel.Font = Enum.Font.SourceSansSemibold
        requiredLabel.TextXAlignment = Enum.TextXAlignment.Left
        requiredLabel.Parent = requiredSection
        
        -- Toggle checkbox on click
        local isRequired = false -- Track checkbox state
        
        local function toggleCheckbox()
            isRequired = not isRequired
            checkmark.Visible = isRequired
            requiredCheckbox.BackgroundColor3 = isRequired and Color3.fromRGB(66, 133, 244) or Color3.fromRGB(50, 50, 50)
        end
        
        requiredCheckbox.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                toggleCheckbox()
            end
        end)
        
        requiredLabel.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                toggleCheckbox()
            end
        end)
        
        -- Default value section
        local defaultSection = Instance.new("Frame")
        defaultSection.Name = "DefaultSection"
        defaultSection.Size = UDim2.new(1, 0, 0, 60)
        defaultSection.BackgroundTransparency = 1
        defaultSection.LayoutOrder = 4
        defaultSection.Parent = editorForm
        
        local defaultLabel = Instance.new("TextLabel")
        defaultLabel.Size = UDim2.new(1, 0, 0, 20)
        defaultLabel.BackgroundTransparency = 1
        defaultLabel.Text = "Default Value"
        defaultLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        defaultLabel.TextSize = 14
        defaultLabel.Font = Enum.Font.SourceSansSemibold
        defaultLabel.TextXAlignment = Enum.TextXAlignment.Left
        defaultLabel.Parent = defaultSection
        
        local defaultInput = Instance.new("TextBox")
        defaultInput.Size = UDim2.new(1, 0, 0, 30)
        defaultInput.Position = UDim2.new(0, 0, 0, 25)
        defaultInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        defaultInput.Text = ""
        defaultInput.TextColor3 = Color3.fromRGB(255, 255, 255)
        defaultInput.PlaceholderText = getDefaultPlaceholder(fieldType)
        defaultInput.TextSize = 14
        defaultInput.Font = Enum.Font.SourceSans
        defaultInput.BorderSizePixel = 0
        defaultInput.Parent = defaultSection
        
        -- Input rounded corners
        local defaultInputCorners = Instance.new("UICorner")
        defaultInputCorners.CornerRadius = UDim.new(0, 4)
        defaultInputCorners.Parent = defaultInput
        
        -- Add specific options based on field type
        if fieldType == "string" then
            -- String validation options
            addStringValidationOptions(editorForm)
        elseif fieldType == "number" then
            -- Number range options
            addNumberRangeOptions(editorForm)
        elseif fieldType == "boolean" then
            -- Boolean has simple options (already covered by default)
        elseif fieldType == "table" or fieldType == "array" then
            -- Table/array structure options
            addStructureOptions(editorForm, fieldType)
        end
    end
    
    -- Helper function for default value placeholder text
    function getDefaultPlaceholder(fieldType)
        if fieldType == "string" then
            return "Default text value"
        elseif fieldType == "number" then
            return "Default number value (e.g., 0)"
        elseif fieldType == "boolean" then
            return "true or false"
        elseif fieldType == "table" then
            return "Default JSON for table"
        elseif fieldType == "array" then
            return "Default JSON array"
        else
            return "Enter default value"
        end
    end
    
    -- Function for adding string validation options
    function addStringValidationOptions(parent)
        local validationSection = Instance.new("Frame")
        validationSection.Name = "ValidationSection"
        validationSection.Size = UDim2.new(1, 0, 0, 110)
        validationSection.BackgroundTransparency = 1
        validationSection.LayoutOrder = 5
        validationSection.Parent = parent
        
        local validationLabel = Instance.new("TextLabel")
        validationLabel.Size = UDim2.new(1, 0, 0, 20)
        validationLabel.BackgroundTransparency = 1
        validationLabel.Text = "String Validation"
        validationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        validationLabel.TextSize = 14
        validationLabel.Font = Enum.Font.SourceSansSemibold
        validationLabel.TextXAlignment = Enum.TextXAlignment.Left
        validationLabel.Parent = validationSection
        
        -- Min Length
        local minSection = Instance.new("Frame")
        minSection.Size = UDim2.new(0.48, 0, 0, 60)
        minSection.Position = UDim2.new(0, 0, 0, 25)
        minSection.BackgroundTransparency = 1
        minSection.Parent = validationSection
        
        local minLabel = Instance.new("TextLabel")
        minLabel.Size = UDim2.new(1, 0, 0, 20)
        minLabel.BackgroundTransparency = 1
        minLabel.Text = "Min Length"
        minLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        minLabel.TextSize = 12
        minLabel.Font = Enum.Font.SourceSans
        minLabel.TextXAlignment = Enum.TextXAlignment.Left
        minLabel.Parent = minSection
        
        local minInput = Instance.new("TextBox")
        minInput.Size = UDim2.new(1, 0, 0, 30)
        minInput.Position = UDim2.new(0, 0, 0, 25)
        minInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        minInput.Text = ""
        minInput.TextColor3 = Color3.fromRGB(255, 255, 255)
        minInput.PlaceholderText = "0"
        minInput.TextSize = 14
        minInput.Font = Enum.Font.SourceSans
        minInput.BorderSizePixel = 0
        minInput.Parent = minSection
        
        -- Input rounded corners
        local minInputCorners = Instance.new("UICorner")
        minInputCorners.CornerRadius = UDim.new(0, 4)
        minInputCorners.Parent = minInput
        
        -- Max Length
        local maxSection = Instance.new("Frame")
        maxSection.Size = UDim2.new(0.48, 0, 0, 60)
        maxSection.Position = UDim2.new(0.52, 0, 0, 25)
        maxSection.BackgroundTransparency = 1
        maxSection.Parent = validationSection
        
        local maxLabel = Instance.new("TextLabel")
        maxLabel.Size = UDim2.new(1, 0, 0, 20)
        maxLabel.BackgroundTransparency = 1
        maxLabel.Text = "Max Length"
        maxLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        maxLabel.TextSize = 12
        maxLabel.Font = Enum.Font.SourceSans
        maxLabel.TextXAlignment = Enum.TextXAlignment.Left
        maxLabel.Parent = maxSection
        
        local maxInput = Instance.new("TextBox")
        maxInput.Size = UDim2.new(1, 0, 0, 30)
        maxInput.Position = UDim2.new(0, 0, 0, 25)
        maxInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        maxInput.Text = ""
        maxInput.TextColor3 = Color3.fromRGB(255, 255, 255)
        maxInput.PlaceholderText = "255"
        maxInput.TextSize = 14
        maxInput.Font = Enum.Font.SourceSans
        maxInput.BorderSizePixel = 0
        maxInput.Parent = maxSection
        
        -- Input rounded corners
        local maxInputCorners = Instance.new("UICorner")
        maxInputCorners.CornerRadius = UDim.new(0, 4)
        maxInputCorners.Parent = maxInput
        
        -- Pattern (Regex) Input
        local patternSection = Instance.new("Frame")
        patternSection.Size = UDim2.new(1, 0, 0, 60)
        patternSection.Position = UDim2.new(0, 0, 0, 90)
        patternSection.BackgroundTransparency = 1
        patternSection.Parent = validationSection
        
        local patternLabel = Instance.new("TextLabel")
        patternLabel.Size = UDim2.new(1, 0, 0, 20)
        patternLabel.BackgroundTransparency = 1
        patternLabel.Text = "Pattern (Regex)"
        patternLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        patternLabel.TextSize = 12
        patternLabel.Font = Enum.Font.SourceSans
        patternLabel.TextXAlignment = Enum.TextXAlignment.Left
        patternLabel.Parent = patternSection
        
        local patternInput = Instance.new("TextBox")
        patternInput.Size = UDim2.new(1, 0, 0, 30)
        patternInput.Position = UDim2.new(0, 0, 0, 25)
        patternInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        patternInput.Text = ""
        patternInput.TextColor3 = Color3.fromRGB(255, 255, 255)
        patternInput.PlaceholderText = "e.g. ^[A-Za-z0-9]+$"
        patternInput.TextSize = 14
        patternInput.Font = Enum.Font.SourceSans
        patternInput.BorderSizePixel = 0
        patternInput.Parent = patternSection
        
        -- Input rounded corners
        local patternInputCorners = Instance.new("UICorner")
        patternInputCorners.CornerRadius = UDim.new(0, 4)
        patternInputCorners.Parent = patternInput
    end
    
    -- Function for adding number range options
    function addNumberRangeOptions(parent)
        local rangeSection = Instance.new("Frame")
        rangeSection.Name = "RangeSection"
        rangeSection.Size = UDim2.new(1, 0, 0, 90)
        rangeSection.BackgroundTransparency = 1
        rangeSection.LayoutOrder = 5
        rangeSection.Parent = parent
        
        local rangeLabel = Instance.new("TextLabel")
        rangeLabel.Size = UDim2.new(1, 0, 0, 20)
        rangeLabel.BackgroundTransparency = 1
        rangeLabel.Text = "Number Range"
        rangeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        rangeLabel.TextSize = 14
        rangeLabel.Font = Enum.Font.SourceSansSemibold
        rangeLabel.TextXAlignment = Enum.TextXAlignment.Left
        rangeLabel.Parent = rangeSection
        
        -- Min Value
        local minSection = Instance.new("Frame")
        minSection.Size = UDim2.new(0.48, 0, 0, 60)
        minSection.Position = UDim2.new(0, 0, 0, 25)
        minSection.BackgroundTransparency = 1
        minSection.Parent = rangeSection
        
        local minLabel = Instance.new("TextLabel")
        minLabel.Size = UDim2.new(1, 0, 0, 20)
        minLabel.BackgroundTransparency = 1
        minLabel.Text = "Min Value"
        minLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        minLabel.TextSize = 12
        minLabel.Font = Enum.Font.SourceSans
        minLabel.TextXAlignment = Enum.TextXAlignment.Left
        minLabel.Parent = minSection
        
        local minInput = Instance.new("TextBox")
        minInput.Size = UDim2.new(1, 0, 0, 30)
        minInput.Position = UDim2.new(0, 0, 0, 25)
        minInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        minInput.Text = ""
        minInput.TextColor3 = Color3.fromRGB(255, 255, 255)
        minInput.PlaceholderText = "Minimum"
        minInput.TextSize = 14
        minInput.Font = Enum.Font.SourceSans
        minInput.BorderSizePixel = 0
        minInput.Parent = minSection
        
        -- Input rounded corners
        local minInputCorners = Instance.new("UICorner")
        minInputCorners.CornerRadius = UDim.new(0, 4)
        minInputCorners.Parent = minInput
        
        -- Max Value
        local maxSection = Instance.new("Frame")
        maxSection.Size = UDim2.new(0.48, 0, 0, 60)
        maxSection.Position = UDim2.new(0.52, 0, 0, 25)
        maxSection.BackgroundTransparency = 1
        maxSection.Parent = rangeSection
        
        local maxLabel = Instance.new("TextLabel")
        maxLabel.Size = UDim2.new(1, 0, 0, 20)
        maxLabel.BackgroundTransparency = 1
        maxLabel.Text = "Max Value"
        maxLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        maxLabel.TextSize = 12
        maxLabel.Font = Enum.Font.SourceSans
        maxLabel.TextXAlignment = Enum.TextXAlignment.Left
        maxLabel.Parent = maxSection
        
        local maxInput = Instance.new("TextBox")
        maxInput.Size = UDim2.new(1, 0, 0, 30)
        maxInput.Position = UDim2.new(0, 0, 0, 25)
        maxInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        maxInput.Text = ""
        maxInput.TextColor3 = Color3.fromRGB(255, 255, 255)
        maxInput.PlaceholderText = "Maximum"
        maxInput.TextSize = 14
        maxInput.Font = Enum.Font.SourceSans
        maxInput.BorderSizePixel = 0
        maxInput.Parent = maxSection
        
        -- Input rounded corners
        local maxInputCorners = Instance.new("UICorner")
        maxInputCorners.CornerRadius = UDim.new(0, 4)
        maxInputCorners.Parent = maxInput
    end
    
    -- Function for adding structure options for tables and arrays
    function addStructureOptions(parent, fieldType)
        local structureSection = Instance.new("Frame")
        structureSection.Name = "StructureSection"
        structureSection.Size = UDim2.new(1, 0, 0, 140)
        structureSection.BackgroundTransparency = 1
        structureSection.LayoutOrder = 5
        structureSection.Parent = parent
        
        local structureLabel = Instance.new("TextLabel")
        structureLabel.Size = UDim2.new(1, 0, 0, 20)
        structureLabel.BackgroundTransparency = 1
        structureLabel.Text = fieldType == "table" and "Table Structure" or "Array Structure"
        structureLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        structureLabel.TextSize = 14
        structureLabel.Font = Enum.Font.SourceSansSemibold
        structureLabel.TextXAlignment = Enum.TextXAlignment.Left
        structureLabel.Parent = structureSection
        
        -- Structure description
        local structureDesc = Instance.new("TextLabel")
        structureDesc.Size = UDim2.new(1, 0, 0, 40)
        structureDesc.Position = UDim2.new(0, 0, 0, 25)
        structureDesc.BackgroundTransparency = 1
        structureDesc.Text = fieldType == "table" 
            and "Define the structure of this table by adding child fields in the schema tree."
            or "Define what type of items this array will contain."
        structureDesc.TextColor3 = Color3.fromRGB(200, 200, 200)
        structureDesc.TextSize = 12
        structureDesc.Font = Enum.Font.SourceSans
        structureDesc.TextWrapped = true
        structureDesc.TextXAlignment = Enum.TextXAlignment.Left
        structureDesc.Parent = structureSection
        
        if fieldType == "array" then
            -- Item type selector for arrays
            local itemTypeLabel = Instance.new("TextLabel")
            itemTypeLabel.Size = UDim2.new(1, 0, 0, 20)
            itemTypeLabel.Position = UDim2.new(0, 0, 0, 70)
            itemTypeLabel.BackgroundTransparency = 1
            itemTypeLabel.Text = "Array Item Type"
            itemTypeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            itemTypeLabel.TextSize = 12
            itemTypeLabel.Font = Enum.Font.SourceSans
            itemTypeLabel.TextXAlignment = Enum.TextXAlignment.Left
            itemTypeLabel.Parent = structureSection
            
            -- Create dropdown for item types
            local itemTypeDropdown = Instance.new("TextButton")
            itemTypeDropdown.Size = UDim2.new(1, 0, 0, 30)
            itemTypeDropdown.Position = UDim2.new(0, 0, 0, 95)
            itemTypeDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            itemTypeDropdown.Text = "string"
            itemTypeDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
            itemTypeDropdown.TextSize = 14
            itemTypeDropdown.Font = Enum.Font.SourceSans
            itemTypeDropdown.BorderSizePixel = 0
            itemTypeDropdown.Parent = structureSection
            
            -- Dropdown rounded corners
            local dropdownCorners = Instance.new("UICorner")
            dropdownCorners.CornerRadius = UDim.new(0, 4)
            dropdownCorners.Parent = itemTypeDropdown
            
            -- Dropdown arrow
            local dropdownArrow = Instance.new("TextLabel")
            dropdownArrow.Size = UDim2.new(0, 20, 0, 20)
            dropdownArrow.Position = UDim2.new(1, -25, 0.5, -10)
            dropdownArrow.BackgroundTransparency = 1
            dropdownArrow.Text = "▼"
            dropdownArrow.TextColor3 = Color3.fromRGB(200, 200, 200)
            dropdownArrow.TextSize = 12
            dropdownArrow.Font = Enum.Font.SourceSans
            dropdownArrow.Parent = itemTypeDropdown
            
            -- Create dropdown menu
            local dropdownMenu = Instance.new("Frame")
            dropdownMenu.Size = UDim2.new(1, 0, 0, 150)
            dropdownMenu.Position = UDim2.new(0, 0, 1, 5)
            dropdownMenu.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            dropdownMenu.BorderSizePixel = 0
            dropdownMenu.Visible = false
            dropdownMenu.ZIndex = 10
            dropdownMenu.Parent = itemTypeDropdown
            
            -- Dropdown menu rounded corners
            local menuCorners = Instance.new("UICorner")
            menuCorners.CornerRadius = UDim.new(0, 4)
            menuCorners.Parent = dropdownMenu
            
            -- Add dropdown options
            local typeOptions = {"string", "number", "boolean", "table"}
            local optionHeight = 30
            
            for i, option in ipairs(typeOptions) do
                local optionButton = Instance.new("TextButton")
                optionButton.Size = UDim2.new(1, 0, 0, optionHeight)
                optionButton.Position = UDim2.new(0, 0, 0, (i-1) * optionHeight)
                optionButton.BackgroundTransparency = 1
                optionButton.Text = option
                optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                optionButton.TextSize = 14
                optionButton.Font = Enum.Font.SourceSans
                optionButton.ZIndex = 11
                optionButton.Parent = dropdownMenu
                
                optionButton.MouseEnter:Connect(function()
                    optionButton.BackgroundTransparency = 0.5
                    optionButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                end)
                
                optionButton.MouseLeave:Connect(function()
                    optionButton.BackgroundTransparency = 1
                end)
                
                optionButton.MouseButton1Click:Connect(function()
                    itemTypeDropdown.Text = option
                    dropdownMenu.Visible = false
                end)
            end
            
            -- Toggle dropdown visibility
            itemTypeDropdown.MouseButton1Click:Connect(function()
                dropdownMenu.Visible = not dropdownMenu.Visible
            end)
        end
    end
    
    -- Handle "Add Field" button click
    addFieldBtn.MouseButton1Click:Connect(function()
        -- Prompt for field name
        local newFieldName = "newField" .. tostring(#treeContainer:GetChildren())
        
        -- Add to tree view
        local newItem = createSchemaFieldItem(newFieldName, "string", treeContainer, true)
        
        -- Select the new field automatically
        selectField(newFieldName, "string")
        
        -- Update selection display
        for _, child in pairs(treeContainer:GetChildren()) do
            if child:IsA("Frame") then
                if child.Name == newFieldName then
                    child.BackgroundColor3 = Color3.fromRGB(66, 133, 244)
                else
                    child.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                end
            end
        end
    end)
    
    -- Handle save button click
    saveBtn.MouseButton1Click:Connect(function()
        -- TODO: Collect form data and save schema
        local savedSuccessfully = SchemaManager.saveSchema(currentSchema, "CurrentDataStore", "SchemaKey")
        
        if savedSuccessfully then
            local notification = StyleGuide.createNotification("Schema saved successfully!", container, "success")
            RunService.Heartbeat:Wait(3)
            notification:Destroy()
        else
            local notification = StyleGuide.createNotification("Error saving schema.", container, "error")
            RunService.Heartbeat:Wait(3)
            notification:Destroy()
        end
    end)
    
    -- Handle validate button click
    validateBtn.MouseButton1Click:Connect(function()
        -- TODO: Validate current schema structure
        local isValid, errors = SchemaValidator.validateSchema(currentSchema)
        
        if isValid then
            local notification = StyleGuide.createNotification("Schema is valid.", container, "success")
            RunService.Heartbeat:Wait(3)
            notification:Destroy()
        else
            local notification = StyleGuide.createNotification("Schema validation failed: " .. tostring(errors), container, "error")
            RunService.Heartbeat:Wait(3)
            notification:Destroy()
        end
    end)
    
    -- Return container and visibility control
    return {
        container = container,
        show = function() container.Visible = true end,
        hide = function() container.Visible = false end
    }
end

return SchemaBuilderUI
