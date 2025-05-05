luau
--!strict
-- UIBootstrapper.client.luau
-- Manages the loading and display of UI components on the client
-- Created: May 15, 2023

local UIBootstrapper = {}

local loadedUIComponents = {}
local screenToComponentMap = {} -- Map screen names to component names
local currentScreen: string | nil = nil

function UIBootstrapper:Initialize()
    print("UIBootstrapper initializing...")

    -- Load essential UI components
    local mainMenuComponent = self:LoadUIComponent("MainMenuUI", "StarterGui.MainMenuUI") -- Assuming the path is StarterGui.MainMenuUI

    -- Register screens
    if mainMenuComponent then
        self:RegisterScreen("MainMenu", "MainMenuUI")
    end

    -- Display the initial screen
    if screenToComponentMap["MainMenu"] then
        self:DisplayScreen("MainMenu")
    else
        warn("Main Menu screen not registered or component not loaded.")
    end

    print("UIBootstrapper initialized.")
end

function UIBootstrapper:LoadUIComponent(componentName: string, componentPath: string)
    if loadedUIComponents[componentName] then
        print("UI component", componentName, "already loaded.")
    end

    if typeof(component) ~= "table" or typeof(component.Initialize) ~= "function" then
        warn("UI component", componentName, "is not a valid module or is missing Initialize function.")
        return nil
    end
    
        -- Check for Show and Hide methods
    if typeof(component.Show) ~= "function" or typeof(component.Hide) ~= "function" then
        warn("UI component", componentName, "is missing Show() or Hide() methods.")
        -- We might still load it, but won't be able to display via DisplayScreen/HideScreen
    end

    local initSuccess, initResult = pcall(component.Initialize, component, self) -- Pass self for potential UIBootstrapper access
    if not initSuccess then
        warn("Error initializing UI component:", componentName, "Error:", initResult)
        return nil
    end

    loadedUIComponents[componentName] = component
    print("Loaded UI component:", componentName)
    return component
end

function UIBootstrapper:RegisterScreen(screenName: string, componentName: string)
    if loadedUIComponents[componentName] then
        screenToComponentMap[screenName] = componentName
        print("Registered screen:", screenName, "with component:", componentName)
    else
        warn("Attempted to register screen", screenName, "with unknown component:", componentName)
    end
end

function UIBootstrapper:GetUIComponent(componentName: string)
    
end

function UIBootstrapper:DisplayScreen(screenName: string)
    local componentName = screenToComponentMap[screenName]
    if not componentName then
        warn("Attempted to display unknown screen:", screenName)
        return
    end

    local component = loadedUIComponents[componentName]
    if not component then
         warn("Component for screen", screenName, "not found after registration:", componentName)
         return
    end
    
    if currentScreen and currentScreen ~= screenName then
        self:HideScreen(currentScreen)
    end

    if typeof(component.Show) == "function" then
        print("Displaying screen:", screenName)

        currentScreen = screenName
        pcall(component.Show, component) -- Call Show method on the component
    else
        warn("UI component for screen", screenName, "does not have a Show() method.")
    end
end

function UIBootstrapper:HideScreen(screenName: string)
     local componentName = screenToComponentMap[screenName]
    if not componentName then
        warn("Attempted to hide unknown screen:", screenName)
        return
    end

    local component = loadedUIComponents[componentName]
    if not component then
         warn("Component for screen", screenName, "not found after registration:", componentName)
         return
    end
    
    if typeof(component.Hide) == "function" then
        print("Hiding screen:", screenName)
        pcall(component.Hide, component) -- Call Hide method on the component
        if currentScreen == screenName then
            currentScreen = nil
        end
    else
        warn("UI component for screen", screenName, "does not have a Hide() method.")
    end
end

return UIBootstrapper