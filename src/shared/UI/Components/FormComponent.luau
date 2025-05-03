--!strict
--[[
    FormComponent.luau
    
    A component for creating and managing forms with various input types,
    validation, and submission handling.
    
    Created: May 4, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import ModuleLoaderHelper
local ModuleLoaderHelper = nil
if ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ModuleLoaderHelper") then
    local success, result = pcall(function()
        return require(ReplicatedStorage.shared.ModuleLoaderHelper)
    end)
    
    if success and result then
        ModuleLoaderHelper = result
    else
        warn("[FormComponent] Failed to load ModuleLoaderHelper, using direct requires")
    end
end

-- Load UIComponentBase
local UIComponentBase
if ModuleLoaderHelper then
    UIComponentBase = ModuleLoaderHelper.loadModule("UI/UIComponentBase")
else
    local componentBasePath = ReplicatedStorage:FindFirstChild("shared") and 
                             ReplicatedStorage.shared:FindFirstChild("UI") and 
                             ReplicatedStorage.shared.UI:FindFirstChild("UIComponentBase")
    
    if componentBasePath then
        UIComponentBase = require(componentBasePath)
    end
end

if not UIComponentBase then
    error("[FormComponent] Required dependency UIComponentBase not found")
end

-- Load ContainerComponent
local ContainerComponent
if ModuleLoaderHelper then
    ContainerComponent = ModuleLoaderHelper.loadModule("UI/Components/ContainerComponent")
else
    local containerComponentPath = ReplicatedStorage:FindFirstChild("shared") and 
                                  ReplicatedStorage.shared:FindFirstChild("UI") and 
                                  ReplicatedStorage.shared.UI:FindFirstChild("Components") and
                                  ReplicatedStorage.shared.UI.Components:FindFirstChild("ContainerComponent")
    
    if containerComponentPath then
        ContainerComponent = require(containerComponentPath)
    end
end

-- Load ButtonComponent
local ButtonComponent
if ModuleLoaderHelper then
    ButtonComponent = ModuleLoaderHelper.loadModule("UI/Components/ButtonComponent")
else
    local buttonComponentPath = ReplicatedStorage:FindFirstChild("shared") and 
                               ReplicatedStorage.shared:FindFirstChild("UI") and 
                               ReplicatedStorage.shared.UI:FindFirstChild("Components") and
                               ReplicatedStorage.shared.UI.Components:FindFirstChild("ButtonComponent")
    
    if buttonComponentPath then
        ButtonComponent = require(buttonComponentPath)
    end
end

-- Load TextComponent
local TextComponent
if ModuleLoaderHelper then
    TextComponent = ModuleLoaderHelper.loadModule("UI/Components/TextComponent")
else
    local textComponentPath = ReplicatedStorage:FindFirstChild("shared") and 
                             ReplicatedStorage.shared:FindFirstChild("UI") and 
                             ReplicatedStorage.shared.UI:FindFirstChild("Components") and
                             ReplicatedStorage.shared.UI.Components:FindFirstChild("TextComponent")
    
    if textComponentPath then
        TextComponent = require(textComponentPath)
    end
end

-- Load UIStyleSystem
local UIStyleSystem
if ModuleLoaderHelper then
    UIStyleSystem = ModuleLoaderHelper.loadModule("UI/UIStyleSystem")
else
    local styleSystemPath = ReplicatedStorage:FindFirstChild("shared") and 
                           ReplicatedStorage.shared:FindFirstChild("UI") and 
                           ReplicatedStorage.shared.UI:FindFirstChild("UIStyleSystem")
    
    if styleSystemPath then
        UIStyleSystem = require(styleSystemPath)
    end
end

-- Default validation functions
local Validation = {
    required = function(value)
        return value ~= nil and value ~= "", "This field is required"
    end,
    
    minLength = function(min)
        return function(value)
            return #tostring(value or "") >= min, string.format("Must be at least %d characters", min)
        end
    end,
    
    maxLength = function(max)
        return function(value)
            return #tostring(value or "") <= max, string.format("Must be no more than %d characters", max)
        end
    end,
    
    pattern = function(pattern, errorMessage)
        return function(value)
            return string.match(tostring(value or ""), pattern) ~= nil, errorMessage or "Invalid format"
        end
    end,
    
    email = function(value)
        local pattern = "^[%w._%+-]+@[%w.-]+%.[%a]+$"
        return string.match(tostring(value or ""), pattern) ~= nil, "Invalid email address"
    end,
    
    number = function(value)
        local num = tonumber(value)
        return num ~= nil, "Must be a number"
    end,
    
    min = function(min)
        return function(value)
            local num = tonumber(value)
            return num ~= nil and num >= min, string.format("Must be at least %s", tostring(min))
        end
    end,
    
    max = function(max)
        return function(value)
            local num = tonumber(value)
            return num ~= nil and num <= max, string.format("Must be no more than %s", tostring(max))
        end
    end,
    
    custom = function(validatorFn, errorMessage)
        return function(value)
            local success = validatorFn(value)
            return success, success and "" or errorMessage or "Validation failed"
        end
    end
}

--[[
    FormComponent - A component for creating and managing forms
]]
local FormComponent = setmetatable({}, UIComponentBase)
FormComponent.__index = FormComponent

-- Validation functions
FormComponent.Validation = Validation

--[[
    Create a new form component
    @param props - Form properties
    @return - New FormComponent instance
]]
function FormComponent.new(props)
    props = props or {}
    
    local self = UIComponentBase.new(props)
    setmetatable(self, FormComponent)
    
    -- Form properties
    self._type = "FormComponent"
    self._fields = props.fields or {}
    self._fieldComponents = {}
    self._fieldValues = {}
    self._fieldErrors = {}
    self._submitButton = nil
    self._submitButtonText = props.submitButtonText or "Submit"
    self._cancelButton = nil
    self._cancelButtonText = props.cancelButtonText or "Cancel"
    self._showSubmitButton = props.showSubmitButton ~= false -- Default to true
    self._showCancelButton = props.showCancelButton ~= false -- Default to true
    self._autoValidate = props.autoValidate ~= false -- Default to true
    self._fieldSpacing = props.fieldSpacing or 16
    self._labelPosition = props.labelPosition or "top" -- top, left, right
    self._layout = props.layout or "vertical" -- vertical, horizontal, grid
    self._columns = props.columns or 1
    self._containerComponent = nil
    
    -- Initialize field values and errors
    for _, field in ipairs(self._fields) do
        self._fieldValues[field.name] = field.defaultValue
        self._fieldErrors[field.name] = nil
    end
    
    return self
end

--[[
    Internal render method - creates the form container with fields
    @return - The created form container
]]
function FormComponent:_render()
    -- Create container component
    self._containerComponent = ContainerComponent.new({
        name = "FormContainer",
        size = self._size or UDim2.new(1, 0, 1, 0),
        position = self._position or UDim2.new(0, 0, 0, 0),
        backgroundColor = self._backgroundColor,
        cornerRadius = self._cornerRadius,
        borderColor = self._borderColor,
        borderWidth = self._borderWidth,
        padding = self._padding or 12,
        layoutType = "vertical",
        layoutConfig = {
            padding = self._fieldSpacing,
            alignment = "start"
        }
    })
    
    local container = self._containerComponent:getInstance()
    
    -- Create form fields
    self:_createFields(container)
    
    -- Create buttons
    if self._showSubmitButton or self._showCancelButton then
        self:_createButtons(container)
    end
    
    return container
end

--[[
    Create form fields based on field definitions
    @param container - Parent container
]]
function FormComponent:_createFields(container)
    for i, field in ipairs(self._fields) do
        local fieldContainer = self:_createFieldContainer(field, i)
        fieldContainer.Parent = container
    end
end

--[[
    Create a container for a single form field
    @param field - Field definition
    @param index - Field index
    @return - Field container instance
]]
function FormComponent:_createFieldContainer(field, index)
    -- Create field container
    local fieldContainer = Instance.new("Frame")
    fieldContainer.Name = "Field_" .. field.name
    fieldContainer.BackgroundTransparency = 1
    fieldContainer.Size = UDim2.new(1, 0, 0, 0) -- Auto height
    fieldContainer.AutomaticSize = Enum.AutomaticSize.Y
    fieldContainer.LayoutOrder = index
    
    -- Add label if provided
    local labelComponent = nil
    if field.label then
        labelComponent = TextComponent.new({
            text = field.label,
            textStyle = "label",
            size = self:_getLabelSize(),
            position = self:_getLabelPosition(),
            layoutOrder = 1
        })
        
        labelComponent:mount(fieldContainer)
    end
    
    -- Create input based on field type
    local inputComponent = self:_createInput(field)
    self._fieldComponents[field.name] = inputComponent
    
    -- Position input based on label position
    if labelComponent and self._labelPosition == "left" then
        inputComponent:setPosition(UDim2.new(0, labelComponent:getInstance().AbsoluteSize.X + 8, 0, 0))
    elseif labelComponent and self._labelPosition == "top" then
        inputComponent:setPosition(UDim2.new(0, 0, 0, labelComponent:getInstance().AbsoluteSize.Y + 4))
    end
    
    -- Add error message text (hidden initially)
    local errorComponent = TextComponent.new({
        text = "",
        textStyle = "error",
        textColor = Color3.fromRGB(220, 50, 50),
        size = UDim2.new(1, 0, 0, 0),
        autoSize = "height",
        position = UDim2.new(0, 0, 1, inputComponent:getInstance().AbsoluteSize.Y + 4),
        visible = false
    })
    
    -- Store components for later access
    self._fieldComponents[field.name .. "_error"] = errorComponent
    
    -- Mount components
    inputComponent:mount(fieldContainer)
    errorComponent:mount(fieldContainer)
    
    return fieldContainer
end

--[[
    Create an input component based on field type
    @param field - Field definition
    @return - Input component
]]
function FormComponent:_createInput(field)
    local inputComponent = nil
    
    if field.type == "text" or field.type == "email" or field.type == "password" or field.type == "number" then
        -- Text input
        inputComponent = self:_createTextInput(field)
    elseif field.type == "textarea" then
        -- Multiline text input
        inputComponent = self:_createTextArea(field)
    elseif field.type == "select" then
        -- Dropdown select
        inputComponent = self:_createSelectInput(field)
    elseif field.type == "checkbox" then
        -- Checkbox input
        inputComponent = self:_createCheckboxInput(field)
    elseif field.type == "radio" then
        -- Radio button group
        inputComponent = self:_createRadioInput(field)
    elseif field.type == "slider" then
        -- Slider input
        inputComponent = self:_createSliderInput(field)
    elseif field.type == "custom" and field.component then
        -- Custom component
        inputComponent = field.component
    end
    
    -- If we have a component and it's a UI component
    if inputComponent then
        -- Set initial value if provided
        if field.defaultValue ~= nil and typeof(inputComponent.setValue) == "function" then
            inputComponent:setValue(field.defaultValue)
        end
        
        -- Set up change handler
        if typeof(inputComponent.onChange) == "function" then
            inputComponent:onChange(function(value)
                self:_handleFieldChange(field.name, value)
            end)
        end
    end
    
    return inputComponent
end

--[[
    Create a text input
    @param field - Field definition
    @return - TextInput component
]]
function FormComponent:_createTextInput(field)
    -- Create a text input instance
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, 0, 0, 40)
    textBox.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    textBox.Text = field.defaultValue or ""
    textBox.PlaceholderText = field.placeholder or ""
    textBox.PlaceholderColor3 = Color3.fromRGB(180, 180, 200)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 16
    textBox.BorderSizePixel = 0
    textBox.ClearTextOnFocus = field.clearOnFocus
    
    -- For password fields
    if field.type == "password" then
        textBox.TextScaled = false
        textBox.TextSize = 16
        textBox.ClearTextOnFocus = false
    end
    
    -- For number fields
    if field.type == "number" then
        textBox.TextScaled = false
        textBox.TextSize = 16
    end
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = textBox
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = textBox
    
    -- Create TextInput component wrapper
    local inputComponent = UIComponentBase.new({
        name = "TextInput_" .. field.name,
        size = UDim2.new(1, 0, 0, 40)
    })
    
    -- Override _render to return our textbox
    function inputComponent:_render()
        return textBox
    end
    
    -- Add setValue method
    function inputComponent:setValue(value)
        textBox.Text = tostring(value or "")
    end
    
    -- Add getValue method
    function inputComponent:getValue()
        return textBox.Text
    end
    
    -- Handle focus
    textBox.Focused:Connect(function()
        -- Visual feedback when focused
        textBox.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    end)
    
    textBox.FocusLost:Connect(function(enterPressed)
        -- Reset background color
        textBox.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        
        -- Trigger change event
        local value = textBox.Text
        if field.type == "number" then
            value = tonumber(value) or 0
        end
        
        inputComponent:triggerEvent("onChange", value)
        
        -- Handle enter key for submission
        if enterPressed and field.submitOnEnter then
            self:_handleSubmit()
        end
    end)
    
    return inputComponent
end

--[[
    Create a multiline text area
    @param field - Field definition
    @return - TextArea component
]]
function FormComponent:_createTextArea(field)
    -- Create a text area instance
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, 0, 0, 100) -- Taller than regular text input
    textBox.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    textBox.Text = field.defaultValue or ""
    textBox.PlaceholderText = field.placeholder or ""
    textBox.PlaceholderColor3 = Color3.fromRGB(180, 180, 200)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.TextYAlignment = Enum.TextYAlignment.Top
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 16
    textBox.BorderSizePixel = 0
    textBox.MultiLine = true
    textBox.TextWrapped = true
    textBox.ClearTextOnFocus = field.clearOnFocus
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = textBox
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = textBox
    
    -- Create TextArea component wrapper
    local inputComponent = UIComponentBase.new({
        name = "TextArea_" .. field.name,
        size = UDim2.new(1, 0, 0, 100)
    })
    
    -- Override _render to return our textbox
    function inputComponent:_render()
        return textBox
    end
    
    -- Add setValue method
    function inputComponent:setValue(value)
        textBox.Text = tostring(value or "")
    end
    
    -- Add getValue method
    function inputComponent:getValue()
        return textBox.Text
    end
    
    -- Handle focus
    textBox.Focused:Connect(function()
        -- Visual feedback when focused
        textBox.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    end)
    
    textBox.FocusLost:Connect(function()
        -- Reset background color
        textBox.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        
        -- Trigger change event
        inputComponent:triggerEvent("onChange", textBox.Text)
    end)
    
    return inputComponent
