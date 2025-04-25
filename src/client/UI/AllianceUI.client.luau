--!strict
--[[
    AllianceUI.client.luau
    Handles the UI for alliance system in the game
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local AllianceUI = {}
local AllianceClient

-- First, try to get or create SafeWaitForChild utility
local SafeWaitForChild
local success, result = pcall(function()
    local moduleScript = ReplicatedStorage:FindFirstChild("src")
    if moduleScript then
        moduleScript = moduleScript:FindFirstChild("shared")
        if moduleScript then
            moduleScript = moduleScript:FindFirstChild("SafeWaitForChild")
            if moduleScript then
                return require(moduleScript)
            end
        end
    end
    
    warn("SafeWaitForChild module not found in AllianceUI, falling back to basic implementation")
    -- Simple fallback implementation
    local fallback = {}
    function fallback.waitForChild(parent, childName, timeout)
        timeout = timeout or 10
        local startTime = os.clock()
        while os.clock() - startTime < timeout do
            local child = parent:FindFirstChild(childName)
            if child then return child end
            task.wait(0.1)
        end
        warn("Timeout waiting for " .. parent:GetFullName() .. ":" .. childName)
        return nil
    end
    return fallback
end)

if not success then
    warn("Error loading SafeWaitForChild in AllianceUI: " .. tostring(result))
    SafeWaitForChild = {
        waitForChild = function(parent, childName)
            warn("Using basic WaitForChild as fallback for " .. parent:GetFullName() .. ":" .. childName)
            return parent:FindFirstChild(childName) or parent:WaitForChild(childName, 2)
        end
    }
else
    SafeWaitForChild = result
end

-- Safely try to get UI or create a placeholder
local function createPlaceholderUI()
    warn("AllianceUIFrame not found, creating fallback UI")
    local placeholder = Instance.new("ScreenGui")
    placeholder.Name = "AllianceUIFrame"
    
    local frame = Instance.new("Frame")
    frame.Name = "AllianceFrame"
    frame.Size = UDim2.new(0, 400, 0, 300)
    frame.Position = UDim2.new(0.5, -200, 0.5, -150)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    frame.Parent = placeholder
    
    local leaveButton = Instance.new("TextButton")
    leaveButton.Name = "LeaveAllianceButton"
    leaveButton.Size = UDim2.new(0, 120, 0, 30)
    leaveButton.Position = UDim2.new(0.5, -60, 0.9, -15)
    leaveButton.Text = "Leave Alliance"
    leaveButton.Parent = frame
    
    -- Add other UI elements as needed
    
    placeholder.Parent = script.Parent
    return placeholder
end

-- Make multiple attempts to get or create the UI with backoff
local UI
local maxAttempts = 3
for attempt = 1, maxAttempts do
    UI = script.Parent:FindFirstChild("AllianceUIFrame")
    if UI then
        break
    end
    
    warn(string.format("Alliance UI attempt %d of %d: UI not found, waiting...", attempt, maxAttempts))
    task.wait(attempt * 0.5) -- Backoff delay increases with each attempt
end

-- Create placeholder UI if still not found
UI = UI or createPlaceholderUI()
local allianceMenu

-- Get UI elements with timeout or fallback
local allianceFrame = SafeWaitForChild.waitForChild(UI, "AllianceFrame", 2)
local leaveAllianceButton = allianceFrame and SafeWaitForChild.waitForChild(allianceFrame, "LeaveAllianceButton", 2)

-- Add checks before using UI elements
if not allianceFrame then
    warn("AllianceFrame not found, some Alliance UI functionality will not work")
end

if not leaveAllianceButton then
    warn("LeaveAllianceButton not found, leave alliance functionality will not work")
end

-- More UI elements with safety checks
local joinAllianceButton = UI:FindFirstChild("JoinAllianceButton")
local joinAllianceButton2 = UI:FindFirstChild("JoinAllianceButton2")
local disbandAllianceButton = UI:FindFirstChild("DisbandAllianceButton")
local viewAllianceButton = UI:FindFirstChild("ViewAllianceButton")

-- Initialize Alliance UI
function AllianceUI.init(allianceClientModule)
    AllianceClient = allianceClientModule
    
    -- Only attach event handlers if UI elements exist
    if leaveAllianceButton then
        leaveAllianceButton.MouseButton1Click:Connect(function()
            if AllianceClient and AllianceClient.leaveAlliance then
                AllianceClient.leaveAlliance()
            else
                warn("AllianceClient.leaveAlliance not available")
            end
        end)
    end
    
    if joinAllianceButton then
        joinAllianceButton.MouseButton1Click:Connect(function()
            if AllianceClient and AllianceClient.showJoinMenu then
                AllianceClient.showJoinMenu()
            end
        end)
    end
    
    -- Continue with other UI element event handlers
    -- Add null checks before attaching events
    
    -- Set initial UI state
    AllianceUI.updateUI({inAlliance = false})
    
    return AllianceUI
end

-- Update UI based on alliance data
function AllianceUI.updateUI(data)
    if not allianceFrame then return end
    
    if data.inAlliance then
        if allianceFrame then
            allianceFrame.Visible = true
        end
        
        if joinAllianceButton then
            joinAllianceButton.Visible = false
        end
        
        if joinAllianceButton2 then
            joinAllianceButton2.Visible = false
        end
        
        -- Update alliance info display
        local allianceNameLabel = allianceFrame:FindFirstChild("AllianceNameLabel")
        if allianceNameLabel then
            allianceNameLabel.Text = data.allianceName or "Unknown Alliance"
        end
        
        -- Update member list if available
        AllianceUI.updateMemberList(data.members or {})
        
    else
        if allianceFrame then
            allianceFrame.Visible = false
        end
        
        if joinAllianceButton then
            joinAllianceButton.Visible = true
        end
        
        if joinAllianceButton2 then
            joinAllianceButton2.Visible = true
        end
    end
    
    -- Set owner-specific controls
    if disbandAllianceButton then
        disbandAllianceButton.Visible = data.isOwner == true
    end
end

-- Update the members list display
function AllianceUI.updateMemberList(members)
    local membersListFrame = allianceFrame and allianceFrame:FindFirstChild("MembersListFrame")
    if not membersListFrame then return end
    
    -- Clear existing member entries
    for _, child in ipairs(membersListFrame:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    -- Create new member entries
    for i, member in ipairs(members) do
        local memberEntry = Instance.new("Frame")
        memberEntry.Name = "MemberEntry_" .. i
        memberEntry.Size = UDim2.new(1, -10, 0, 30)
        memberEntry.Position = UDim2.new(0, 5, 0, (i-1) * 35)
        memberEntry.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
        nameLabel.Text = member.name or "Unknown Player"
        nameLabel.Parent = memberEntry
        
        local rankLabel = Instance.new("TextLabel")
        rankLabel.Size = UDim2.new(0.3, 0, 1, 0)
        rankLabel.Position = UDim2.new(0.7, 0, 0, 0)
        rankLabel.Text = member.rank or "Member"
        rankLabel.Parent = memberEntry
        
        memberEntry.Parent = membersListFrame
    end
end

-- Toggle alliance menu visibility
function AllianceUI.toggleMenu()
    if allianceMenu then
        allianceMenu.Visible = not allianceMenu.Visible
    end
end

-- Public API
return AllianceUI
