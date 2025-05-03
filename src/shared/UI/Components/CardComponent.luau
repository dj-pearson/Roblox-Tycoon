--!strict
--[[
    CardComponent.luau
    
    A reusable card component that extends the container component to provide
    a pre-styled content container with optional header, footer, and shadow.
    
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
        warn("[CardComponent] Failed to load ModuleLoaderHelper, using direct requires")
    end
end

-- Load ContainerComponent (parent class)
local ContainerComponent
if ModuleLoaderHelper then
    ContainerComponent = ModuleLoaderHelper.loadModule("UI/Components/ContainerComponent")
else
    local componentPath = ReplicatedStorage:FindFirstChild("shared") and 
                          ReplicatedStorage.shared:FindFirstChild("UI") and 
                          ReplicatedStorage.shared.UI:FindFirstChild("Components") and
                          ReplicatedStorage.shared.UI.Components:FindFirstChild("ContainerComponent")
    
    if componentPath then
        ContainerComponent = require(componentPath)
    end
end

if not ContainerComponent then
    error("[CardComponent] Required dependency ContainerComponent not found")
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

--[[
    CardComponent - A styled card container component
]]
local CardComponent = setmetatable({}, ContainerComponent)
CardComponent.__index = CardComponent

--[[
    Create a new card component
    @param props - Card properties
    @return - New CardComponent instance
]]
function CardComponent.new(props)
    props = props or {}
    
    -- Apply default card styling
    props.backgroundColor = props.backgroundColor
    props.shadow = props.shadow ~= nil and props.shadow or true
    props.cornerRadius = props.cornerRadius ~= nil and props.cornerRadius or 8
    props.padding = props.padding ~= nil and props.padding or 12
    
    -- Create the container component
    local self = ContainerComponent.new(props)
    setmetatable(self, CardComponent)
    
    -- Card-specific properties
    self._type = "CardComponent"
    self._title = props.title
    self._titlePosition = props.titlePosition or "top" -- top, inside
    self._titleStyle = props.titleStyle or "heading3"
    self._titleComponent = nil
    self._footerContent = props.footerContent
    self._footerComponent = nil
    self._headerComponent = nil
    self._contentComponent = nil
    self._elevation = props.elevation or "medium" -- none, low, medium, high
    self._headerVisible = props.headerVisible ~= false -- Default to true if header content exists
    self._footerVisible = props.footerVisible ~= false -- Default to true if footer content exists
    self._contentPadding = props.contentPadding
    self._headerPadding = props.headerPadding
    self._footerPadding = props.footerPadding
    self._headerBackgroundColor = props.headerBackgroundColor
    self._footerBackgroundColor = props.footerBackgroundColor
    self._borderColor = props.borderColor
    self._borderWidth = props.borderWidth
    self._clickable = props.clickable -- Makes the whole card clickable
    
    -- Get style from UIStyleSystem if available
    if UIStyleSystem then
        self._cardStyle = UIStyleSystem:createStyle("Card", props.themeOverrides)
    end
    
    return self
end

--[[
    Internal render method - creates the card container with optional header/footer
    @return - The created card container
]]
function CardComponent:_render()
    -- Create the main container using the parent's render method
    local container = ContainerComponent._render(self)
    
    -- Apply card-specific styling
    self:_applyCardStyle(container)
    
    -- Create header if title is specified
    if self._title and self._headerVisible and self._titlePosition == "top" then
        self:_createHeader(container)
    end
    
    -- Create content container
    self:_createContent(container)
    
    -- Create footer if footer content is specified
    if self._footerContent and self._footerVisible then
        self:_createFooter(container)
    end
    
    -- Make clickable if needed
    if self._clickable then
        self:_makeClickable(container)
    end
    
    return container
end

--[[
    Apply card-specific styling
    @param container - Container to style
]]
function CardComponent:_applyCardStyle(container)
    if self._cardStyle then
        -- Apply card styling from UIStyleSystem
        local backgroundColor = self._backgroundColor or self._cardStyle:getColor("background")
        if backgroundColor then
            container.BackgroundColor3 = backgroundColor
        end
        
        -- Apply border if specified
        if self._borderColor or self._borderWidth then
            container.BorderSizePixel = self._borderWidth or 1
            container.BorderColor3 = self._borderColor or self._cardStyle:getColor("border") or Color3.fromRGB(200, 200, 220)
        end
        
        -- Apply elevation (shadow)
        if self._elevation ~= "none" and self._shadow then
            local shadowConfig = self._cardStyle:getShadow(self._elevation) or {}
            
            -- Create shadow frame
            local shadowFrame = Instance.new("Frame")
            shadowFrame.Name = "Shadow"
            shadowFrame.ZIndex = container.ZIndex - 1
            shadowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
            shadowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
            
            -- Apply shadow size based on elevation
            local shadowOffsetX = 0
            local shadowOffsetY = 0
            local shadowSize = 0
            
            if self._elevation == "low" then
                shadowSize = 4
                shadowOffsetY = 1
            elseif self._elevation == "medium" then
                shadowSize = 8
                shadowOffsetY = 2
            elseif self._elevation == "high" then
                shadowSize = 12
                shadowOffsetY = 4
            end
            
            shadowFrame.Size = UDim2.new(1, shadowSize * 2, 1, shadowSize * 2)
            shadowFrame.Position = UDim2.new(0.5, shadowOffsetX, 0.5, shadowOffsetY)
            
            -- Apply shadow color and transparency
            shadowFrame.BackgroundColor3 = self._cardStyle:getColor("shadow") or Color3.fromRGB(0, 0, 0)
            shadowFrame.BackgroundTransparency = 0.7
            
            -- Apply corner radius to match the card
            if self._cornerRadius then
                local shadowCorner = Instance.new("UICorner")
                shadowCorner.CornerRadius = typeof(self._cornerRadius) == "UDim" 
                                        and self._cornerRadius 
                                        or UDim.new(0, self._cornerRadius + shadowSize / 2)
                shadowCorner.Parent = shadowFrame
            end
            
            -- Insert at the beginning to ensure it's behind the card
            shadowFrame.Parent = container
        end
    else
        -- Fallback styling when UIStyleSystem is not available
        -- Default background color if not specified
        container.BackgroundColor3 = self._backgroundColor or Color3.fromRGB(255, 255, 255)
        
        -- Apply border if specified
        if self._borderColor or self._borderWidth then
            container.BorderSizePixel = self._borderWidth or 1
            container.BorderColor3 = self._borderColor or Color3.fromRGB(200, 200, 220)
        else
            container.BorderSizePixel = 0
        end
        
        -- Apply basic shadow if elevation is not none
        if self._elevation ~= "none" and self._shadow then
            local shadowFrame = Instance.new("Frame")
            shadowFrame.Name = "Shadow"
            shadowFrame.ZIndex = container.ZIndex - 1
            shadowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
            
            -- Apply shadow size and offset based on elevation
            local shadowOffsetY = 0
            local shadowSize = 0
            
            if self._elevation == "low" then
                shadowSize = 4
                shadowOffsetY = 1
            elseif self._elevation == "medium" then
                shadowSize = 8
                shadowOffsetY = 2
            elseif self._elevation == "high" then
                shadowSize = 12
                shadowOffsetY = 4
            end
            
            shadowFrame.Size = UDim2.new(1, shadowSize * 2, 1, shadowSize * 2)
            shadowFrame.Position = UDim2.new(0.5, 0, 0.5, shadowOffsetY)
            
            -- Apply shadow properties
            shadowFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            shadowFrame.BackgroundTransparency = 0.7
            
            -- Apply corner radius to match the card
            if self._cornerRadius then
                local shadowCorner = Instance.new("UICorner")
                shadowCorner.CornerRadius = typeof(self._cornerRadius) == "UDim" 
                                        and self._cornerRadius 
                                        or UDim.new(0, self._cornerRadius + shadowSize / 2)
                shadowCorner.Parent = shadowFrame
            end
            
            -- Insert at the beginning to ensure it's behind the card
            shadowFrame.Parent = container
        end
    end
end

--[[
    Create the header part of the card
    @param container - Parent container
]]
function CardComponent:_createHeader(container)
    -- Create header container
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, self._titleStyle == "heading1" and 40 or (self._titleStyle == "heading2" and 32 or 28))
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundTransparency = 1 -- Transparent by default
    header.LayoutOrder = 1
    
    -- Apply header background color if specified
    if self._headerBackgroundColor then
        header.BackgroundTransparency = 0
        header.BackgroundColor3 = self._headerBackgroundColor
        
        -- Add corners to match the card
        if self._cornerRadius then
            local headerCorner = Instance.new("UICorner")
            headerCorner.CornerRadius = typeof(self._cornerRadius) == "UDim" 
                                    and self._cornerRadius 
                                    or UDim.new(0, self._cornerRadius)
            headerCorner.Parent = header
        end
    end
    
    -- Apply header padding
    local headerPadding = Instance.new("UIPadding")
    headerPadding.PaddingLeft = UDim.new(0, self._headerPadding or self._padding or 12)
    headerPadding.PaddingRight = UDim.new(0, self._headerPadding or self._padding or 12)
    headerPadding.PaddingTop = UDim.new(0, (self._headerPadding or self._padding or 12) / 2)
    headerPadding.PaddingBottom = UDim.new(0, (self._headerPadding or self._padding or 12) / 2)
    headerPadding.Parent = header
    
    -- Create title text
    self._titleComponent = TextComponent.new({
        text = self._title,
        textStyle = self._titleStyle,
        size = UDim2.new(1, 0, 1, 0),
        autoSize = "height"
    })
    
    self._titleComponent:mount(header)
    self._headerComponent = header
    header.Parent = container
end

--[[
    Create the content container
    @param container - Parent container
]]
function CardComponent:_createContent(container)
    -- Create content container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.LayoutOrder = 2
    
    -- Set size based on whether header and footer exist
    if self._title and self._headerVisible and self._titlePosition == "top" then
        if self._footerContent and self._footerVisible then
            -- Both header and footer
            content.Size = UDim2.new(1, 0, 1, -self._headerComponent.AbsoluteSize.Y - 40)
            content.Position = UDim2.new(0, 0, 0, self._headerComponent.AbsoluteSize.Y)
        else
            -- Header only
            content.Size = UDim2.new(1, 0, 1, -self._headerComponent.AbsoluteSize.Y)
            content.Position = UDim2.new(0, 0, 0, self._headerComponent.AbsoluteSize.Y)
        end
    else
        if self._footerContent and self._footerVisible then
            -- Footer only
            content.Size = UDim2.new(1, 0, 1, -40)
            content.Position = UDim2.new(0, 0, 0, 0)
        else
            -- Neither header nor footer
            content.Size = UDim2.new(1, 0, 1, 0)
            content.Position = UDim2.new(0, 0, 0, 0)
        end
    end
    
    -- Add title inside content if position is "inside"
    if self._title and self._headerVisible and self._titlePosition == "inside" then
        -- Create title at the top of content
        self._titleComponent = TextComponent.new({
            text = self._title,
            textStyle = self._titleStyle,
            size = UDim2.new(1, 0, 0, self._titleStyle == "heading1" and 40 or (self._titleStyle == "heading2" and 32 or 28)),
            position = UDim2.new(0, 0, 0, 0)
        })
        
        self._titleComponent:mount(content)
    end
    
    -- Apply content padding
    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingLeft = UDim.new(0, self._contentPadding or self._padding or 12)
    contentPadding.PaddingRight = UDim.new(0, self._contentPadding or self._padding or 12)
    contentPadding.PaddingTop = UDim.new(0, self._contentPadding or self._padding or 12)
    contentPadding.PaddingBottom = UDim.new(0, self._contentPadding or self._padding or 12)
    contentPadding.Parent = content
    
    self._contentComponent = content
    content.Parent = container
end

--[[
    Create the footer part of the card
    @param container - Parent container
]]
function CardComponent:_createFooter(container)
    -- Create footer container
    local footer = Instance.new("Frame")
    footer.Name = "Footer"
    footer.Size = UDim2.new(1, 0, 0, 40)
    footer.Position = UDim2.new(0, 0, 1, -40)
    footer.BackgroundTransparency = 1 -- Transparent by default
    footer.LayoutOrder = 3
    
    -- Apply footer background color if specified
    if self._footerBackgroundColor then
        footer.BackgroundTransparency = 0
        footer.BackgroundColor3 = self._footerBackgroundColor
        
        -- Add corners to match the card
        if self._cornerRadius then
            local footerCorner = Instance.new("UICorner")
            footerCorner.CornerRadius = typeof(self._cornerRadius) == "UDim" 
                                    and self._cornerRadius 
                                    or UDim.new(0, self._cornerRadius)
            footerCorner.Parent = footer
        end
    end
    
    -- Apply footer padding
    local footerPadding = Instance.new("UIPadding")
    footerPadding.PaddingLeft = UDim.new(0, self._footerPadding or self._padding or 12)
    footerPadding.PaddingRight = UDim.new(0, self._footerPadding or self._padding or 12)
    footerPadding.PaddingTop = UDim.new(0, (self._footerPadding or self._padding or 12) / 2)
    footerPadding.PaddingBottom = UDim.new(0, (self._footerPadding or self._padding or 12) / 2)
    footerPadding.Parent = footer
    
    -- Add footer content if it's a table of components
    if typeof(self._footerContent) == "table" then
        for _, component in ipairs(self._footerContent) do
            component:mount(footer)
        end
    elseif typeof(self._footerContent) == "string" then
        -- Create a text component if it's a string
        local footerText = TextComponent.new({
            text = self._footerContent,
            textStyle = "small",
            size = UDim2.new(1, 0, 1, 0)
        })
        
        footerText:mount(footer)
    end
    
    self._footerComponent = footer
    footer.Parent = container
end

--[[
    Make the card clickable
    @param container - The card container
]]
function CardComponent:_makeClickable(container)
    -- Convert container to a button if it's a frame
    if container:IsA("Frame") then
        local button = Instance.new("TextButton")
        button.Name = container.Name
        button.Size = container.Size
        button.Position = container.Position
        button.AnchorPoint = container.AnchorPoint
        button.BackgroundColor3 = container.BackgroundColor3
        button.BackgroundTransparency = container.BackgroundTransparency
        button.BorderSizePixel = container.BorderSizePixel
        button.BorderColor3 = container.BorderColor3
        button.ZIndex = container.ZIndex
        button.LayoutOrder = container.LayoutOrder
        button.Text = ""
        button.AutoButtonColor = false
        
        -- Copy UI corner if it exists
        local corner = container:FindFirstChild("UICorner")
        if corner then
            corner:Clone().Parent = button
        end
        
        -- Copy shadow if it exists
        local shadow = container:FindFirstChild("Shadow")
        if shadow then
            shadow:Clone().Parent = button
        end
        
        -- Move all children
        for _, child in ipairs(container:GetChildren()) do
            if child.Name ~= "UICorner" and child.Name ~= "Shadow" then
                child.Parent = button
            end
        end
        
        -- Replace the container with the button
        button.Parent = container.Parent
        self._instance = button
        container:Destroy()
        container = button
        
        -- Add hover effect
        local originalColor = container.BackgroundColor3
        local hoverColor = Color3.new(
            math.min(originalColor.R * 1.05, 1),
            math.min(originalColor.G * 1.05, 1),
            math.min(originalColor.B * 1.05, 1)
        )
        
        container.MouseEnter:Connect(function()
            container.BackgroundColor3 = hoverColor
        end)
        
        container.MouseLeave:Connect(function()
            container.BackgroundColor3 = originalColor
        end)
        
        -- Add click handler
        container.MouseButton1Click:Connect(function()
            self:_onClick()
        end)
    end
end

--[[
    Handle click events
    @private
]]
function CardComponent:_onClick()
    self:triggerEvent("onClick")
end

--[[
    Set the card title
    @param title - New title text
    @return - Self for method chaining
]]
function CardComponent:setTitle(title)
    self._title = title
    
    if self._titleComponent then
        self._titleComponent:setText(title)
    end
    
    return self
end

--[[
    Set title visibility
    @param visible - Visibility state
    @return - Self for method chaining
]]
function CardComponent:setTitleVisible(visible)
    self._headerVisible = visible
    
    if self._headerComponent then
        self._headerComponent.Visible = visible
    end
    
    return self
end

--[[
    Set footer visibility
    @param visible - Visibility state
    @return - Self for method chaining
]]
function CardComponent:setFooterVisible(visible)
    self._footerVisible = visible
    
    if self._footerComponent then
        self._footerComponent.Visible = visible
    end
    
    return self
end

--[[
    Register an onClick handler
    @param handler - Function to call when clicked
    @return - Connection ID
]]
function CardComponent:onClick(handler)
    return self:on("onClick", handler)
end

return CardComponent