end

--[[
    Create a dropdown select input
    @param field - Field definition
    @return - Select component
]]
function FormComponent:_createSelectInput(field)
    -- Create a dropdown frame
    local dropdown = Instance.new("Frame")
    dropdown.Size = UDim2.new(1, 0, 0, 40)
    dropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    dropdown.BorderSizePixel = 0
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = dropdown
    
    -- Create the select button
    local selectButton = Instance.new("TextButton")
    selectButton.Name = "SelectButton"
    selectButton.Size = UDim2.new(1, 0, 1, 0)
    selectButton.BackgroundTransparency = 1
    selectButton.Text = field.placeholder or "Select..."
    selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectButton.Font = Enum.Font.Gotham
    selectButton.TextSize = 16
    selectButton.TextXAlignment = Enum.TextXAlignment.Left
    selectButton.AutoButtonColor = false
    selectButton.Parent = dropdown
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = selectButton
    
    -- Add dropdown arrow
    local arrowIcon = Instance.new("ImageLabel")
    arrowIcon.Size = UDim2.new(0, 16, 0, 16)
    arrowIcon.Position = UDim2.new(1, -8, 0.5, 0)
    arrowIcon.AnchorPoint = Vector2.new(1, 0.5)
    arrowIcon.BackgroundTransparency = 1
    arrowIcon.Image = "rbxassetid://6031091004" -- Arrow down icon
    arrowIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    arrowIcon.Parent = dropdown
    
    -- Create dropdown options container (hidden initially)
    local optionsContainer = Instance.new("Frame")
    optionsContainer.Name = "OptionsContainer"
    optionsContainer.Size = UDim2.new(1, 0, 0, 0) -- Will be sized based on options
    optionsContainer.Position = UDim2.new(0, 0, 1, 4)
    optionsContainer.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    optionsContainer.BorderSizePixel = 0
    optionsContainer.Visible = false
    optionsContainer.ZIndex = 10
    
    -- Add corner radius to options container
    local optionsCorner = Instance.new("UICorner")
    optionsCorner.CornerRadius = UDim.new(0, 4)
    optionsCorner.Parent = optionsContainer
    
    -- Add options layout
    local optionsLayout = Instance.new("UIListLayout")
    optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    optionsLayout.Padding = UDim.new(0, 2)
    optionsLayout.Parent = optionsContainer
    
    -- Add options padding
    local optionsPadding = Instance.new("UIPadding")
    optionsPadding.PaddingLeft = UDim.new(0, 4)
    optionsPadding.PaddingRight = UDim.new(0, 4)
    optionsPadding.PaddingTop = UDim.new(0, 4)
    optionsPadding.PaddingBottom = UDim.new(0, 4)
    optionsPadding.Parent = optionsContainer
    
    -- Create option buttons
    local selectedValue = field.defaultValue
    local options = field.options or {}
    local optionButtons = {}
    
    for i, option in ipairs(options) do
        local optionValue = option.value or option
        local optionLabel = option.label or tostring(option)
        
        local optionButton = Instance.new("TextButton")
        optionButton.Size = UDim2.new(1, 0, 0, 32)
        optionButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
        optionButton.Text = optionLabel
        optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        optionButton.Font = Enum.Font.Gotham
        optionButton.TextSize = 14
        optionButton.TextXAlignment = Enum.TextXAlignment.Left
        optionButton.LayoutOrder = i
        optionButton.ZIndex = 10
        
        -- Add corner radius to option button
        local optionCorner = Instance.new("UICorner")
        optionCorner.CornerRadius = UDim.new(0, 4)
        optionCorner.Parent = optionButton
        
        -- Add padding to option button
        local optionPadding = Instance.new("UIPadding")
        optionPadding.PaddingLeft = UDim.new(0, 8)
        optionPadding.PaddingRight = UDim.new(0, 8)
        optionPadding.Parent = optionButton
        
        -- Handle option selection
        optionButton.MouseButton1Click:Connect(function()
            selectedValue = optionValue
            selectButton.Text = optionLabel
            optionsContainer.Visible = false
            
            -- Update selected UI
            for _, btn in ipairs(optionButtons) do
                btn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
            end
            optionButton.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
            
            -- Trigger change event
            inputComponent:triggerEvent("onChange", selectedValue)
        end)
        
        -- Hover effect
        optionButton.MouseEnter:Connect(function()
            if selectedValue ~= optionValue then
                optionButton.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
            end
        end)
        
        optionButton.MouseLeave:Connect(function()
            if selectedValue ~= optionValue then
                optionButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
            else
                optionButton.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
            end
        end)
        
        -- Mark as selected if it's the default value
        if optionValue == selectedValue then
            optionButton.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
            selectButton.Text = optionLabel
        end
        
        optionButton.Parent = optionsContainer
        table.insert(optionButtons, optionButton)
    end
    
    -- Set initial selection if it matches a value
    if selectedValue then
        for _, option in ipairs(options) do
            local optionValue = option.value or option
            local optionLabel = option.label or tostring(option)
            
            if optionValue == selectedValue then
                selectButton.Text = optionLabel
                break
            end
        end
    end
    
    -- Toggle dropdown on click
    selectButton.MouseButton1Click:Connect(function()
        optionsContainer.Visible = not optionsContainer.Visible
        
        -- Update arrow direction
        if optionsContainer.Visible then
            arrowIcon.Rotation = 180
            -- Update the container height based on content
            optionsContainer.Size = UDim2.new(1, 0, 0, optionsLayout.AbsoluteContentSize.Y + 8)
        else
            arrowIcon.Rotation = 0
        end
    end)
    
    -- Handle click outside to close dropdown
    selectButton.MouseLeave:Connect(function()
        -- Add a slight delay to check if mouse is over options
        task.delay(0.1, function()
            if not optionsContainer.Visible then
                return
            end
            
            -- Check if mouse is over options container
            local mouse = game:GetService("Players").LocalPlayer:GetMouse()
            local optionsFrame = optionsContainer.AbsolutePosition
            local optionsSize = optionsContainer.AbsoluteSize
            
            local isOverOptions = 
                mouse.X >= optionsFrame.X and 
                mouse.X <= optionsFrame.X + optionsSize.X and
                mouse.Y >= optionsFrame.Y and
                mouse.Y <= optionsFrame.Y + optionsSize.Y
                
            if not isOverOptions then
                optionsContainer.Visible = false
                arrowIcon.Rotation = 0
            end
        end)
    end)
    
    optionsContainer.Parent = dropdown
    
    -- Create Select component wrapper
    local inputComponent = UIComponentBase.new({
        name = "Select_" .. field.name,
        size = UDim2.new(1, 0, 0, 40)
    })
    
    -- Override _render to return our dropdown
    function inputComponent:_render()
        return dropdown
    end
    
    -- Add setValue method
    function inputComponent:setValue(value)
        selectedValue = value
        for _, option in ipairs(options) do
            local optionValue = option.value or option
            local optionLabel = option.label or tostring(option)
            
            if optionValue == value then
                selectButton.Text = optionLabel
                -- Update selected UI
                for i, optVal in ipairs(options) do
                    local val = optVal.value or optVal
                    optionButtons[i].BackgroundColor3 = val == value 
                        and Color3.fromRGB(100, 100, 120) 
                        or Color3.fromRGB(80, 80, 100)
                end
                break
            end
        end
    end
    
    -- Add getValue method
    function inputComponent:getValue()
        return selectedValue
    end
    
    return inputComponent
