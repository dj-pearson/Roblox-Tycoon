--!strict
--[[
    ContainerComponent.luau
    
    A reusable container component for the enhanced UI system.
    Provides layout management and child component handling.
    
    Created: May 4, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Import ModuleLoaderHelper
local ModuleLoaderHelper = nil
if ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ModuleLoaderHelper") then
    local success, result = pcall(function()
        return require(ReplicatedStorage.shared.ModuleLoaderHelper)
    end)
    
    if success and result then
        ModuleLoaderHelper = result
    else
        warn("[ContainerComponent] Failed to load ModuleLoaderHelper, using direct requires")
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
    error("[ContainerComponent] Required dependency UIComponentBase not found")
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

--[[
    ContainerComponent - A container component with layout capabilities
]]
local ContainerComponent = setmetatable({}, UIComponentBase)
ContainerComponent.__index = ContainerComponent

--[[
    Create a new container component
    @param props - Container properties
    @return - New ContainerComponent instance
]]
function ContainerComponent.new(props)
    props = props or {}
    
    local self = UIComponentBase.new(props)
    setmetatable(self, ContainerComponent)
    
    -- Container-specific properties
    self._type = "ContainerComponent"
    self._layoutType = props.layoutType or "none" -- none, list, grid, flow
    self._layoutDirection = props.layoutDirection or "vertical" -- vertical, horizontal
    self._layoutAnchorPoint = props.layoutAnchorPoint or Vector2.new(0, 0)
    self._layoutFillDirection = props.layoutFillDirection or Enum.FillDirection.Vertical
    self._layoutHorizontalAlignment = props.layoutHorizontalAlignment or Enum.HorizontalAlignment.Left
    self._layoutVerticalAlignment = props.layoutVerticalAlignment or Enum.VerticalAlignment.Top
    self._layoutPadding = props.layoutPadding or 0
    self._layoutCellSize = props.layoutCellSize or UDim2.new(0, 100, 0, 100)
    self._layoutCellPadding = props.layoutCellPadding or UDim2.new(0, 5, 0, 5)
    self._layoutStartCorner = props.layoutStartCorner or Enum.StartCorner.TopLeft
    self._layoutSortOrder = props.layoutSortOrder or Enum.SortOrder.LayoutOrder
    self._layoutAutoSize = props.layoutAutoSize -- nil, XY, X, Y
    self._scrollable = props.scrollable == true -- Default to false
    self._scrollingDirection = props.scrollingDirection or Enum.ScrollingDirection.Y
    self._scrollBarThickness = props.scrollBarThickness or 4
    self._scrollBarImageColor = props.scrollBarImageColor or Color3.fromRGB(120, 120, 140)
    self._scrollBarTransparency = props.scrollBarTransparency or 0.5
    self._scrollBarShowAlways = props.scrollBarShowAlways or false
    self._paddingTop = props.paddingTop or props.padding or 0
    self._paddingBottom = props.paddingBottom or props.padding or 0
    self._paddingLeft = props.paddingLeft or props.padding or 0
    self._paddingRight = props.paddingRight or props.padding or 0
    self._backgroundColor = props.backgroundColor
    self._backgroundTransparency = props.backgroundTransparency
    self._cornerRadius = props.cornerRadius
    self._border = props.border
    self._shadow = props.shadow
    self._clipsDescendants = props.clipsDescendants ~= false -- Default to true
    
    -- Child tracking
    self._childComponents = {}
    
    -- Get style from UIStyleSystem if available
    if UIStyleSystem then
        self._containerStyle = UIStyleSystem:createStyle("Container", props.themeOverrides)
    end
    
    return self
end

--[[
    Internal render method - creates the container instance
    @return - The created container instance
]]
function ContainerComponent:_render()
    local container
    
    -- Create the appropriate container type
    if self._scrollable then
        container = Instance.new("ScrollingFrame")
        container.ScrollBarThickness = self._scrollBarThickness
        container.ScrollingDirection = self._scrollingDirection
        container.ScrollBarImageColor3 = self._scrollBarImageColor
        container.ScrollBarImageTransparency = self._scrollBarTransparency
        container.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
        container.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
        container.ElasticBehavior = Enum.ElasticBehavior.Always
        container.ScrollBarInset = Enum.ScrollBarInset.ScrollBar
        container.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
        container.HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar
        container.AutomaticCanvasSize = Enum.AutomaticSize.None
    else
        container = Instance.new("Frame")
    end
    
    -- Set basic properties
    container.Name = self._name
    container.Size = self._size or UDim2.new(1, 0, 1, 0)
    container.Position = self._position or UDim2.new(0, 0, 0, 0)
    container.AnchorPoint = self._anchorPoint or Vector2.new(0, 0)
    container.ClipsDescendants = self._clipsDescendants
    
    -- Apply style
    self:_applyContainerStyle(container)
    
    -- Add layout based on type
    self:_applyLayout(container)
    
    -- Add padding
    self:_applyPadding(container)
    
    -- Apply corner radius if specified
    if self._cornerRadius then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = typeof(self._cornerRadius) == "UDim" 
                         and self._cornerRadius 
                         or UDim.new(0, self._cornerRadius)
        corner.Parent = container
    end
    
    return container
end

--[[
    Apply container styling
    @param container - Container to style
]]
function ContainerComponent:_applyContainerStyle(container)
    if self._containerStyle then
        -- Use UIStyleSystem styling
        local backgroundColor = self._backgroundColor or self._containerStyle:getColor("background")
        local backgroundTransparency = self._backgroundTransparency
        
        if backgroundColor then
            container.BackgroundColor3 = backgroundColor
        end
        
        if backgroundTransparency ~= nil then
            container.BackgroundTransparency = backgroundTransparency
        end
        
        -- Apply border if specified
        if self._border then
            -- If it's simple boolean, use default border
            if typeof(self._border) == "boolean" and self._border then
                container.BorderSizePixel = 1
                container.BorderColor3 = self._containerStyle:getColor("border") or Color3.fromRGB(70, 70, 90)
            elseif typeof(self._border) == "table" then
                -- Use specified border properties
                container.BorderSizePixel = self._border.size or 1
                container.BorderColor3 = self._border.color or self._containerStyle:getColor("border") or Color3.fromRGB(70, 70, 90)
            end
        else
            container.BorderSizePixel = 0
        end
    else
        -- Fallback styling when UIStyleSystem is not available
        -- Default background color if not specified
        local backgroundColor = self._backgroundColor or Color3.fromRGB(60, 60, 80)
        container.BackgroundColor3 = backgroundColor
        
        if self._backgroundTransparency ~= nil then
            container.BackgroundTransparency = self._backgroundTransparency
        end
        
        -- Apply border if specified
        if self._border then
            -- If it's simple boolean, use default border
            if typeof(self._border) == "boolean" and self._border then
                container.BorderSizePixel = 1
                container.BorderColor3 = Color3.fromRGB(80, 80, 100)
            elseif typeof(self._border) == "table" then
                -- Use specified border properties
                container.BorderSizePixel = self._border.size or 1
                container.BorderColor3 = self._border.color or Color3.fromRGB(80, 80, 100)
            end
        else
            container.BorderSizePixel = 0
        end
    end
    
    -- Apply shadow if specified
    if self._shadow and self._shadow ~= false then
        local shadowFrame = Instance.new("Frame")
        shadowFrame.Name = "Shadow"
        shadowFrame.Size = UDim2.new(1, 10, 1, 10)
        shadowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        shadowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        shadowFrame.ZIndex = container.ZIndex - 1
        
        local shadowColor
        local shadowTransparency = 0.6
        local shadowCornerRadius
        
        if self._containerStyle then
            shadowColor = self._containerStyle:getColor("shadow") or Color3.fromRGB(20, 20, 30)
            shadowTransparency = self._containerStyle:getTransparency("shadowDefault") or 0.6
        else
            shadowColor = Color3.fromRGB(20, 20, 30)
        end
        
        if typeof(self._shadow) == "table" then
            shadowColor = self._shadow.color or shadowColor
            shadowTransparency = self._shadow.transparency or shadowTransparency
        end
        
        shadowFrame.BackgroundColor3 = shadowColor
        shadowFrame.BackgroundTransparency = shadowTransparency
        
        -- Match corner radius
        if self._cornerRadius then
            shadowCornerRadius = typeof(self._cornerRadius) == "UDim" 
                             and self._cornerRadius 
                             or UDim.new(0, self._cornerRadius)
            
            local shadowCorner = Instance.new("UICorner")
            shadowCorner.CornerRadius = shadowCornerRadius
            shadowCorner.Parent = shadowFrame
        end
        
        shadowFrame.Parent = container
        container:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            shadowFrame.Size = UDim2.new(1, 10, 1, 10)
        end)
    end
end

--[[
    Apply layout to the container
    @param container - Container to apply layout to
]]
function ContainerComponent:_applyLayout(container)
    -- Remove any existing layouts
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("UIGridLayout") or child:IsA("UIListLayout") or child:IsA("UIPageLayout") or child:IsA("UITableLayout") then
            child:Destroy()
        end
    end
    
    -- Create and configure layout based on type
    if self._layoutType == "list" then
        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = typeof(self._layoutPadding) == "UDim" 
                        and self._layoutPadding 
                        or UDim.new(0, self._layoutPadding)
        listLayout.FillDirection = self._layoutFillDirection
        listLayout.HorizontalAlignment = self._layoutHorizontalAlignment
        listLayout.VerticalAlignment = self._layoutVerticalAlignment
        listLayout.SortOrder = self._layoutSortOrder
        
        -- Auto size logic
        if self._layoutAutoSize then
            if self._layoutAutoSize == "XY" or self._layoutAutoSize == true then
                listLayout.Padding = UDim.new(0, self._layoutPadding)
                
                if self._scrollable then
                    -- For ScrollingFrame, set CanvasSize
                    container.AutomaticCanvasSize = Enum.AutomaticSize.XY
                else
                    container.AutomaticSize = Enum.AutomaticSize.XY
                end
            elseif self._layoutAutoSize == "X" then
                if self._scrollable then
                    container.AutomaticCanvasSize = Enum.AutomaticSize.X
                else
                    container.AutomaticSize = Enum.AutomaticSize.X
                end
            elseif self._layoutAutoSize == "Y" then
                if self._scrollable then
                    container.AutomaticCanvasSize = Enum.AutomaticSize.Y
                else
                    container.AutomaticSize = Enum.AutomaticSize.Y
                end
            end
        end
        
        listLayout.Parent = container
        
    elseif self._layoutType == "grid" then
        local gridLayout = Instance.new("UIGridLayout")
        gridLayout.CellSize = self._layoutCellSize
        gridLayout.CellPadding = typeof(self._layoutCellPadding) == "UDim2" 
                            and self._layoutCellPadding 
                            or UDim2.new(0, self._layoutCellPadding, 0, self._layoutCellPadding)
        gridLayout.StartCorner = self._layoutStartCorner
        gridLayout.FillDirection = self._layoutFillDirection
        gridLayout.HorizontalAlignment = self._layoutHorizontalAlignment
        gridLayout.VerticalAlignment = self._layoutVerticalAlignment
        gridLayout.SortOrder = self._layoutSortOrder
        
        -- Auto size logic
        if self._layoutAutoSize then
            if self._layoutAutoSize == "XY" or self._layoutAutoSize == true then
                if self._scrollable then
                    container.AutomaticCanvasSize = Enum.AutomaticSize.XY
                else
                    container.AutomaticSize = Enum.AutomaticSize.XY
                end
            elseif self._layoutAutoSize == "X" then
                if self._scrollable then
                    container.AutomaticCanvasSize = Enum.AutomaticSize.X
                else
                    container.AutomaticSize = Enum.AutomaticSize.X
                end
            elseif self._layoutAutoSize == "Y" then
                if self._scrollable then
                    container.AutomaticCanvasSize = Enum.AutomaticSize.Y
                else
                    container.AutomaticSize = Enum.AutomaticSize.Y
                end
            end
        end
        
        gridLayout.Parent = container
        
    elseif self._layoutType == "page" then
        local pageLayout = Instance.new("UIPageLayout")
        pageLayout.Padding = typeof(self._layoutPadding) == "UDim" 
                        and self._layoutPadding 
                        or UDim.new(0, self._layoutPadding)
        pageLayout.FillDirection = self._layoutFillDirection
        pageLayout.HorizontalAlignment = self._layoutHorizontalAlignment
        pageLayout.VerticalAlignment = self._layoutVerticalAlignment
        pageLayout.SortOrder = self._layoutSortOrder
        pageLayout.EasingStyle = Enum.EasingStyle.Quad
        pageLayout.EasingDirection = Enum.EasingDirection.Out
        pageLayout.TweenTime = 0.3
        pageLayout.Circular = false
        
        pageLayout.Parent = container
        
        -- Store reference for page navigation
        self._pageLayout = pageLayout
    end
end

--[[
    Apply padding to the container
    @param container - Container to apply padding to
]]
function ContainerComponent:_applyPadding(container)
    -- Remove any existing padding
    local existingPadding = container:FindFirstChild("UIPadding")
    if existingPadding then
        existingPadding:Destroy()
    end
    
    -- Create padding if any padding values are non-zero
    if self._paddingTop > 0 or self._paddingBottom > 0 or 
       self._paddingLeft > 0 or self._paddingRight > 0 then
        
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = typeof(self._paddingTop) == "UDim" 
                        and self._paddingTop 
                        or UDim.new(0, self._paddingTop)
        padding.PaddingBottom = typeof(self._paddingBottom) == "UDim" 
                           and self._paddingBottom 
                           or UDim.new(0, self._paddingBottom)
        padding.PaddingLeft = typeof(self._paddingLeft) == "UDim" 
                         and self._paddingLeft 
                         or UDim.new(0, self._paddingLeft)
        padding.PaddingRight = typeof(self._paddingRight) == "UDim" 
                          and self._paddingRight 
                          or UDim.new(0, self._paddingRight)
        
        padding.Parent = container
    end
end

--[[
    Add a child component to this container
    @param child - Child component to add
    @param layoutOrder - Optional layout order for the child
    @return - Self for method chaining
]]
function ContainerComponent:addChild(child, layoutOrder)
    if not child then
        return self
    end
    
    -- Set layout order if provided
    if layoutOrder and child._instance then
        if child._instance:IsA("GuiObject") then
            child._instance.LayoutOrder = layoutOrder
        end
    end
    
    -- Add to children collection
    table.insert(self._childComponents, child)
    
    -- If we're already mounted, mount the child too
    if self._mounted and self._instance then
        child:mount(self._instance)
    end
    
    return self
end

--[[
    Add multiple children at once
    @param children - Array of children to add
    @return - Self for method chaining
]]
function ContainerComponent:addChildren(children)
    if not children or typeof(children) ~= "table" then
        return self
    end
    
    for _, child in ipairs(children) do
        self:addChild(child)
    end
    
    return self
end

--[[
    Remove a child component
    @param child - Child component to remove
    @return - Self for method chaining
]]
function ContainerComponent:removeChild(child)
    if not child then
        return self
    end
    
    -- Find and remove the child
    for i, c in ipairs(self._childComponents) do
        if c == child then
            table.remove(self._childComponents, i)
            child:unmount()
            break
        end
    end
    
    return self
end

--[[
    Remove all child components
    @return - Self for method chaining
]]
function ContainerComponent:clearChildren()
    for _, child in ipairs(self._childComponents) do
        child:unmount()
    end
    
    self._childComponents = {}
    
    return self
end

--[[
    Set the container layout type
    @param layoutType - Layout type (none, list, grid, page)
    @return - Self for method chaining
]]
function ContainerComponent:setLayoutType(layoutType)
    self._layoutType = layoutType
    
    if self._instance then
        self:_applyLayout(self._instance)
    end
    
    return self
end

--[[
    Set the fill direction
    @param fillDirection - Fill direction enum
    @return - Self for method chaining
]]
function ContainerComponent:setFillDirection(fillDirection)
    self._layoutFillDirection = fillDirection
    
    if self._instance then
        self:_applyLayout(self._instance)
    end
    
    return self
end

--[[
    Go to a specific page (only for page layout)
    @param pageNumber - Page number to navigate to
    @return - Success status
]]
function ContainerComponent:goToPage(pageNumber)
    if not self._pageLayout then
        warn("[ContainerComponent] No page layout found, ensure layout type is 'page'")
        return false
    end
    
    -- Get children from GUI
    local children = self._instance:GetChildren()
    local pages = {}
    
    -- Filter to only GuiObjects (potential pages)
    for _, child in ipairs(children) do
        if child:IsA("GuiObject") and not (
           child:IsA("UIGridLayout") or 
           child:IsA("UIListLayout") or 
           child:IsA("UIPageLayout") or 
           child:IsA("UIPadding") or
           child:IsA("UITableLayout")) then
            table.insert(pages, child)
        end
    end
    
    -- Validate page number
    if pageNumber < 1 or pageNumber > #pages then
        warn("[ContainerComponent] Invalid page number: " .. pageNumber .. ", valid range is 1-" .. #pages)
        return false
    end
    
    -- Jump to the page
    self._pageLayout:JumpToIndex(pageNumber)
    
    return true
end

--[[
    Get the current page number (only for page layout)
    @return - Current page number or nil if no page layout
]]
function ContainerComponent:getCurrentPage()
    if not self._pageLayout then
        return nil
    end
    
    return self._pageLayout.CurrentPage
end

--[[
    Scroll to a position (only for scrollable containers)
    @param position - Position to scroll to (Vector2)
    @return - Success status
]]
function ContainerComponent:scrollTo(position)
    if not self._scrollable or not self._instance or not self._instance:IsA("ScrollingFrame") then
        return false
    end
    
    -- Create a tween to smoothly scroll
    local tween = TweenService:Create(
        self._instance,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {CanvasPosition = position}
    )
    
    tween:Play()
    return true
end

--[[
    Set padding
    @param padding - Padding (number or table with top, bottom, left, right)
    @return - Self for method chaining
]]
function ContainerComponent:setPadding(padding)
    if typeof(padding) == "number" then
        self._paddingTop = padding
        self._paddingBottom = padding
        self._paddingLeft = padding
        self._paddingRight = padding
    elseif typeof(padding) == "table" then
        self._paddingTop = padding.top or self._paddingTop
        self._paddingBottom = padding.bottom or self._paddingBottom
        self._paddingLeft = padding.left or self._paddingLeft
        self._paddingRight = padding.right or self._paddingRight
    end
    
    if self._instance then
        self:_applyPadding(self._instance)
    end
    
    return self
end

--[[
    Set the background color
    @param color - Background color
    @return - Self for method chaining
]]
function ContainerComponent:setBackgroundColor(color)
    self._backgroundColor = color
    
    if self._instance then
        self._instance.BackgroundColor3 = color
    end
    
    return self
end

--[[
    Override mount to handle children
    @param parent - Parent to mount to
    @return - Self for method chaining
]]
function ContainerComponent:mount(parent)
    -- Call base mount
    UIComponentBase.mount(self, parent)
    
    -- Mount all children
    for _, child in ipairs(self._childComponents) do
        child:mount(self._instance)
    end
    
    return self
end

--[[
    Register an onScroll handler
    @param handler - Function to call when scrolling occurs
    @return - Connection ID
]]
function ContainerComponent:onScroll(handler)
    if self._scrollable and self._instance and self._instance:IsA("ScrollingFrame") then
        return self:connect(self._instance, "Changed", function(self, property)
            if property == "CanvasPosition" then
                handler(self, self._instance.CanvasPosition)
            end
        end)
    end
    
    return nil
end

--[[
    Register an onPageChanged handler
    @param handler - Function to call when page changes
    @return - Connection ID
]]
function ContainerComponent:onPageChanged(handler)
    if self._pageLayout then
        return self:connect(self._pageLayout, "PageEnter", function(self, page)
            -- Find the index of the page
            local pageIndex = 1
            for i, child in ipairs(self._instance:GetChildren()) do
                if child == page then
                    pageIndex = i
                    break
                end
            end
            
            handler(self, page, pageIndex)
        end)
    end
    
    return nil
end

return ContainerComponent
