--!strict
--[[
    UIToggleSystem.luau
    
    A module that provides a toggle mechanism to switch between old and new UI systems.
    This helps with testing and gradual migration.
]]

local UIToggleSystem = {
    -- Configuration
    UseNewUISystem = true, -- Set to true to use the new UI system, false to use old
    
    -- List of UI components to enable/disable
    Components = {
        MainMenu = true,
        SideMenu = true,
        Achievements = true,
        CommunityGoals = true,
        Settings = true,
        Tutorial = true,
        GuestPass = true,
        GymMenu = true,
        MemberSatisfaction = true,
        PlayerStats = true,
        ProgressBar = true,
        -- Add other components as needed
    },
    
    -- Debug options
    LogUIActions = false, -- Set to true to log UI actions
}

function UIToggleSystem.shouldUseNewUI()
    return UIToggleSystem.UseNewUISystem
end

function UIToggleSystem.isComponentEnabled(componentName)
    return UIToggleSystem.Components[componentName] == true
end

function UIToggleSystem.setUseNewUI(value)
    UIToggleSystem.UseNewUISystem = value
    if UIToggleSystem.LogUIActions then
        print("UI System toggled to: " .. (value and "NEW" or "OLD"))
    end
end

function UIToggleSystem.enableComponent(componentName)
    UIToggleSystem.Components[componentName] = true
    if UIToggleSystem.LogUIActions then
        print("UI Component enabled: " .. componentName)
    end
end

function UIToggleSystem.disableComponent(componentName)
    UIToggleSystem.Components[componentName] = false
    if UIToggleSystem.LogUIActions then
        print("UI Component disabled: " .. componentName)
    end
end

function UIToggleSystem.logAction(action, details)
    if UIToggleSystem.LogUIActions then
        print("[UI Toggle] " .. action .. (details and (": " .. details) or ""))
    end
end

return UIToggleSystem
