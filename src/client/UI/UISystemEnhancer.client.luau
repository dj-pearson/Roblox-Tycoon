--[[
    UISystemEnhancer.client.luau
    
    Enhances UI system functionality by handling UI component display,
    error recovery, and visibility management. This helps resolve issues
    with MainMenuUI display failures and other UI visibility problems.
    
    Created: May 1, 2025
    Updated: May 5, 2025 - Fixed UI folder not found issues and enhanced UI system recovery
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Configuration
local CONFIG = {
    MAX_DISPLAY_ATTEMPTS = 10,
    RETRY_DELAY = 0.5,
    DEBUG_MODE = true,
    MAX_RETRIES = 5
}

-- Debug logging
local function log(message, level)
    if CONFIG.DEBUG_MODE then
        local prefix = "[UISystemEnhancer]"
        if level == "Warning" then
            warn(prefix .. " " .. message)
        elseif level == "Error" then
            error(prefix .. " " .. message)
        else
            print(prefix .. " " .. message)
        end
    end
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
        if CONFIG.DEBUG_MODE then
            warn("[UISystemEnhancer] Failed to require module: " .. module:GetFullName())
        end
        return nil
    end
end

-- Ensure folder exists
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

-- Create path from segments
local function ensureFolderPath(parent, pathSegments)
    local current = parent
    for _, segment in ipairs(pathSegments) do
        current = ensureFolderExists(current, segment)
    end
    return current
end

-- Module search function
local function findModule(moduleName)
    -- Try standard locations first
    local searchPaths = {
        player.PlayerScripts:FindFirstChild("Client"),
        player.PlayerScripts:FindFirstChild("Core"),
        player.PlayerScripts,
        ReplicatedStorage:FindFirstChild("shared"),
        ReplicatedStorage
    }
    
    -- Try to ensure UI folder exists
    local uiFolder = nil
    if player.PlayerScripts:FindFirstChild("Client") then
        uiFolder = player.PlayerScripts.Client:FindFirstChild("UI")
        if not uiFolder then
            uiFolder = Instance.new("Folder")
            uiFolder.Name = "UI"
            uiFolder.Parent = player.PlayerScripts.Client
            log("Created missing UI folder in Client")
        end
        table.insert(searchPaths, 1, uiFolder) -- Add to beginning for priority
    end
    
    -- Try recursive search for modules with depth limiting
    local function searchRecursive(parent, name, depth)
        if not parent or depth <= 0 then return nil end
        
        -- Try direct match
        local module = parent:FindFirstChild(name)
        if module and module:IsA("ModuleScript") then
            return module
        end
        
        -- Try common UI module extensions
        for _, ext in ipairs({".client", "UI", ".ui"}) do
            module = parent:FindFirstChild(name .. ext)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
        
        -- Try with .client.luau or .luau extension
        for _, ext in ipairs({".client.luau", ".luau"}) do
            module = parent:FindFirstChild(name .. ext)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
        
        -- Recursively search in children folders with reduced depth
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("Folder") or child:IsA("ModuleScript") then
                local found = searchRecursive(child, name, depth - 1)
                if found then
                    return found
                end
            end
        end
        
        return nil
    end
    
    -- First try direct paths 
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
    
    -- Try recursive search with limited depth
    for _, path in ipairs(searchPaths) do
        if path then
            local found = searchRecursive(path, moduleName, 3) -- Limit depth to 3 for performance
            if found then
                return found
            end
        end
    end
    
    -- Check UI-specific folders that might exist in various locations
    local uiLocations = {
        player.PlayerScripts.Client and player.PlayerScripts.Client:FindFirstChild("UI"),
        player.PlayerScripts:FindFirstChild("UI"),
        ReplicatedStorage:FindFirstChild("UI"),
        game:GetService("StarterGui"):FindFirstChild("UI")
    }
    
    for _, location in ipairs(uiLocations) do
        if location then
            local module = location:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return module
            end
        end
    end
    
    -- Try to search in Screens folder which is common for UI
    if uiFolder and uiFolder:FindFirstChild("Screens") then
        local screensFolder = uiFolder.Screens
        local module = screensFolder:FindFirstChild(moduleName)
        if module and module:IsA("ModuleScript") then
            return module
        end
    end
    
    log("Could not find module: " .. moduleName, "Warning")
    return nil
end

-- Check if UI is loaded
local function isUILoaded(uiName)
    -- Try through ClientRegistry first
    if ClientRegistry then
        -- Check different possible ways the UI might be registered
        if typeof(ClientRegistry.getSystem) == "function" then
            local system = ClientRegistry.getSystem(uiName)
            if system then
                return true
            end
            
            -- Try with common suffixes
            for _, suffix in ipairs({"UI", "System", "Manager"}) do
                system = ClientRegistry.getSystem(uiName .. suffix)
                if system then
                    return true
                end
            end
        end
        
        -- Try component registry if it exists
        if typeof(ClientRegistry.getComponent) == "function" then
            local component = ClientRegistry.getComponent(uiName)
            if component then
                return true
            end
        end
    end
    
    -- Check if UI exists in PlayerGui
    local ui = playerGui:FindFirstChild(uiName) or playerGui:FindFirstChild(uiName .. "Gui")
    if ui then
        return true
    end
    
    -- Check if UI exists in _G
    if _G[uiName] then
        return true
    end
    
    return false
end

-- Global state tracking for fallback UIs
local fallbackUIs = {}

local function cleanupFallbackUI(uiName)
    if fallbackUIs[uiName] then
        if fallbackUIs[uiName].gui then
            fallbackUIs[uiName].gui:Destroy()
        end
        fallbackUIs[uiName] = nil
        log("Cleaned up fallback UI: " .. uiName)
        return true
    end
    return false
end

-- Attempt to show UI with improved error recovery
local function showUI(uiName)
    if not uiName then return false end
    
    log("Attempting to show UI: " .. uiName)
    
    local showComplete = false
    local attempts = 0
    
    while not showComplete and attempts < CONFIG.MAX_DISPLAY_ATTEMPTS do
        attempts = attempts + 1
        
        -- Try ClientRegistry first if available
        if ClientRegistry then
            if typeof(ClientRegistry.getSystem) == "function" then
                local system = ClientRegistry.getSystem(uiName)
                if system then
                    -- Try various known show patterns
                    if typeof(system.show) == "function" then
                        local success = pcall(function()
                            system:show()
                        end)
                        if success then
                            showComplete = true
                            log("Successfully showed UI using ClientRegistry.getSystem and show(): " .. uiName)
                            return true
                        end
                    elseif typeof(system.Show) == "function" then
                        local success = pcall(function()
                            system:Show()
                        end)
                        if success then
                            showComplete = true
                            log("Successfully showed UI using ClientRegistry.getSystem and Show(): " .. uiName)
                            return true
                        end
                    elseif typeof(system.setVisible) == "function" then
                        local success = pcall(function()
                            system:setVisible(true)
                        end)
                        if success then
                            showComplete = true
                            log("Successfully showed UI using ClientRegistry.getSystem and setVisible(): " .. uiName)
                            return true
                        end
                    end
                end
            end
        end
        
        -- Try to find the UI module if not found in registry
        local uiModule = findModule(uiName)
        if uiModule then
            local ui = safeRequire(uiModule)
            if ui then
                -- Store for future use
                _G[uiName] = ui
                
                -- Register with ClientRegistry if available
                if ClientRegistry and typeof(ClientRegistry.registerSystem) == "function" then
                    ClientRegistry.registerSystem(uiName, ui)
                    log("Registered UI module with ClientRegistry: " .. uiName)
                end
                
                -- Try various known show patterns
                if typeof(ui.show) == "function" then
                    local success = pcall(function()
                        ui:show()
                    end)
                    if success then
                        showComplete = true
                        log("Successfully showed UI using show(): " .. uiName)
                        return true
                    end
                elseif typeof(ui.Show) == "function" then
                    local success = pcall(function()
                        ui:Show()
                    end)
                    if success then
                        showComplete = true
                        log("Successfully showed UI using Show(): " .. uiName)
                        return true
                    end
                elseif typeof(ui.ShowMainMenu) == "function" then
                    local success = pcall(function()
                        ui:ShowMainMenu(true)
                    end)
                    if success then
                        showComplete = true
                        log("Successfully showed UI using ShowMainMenu(): " .. uiName)
                        return true
                    end
                elseif typeof(ui.setVisible) == "function" then
                    local success = pcall(function()
                        ui:setVisible(true)
                    end)
                    if success then
                        showComplete = true
                        log("Successfully showed UI using setVisible(): " .. uiName)
                        return true
                    end
                end
            end
        end
        
        -- Check _G for UI components
        if _G[uiName] and typeof(_G[uiName]) == "table" then
            local ui = _G[uiName]
            if typeof(ui.show) == "function" then
                local success = pcall(function()
                    ui:show()
                end)
                if success then
                    showComplete = true
                    log("Successfully showed UI from _G using show(): " .. uiName)
                    return true
                end
            elseif typeof(ui.Show) == "function" then
                local success = pcall(function()
                    ui:Show()
                end)
                if success then
                    showComplete = true
                    log("Successfully showed UI from _G using Show(): " .. uiName)
                    return true
                end
            elseif typeof(ui.ShowMainMenu) == "function" then
                local success = pcall(function()
                    ui:ShowMainMenu(true)
                end)
                if success then
                    showComplete = true
                    log("Successfully showed UI from _G using ShowMainMenu(): " .. uiName)
                    return true
                end
            elseif typeof(ui.setVisible) == "function" then
                local success = pcall(function()
                    ui:setVisible(true)
                end)
                if success then
                    showComplete = true
                    log("Successfully showed UI from _G using setVisible(): " .. uiName)
                    return true
                end
            end
        end
        
        -- Last resort - try to find UI in PlayerGui
        local guiObject = playerGui:FindFirstChild(uiName) or playerGui:FindFirstChild(uiName .. "Gui")
        if guiObject then
            if guiObject:IsA("ScreenGui") or guiObject:IsA("GuiObject") then
                guiObject.Visible = true
                showComplete = true
                log("Successfully showed UI by setting Visible property: " .. uiName)
                return true
            end
        end
        
        -- Wait before next attempt
        task.wait(CONFIG.RETRY_DELAY)
    end
    
    log("Failed to show UI after " .. attempts .. " attempts: " .. uiName, "Warning")
    return false
end

-- Create fallback function for a UI system
local function createFallbackUI(uiName)
    -- Clean up any existing fallback UI first
    cleanupFallbackUI(uiName)
    
    log("Creating fallback UI for: " .. uiName)
    
    local fallbackUI = {
        gui = nil,
        visible = false
    }
    
    function fallbackUI:show()
        log("Showing fallback UI: " .. uiName)
        
        -- Clean up existing GUI if any
        if self.gui then
            self.gui:Destroy()
            self.gui = nil
        end
        
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = uiName .. "Gui"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        local frame = Instance.new("Frame")
        frame.Name = "MainFrame"
        frame.Size = UDim2.new(0.5, 0, 0.5, 0)
        frame.Position = UDim2.new(0.25, 0, 0.25, 0)
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        frame.BorderSizePixel = 0
        frame.Parent = screenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = frame
        
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, 0, 0.1, 0)
        title.BackgroundTransparency = 1
        title.Text = uiName
        title.Font = Enum.Font.SourceSansBold
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextScaled = true
        title.Parent = frame
        
        local messageLabel = Instance.new("TextLabel")
        messageLabel.Name = "Message"
        messageLabel.Size = UDim2.new(0.8, 0, 0.6, 0)
        messageLabel.Position = UDim2.new(0.1, 0, 0.2, 0)
        messageLabel.BackgroundTransparency = 1
        messageLabel.Text = "Fallback " .. uiName .. " system active.\nOriginal UI could not be loaded.\nClick Close to dismiss this message."
        messageLabel.Font = Enum.Font.SourceSans
        messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        messageLabel.TextSize = 18
        messageLabel.TextWrapped = true
        messageLabel.Parent = frame
        
        local closeButton = Instance.new("TextButton")
        closeButton.Name = "CloseButton"
        closeButton.Size = UDim2.new(0.4, 0, 0.1, 0)
        closeButton.Position = UDim2.new(0.3, 0, 0.85, 0)
        closeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        closeButton.Text = "Close"
        closeButton.Font = Enum.Font.SourceSansBold
        closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeButton.TextSize = 18
        closeButton.Parent = frame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 5)
        buttonCorner.Parent = closeButton
        
        -- Enhanced close button handling
        closeButton.MouseButton1Click:Connect(function()
            cleanupFallbackUI(uiName)
        end)
        
        screenGui.Parent = playerGui
        self.gui = screenGui
        self.visible = true
        
        -- Store in global tracking
        fallbackUIs[uiName] = self
        
        return true
    end
    
    function fallbackUI:hide()
        log("Hiding fallback UI: " .. uiName)
        return cleanupFallbackUI(uiName)
    end
    
    function fallbackUI:cleanup()
        return cleanupFallbackUI(uiName)
    end
    
    -- Add method to check visibility
    function fallbackUI:isVisible()
        return self.visible
    end
    
    return fallbackUI
