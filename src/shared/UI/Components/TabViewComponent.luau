--!strict
--[[
    TabViewComponent.luau
    
    A component that provides tab-based navigation between different content sections.
    
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
        warn("[TabViewComponent] Failed to load ModuleLoaderHelper, using direct requires")
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
    error("[TabViewComponent] Required dependency UIComponentBase not found")
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
    TabViewComponent - A component that provides tab-based navigation
]]
local TabViewComponent = setmetatable({}, UIComponentBase)
TabViewComponent.__index = TabViewComponent

--[[
    Create a new tab view component
    @param props - Tab view properties
    @return - New TabViewComponent instance
]]
function TabViewComponent.new(props)
    props = props or {}
    
    local self = UIComponentBase.new(props)
    setmetatable(self, TabViewComponent)
    
    -- Tab view properties
    self._type = "TabViewComponent"
    self._tabs = props.tabs or {} -- Array of {id = string, title = string, content = component or instance}
    self._activeTabId = props.activeTabId
    self._tabPosition = props.tabPosition or "top" -- top, left, bottom, right
    self._tabSize = props.tabSize or UDim2.new(0, 120, 0, 40)
    self._tabSpacing = props.tabSpacing or 2
    self._tabAlignment = props.tabAlignment or "start" -- start, center, end
    self._tabBackgroundColor = props.tabBackgroundColor
    self._tabTextColor = props.tabTextColor
    self._activeTabBackgroundColor = props.activeTabBackgroundColor
    self._activeTabTextColor = props.activeTabTextColor
    self._tabButtons = {}
    self._contentContainers = {}
    
    -- UI Components
    self._tabContainer = nil
    self._contentContainer = nil
    
    -- Get style from UIStyleSystem if available
    if UIStyleSystem then
        self._tabStyle = UIStyleSystem:createStyle("TabView", props.themeOverrides)
    end
    
    -- Set default active tab if none specified
    if not self._activeTabId and #self._tabs > 0 then
        self._activeTabId = self._tabs[1].id
    end
    
    return self
end

--[[
    Internal render method - creates the tab view container
    @return - The created tab view container
]]
function TabViewComponent:_render()
    -- Create main container frame
    local container = Instance.new("Frame")
    container.Name = "TabView"
    container.Size = self._size or UDim2.new(1, 0, 1, 0)
    container.Position = self._position or UDim2.new(0, 0, 0, 0)
    container.AnchorPoint = self._anchorPoint or Vector2.new(0, 0)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    
    -- Create tab container
    self:_createTabContainer(container)
    
    -- Create content container
    self:_createContentContainer(container)
    
    -- Activate initial tab
    self:_activateTab(self._activeTabId)
    
    return container
end

--[[
    Create the tab container with tab buttons
    @param parentContainer - The parent container
]]
function TabViewComponent:_createTabContainer(parentContainer)
    -- Create container for the tabs
    local tabContainer = ContainerComponent.new({
        name = "TabContainer",
        backgroundColor = self._tabBackgroundColor or Color3.fromRGB(40, 40, 60),
        size = self:_getTabContainerSize(),
        position = self:_getTabContainerPosition(),
        layoutType = self:_getTabLayoutDirection(),
        layoutConfig = {
            padding = self._tabSpacing,
            alignment = self._tabAlignment
        }
    })
    
    tabContainer:mount(parentContainer)
    self._tabContainer = tabContainer
    
    -- Create tab buttons
    for i, tab in ipairs(self._tabs) do
        self:_createTabButton(tab, i)
    end
end

--[[
    Create a tab button
    @param tab - Tab data
    @param index - Tab index
]]
function TabViewComponent:_createTabButton(tab, index)
    local tabButton = ButtonComponent.new({
        name = "Tab_" .. tab.id,
        text = tab.title,
        size = self:_getTabButtonSize(),
        backgroundColor = self:_getTabButtonColor(tab.id == self._activeTabId),
        textColor = self:_getTabButtonTextColor(tab.id == self._activeTabId),
        cornerRadius = 4,
        layoutOrder = index
    })
    
    -- Store the button
    self._tabButtons[tab.id] = tabButton
    
    -- Register click handler
    tabButton:onClick(function()
        self:selectTab(tab.id)
    end)
    
    -- Mount to tab container
    tabButton:mount(self._tabContainer:getInstance())
end