end

--[[
    Create a checkbox input
    @param field - Field definition
    @return - Checkbox component
]]
function FormComponent:_createCheckboxInput(field)
    -- Create a checkbox container
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 32)
    container.BackgroundTransparency = 1
    
    -- Create the checkbox frame
    local checkbox = Instance.new("Frame")
    checkbox.Name = "Checkbox"
    checkbox.Size = UDim2.new(0, 24, 0, 24)
    checkbox.Position = UDim2.new(0, 0, 0.5, 0)
    checkbox.AnchorPoint = Vector2.new(0, 0.5)
    checkbox.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    checkbox.BorderSizePixel = 0
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = checkbox
    
    -- Create checkmark (hidden initially)
    local checkmark = Instance.new("ImageLabel")
    checkmark.Name = "Checkmark"
    checkmark.Size = UDim2.new(0.8, 0, 0.8, 0)
    checkmark.Position = UDim2.new(0.5, 0, 0.5, 0)
    checkmark.AnchorPoint = Vector2.new(0.5, 0.5)
    checkmark.BackgroundTransparency = 1
    checkmark.Image = "rbxassetid://6031094667" -- Checkmark icon
    checkmark.ImageColor3 = Color3.fromRGB(255, 255, 255)
    checkmark.Visible = field.defaultValue == true
    checkmark.Parent = checkbox
    
    -- Create label if provided
    if field.checkboxLabel then
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -32, 1, 0)
        label.Position = UDim2.new(0, 32, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = field.checkboxLabel
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = Enum.Font.Gotham
        label.TextSize = 16
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = container
    end
    
    -- Create the click detector
    local clickDetector = Instance.new("TextButton")
    clickDetector.Size = UDim2.new(1, 0, 1, 0)
    clickDetector.BackgroundTransparency = 1
    clickDetector.Text = ""
    clickDetector.ZIndex = 2
    clickDetector.Parent = container
    
    checkbox.Parent = container
    
    -- Create Checkbox component wrapper
    local inputComponent = UIComponentBase.new({
        name = "Checkbox_" .. field.name,
        size = UDim2.new(1, 0, 0, 32)
    })
    
    -- Track checked state
    local isChecked = field.defaultValue == true
    
    -- Toggle checkbox state
    local function toggleCheckbox()
        isChecked = not isChecked
        checkmark.Visible = isChecked
        
        -- Visual feedback
        checkbox.BackgroundColor3 = isChecked 
            and Color3.fromRGB(80, 80, 200) 
            or Color3.fromRGB(60, 60, 80)
        
        -- Trigger change event
        inputComponent:triggerEvent("onChange", isChecked)
    end
    
    -- Set initial state
    if isChecked then
        checkbox.BackgroundColor3 = Color3.fromRGB(80, 80, 200)
    end
    
    -- Handle checkbox click
    clickDetector.MouseButton1Click:Connect(toggleCheckbox)
    
    -- Override _render to return our container
    function inputComponent:_render()
        return container
    end
    
    -- Add setValue method
    function inputComponent:setValue(value)
        if isChecked ~= (value == true) then
            toggleCheckbox()
        end
    end
    
    -- Add getValue method
    function inputComponent:getValue()
        return isChecked
    end
    
    return inputComponent
end

--[[
    Create a radio button group input
    @param field - Field definition
    @return - RadioGroup component
]]
function FormComponent:_createRadioInput(field)
    -- Create a radio group container
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 0) -- Will be sized based on options
    container.BackgroundTransparency = 1
    container.AutomaticSize = Enum.AutomaticSize.Y
    
    -- Add layout
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = container
    
    -- Track selected value
    local selectedValue = field.defaultValue
    local radioButtons = {}
    local options = field.options or {}
    
    -- Create radio options
    for i, option in ipairs(options) do
        local optionValue = option.value or option
        local optionLabel = option.label or tostring(option)
        
        -- Create option container
        local optionContainer = Instance.new("Frame")
        optionContainer.Size = UDim2.new(1, 0, 0, 32)
        optionContainer.BackgroundTransparency = 1
        optionContainer.LayoutOrder = i
        
        -- Create radio button
        local radioButton = Instance.new("Frame")
        radioButton.Name = "RadioButton"
        radioButton.Size = UDim2.new(0, 24, 0, 24)
        radioButton.Position = UDim2.new(0, 0, 0.5, 0)
        radioButton.AnchorPoint = Vector2.new(0, 0.5)
        radioButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        radioButton.BorderSizePixel = 0
        
        -- Make radio button round
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0) -- Perfect circle
        corner.Parent = radioButton
        
        -- Create radio indicator (hidden initially)
        local indicator = Instance.new("Frame")
        indicator.Name = "Indicator"
        indicator.Size = UDim2.new(0.6, 0, 0.6, 0)
        indicator.Position = UDim2.new(0.5, 0, 0.5, 0)
        indicator.AnchorPoint = Vector2.new(0.5, 0.5)
        indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        indicator.BorderSizePixel = 0
        indicator.Visible = optionValue == selectedValue
        
        -- Make indicator round
        local indicatorCorner = Instance.new("UICorner")
        indicatorCorner.CornerRadius = UDim.new(1, 0) -- Perfect circle
        indicatorCorner.Parent = indicator
        
        indicator.Parent = radioButton
        
        -- Create label
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -32, 1, 0)
        label.Position = UDim2.new(0, 32, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = optionLabel
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = Enum.Font.Gotham
        label.TextSize = 16
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = optionContainer
        
        -- Create click detector
        local clickDetector = Instance.new("TextButton")
        clickDetector.Size = UDim2.new(1, 0, 1, 0)
        clickDetector.BackgroundTransparency = 1
        clickDetector.Text = ""
        clickDetector.ZIndex = 2
        clickDetector.Parent = optionContainer
        
        -- Highlight selected option
        if optionValue == selectedValue then
            radioButton.BackgroundColor3 = Color3.fromRGB(80, 80, 200)
        end
        
        -- Handle option click
        clickDetector.MouseButton1Click:Connect(function()
            selectedValue = optionValue
            
            -- Update UI
            for j, btn in ipairs(radioButtons) do
                local buttonValue = options[j].value or options[j]
                btn.BackgroundColor3 = buttonValue == selectedValue 
                    and Color3.fromRGB(80, 80, 200) 
                    or Color3.fromRGB(60, 60, 80)
                
                btn.Indicator.Visible = buttonValue == selectedValue
            end
            
            -- Trigger change event
            inputComponent:triggerEvent("onChange", selectedValue)
        end)
        
        -- Hover effect
        clickDetector.MouseEnter:Connect(function()
            if optionValue ~= selectedValue then
                radioButton.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
            end
        end)
        
        clickDetector.MouseLeave:Connect(function()
            if optionValue ~= selectedValue then
                radioButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            end
        end)
        
        radioButton.Parent = optionContainer
        optionContainer.Parent = container
        table.insert(radioButtons, radioButton)
    end
    
    -- Create RadioGroup component wrapper
    local inputComponent = UIComponentBase.new({
        name = "RadioGroup_" .. field.name,
        size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
    })
    
    -- Override _render to return our container
    function inputComponent:_render()
        return container
    end
    
    -- Add setValue method
    function inputComponent:setValue(value)
        if value ~= selectedValue then
            selectedValue = value
            
            -- Update UI
            for i, btn in ipairs(radioButtons) do
                local btnValue = options[i].value or options[i]
                btn.BackgroundColor3 = btnValue == selectedValue 
                    and Color3.fromRGB(80, 80, 200) 
                    or Color3.fromRGB(60, 60, 80)
                
                btn.Indicator.Visible = btnValue == selectedValue
            end
        end
    end
    
    -- Add getValue method
    function inputComponent:getValue()
        return selectedValue
    end
    
    return inputComponent
end

--[[
    Create a slider input
    @param field - Field definition
    @return - Slider component
]]
function FormComponent:_createSliderInput(field)
    -- Default values
    local minValue = field.min or 0
    local maxValue = field.max or 100
    local stepSize = field.step or 1
    local defaultValue = field.defaultValue or minValue
    
    -- Create slider container
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 48)
    container.BackgroundTransparency = 1
    
    -- Create slider track
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, 0, 0, 8)
    track.Position = UDim2.new(0, 0, 0.5, 0)
    track.AnchorPoint = Vector2.new(0, 0.5)
    track.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    track.BorderSizePixel = 0
    
    -- Add corner radius to track
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track
    
    -- Create filled part of track
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0) -- Will be sized based on value
    fill.BackgroundColor3 = Color3.fromRGB(80, 80, 200)
    fill.BorderSizePixel = 0
    
    -- Add corner radius to fill
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill
    
    fill.Parent = track
    
    -- Create slider thumb
    local thumb = Instance.new("Frame")
    thumb.Name = "Thumb"
    thumb.Size = UDim2.new(0, 20, 0, 20)
    thumb.Position = UDim2.new(0, 0, 0.5, 0)
    thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    
    -- Add corner radius to thumb
    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(1, 0)
    thumbCorner.Parent = thumb
    
    thumb.Parent = track
    
    -- Create value label
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 50, 0, 24)
    valueLabel.Position = UDim2.new(1, 0, 0, 0)
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultValue)
    valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextSize = 16
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = container
    
    -- Create click detector
    local clickDetector = Instance.new("TextButton")
    clickDetector.Size = UDim2.new(1, 0, 1, 0)
    clickDetector.BackgroundTransparency = 1
    clickDetector.Text = ""
    clickDetector.ZIndex = 2
    clickDetector.Parent = container
    
    track.Parent = container
    
    -- Current value and normalized position
    local currentValue = defaultValue
    
    -- Update slider position and value
    local function updateSlider(position)
        -- Convert position to value
        local trackWidth = track.AbsoluteSize.X
        local relativeX = math.clamp(position - track.AbsolutePosition.X, 0, trackWidth)
        local ratio = relativeX / trackWidth
        
        -- Calculate value based on step size
        local range = maxValue - minValue
        local rawValue = minValue + (range * ratio)
        local steppedValue = math.floor((rawValue - minValue) / stepSize + 0.5) * stepSize + minValue
        currentValue = math.clamp(steppedValue, minValue, maxValue)
        
        -- Update UI
        local normalizedPos = (currentValue - minValue) / range
        thumb.Position = UDim2.new(normalizedPos, 0, 0.5, 0)
        fill.Size = UDim2.new(normalizedPos, 0, 1, 0)
        valueLabel.Text = tostring(currentValue)
    end
    
    -- Set initial position
    updateSlider(track.AbsolutePosition.X + track.AbsoluteSize.X * ((defaultValue - minValue) / (maxValue - minValue)))
    
    -- Handle click and drag
    local isDragging = false
    
    clickDetector.MouseButton1Down:Connect(function()
        isDragging = true
        updateSlider(game:GetService("Players").LocalPlayer:GetMouse().X)
    end)
    
    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if isDragging then
                isDragging = false
                inputComponent:triggerEvent("onChange", currentValue)
            end
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(game:GetService("Players").LocalPlayer:GetMouse().X)
        end
    end)
    
    -- Create Slider component wrapper
    local inputComponent = UIComponentBase.new({
        name = "Slider_" .. field.name,
        size = UDim2.new(1, 0, 0, 48)
    })
    
    -- Override _render to return our container
    function inputComponent:_render()
        return container
    end
    
    -- Add setValue method
    function inputComponent:setValue(value)
        if value ~= currentValue then
            currentValue = math.clamp(value, minValue, maxValue)
            
            -- Update UI
            local normalizedPos = (currentValue - minValue) / (maxValue - minValue)
            thumb.Position = UDim2.new(normalizedPos, 0, 0.5, 0)
            fill.Size = UDim2.new(normalizedPos, 0, 1, 0)
            valueLabel.Text = tostring(currentValue)
        end
    end
    
    -- Add getValue method
    function inputComponent:getValue()
        return currentValue
    end
    
    return inputComponent
