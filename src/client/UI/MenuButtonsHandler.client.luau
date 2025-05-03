--[[
    MenuButtonsHandler.client.luau
    
    Creates and manages menu buttons using asset IDs from UIElements.md
    Handles button creation, positioning, and connecting to respective UI components
    
    Created: May 2, 2025
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load required modules
local sharedFolder = ReplicatedStorage:FindFirstChild("shared") or ReplicatedStorage:FindFirstChild("Shared")

-- Load ModuleLoaderHelper
local ModuleLoaderHelper = nil
if sharedFolder and sharedFolder:FindFirstChild("ModuleLoaderHelper") then
    local success, result = pcall(function()
        return require(sharedFolder.ModuleLoaderHelper)
    end)
    
    if success and result then
        ModuleLoaderHelper = result
        print("[MenuButtonsHandler] ModuleLoaderHelper loaded successfully")
    else
        warn("[MenuButtonsHandler] Failed to load ModuleLoaderHelper, falling back to legacy loading")
    end
end

-- If ModuleLoaderHelper is not available, create a simple fallback
if not ModuleLoaderHelper then
    -- Safe require helper (fallback implementation)
    local function requireSafely(moduleScript)
        if moduleScript and moduleScript:IsA("ModuleScript") then
            local success, result = pcall(function()
                return require(moduleScript)
            end)
            
            if success then
                return result
            else
                warn("Failed to load module: " .. moduleScript.Name)
                return nil
            end
        end
        return nil
    end
    
    ModuleLoaderHelper = {
        safeRequire = requireSafely,
        loadModule = function(name)
            warn("[MenuButtonsHandler] Using legacy module loading for: " .. name)
            -- Simple implementation to search in common locations
            local locations = {
                script.Parent,
                player.PlayerScripts:FindFirstChild("client"),
                player.PlayerScripts:FindFirstChild("client") and player.PlayerScripts.client:FindFirstChild("UI"),
                ReplicatedStorage:FindFirstChild("shared")
            }
            
            for _, location in ipairs(locations) do
                if location and location:FindFirstChild(name) then
                    return requireSafely(location:FindFirstChild(name))
                end
            end
            
            return nil
        end
    }
end

-- Try to find UIRegistry using the ModuleLoaderHelper
local UIRegistry = ModuleLoaderHelper.loadModule("UIRegistry")

if not UIRegistry then
    print("[MenuButtonsHandler] UIRegistry not found with ModuleLoaderHelper, trying fallback method...")
    
    -- Fallback: attempt to load UIRegistry directly
    local function loadUIRegistry()
        print("[MenuButtonsHandler] Attempting to load UIRegistry...")
        
        -- Search locations for UIRegistry
        local searchLocations = {
            -- Client UI folder
            script.Parent and script.Parent:FindFirstChild("UIRegistry"),
            script.Parent and script.Parent:FindFirstChild("UIRegistry.client"),
            
            -- Client Core folder
            player.PlayerScripts:FindFirstChild("client") and 
            player.PlayerScripts:FindFirstChild("client"):FindFirstChild("Core") and 
            player.PlayerScripts:FindFirstChild("client"):FindFirstChild("Core"):FindFirstChild("UIRegistry"),
            
            -- Shared folder
            ReplicatedStorage:FindFirstChild("shared") and 
            ReplicatedStorage:FindFirstChild("shared"):FindFirstChild("UIRegistry")
        }
        
        for _, location in ipairs(searchLocations) do
            if location and location:IsA("ModuleScript") then
                local success, result = pcall(function()
                    return require(location)
                end)
                
                if success and result then
                    print("[MenuButtonsHandler] Found UIRegistry at: " .. location:GetFullName())
                    return result
                end
            end
        end
        
        return nil
    end
    
    UIRegistry = loadUIRegistry()
end

if UIRegistry then
    print("[MenuButtonsHandler] UIRegistry loaded successfully")
else
    warn("[MenuButtonsHandler] UIRegistry not found, some menu features may not work correctly")
end

-- UI module paths - will try to require these when needed
local uiModulePaths = {
    -- Standard format - these module names will be resolved by ModuleLoader
    SettingsMenuUI = "UI/SettingsMenuUI",
    MainMenuUI = "UI/MainMenuUI",
    AllianceUI = "UI/AllianceUI",
    CommunityGoalsUI = "UI/CommunityGoalsUI",
    ChallengesUI = "UI/ChallengesUI",
    GuestPassUI = "UI/GuestPassUI",
    TutorialUI = "UI/TutorialUI",
    RebirthUI = "UI/RebirthUI",
    StaffManagementUI = "UI/StaffManagementUI",
    UpgradesUI = "UI/UpgradesUI",
    AchievementsUI = "UI/AchievementsUI",
}

-- Cached UI modules
local loadedUIModules = {}

-- Load a UI module when needed
local function loadUIModule(moduleName)
    -- Check if already loaded
    if loadedUIModules[moduleName] then
        return loadedUIModules[moduleName]
    end
    
    -- Try to load the module using ModuleLoaderHelper
    local path = uiModulePaths[moduleName]
    if path then
        local module = ModuleLoaderHelper.loadModule(path)
        if module then
            loadedUIModules[moduleName] = module
            print("[MenuButtonsHandler] Loaded UI module: " .. moduleName)
            return module
        end
    end
    
    -- Fallback: try direct path in common locations
    local commonLocations = {
        script.Parent,
        player.PlayerScripts:FindFirstChild("client") and player.PlayerScripts.client:FindFirstChild("UI"),
        ReplicatedStorage:FindFirstChild("src") and ReplicatedStorage.src:FindFirstChild("client") and ReplicatedStorage.src.client:FindFirstChild("UI")
    }
    
    for _, location in ipairs(commonLocations) do
        if location and location:FindFirstChild(moduleName) then
            local module = ModuleLoaderHelper.safeRequire(location:FindFirstChild(moduleName))
            if module then
                loadedUIModules[moduleName] = module
                print("[MenuButtonsHandler] Loaded UI module (fallback): " .. moduleName)
                return module
            end
        end
    end
    
    warn("[MenuButtonsHandler] Could not load UI module: " .. moduleName)
    return nil
end
    CommunityGoalsUI_client = {"client", "UI", "CommunityGoalsUI"},
    ChallengesUI_client = {"client", "UI", "ChallengesUI"},
    GuestPassUI_client = {"client", "UI", "GuestPassUI"},
    TutorialUI_client = {"client", "UI", "TutorialUI"},
    RebirthUI_client = {"client", "UI", "RebirthUI"},
    StaffManagementUI_client = {"client", "UI", "StaffManagementUI"},
    UpgradesUI_client = {"client", "UI", "UpgradesUI"},
    AchievementsUI_client = {"client", "UI", "AchievementsUI"},
    
    -- Direct UI path (no client folder)
    SettingsMenuUI_direct = {"UI", "SettingsMenuUI"},
    MainMenuUI_direct = {"UI", "MainMenuUI"},
    AllianceUI_direct = {"UI", "AllianceUI"},
    CommunityGoalsUI_direct = {"UI", "CommunityGoalsUI"},
    ChallengesUI_direct = {"UI", "ChallengesUI"},
    GuestPassUI_direct = {"UI", "GuestPassUI"},
    TutorialUI_direct = {"UI", "TutorialUI"},
    RebirthUI_direct = {"UI", "RebirthUI"},
    StaffManagementUI_direct = {"UI", "StaffManagementUI"},
    UpgradesUI_direct = {"UI", "UpgradesUI"},
    AchievementsUI_direct = {"UI", "AchievementsUI"}
}

-- Asset IDs from UIElements.md
local iconAssetIds = {
    Alliance = "rbxassetid://128203268160479",
    CommunityGoals = "rbxassetid://97149848004338",
    Challenges = "rbxassetid://120333480860384",
    GuestPass = "rbxassetid://110319251186892",
    Tutorial = "rbxassetid://98150393120956",
    Settings = "rbxassetid://72876573893033",
    Rebirth = "rbxassetid://129409029383961",
    StaffManagement = "rbxassetid://89834599810886",
    Upgrades = "rbxassetid://132635366103906",
    Achievements = "rbxassetid://79337595530955"
}

-- Button configuration
local buttonConfig = {
    size = UDim2.new(0, 50, 0, 50),
    cornerRadius = UDim.new(0, 8),
    margin = 10,
    hoverScale = 1.1,
    hoverDuration = 0.1,
    arrangementStyle = "vertical", -- or "horizontal", "grid"
    startPosition = UDim2.new(0.95, -60, 0.2, 0),
    showTooltips = true, -- Show button names on hover
    activeIndicator = true -- Show visual indicator for active menu
}

-- Create a ScreenGui for menu buttons if it doesn't exist
local menuButtonsGui = playerGui:FindFirstChild("MenuButtonsGui")
if not menuButtonsGui then
    menuButtonsGui = Instance.new("ScreenGui")
    menuButtonsGui.Name = "MenuButtonsGui"
    menuButtonsGui.ResetOnSpawn = false
    menuButtonsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    menuButtonsGui.Parent = playerGui
end

-- Create a container frame for our buttons
local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "MenuButtonContainer"
buttonContainer.Size = UDim2.new(0, 60, 0.6, 0)
buttonContainer.Position = UDim2.new(0.97, -60, 0.2, 0)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = menuButtonsGui

-- Function to try to get a UI module
local function getUIModule(moduleName)
    print("[MenuButtonsHandler] Looking for UI module: " .. moduleName)
    
    -- First check UIRegistry if available
    if UIRegistry then
        local registryModule = UIRegistry.getComponent and UIRegistry.getComponent(moduleName)
        if registryModule then
            print("[MenuButtonsHandler] Found " .. moduleName .. " in UIRegistry")
            return registryModule
        end
        
        -- Try alternative name formats through UIRegistry
        local altNames = {
            moduleName:gsub("UI$", ""),       -- Without UI suffix
            moduleName .. "UI",               -- With UI suffix
            moduleName:gsub("Menu$", ""),     -- Without Menu suffix
            moduleName:gsub("Menu$", "UI"),   -- Replace Menu with UI
            "UI" .. moduleName                -- With UI prefix
        }
        
        for _, altName in ipairs(altNames) do
            if altName ~= moduleName then
                local altModule = UIRegistry.getComponent and UIRegistry.getComponent(altName)
                if altModule then
                    print("[MenuButtonsHandler] Found " .. moduleName .. " in UIRegistry as " .. altName)
                    return altModule
                end
            end
        end
    end
    
    -- First try to find the module directly in the UI folder
    local directModule = script.Parent:FindFirstChild(moduleName)
    if directModule and directModule:IsA("ModuleScript") then
        local success, module = pcall(function()
            return require(directModule)
        end)
        
        if success then
            print("[MenuButtonsHandler] Found " .. moduleName .. " directly in UI folder")
            -- Register with UIRegistry if possible
            if UIRegistry and UIRegistry.registerComponent then
                UIRegistry.registerComponent(moduleName, module)
                print("[MenuButtonsHandler] Registered " .. moduleName .. " with UIRegistry")
            end
            return module
        else
            warn("[MenuButtonsHandler] Failed to require " .. moduleName .. " from UI folder: " .. tostring(module))
        end
    end
    
    -- Try to find the module with .client suffix added (.client.luau or .client.lua)
    local suffixNames = {
        moduleName .. ".client",    -- For .client.luau
        moduleName:gsub("UI$", "")  -- Try without the UI suffix
    }
    
    for _, suffixName in ipairs(suffixNames) do
        local suffixModule = script.Parent:FindFirstChild(suffixName)
        if suffixModule and suffixModule:IsA("ModuleScript") then
            local success, module = pcall(function()
                return require(suffixModule)
            end)
            
            if success then
                print("[MenuButtonsHandler] Found " .. moduleName .. " as " .. suffixName .. " in UI folder")
                return module
            else
                warn("[MenuButtonsHandler] Failed to require " .. suffixName .. ": " .. tostring(module))
            end
        end
    end
    
    -- Try path components if specified
    local pathComponents = uiModulePaths[moduleName]
    if not pathComponents then
        warn("[MenuButtonsHandler] No path defined for module: " .. moduleName)
        return nil
    end
    
    -- Try various locations with path components
    local locations = {
        player.PlayerScripts,
        player.PlayerScripts:FindFirstChild("client"),
        player.PlayerScripts:FindFirstChild("Client"),
        ReplicatedStorage,
        ReplicatedStorage:FindFirstChild("client"),
        ReplicatedStorage:FindFirstChild("Client")
    }
    
    for _, baseLocation in ipairs(locations) do
        if baseLocation then
            local currentLocation = baseLocation
            local locationPath = baseLocation:GetFullName()
            
            for _, component in ipairs(pathComponents) do
                if currentLocation then
                    currentLocation = currentLocation:FindFirstChild(component)
                    if currentLocation then
                        locationPath = locationPath .. "/" .. component
                    else
                        break
                    end
                else
                    break
                end
            end
            
            if currentLocation and currentLocation:IsA("ModuleScript") then
                local success, module = pcall(function()
                    return require(currentLocation)
                end)
                
                if success then
                    print("[MenuButtonsHandler] Found " .. moduleName .. " in " .. locationPath)
                    return module
                else
                    warn("[MenuButtonsHandler] Failed to require " .. moduleName .. " from " .. locationPath .. ": " .. tostring(module))
                end
            end
        end
    end    -- Also check alternative module name formats
    local altModuleNames = {
        moduleName .. "_client",
        moduleName .. "_direct"
    }
    
    for _, altName in ipairs(altModuleNames) do
        local altPathComponents = uiModulePaths[altName]
        if altPathComponents then
            for _, baseLocation in ipairs(locations) do
                if baseLocation then
                    local currentLocation = baseLocation
                    local locationPath = baseLocation:GetFullName()
                    
                    for _, component in ipairs(altPathComponents) do
                        if currentLocation then
                            currentLocation = currentLocation:FindFirstChild(component)
                            if currentLocation then
                                locationPath = locationPath .. "/" .. component
                            else
                                break
                            end
                        else
                            break
                        end
                    end
                    
                    if currentLocation and currentLocation:IsA("ModuleScript") then
                        local success, module = pcall(function()
                            return require(currentLocation)
                        end)
                        
                        if success then
                            print("[MenuButtonsHandler] Found " .. moduleName .. " using alternative path " .. altName .. " at " .. locationPath)
                            return module
                        else
                            warn("[MenuButtonsHandler] Failed to require " .. moduleName .. " from " .. locationPath .. ": " .. tostring(module))
                        end
                    end
                end
            end
        end
    end
    
    -- Extract button name from module name (remove "UI" suffix)
    local baseName = moduleName:gsub("UI$", "")
    
    -- Try to find the module with just its name (without UI suffix)
    local bareNameComponents = {
        baseName, -- Just the button name
        baseName .. "Menu", -- e.g., "SettingsMenu" instead of "SettingsMenuUI"
        "UI" .. baseName -- e.g., "UISettings" instead of "SettingsMenuUI"
    }
    
    for _, bareName in ipairs(bareNameComponents) do
        -- Try in script.Parent folder
        local bareModule = script.Parent:FindFirstChild(bareName)
        if bareModule and bareModule:IsA("ModuleScript") then
            local success, module = pcall(function()
                return require(bareModule)
            end)
            
            if success then
                print("[MenuButtonsHandler] Found " .. moduleName .. " as " .. bareName .. " in UI folder")
                return module
            end
        end
        
        -- Also try in shared folder
        if sharedFolder then
            local sharedModule = sharedFolder:FindFirstChild(bareName)
            if sharedModule and sharedModule:IsA("ModuleScript") then
                local success, module = pcall(function()
                    return require(sharedModule)
                end)
                
                if success then
                    print("[MenuButtonsHandler] Found " .. moduleName .. " as " .. bareName .. " in shared folder")
                    return module
                end
            end
        end
    end
    
    -- Create a placeholder module with a clear warning
    warn("[MenuButtonsHandler] Could not find " .. moduleName .. " in any location, using placeholder. UI will not function properly.")
    return {
        ToggleUI = function()
            print(moduleName .. " would toggle here!")
        end,
        ShowUI = function()
            print(moduleName .. " would show here!")
        end,
        HideUI = function()
            print(moduleName .. " would hide here!")
        end
    }
end

-- Function to create a menu button
local function createMenuButton(name, iconId, position, onClick)
    local button = Instance.new("ImageButton")
    button.Name = name .. "Button"
    button.Size = buttonConfig.size
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    button.BackgroundTransparency = 0.5
    button.Image = iconId
    button.Parent = buttonContainer
    
    -- Add UI corner for rounded edges
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = buttonConfig.cornerRadius
    uiCorner.Parent = button
    
    -- Create active indicator if enabled
    local activeIndicator = nil
    if buttonConfig.activeIndicator then
        activeIndicator = Instance.new("Frame")
        activeIndicator.Name = "ActiveIndicator"
        activeIndicator.Size = UDim2.new(0, 4, 1, 0)
        activeIndicator.Position = UDim2.new(0, -5, 0, 0)
        activeIndicator.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        activeIndicator.Visible = false
        activeIndicator.Parent = button
        
        -- Round the indicator corners
        local indicatorCorner = Instance.new("UICorner")
        indicatorCorner.CornerRadius = UDim.new(0, 2)
        indicatorCorner.Parent = activeIndicator
    end
    
    -- Create tooltip if enabled
    local tooltip = nil
    if buttonConfig.showTooltips then
        tooltip = Instance.new("TextLabel")
        tooltip.Name = "Tooltip"
        tooltip.Size = UDim2.new(0, 0, 0, 30) -- Will be resized based on text
        tooltip.Position = UDim2.new(0, -10, 0.5, 0)
        tooltip.AnchorPoint = Vector2.new(1, 0.5)
        tooltip.Text = name
        tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
        tooltip.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        tooltip.BackgroundTransparency = 0.2
        tooltip.TextSize = 14
        tooltip.Font = Enum.Font.GothamSemibold
        tooltip.TextXAlignment = Enum.TextXAlignment.Center
        tooltip.Visible = false
        tooltip.AutomaticSize = Enum.AutomaticSize.X
        tooltip.Parent = button
        
        -- Add padding for text
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.Parent = tooltip
        
        -- Round the tooltip corners
        local tooltipCorner = Instance.new("UICorner")
        tooltipCorner.CornerRadius = UDim.new(0, 4)
        tooltipCorner.Parent = tooltip
    end
    
    -- Add hover effects
    local originalSize = button.Size
    button.MouseEnter:Connect(function()
        TweenService:Create(
            button,
            TweenInfo.new(buttonConfig.hoverDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Size = UDim2.new(
                    originalSize.X.Scale, 
                    originalSize.X.Offset * buttonConfig.hoverScale, 
                    originalSize.Y.Scale, 
                    originalSize.Y.Offset * buttonConfig.hoverScale
                ),
                BackgroundTransparency = 0.3
            }
        ):Play()
        
        -- Show tooltip on hover if enabled
        if tooltip then
            tooltip.Visible = true
        end
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(
            button,
            TweenInfo.new(buttonConfig.hoverDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Size = originalSize,
                BackgroundTransparency = 0.5
            }
        ):Play()
        
        -- Hide tooltip on mouse leave
        if tooltip then
            tooltip.Visible = false
        end
    end)
    
    -- Connect the click event
    button.MouseButton1Click:Connect(onClick)
    
    return button, activeIndicator
end

-- Create all menu buttons and position them
local function createAllMenuButtons(closeAllMenus)
    -- Define the button order
    local buttonOrder = {
        "Settings",
        "Alliance",
        "CommunityGoals",
        "Challenges",
        "StaffManagement",
        "Upgrades",
        "Achievements",
        "Tutorial",
        "Rebirth",
        "GuestPass"
    }
    
    local buttons = {}
    local buttonSpacing = buttonConfig.size.Y.Offset + buttonConfig.margin
    
    -- Function to set the active state of a button
    local function setActiveButton(activeButtonName)
        for name, buttonData in pairs(buttons) do
            if buttonData.activeIndicator then
                buttonData.activeIndicator.Visible = (name == activeButtonName)
            end
        end
    end
    
    for index, buttonName in ipairs(buttonOrder) do
        local position
        
        if buttonConfig.arrangementStyle == "vertical" then
            position = UDim2.new(
                0, 0,
                0, (index - 1) * buttonSpacing
            )
        elseif buttonConfig.arrangementStyle == "horizontal" then
            position = UDim2.new(
                0, (index - 1) * buttonSpacing,
                0, 0
            )
        elseif buttonConfig.arrangementStyle == "grid" then
            local row = math.floor((index - 1) / 3) -- 3 buttons per row
            local col = (index - 1) % 3
            position = UDim2.new(
                0, col * buttonSpacing,
                0, row * buttonSpacing
            )
        end        -- Try to get the UI module for this button
        local uiModuleName = buttonName .. "UI"
        local uiModule = getUIModule(uiModuleName)
        
        -- Print debug info about found UI module
        if uiModule then
            local hasToggleUI = typeof(uiModule.ToggleUI) == "function"
            local hasShowUI = typeof(uiModule.ShowUI) == "function"
            local hasHideUI = typeof(uiModule.HideUI) == "function"
            print("[MenuButtonsHandler] Module " .. uiModuleName .. " loaded. Has ToggleUI: " .. tostring(hasToggleUI) .. 
                  ", Has ShowUI: " .. tostring(hasShowUI) .. ", Has HideUI: " .. tostring(hasHideUI))
            
            -- Register with UIRegistry if not already registered
            if UIRegistry and UIRegistry.registerComponent and not UIRegistry.getComponent(uiModuleName) then
                UIRegistry.registerComponent(uiModuleName, uiModule)
                print("[MenuButtonsHandler] Registered " .. uiModuleName .. " with UIRegistry during button creation")
            end
        else
            warn("[MenuButtonsHandler] Failed to load UI module: " .. uiModuleName)
        end
        
        -- Create the button
        local button, activeIndicator = createMenuButton(
            buttonName,
            iconAssetIds[buttonName] or "rbxassetid://0",
            position,
            function()
                local isSuccess = false
                
                -- First try standard ToggleUI method
                if uiModule and typeof(uiModule.ToggleUI) == "function" then
                    uiModule:ToggleUI()
                    isSuccess = true
                else
                    -- Try specific toggle methods based on module naming patterns
                    if uiModule then
                        local methodPrefix = "Toggle"
                        local methodSuffix = "Menu"
                        
                        -- Try different method patterns: ToggleSettingsMenu, ToggleSettings, etc.
                        local methodNames = {
                            methodPrefix .. buttonName .. methodSuffix,
                            methodPrefix .. buttonName,
                            "Toggle" -- Generic toggle
                        }
                        
                        for _, methodName in ipairs(methodNames) do
                            if typeof(uiModule[methodName]) == "function" then
                                uiModule[methodName](uiModule)
                                isSuccess = true
                                break
                            end
                        end
                        
                        -- Try Show/Hide pattern if no Toggle method found
                        if not isSuccess and typeof(uiModule.Show) == "function" and typeof(uiModule.Hide) == "function" then
                            if not buttons[buttonName].isOpen then
                                uiModule:Show()
                                buttons[buttonName].isOpen = true
                            else
                                uiModule:Hide()
                                buttons[buttonName].isOpen = false
                            end
                            isSuccess = true
                        end
                        
                        -- Fallback message if no method works
                        if not isSuccess then
                            print("Toggling " .. buttonName .. " UI")
                            isSuccess = true -- Consider it "successful" for UI purposes
                        end
                    end
                end
                  -- Update active state if successful
                if isSuccess then
                    if buttons[buttonName].isOpen == nil then
                        buttons[buttonName].isOpen = true
                    else
                        buttons[buttonName].isOpen = not buttons[buttonName].isOpen
                    end
                    if buttons[buttonName].isOpen then
                        if closeAllMenus then closeAllMenus(buttonName) end
                        setActiveButton(buttonName)
                    else
                        setActiveButton(nil)
                    end
                end
            end
        )
        
        -- Store button with state
        buttons[buttonName] = {
            button = button,
            activeIndicator = activeIndicator,
            isOpen = false,
            uiModule = uiModule
        }
    end
    
    return buttons
end

-- Initialize all menu buttons

-- Function to close all menus except the one specified
local menuButtons -- forward declaration

local function closeAllMenus(exceptButtonName)
    for name, buttonData in pairs(menuButtons) do
        if buttonData.isOpen and name ~= exceptButtonName then
            -- Try to hide the UI if possible
            local uiModule = buttonData.uiModule
            if uiModule then
                if typeof(uiModule.HideUI) == "function" then
                    uiModule:HideUI()
                elseif typeof(uiModule.Hide) == "function" then
                    uiModule:Hide()
                end
            end
            buttonData.isOpen = false
            if buttonData.activeIndicator then
                buttonData.activeIndicator.Visible = false
            end
        end
    end
end

menuButtons = createAllMenuButtons(closeAllMenus)

-- Function to toggle button visibility
local function toggleMenuButtonsVisibility(visible, buttons)
    for _, buttonData in pairs(buttons) do
        buttonData.button.Visible = visible
    end
end

-- Optional: Create toggle button for collapsing/expanding menu
local function createMenuToggle(menuButtons, closeAllMenus)
    local toggleButton = Instance.new("ImageButton")
    toggleButton.Name = "MenuToggleButton"
    toggleButton.Size = UDim2.new(0, 40, 0, 40)
    toggleButton.Position = UDim2.new(0.97, -40, 0.1, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    toggleButton.BackgroundTransparency = 0.3
    toggleButton.Image = "rbxassetid://8093763464" -- Using menu icon
    toggleButton.Parent = menuButtonsGui
    
    -- Add UI corner
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = toggleButton
    
    -- Add hover effect
    toggleButton.MouseEnter:Connect(function()
        TweenService:Create(
            toggleButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                BackgroundTransparency = 0.1,
                Size = UDim2.new(0, 44, 0, 44)
            }
        ):Play()
    end)
    
    toggleButton.MouseLeave:Connect(function()
        TweenService:Create(
            toggleButton,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                BackgroundTransparency = 0.3,
                Size = UDim2.new(0, 40, 0, 40)
            }
        ):Play()
    end)
    
    -- Track menu state
    local menuExpanded = true
    
    -- Toggle function
    toggleButton.MouseButton1Click:Connect(function()
        menuExpanded = not menuExpanded
        toggleMenuButtonsVisibility(menuExpanded, menuButtons)
        
        -- Rotate icon for visual feedback and add sliding animation
        local targetRotation = menuExpanded and 0 or 180
        local targetPosition = menuExpanded 
            and UDim2.new(0.97, -40, 0.1, 0) 
            or UDim2.new(0.99, -20, 0.1, 0)
            
        TweenService:Create(
            toggleButton, 
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {
                Rotation = targetRotation,
                Position = targetPosition
            }
        ):Play()
        
        -- Close all open menus when collapsing
        if not menuExpanded then
            closeAllMenus()
        end
    end)
    
    return toggleButton
end

-- Create the menu toggle button
local menuToggle = createMenuToggle(menuButtons, closeAllMenus)

-- Log successful initialization
print("Menu buttons initialized successfully!")
