-- PrimaryPartLoader.client.luau
-- Client-side script to load and prepare the Primary Part assignment functionality
-- Created: May 4, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Wait for the remote function (create it if it doesn't exist to prevent errors)
local waitForRemote = function()
    local remote = ReplicatedStorage:FindFirstChild("AssignPrimaryPartsRemote")
    if not remote then
        -- Try waiting for it
        for i = 1, 10 do
            remote = ReplicatedStorage:FindFirstChild("AssignPrimaryPartsRemote")
            if remote then break end
            task.wait(0.5)
        end
        
        -- If still not found, create a temporary one
        if not remote then
            print("Creating temporary AssignPrimaryPartsRemote")
            remote = Instance.new("RemoteFunction")
            remote.Name = "AssignPrimaryPartsRemote"
            remote.Parent = ReplicatedStorage
        end
    end
    return remote
end

local assignPrimaryPartsRemote = waitForRemote()

-- Create a global function to call the remote
_G.AssignPrimaryParts = function(targetFolderName)
    -- Default to GymParts if no target specified
    targetFolderName = targetFolderName or "GymParts"
    
    print("Attempting to assign primary parts to models in " .. targetFolderName)
    
    -- Show a notification that we're processing
    local message = Instance.new("Message")
    message.Text = "Processing models in " .. targetFolderName .. "..."
    message.Parent = workspace
    
    -- Call the server function
    local result
    
    local success, response = pcall(function()
        return assignPrimaryPartsRemote:InvokeServer(targetFolderName)
    end)
    
    -- Remove the processing message
    message:Destroy()
    
    if success then
        result = response
        -- Show success message if it worked
        if not string.find(tostring(result or ""), "Error") then
            local successMessage = Instance.new("Message")
            successMessage.Text = tostring(result or "Operation completed")
            successMessage.Parent = workspace
            
            -- Auto-remove after 5 seconds
            task.delay(5, function()
                if successMessage and successMessage.Parent then
                    successMessage:Destroy()
                end
            end)
        else
            -- Show error message
            warn(tostring(result or "Unknown error"))
            local errorMessage = Instance.new("Message")
            errorMessage.Text = tostring(result or "Unknown error")
            errorMessage.Parent = workspace
            
            -- Auto-remove after 5 seconds
            task.delay(5, function()
                if errorMessage and errorMessage.Parent then
                    errorMessage:Destroy()
                end
            end)
        end
    else
        -- Show error message for failure
        warn("Failed to assign primary parts: " .. tostring(response or "Unknown error"))
        local errorMessage = Instance.new("Message")
        errorMessage.Text = "Error: Failed to assign primary parts"
        errorMessage.Parent = workspace
        
        -- Auto-remove after 5 seconds
        task.delay(5, function()
            if errorMessage and errorMessage.Parent then
                errorMessage:Destroy()
            end
        end)
        
        result = "Error: Failed to assign primary parts"
    end
    
    return result
end

print("Primary Part Assignment functionality loaded and registered to _G.AssignPrimaryParts")