end

--[[
    Get the size for a field label based on label position
    @return - Size UDim2
]]
function FormComponent:_getLabelSize()
    if self._labelPosition == "top" then
        return UDim2.new(1, 0, 0, 24)
    elseif self._labelPosition == "left" then
        return UDim2.new(0.3, 0, 1, 0)
    elseif self._labelPosition == "right" then
        return UDim2.new(0.3, 0, 1, 0)
    end
    
    return UDim2.new(1, 0, 0, 24)
end

--[[
    Get the position for a field label based on label position
    @return - Position UDim2
]]
function FormComponent:_getLabelPosition()
    if self._labelPosition == "top" then
        return UDim2.new(0, 0, 0, 0)
    elseif self._labelPosition == "left" then
        return UDim2.new(0, 0, 0, 0)
    elseif self._labelPosition == "right" then
        return UDim2.new(0.7, 8, 0, 0)
    end
    
    return UDim2.new(0, 0, 0, 0)
end

--[[
    Create form buttons (submit/cancel)
    @param container - Parent container
]]
function FormComponent:_createButtons(container)
    -- Create button container
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, 0, 0, 40)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.LayoutOrder = 999 -- Always at the end
    
    -- Create layout
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 16)
    layout.Parent = buttonContainer
    
    -- Create submit button if enabled
    if self._showSubmitButton then
        self._submitButton = ButtonComponent.new({
            text = self._submitButtonText,
            size = UDim2.new(0, 120, 0, 40),
            backgroundColor = Color3.fromRGB(0, 120, 215),
            textColor = Color3.fromRGB(255, 255, 255),
            cornerRadius = 4,
            layoutOrder = 1
        })
        
        self._submitButton:onClick(function()
            self:_handleSubmit()
        end)
        
        self._submitButton:mount(buttonContainer)
    end
    
    -- Create cancel button if enabled
    if self._showCancelButton then
        self._cancelButton = ButtonComponent.new({
            text = self._cancelButtonText,
            size = UDim2.new(0, 120, 0, 40),
            backgroundColor = Color3.fromRGB(80, 80, 100),
            textColor = Color3.fromRGB(255, 255, 255),
            cornerRadius = 4,
            layoutOrder = 2
        })
        
        self._cancelButton:onClick(function()
            self:_handleCancel()
        end)
        
        self._cancelButton:mount(buttonContainer)
    end
    
    buttonContainer.Parent = container