--[[
    Create the content container
    @param parentContainer - The parent container
]]
function TabViewComponent:_createContentContainer(parentContainer)
    -- Create container for the content
    local contentContainer = ContainerComponent.new({
        name = "ContentContainer",
        backgroundColor = Color3.fromRGB(50, 50, 70),
        size = self:_getContentContainerSize(),
        position = self:_getContentContainerPosition(),
        cornerRadius = 4
    })
    
    contentContainer:mount(parentContainer)
    self._contentContainer = contentContainer
    
    -- Create content for each tab
    for _, tab in ipairs(self._tabs) do
        self:_createTabContent(tab)
    end
end

--[[
    Create the content for a tab
    @param tab - Tab data
]]
function TabViewComponent:_createTabContent(tab)
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content_" .. tab.id
    contentFrame.Size = UDim2.new(1, 0, 1, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Visible = false -- Hidden by default
    
    -- Store the content frame
    self._contentContainers[tab.id] = contentFrame
    
    -- If content is a UI component with mount method
    if typeof(tab.content) == "table" and typeof(tab.content.mount) == "function" then
        tab.content:mount(contentFrame)
    elseif typeof(tab.content) == "Instance" then
        -- If content is an Instance, parent it to the content frame
        tab.content.Parent = contentFrame
    elseif typeof(tab.content) == "function" then
        -- If content is a function, call it to get the content
        local result = tab.content()
        if typeof(result) == "Instance" then
            result.Parent = contentFrame
        end
    end
    
    contentFrame.Parent = self._contentContainer:getInstance()
end

--[[
    Get the size for the tab container based on tab position
    @return - Size UDim2
]]
function TabViewComponent:_getTabContainerSize()
    if self._tabPosition == "top" or self._tabPosition == "bottom" then
        -- Horizontal tabs
        return UDim2.new(1, 0, 0, self._tabSize.Y.Offset)
    else
        -- Vertical tabs
        return UDim2.new(0, self._tabSize.X.Offset, 1, 0)
    end
end

--[[
    Get the position for the tab container based on tab position
    @return - Position UDim2
]]
function TabViewComponent:_getTabContainerPosition()
    if self._tabPosition == "top" then
        return UDim2.new(0, 0, 0, 0)
    elseif self._tabPosition == "bottom" then
        return UDim2.new(0, 0, 1, -self._tabSize.Y.Offset)
    elseif self._tabPosition == "left" then
        return UDim2.new(0, 0, 0, 0)
    else -- right
        return UDim2.new(1, -self._tabSize.X.Offset, 0, 0)
    end
end

--[[
    Get the size for the content container based on tab position
    @return - Size UDim2
]]
function TabViewComponent:_getContentContainerSize()
    if self._tabPosition == "top" or self._tabPosition == "bottom" then
        -- Horizontal tabs
        return UDim2.new(1, 0, 1, -self._tabSize.Y.Offset)
    else
        -- Vertical tabs
        return UDim2.new(1, -self._tabSize.X.Offset, 1, 0)
    end
end

--[[
    Get the position for the content container based on tab position
    @return - Position UDim2
]]
function TabViewComponent:_getContentContainerPosition()
    if self._tabPosition == "top" then
        return UDim2.new(0, 0, 0, self._tabSize.Y.Offset)
    elseif self._tabPosition == "bottom" then
        return UDim2.new(0, 0, 0, 0)
    elseif self._tabPosition == "left" then
        return UDim2.new(0, self._tabSize.X.Offset, 0, 0)
    else -- right
        return UDim2.new(0, 0, 0, 0)
    end
end

--[[
    Get the layout direction for the tab container based on tab position
    @return - Layout type string
]]
function TabViewComponent:_getTabLayoutDirection()
    if self._tabPosition == "top" or self._tabPosition == "bottom" then
        return "horizontal"
    else
        return "vertical"
    end
end

--[[
    Get the size for individual tab buttons based on tab position
    @return - Size UDim2
]]
function TabViewComponent:_getTabButtonSize()
    local tabSize = self._tabSize
    
    if self._tabPosition == "top" or self._tabPosition == "bottom" then
        -- Adjust width if we need equal width for horizontal tabs
        return tabSize
    else
        -- For vertical tabs, ensure full width
        return UDim2.new(1, 0, 0, tabSize.Y.Offset)
    end
end

--[[
    Get the background color for a tab button
    @param isActive - Whether the tab is active
    @return - Color3
]]
function TabViewComponent:_getTabButtonColor(isActive)
    if isActive then
        if self._activeTabBackgroundColor then
            return self._activeTabBackgroundColor
        elseif self._tabStyle then
            return self._tabStyle:getColor("activeTabBackground")
        else
            return Color3.fromRGB(70, 70, 90)
        end
    else
        if self._tabBackgroundColor then
            return self._tabBackgroundColor
        elseif self._tabStyle then
            return self._tabStyle:getColor("tabBackground")
        else
            return Color3.fromRGB(50, 50, 70)
        end
    end
end

--[[
    Get the text color for a tab button
    @param isActive - Whether the tab is active
    @return - Color3
]]
function TabViewComponent:_getTabButtonTextColor(isActive)
    if isActive then
        if self._activeTabTextColor then
            return self._activeTabTextColor
        elseif self._tabStyle then
            return self._tabStyle:getColor("activeTabText")
        else
            return Color3.fromRGB(255, 255, 255)
        end
    else
        if self._tabTextColor then
            return self._tabTextColor
        elseif self._tabStyle then
            return self._tabStyle:getColor("tabText")
        else
            return Color3.fromRGB(200, 200, 220)
        end
    end
end

--[[
    Activate a tab by its ID
    @param tabId - The ID of the tab to activate
]]
function TabViewComponent:_activateTab(tabId)
    -- Validate tab ID
    if not self._contentContainers[tabId] then
        warn("[TabViewComponent] Tab ID not found: " .. tostring(tabId))
        return
    end
    
    -- Update visual state of all tabs
    for id, button in pairs(self._tabButtons) do
        local isActive = id == tabId
        button:setBackgroundColor(self:_getTabButtonColor(isActive))
        button:setTextColor(self:_getTabButtonTextColor(isActive))
    end
    
    -- Show the selected tab content, hide others
    for id, contentFrame in pairs(self._contentContainers) do
        contentFrame.Visible = id == tabId
    end
    
    -- Update active tab ID
    self._activeTabId = tabId
    
    -- Trigger event
    self:triggerEvent("tabChanged", tabId)
end

--[[
    Select a tab by its ID
    @param tabId - The ID of the tab to select
    @return - Self for method chaining
]]
function TabViewComponent:selectTab(tabId)
    self:_activateTab(tabId)
    return self
end

--[[
    Get the currently active tab ID
    @return - The active tab ID
]]
function TabViewComponent:getActiveTabId()
    return self._activeTabId
end

--[[
    Add a new tab
    @param tab - Tab data {id = string, title = string, content = component or instance}
    @return - Self for method chaining
]]
function TabViewComponent:addTab(tab)
    -- Validate tab data
    if not tab.id or not tab.title then
        warn("[TabViewComponent] Tab must have id and title")
        return self
    end
    
    -- Add to tabs array
    table.insert(self._tabs, tab)
    
    -- If the component is already rendered, create the new tab UI
    if self._tabContainer and self._contentContainer then
        self:_createTabButton(tab, #self._tabs)
        self:_createTabContent(tab)
    end
    
    -- If it's the first tab, select it
    if #self._tabs == 1 and not self._activeTabId then
        self._activeTabId = tab.id
        self:_activateTab(tab.id)
    end
    
    return self
end

--[[
    Remove a tab by its ID
    @param tabId - The ID of the tab to remove
    @return - Self for method chaining
]]
function TabViewComponent:removeTab(tabId)
    -- Find the tab index
    local tabIndex = nil
    for i, tab in ipairs(self._tabs) do
        if tab.id == tabId then
            tabIndex = i
            break
        end
    end
    
    if not tabIndex then
        warn("[TabViewComponent] Tab ID not found: " .. tostring(tabId))
        return self
    end
    
    -- Remove from tabs array
    table.remove(self._tabs, tabIndex)
    
    -- If component is rendered, remove the UI
    if self._tabButtons[tabId] then
        self._tabButtons[tabId]:destroy()
        self._tabButtons[tabId] = nil
    end
    
    if self._contentContainers[tabId] then
        self._contentContainers[tabId]:Destroy()
        self._contentContainers[tabId] = nil
    end
    
    -- If the active tab was removed, select another tab
    if self._activeTabId == tabId and #self._tabs > 0 then
        self:selectTab(self._tabs[1].id)
    elseif #self._tabs == 0 then
        self._activeTabId = nil
    end
    
    return self
end

--[[
    Register a tab changed event handler
    @param handler - Function to call when a tab is selected
    @return - Connection ID
]]
function TabViewComponent:onTabChanged(handler)
    return self:on("tabChanged", handler)
end

--[[
    Set the tab position
    @param position - New tab position ("top", "left", "bottom", "right")
    @return - Self for method chaining
]]
function TabViewComponent:setTabPosition(position)
    if position ~= "top" and position ~= "left" and position ~= "bottom" and position ~= "right" then
        warn("[TabViewComponent] Invalid tab position: " .. tostring(position))
        return self
    end
    
    self._tabPosition = position
    
    -- Re-render if already mounted
    if self._mounted then
        self:refresh()
    end
    
    return self
end

return TabViewComponent
