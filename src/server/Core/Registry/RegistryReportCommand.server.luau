--!strict
--[[
    RegistryReportCommand.server.luau
    
    A server-side command script that adds an admin command to generate
    Registry usage reports on demand. This helps administrators track
    migration progress and identify systems that need attention.
    
    Usage:
    - /registryreport - Generates a basic report
    - /registryreport full - Generates a detailed report
    
    Created: May 2, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SharedModules = ReplicatedStorage:WaitForChild("src"):WaitForChild("shared")
local RegistryModules = SharedModules:WaitForChild("Registry")

-- Import required modules
local RegistryUsageReport = require(RegistryModules:WaitForChild("RegistryUsageReport"))

-- Command handler function
local function handleRegistryReportCommand(player, args)
    -- Check if player has appropriate permissions
    local isAdmin = false
    
    -- Simple admin check (replace with your actual permission system)
    if player:GetRankInGroup(123456) >= 100 then -- Example group ID
        isAdmin = true
    end
    
    -- Allow use in Studio for testing
    if game:GetService("RunService"):IsStudio() then
        isAdmin = true
    end
    
    if not isAdmin then
        print("[RegistryReportCommand] Player " .. player.Name .. " attempted to use registry report command without permission")
        return "You don't have permission to use this command."
    end
    
    -- Parse command arguments
    local detailLevel = "basic"
    if args and args[1] and args[1]:lower() == "full" then
        detailLevel = "full"
    end
    
    -- Configure the report generator
    RegistryUsageReport.Config.includeFullDetails = (detailLevel == "full")
    
    -- Generate the report
    local report = RegistryUsageReport:GenerateLegacyUsageReport()
    
    -- Save the report to a file
    local _, filePath = RegistryUsageReport:SaveReportToFile()
    
    -- Return a confirmation message
    return "Registry report generated with " .. detailLevel .. " detail level. Saved to: " .. filePath
end

-- Register the command with the command system
local success, CommandSystem = pcall(function()
    return require(script.Parent.Parent:WaitForChild("CommandSystem"))
end)

if success and CommandSystem then
    CommandSystem:RegisterCommand("registryreport", {
        description = "Generates a report on registry system migration progress",
        usage = "/registryreport [full]",
        permission = "admin",
        handler = handleRegistryReportCommand
    })
    
    print("[RegistryReportCommand] Registered the registry report command")
else
    -- Fallback to manual command registration if command system is not available
    local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if chatEvents then
        local messageReceived = chatEvents:FindFirstChild("OnMessageDoneFiltering")
        if messageReceived then
            messageReceived.OnServerEvent:Connect(function(player, messageObj)
                local message = messageObj.Message or ""
                
                if message:sub(1, 14) == "/registryreport" then
                    local args = {}
                    for part in message:sub(15):gmatch("%S+") do
                        table.insert(args, part)
                    end
                    
                    local response = handleRegistryReportCommand(player, args)
                    if response then
                        -- Send the response back to the player
                        local function sendMessage(player, message)
                            local newMessage = Instance.new("Message")
                            newMessage.Text = message
                            newMessage.Parent = player
                            task.delay(5, function()
                                newMessage:Destroy()
                            end)
                        end
                        
                        sendMessage(player, response)
                    end
                end
            end)
            
            print("[RegistryReportCommand] Registered registry report command using chat filter event")
        end
    end
end

return {
    handleRegistryReportCommand = handleRegistryReportCommand
}