end

--[[
    Handle field value change
    @param fieldName - Name of the changed field
    @param value - New field value
]]
function FormComponent:_handleFieldChange(fieldName, value)
    -- Update the value
    self._fieldValues[fieldName] = value
    
    -- Validate if auto-validate is enabled
    if self._autoValidate then
        self:validateField(fieldName)
    end
    
    -- Trigger onChange event
    self:triggerEvent("fieldChange", fieldName, value)
    self:triggerEvent("formChange", self._fieldValues)
end

--[[
    Handle form submission
    @private
]]
function FormComponent:_handleSubmit()
    -- Validate all fields
    local isValid = self:validate()
    
    -- If valid, trigger submit event
    if isValid then
        self:triggerEvent("submit", self._fieldValues)
    else
        self:triggerEvent("validationError", self._fieldErrors)
    end
end

--[[
    Handle form cancellation
    @private
]]
function FormComponent:_handleCancel()
    self:triggerEvent("cancel")
end

--[[
    Validate a specific field
    @param fieldName - Name of the field to validate
    @return - Whether the field is valid
]]
function FormComponent:validateField(fieldName)
    -- Find the field
    local field = nil
    for _, f in ipairs(self._fields) do
        if f.name == fieldName then
            field = f
            break
        end
    end
    
    if not field then
        warn("[FormComponent] Field not found for validation: " .. fieldName)
        return true
    end
    
    -- Skip validation if no validators
    if not field.validators or #field.validators == 0 then
        self._fieldErrors[fieldName] = nil
        self:_updateFieldErrorUI(fieldName, nil)
        return true
    end
    
    -- Get field value
    local value = self._fieldValues[fieldName]
    
    -- Run validators
    for _, validator in ipairs(field.validators) do
        local isValid, errorMessage = validator(value)
        
        if not isValid then
            self._fieldErrors[fieldName] = errorMessage
            self:_updateFieldErrorUI(fieldName, errorMessage)
            return false
        end
    end
    
    -- Clear error if validation passed
    self._fieldErrors[fieldName] = nil
    self:_updateFieldErrorUI(fieldName, nil)
    return true
