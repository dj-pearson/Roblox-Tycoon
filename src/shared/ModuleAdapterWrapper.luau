--[[
    ModuleAdapterWrapper.luau
    
    This utility wraps module require calls to ensure compatibility between the old 
    ReplicatedStorage\shared modules and the new src\shared modules. It helps during
    the transition period by standardizing return types and function interfaces.
    
    Created: May 3, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleAdapterWrapper = {}

-- Module-specific adapters
local adapters = {
    -- AssetValidator adapter
    AssetValidator = function(newModule)
        -- Create a compatibility layer that matches the old module's interface
        local compatModule = {}
        
        -- Map functions from new to old interface
        compatModule.validateAsset = function(assetId, assetType)
            return newModule.validateAsset and newModule.validateAsset(assetId, assetType)
        end
        
        compatModule.preloadAsset = function(assetId, assetType)
            return newModule.preloadAsset and newModule.preloadAsset(assetId, assetType)
        end
        
        compatModule.getAsset = function(assetId, assetType)
            return newModule.getAsset and newModule.getAsset(assetId, assetType)
        end
        
        -- Add any other functions needed for compatibility
        
        return compatModule
    end,
    
    -- ModuleLoader adapter
    ModuleLoader = function(newModule)
        local compatModule = {}
        
        -- Map functions from new to old interface
        compatModule.loadModule = function(moduleName, ...)
            return newModule.loadModule and newModule.loadModule(moduleName, ...)
        end
        
        compatModule.getModule = function(moduleName)
            return newModule.getModule and newModule.getModule(moduleName)
        end
        
        -- Add any other functions needed for compatibility
        
        return compatModule
    end,
    
    -- SafeRequire adapter
    SafeRequire = function(newModule)
        local compatModule = {}
        
        -- Map functions from new to old interface
        compatModule.require = function(moduleScript)
            if newModule.require then
                return newModule.require(moduleScript)
            elseif typeof(newModule) == "function" then
                -- Handle case where the new module might be a direct function
                return newModule(moduleScript)
            end
            return nil
        end
        
        return compatModule
    end,
    
    -- SafeWaitForChild adapter
    SafeWaitForChild = function(newModule)
        local compatModule = {}
        
        -- Map functions from new to old interface
        compatModule.waitForChild = function(parent, childName, timeout)
            if newModule.waitForChild then
                return newModule.waitForChild(parent, childName, timeout)
            elseif typeof(newModule) == "function" then
                -- Handle case where the new module might be a direct function
                return newModule(parent, childName, timeout)
            end
            return nil
        end
        
        return compatModule
    end,
    
    -- UIComponents adapter
    UIComponents = function(newModule)
        local compatModule = {}
        
        -- Map functions from new to old interface
        compatModule.CreateButton = function(...)
            return newModule.CreateButton and newModule.CreateButton(...)
        end
        
        compatModule.CreateFrame = function(...)
            return newModule.CreateFrame and newModule.CreateFrame(...)
        end
        
        compatModule.CreateLabel = function(...)
            return newModule.CreateLabel and newModule.CreateLabel(...)
        end
        
        -- Add any other functions needed for compatibility
        
        return compatModule
    end,
    
    -- UIRegistry adapter
    UIRegistry = function(newModule)
        local compatModule = {}
        
        -- Map functions from new to old interface
        compatModule.RegisterComponent = function(...)
            return newModule.RegisterComponent and newModule.RegisterComponent(...)
        end
        
        compatModule.RegisterScreen = function(...)
            return newModule.RegisterScreen and newModule.RegisterScreen(...)
        end
        
        compatModule.OpenScreen = function(...)
            return newModule.OpenScreen and newModule.OpenScreen(...)
        end
        
        compatModule.CloseScreen = function(...)
            return newModule.CloseScreen and newModule.CloseScreen(...)
        end
        
        -- Add any other functions needed for compatibility
        
        return compatModule
    end
}

-- Function to wrap a module with an adapter to ensure compatibility
function ModuleAdapterWrapper.wrapModule(moduleName, module)
    if adapters[moduleName] then
        return adapters[moduleName](module)
    end
    
    return module
end

-- Function to safely require a module with compatibility layer
function ModuleAdapterWrapper.requireCompatible(moduleName)
    local newModule = nil
    
    -- First try to require from the new location (src\shared)
    local success, result = pcall(function()
        return require(ReplicatedStorage.Shared:FindFirstChild(moduleName))
    end)
    
    if success then
        newModule = result
    else
        -- If that fails, try the old location
        success, result = pcall(function()
            local moduleScript = ReplicatedStorage:FindFirstChild("shared"):FindFirstChild(moduleName .. ".luau")
            if moduleScript then
                return require(moduleScript)
            end
            return nil
        end)
        
        if success then
            newModule = result
        else
            warn("ModuleAdapterWrapper: Failed to require module " .. moduleName .. ": " .. tostring(result))
            return nil
        end
    end
    
    -- Apply appropriate adapter
    return ModuleAdapterWrapper.wrapModule(moduleName, newModule)
end

return ModuleAdapterWrapper
