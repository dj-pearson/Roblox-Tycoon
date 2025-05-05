--[[
    MainMenuUILoader.client.luau
    
    Ensures that MainMenuUI is properly loaded and displayed for users.
    This script fixes the persistent issue where MainMenuUI fails to display.
    
    Created: May 1, 2025
    Updated: May 7, 2025 - Enhanced with better module finding, fallback UI creation,
                           and integration with UISystemEnhancer
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")

-- Configuration
local CONFIG = {
    maxRetries = 5,
    retryDelay = 1,
    waitTimeBeforeStart = 2,
    debugMode = true,
    checkExistingUI = true,
    createFallbackUI = true,
    showRetryMessages = true
}

print("MainMenuUILoader: Starting...")

-- Debug logging
local function log(message, level)
    if CONFIG.debugMode then
        local prefix = "[MainMenuUILoader]"
        if level == "Warning" then
            warn(prefix .. " " .. message)
        elseif level == "Error" then
            error(prefix .. " " .. message)
        else
            print(prefix .. " " .. message)
        end
    end
end

-- Ensure folder exists helper
local function ensureFolderExists(parent, folderName)
    local folder = parent:FindFirstChild(folderName)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = folderName
        folder.Parent = parent
        log("Created missing folder: " .. folderName .. " in " .. parent:GetFullName())
    end
    return folder
end

-- Ensure proper folder structure for UI components
local function ensureUIFolders()
    log("Ensuring proper UI folder structure")
    
    -- Create Client folder in PlayerScripts if it doesn't exist
    local clientFolder = ensureFolderExists(playerScripts, "Client")
    
    -- Create UI folder in Client folder if it doesn't exist
    local uiFolder = ensureFolderExists(clientFolder, "UI")
    
    -- Create standard UI subfolders
    ensureFolderExists(uiFolder, "Components")
    ensureFolderExists(uiFolder, "Screens")
    ensureFolderExists(uiFolder, "Core")
    
    return uiFolder
end

-- Find module with enhanced capabilities
local function findModule(moduleName)
    -- Try using UISystemEnhancer first if it's available globally
    if _G.UISystemEnhancer and typeof(_G.UISystemEnhancer.findModule) == "function" then
        local module = _G.UISystemEnhancer.findModule(moduleName)
        if module then
            log("Found " .. moduleName .. " using UISystemEnhancer")
            return module
        end
    end
    
    -- Common search paths
    local searchPaths = {
        player.PlayerScripts:FindFirstChild("Client") and player.PlayerScripts.Client:FindFirstChild("UI"),
        player.PlayerScripts:FindFirstChild("Client"),
        player.PlayerScripts:FindFirstChild("UI"),
        player.PlayerScripts:FindFirstChild("Core"),
        player.PlayerScripts,
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage
    }
    
    -- Try direct name match in common paths
    for _, path in ipairs(searchPaths) do
        if path then
            local module = path:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
            
            -- Try with common extensions
            for _, ext in ipairs({".client", "UI", ".ui", ".client.luau", ".luau"}) do
                module = path:FindFirstChild(moduleName .. ext)
                if module and module:IsA("ModuleScript") then
                    return module
                end
            end
        end
    end
    
    -- Recursive search with depth limiting for performance
    local function searchRecursive(parent, name, maxDepth)
        if not parent or maxDepth <= 0 then return nil end
        
        -- Try direct match
        local module = parent:FindFirstChild(name)
        if module and module:IsA("ModuleScript") then
            return module
        end
        
        -- Try with extensions
        for _, ext in ipairs({".client", "UI", ".ui", ".client.luau", ".luau"}) do
            module = parent:FindFirstChild(name .. ext)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
        
        -- Recursively search in children
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("Folder") or child:IsA("ModuleScript") then
                local found = searchRecursive(child, name, maxDepth - 1)
                if found then
                    return found
                end
            end
        end
        
        return nil
    end
    
    -- Try recursive search in common paths with limited depth
    for _, path in ipairs(searchPaths) do
        if path then
            local found = searchRecursive(path, moduleName, 3) -- Depth of 3 for performance
            if found then
                return found
            end
        end
    end
    
    log("Module not found: " .. moduleName, "Warning")
    return nil
end

-- Safe require function
local function safeRequire(module)
    if not module then return nil end
    if not module:IsA("ModuleScript") then return nil end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success then
        return result
    else
        log("Failed to require module: " .. module:GetFullName() .. " | " .. tostring(result), "Warning")
        return nil
    end
end

-- Create a basic fallback UI if MainMenuUI can't be found
local function createFallbackMainMenuUI()
    log("Creating fallback MainMenuUI")
    
    local fallbackUI = {}
    
    function fallbackUI:Show()
        log("Showing fallback MainMenuUI")
        
        -- Clear any existing fallback UI
        local existingGui = player.PlayerGui:FindFirstChild("FallbackMainMenuUI")
        if existingGui then
            existingGui:Destroy()
        end
        
        -- Create a basic UI
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "FallbackMainMenuUI"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        local frame = Instance.new("Frame")
        frame.Name = "MainFrame"
        frame.Size = UDim2.new(0.6, 0, 0.7, 0)
        frame.Position = UDim2.new(0.2, 0, 0.15, 0)
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        frame.BorderSizePixel = 0
        frame.Parent = screenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = frame
        
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, 0, 0.1, 0)
        title.Position = UDim2.new(0, 0, 0.05, 0)
        title.BackgroundTransparency = 1
        title.Text = "MAIN MENU"
        title.Font = Enum.Font.SourceSansBold
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextScaled = true
        title.Parent = frame
        
        local subtitle = Instance.new("TextLabel")
        subtitle.Name = "Subtitle"
        subtitle.Size = UDim2.new(0.8, 0, 0.1, 0)
        subtitle.Position = UDim2.new(0.1, 0, 0.15, 0)
        subtitle.BackgroundTransparency = 1
        subtitle.Text = "Fallback UI - Original MainMenuUI could not be loaded"
        subtitle.Font = Enum.Font.SourceSans
        subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
        subtitle.TextSize = 18
        subtitle.TextWrapped = true
        subtitle.Parent = frame
        
        -- Create some buttons
        local buttonData = {
            {name = "PlayButton", text = "Play", position = UDim2.new(0, 0, 0.3, 0)},
            {name = "SettingsButton", text = "Settings", position = UDim2.new(0, 0, 0.45, 0)},
            {name = "CreditsButton", text = "Credits", position = UDim2.new(0, 0, 0.6, 0)},
            {name = "CloseButton", text = "Close", position = UDim2.new(0, 0, 0.75, 0)}
        }
        
        for _, data in ipairs(buttonData) do
            local button = Instance.new("TextButton")
            button.Name = data.name
            button.Size = UDim2.new(0.4, 0, 0.1, 0)
            button.Position = UDim2.new(0.3, 0, data.position.Y.Scale, 0)
            button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            button.Text = data.text
            button.Font = Enum.Font.SourceSansBold
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.TextSize = 24
            button.Parent = frame
            
            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = UDim.new(0, 8)
            buttonCorner.Parent = button
            
            -- Add hover effect
            button.MouseEnter:Connect(function()
                button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            end)
            
            button.MouseLeave:Connect(function()
                button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end)
            
            -- Button functionality
            button.MouseButton1Click:Connect(function()
                if button.Name == "CloseButton" then
                    fallbackUI:Hide()
                else
                    log("Clicked on " .. button.Name .. " - This is a fallback button with no functionality")
                end
            end)
        end
        
        screenGui.Parent = player.PlayerGui
        fallbackUI.gui = screenGui
        
        return true
    end
    
    function fallbackUI:show()
        return self:Show()
    end
    
    function fallbackUI:Hide()
        log("Hiding fallback MainMenuUI")
        if fallbackUI.gui then
            fallbackUI.gui.Enabled = false
        end
        return true
    end
    
    function fallbackUI:hide()
        return self:Hide()
    end
    
    function fallbackUI:toggle()
        if fallbackUI.gui and fallbackUI.gui.Enabled then
            return self:Hide()
        else
            return self:Show()
        end
    end
    
    function fallbackUI:Initialize()
        log("Initializing fallback MainMenuUI")
        return true
    end
    
    function fallbackUI:initialize()
        return self:Initialize()
    end
    
    -- Add to _G for future reference
    _G.MainMenuUI = fallbackUI
    
    -- Register with ClientRegistry if available
    if _G.ClientRegistry then
        local ClientRegistry = _G.ClientRegistry
        if typeof(ClientRegistry.registerSystem) == "function" then
            ClientRegistry.registerSystem("MainMenuUI", fallbackUI)
            log("Registered fallback MainMenuUI with ClientRegistry")
        end
    end
    
    return fallbackUI
end

-- Try to show UI with support for various calling patterns
local function showMainMenuUI(mainMenuUI)
    if not mainMenuUI then return false end
    
    -- Try UISystemEnhancer first if available
    if _G.UISystemEnhancer and typeof(_G.UISystemEnhancer.showUI) == "function" then
        log("Showing MainMenuUI using UISystemEnhancer")
        return _G.UISystemEnhancer.showUI("MainMenuUI")
    end
    
    log("Attempting to show MainMenuUI")
    
    -- Try different show methods
    if typeof(mainMenuUI.Show) == "function" then
        local success, result = pcall(function()
            return mainMenuUI:Show()
        end)
        if success then 
            log("Successfully showed MainMenuUI using Show()")
            return true
        end
    end
    
    if typeof(mainMenuUI.show) == "function" then
        local success, result = pcall(function()
            return mainMenuUI:show()
        end)
        if success then 
            log("Successfully showed MainMenuUI using show()")
            return true
        end
    end
    
    if typeof(mainMenuUI.ShowMainMenu) == "function" then
        local success, result = pcall(function()
            return mainMenuUI:ShowMainMenu(true)
        end)
        if success then 
            log("Successfully showed MainMenuUI using ShowMainMenu()")
            return true
        end
    end
    
    if typeof(mainMenuUI.setVisible) == "function" then
        local success, result = pcall(function()
            return mainMenuUI:setVisible(true)
        end)
        if success then 
            log("Successfully showed MainMenuUI using setVisible()")
            return true
        end
    end
    
    log("Failed to show MainMenuUI - no compatible show method found", "Warning")
    return false
end

-- Main function to load and display MainMenuUI
local function loadAndShowMainMenuUI()
    log("Starting MainMenuUI loading process")
    
    -- Ensure UI folders exist
    local uiFolder = ensureUIFolders()
    
    -- Check if MainMenuUI is already loaded in _G
    if _G.MainMenuUI then
        log("MainMenuUI already loaded in _G, trying to show it")
        local success = showMainMenuUI(_G.MainMenuUI)
        if success then return true end
    end
    
    -- Check if MainMenuUI is registered with ClientRegistry
    if _G.ClientRegistry then
        local ClientRegistry = _G.ClientRegistry
        if typeof(ClientRegistry.getSystem) == "function" then
            local mainMenuUI = ClientRegistry.getSystem("MainMenuUI")
            if mainMenuUI then
                log("MainMenuUI found in ClientRegistry, trying to show it")
                local success = showMainMenuUI(mainMenuUI)
                if success then return true end
            end
        end
    end
    
    -- Find MainMenuUI module
    log("Looking for MainMenuUI module")
    local mainMenuModule = findModule("MainMenuUI")
    if not mainMenuModule then
        log("MainMenuUI module not found, creating fallback", "Warning")
        if CONFIG.createFallbackUI then
            local fallbackUI = createFallbackMainMenuUI()
            return showMainMenuUI(fallbackUI)
        end
        return false
    end
    
    -- Require MainMenuUI module
    log("Requiring MainMenuUI module: " .. mainMenuModule:GetFullName())
    local MainMenuUI = safeRequire(mainMenuModule)
    if not MainMenuUI then
        log("Failed to require MainMenuUI module, creating fallback", "Warning")
        if CONFIG.createFallbackUI then
            local fallbackUI = createFallbackMainMenuUI()
            return showMainMenuUI(fallbackUI)
        end
        return false
    end
    
    -- Initialize if needed
    if typeof(MainMenuUI.Initialize) == "function" or typeof(MainMenuUI.initialize) == "function" then
        log("Initializing MainMenuUI")
        pcall(function()
            if typeof(MainMenuUI.Initialize) == "function" then
                MainMenuUI:Initialize()
            elseif typeof(MainMenuUI.initialize) == "function" then
                MainMenuUI:initialize()
            end
        end)
    end
    
    -- Register with _G for future reference
    _G.MainMenuUI = MainMenuUI
    
    -- Register with ClientRegistry if available
    if _G.ClientRegistry then
        local ClientRegistry = _G.ClientRegistry
        if typeof(ClientRegistry.registerSystem) == "function" then
            ClientRegistry.registerSystem("MainMenuUI", MainMenuUI)
            log("Registered MainMenuUI with ClientRegistry")
        end
    end
    
    -- Show MainMenuUI
    return showMainMenuUI(MainMenuUI)
end

-- Main execution logic
local function main()
    -- Wait a moment for other scripts to initialize
    task.wait(CONFIG.waitTimeBeforeStart)
    
    -- Try to load and show MainMenuUI
    local success = false
    local attempts = 0
    
    while not success and attempts < CONFIG.maxRetries do
        attempts = attempts + 1
        log("Attempt " .. attempts .. " of " .. CONFIG.maxRetries .. " to load and show MainMenuUI")
        
        success = loadAndShowMainMenuUI()
        
        if success then
            log("Successfully loaded and showed MainMenuUI on attempt " .. attempts)
            break
        else
            if CONFIG.showRetryMessages and attempts < CONFIG.maxRetries then
                log("Failed to load and show MainMenuUI, retrying in " .. CONFIG.retryDelay .. " seconds...", "Warning")
                task.wait(CONFIG.retryDelay)
            end
        end
    end
    
    if not success then
        log("Failed to load and show MainMenuUI after " .. attempts .. " attempts", "Warning")
        
        -- Create fallback UI as a last resort
        if CONFIG.createFallbackUI then
            log("Creating fallback MainMenuUI as last resort")
            local fallbackUI = createFallbackMainMenuUI()
            fallbackUI:Show()
        end
    end
end

-- Run the main function
main()