end

--[[
    Validate all form fields
    @return - Whether all fields are valid
]]
function FormComponent:validate()
    local isValid = true
    
    -- Validate each field
    for _, field in ipairs(self._fields) do
        if not self:validateField(field.name) then
            isValid = false
        end
    end
    
    return isValid
end

--[[
    Update field error UI
    @param fieldName - Name of the field
    @param errorMessage - Error message or nil
    @private
]]
function FormComponent:_updateFieldErrorUI(fieldName, errorMessage)
    local errorComponent = self._fieldComponents[fieldName .. "_error"]
    if not errorComponent then
        return
    end
    
    if errorMessage then
        errorComponent:setText(errorMessage)
        errorComponent:setVisible(true)
    else
        errorComponent:setVisible(false)
    end
    
    -- Also update input styling to indicate error
    local inputComponent = self._fieldComponents[fieldName]
    if inputComponent then
        local instance = inputComponent:getInstance()
        
        if instance then
            -- Apply error styling
            if errorMessage then
                -- For TextBox
                if instance:IsA("TextBox") or instance.TextBox then
                    local textBox = instance:IsA("TextBox") and instance or instance.TextBox
                    textBox.BorderColor3 = Color3.fromRGB(220, 50, 50)
                end
                
                -- For Frame-based inputs
                if instance:IsA("Frame") and instance:FindFirstChild("Track") then
                    instance.Track.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
                end
            else
                -- Reset to normal
                if instance:IsA("TextBox") or instance.TextBox then
                    local textBox = instance:IsA("TextBox") and instance or instance.TextBox
                    textBox.BorderColor3 = Color3.fromRGB(60, 60, 80)
                end
                
                if instance:IsA("Frame") and instance:FindFirstChild("Track") then
                    instance.Track.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
                end
            end
        end
    end