end

-- Ensure critical UI folders exist
local function ensureUIFolders()
    log("Ensuring UI folders exist")
    
    -- Start with player scripts
    if player then
        local playerScripts = player:FindFirstChild("PlayerScripts")
        if playerScripts then
            -- Create Client folder
            local clientFolder = ensureFolderExists(playerScripts, "Client")
            
            -- Create UI folder and subfolders
            local uiFolder = ensureFolderExists(clientFolder, "UI")
            ensureFolderExists(uiFolder, "Screens")
            ensureFolderExists(uiFolder, "Components")
            ensureFolderExists(uiFolder, "Core")
            
            log("UI folder structure verified")
            return true
        end
    end
    
    return false
end

-- Ensure ClientRegistry is available
local function ensureClientRegistry()
    local ClientRegistry = _G.ClientRegistry
    
    if not ClientRegistry then
        -- Try to find and require ClientRegistry
        local registryModule = findModule("ClientRegistry")
        if registryModule then
            local success, registry = pcall(function()
                return require(registryModule)
            end)
            
            if success then
                ClientRegistry = registry
                _G.ClientRegistry = registry
                log("Found and loaded ClientRegistry module")
            end
        end
    end
    
    if not ClientRegistry then
        -- Create a basic registry
        log("Creating basic ClientRegistry fallback")
        ClientRegistry = {
            systems = {},
            components = {},
        }
        
        function ClientRegistry.registerSystem(name, system)
            ClientRegistry.systems[name] = system
            log("Registered system in fallback registry: " .. name)
            return true
        end
        
        function ClientRegistry.getSystem(name)
            return ClientRegistry.systems[name]
        end
        
        function ClientRegistry.registerComponent(name, component)
            ClientRegistry.components[name] = component
            log("Registered component in fallback registry: " .. name)
            return true
        end
        
        function ClientRegistry.getComponent(name)
            return ClientRegistry.components[name]
        end
        
        _G.ClientRegistry = ClientRegistry
    end
    
    return ClientRegistry