end

--[[
    Get all form values
    @return - Table of field values
]]
function FormComponent:getValues()
    return self._fieldValues
end

--[[
    Get a specific field value
    @param fieldName - Name of the field
    @return - Field value
]]
function FormComponent:getValue(fieldName)
    return self._fieldValues[fieldName]
end

--[[
    Set a specific field value
    @param fieldName - Name of the field
    @param value - New field value
    @return - Self for method chaining
]]
function FormComponent:setValue(fieldName, value)
    -- Update internal value
    self._fieldValues[fieldName] = value
    
    -- Update component if it exists
    local inputComponent = self._fieldComponents[fieldName]
    if inputComponent and typeof(inputComponent.setValue) == "function" then
        inputComponent:setValue(value)
    end
    
    -- Validate if auto-validate is enabled
    if self._autoValidate then
        self:validateField(fieldName)
    end
    
    return self
end

--[[
    Reset the form to default values
    @return - Self for method chaining
]]
function FormComponent:reset()
    -- Reset to default values
    for _, field in ipairs(self._fields) do
        self:setValue(field.name, field.defaultValue)
    end
    
    -- Clear all errors
    self._fieldErrors = {}
    
    -- Update UI to remove errors
    for _, field in ipairs(self._fields) do
        self:_updateFieldErrorUI(field.name, nil)
    end
    
    return self
end

--[[
    Set a field as enabled or disabled
    @param fieldName - Name of the field
    @param enabled - Whether the field is enabled
    @return - Self for method chaining
]]
function FormComponent:setFieldEnabled(fieldName, enabled)
    local inputComponent = self._fieldComponents[fieldName]
    if not inputComponent then
        return self
    end
    
    local instance = inputComponent:getInstance()
    if not instance then
        return self
    end
    
    -- Enable/disable based on input type
    if instance:IsA("TextBox") then
        instance.TextEditable = enabled
        instance.BackgroundColor3 = enabled and Color3.fromRGB(60, 60, 80) or Color3.fromRGB(40, 40, 60)
    elseif instance:IsA("Frame") then
        -- For custom inputs like checkbox, radio, slider
        local clickDetector = instance:FindFirstChildWhichIsA("TextButton")
        if clickDetector then
            clickDetector.Active = enabled
            
            -- Update visual style
            local button = instance:FindFirstChild("RadioButton") or instance:FindFirstChild("Checkbox")
            if button then
                button.BackgroundColor3 = enabled and Color3.fromRGB(60, 60, 80) or Color3.fromRGB(40, 40, 60)
            end
            
            local track = instance:FindFirstChild("Track")
            if track then
                track.BackgroundColor3 = enabled and Color3.fromRGB(60, 60, 80) or Color3.fromRGB(40, 40, 60)
            end
        end
    end
    
    return self
end

--[[
    Register a form submit handler
    @param handler - Function to call when form is submitted
    @return - Connection ID
]]
function FormComponent:onSubmit(handler)
    return self:on("submit", handler)
end

--[[
    Register a form cancel handler
    @param handler - Function to call when form is cancelled
    @return - Connection ID
]]
function FormComponent:onCancel(handler)
    return self:on("cancel", handler)
end

--[[
    Register a field change handler
    @param handler - Function to call when a field changes
    @return - Connection ID
]]
function FormComponent:onFieldChange(handler)
    return self:on("fieldChange", handler)
end

--[[
    Register a form change handler (fired when any field changes)
    @param handler - Function to call when form changes
    @return - Connection ID
]]
function FormComponent:onFormChange(handler)
    return self:on("formChange", handler)
end

--[[
    Register a validation error handler
    @param handler - Function to call when validation fails
    @return - Connection ID
]]
function FormComponent:onValidationError(handler)
    return self:on("validationError", handler)
end

return FormComponent