end

-- Main execution sequence
local function initialize()
    log("Initializing UISystemEnhancer...")
    
    -- Clean up any existing fallback UIs first
    EnhancedUISystem.cleanupFallbackUIs()
    
    -- Preload components
    preloadComponents()
    
    -- Patch UISystem
    patchUISystem()
    
    -- Attempt to show main menu after a delay
    task.delay(1, function()
        local retryCount = 0
        local MAX_RETRIES = 3
        local RETRY_DELAY = 1
        
        local function tryShowMainMenu()
            -- Check if any fallback UIs are visible
            for uiName, fallbackUI in pairs(fallbackUIs) do
                if fallbackUI:isVisible() then
                    log("Found visible fallback UI: " .. uiName .. ", cleaning up")
                    cleanupFallbackUI(uiName)
                end
            end
            
            if showUI("MainMenuUI") then
                log("Successfully showed MainMenuUI")
                return
            end
            
            retryCount = retryCount + 1
            if retryCount < MAX_RETRIES then
                log("Retry " .. retryCount .. " of " .. MAX_RETRIES .. " to show MainMenuUI")
                task.delay(RETRY_DELAY, tryShowMainMenu)
            else
                log("Failed to show MainMenuUI after " .. MAX_RETRIES .. " attempts", "Warning")
                -- Create fallback UI as last resort
                local fallbackUI = createFallbackUI("MainMenuUI")
                if fallbackUI then
                    fallbackUI:show()
                end
            end
        end
        
        tryShowMainMenu()
    end)
    
    log("UISystemEnhancer initialization complete")
end

-- Public API
local UISystemEnhancer = {
    findModule = findModule,
    showUI = showUI,
    isUILoaded = isUILoaded,
    ensureUIFolders = ensureUIFolders,
    createFallbackUI = createFallbackUI
}

-- Initialize on a slight delay to allow other systems to load first
task.spawn(function()
    task.wait(1) -- Wait 1 second before initializing to allow other systems to load
    initialize()
end)

-- Add emergency cleanup method to EnhancedUISystem
EnhancedUISystem.emergencyCleanup = function()
    log("Performing emergency UI cleanup")
    
    -- Clean up all fallback UIs
    EnhancedUISystem.cleanupFallbackUIs()
    
    -- Clean up any ScreenGui with "Gui" suffix
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and string.match(gui.Name, "Gui$") then
            log("Emergency cleanup: Removing " .. gui.Name)
            gui:Destroy()
        end
    end
    
    -- Restore original UI methods
    restoreOriginalMethods()
    
    -- Try to reinitialize the UI system
    task.spawn(function()
        task.wait(1)
        initialize()
    end)
    
    return true
end

return UISystemEnhancer
