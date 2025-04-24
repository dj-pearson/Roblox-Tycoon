	--[[
    TutorialManager.server.luau
    
    A comprehensive tutorial system for Gym Tycoon that guides new players through all aspects of the game.
    Features:
    - Progressive tutorials that unlock as the player advances
    - Interactive UI elements and visual guides
    - Task-based learning with completion tracking
    - Adaptive tutorials based on player progression
    - Skip/Resume functionality
]]

local TutorialManager = {}
TutorialManager._version = "1.0.0"

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

-- Core modules
local CoreRegistry
local EventBridge
local DataManager

-- Debug/logging
local DEBUG_ENABLED = true
local function debugPrint(...)
    if DEBUG_ENABLED then
        print("[TutorialManager]", ...)
    end
end

-- Load tutorial steps
local TutorialSteps
local success, result = pcall(function()
    -- Try in shared folder which is the standard location
    return require(ReplicatedStorage.shared.TutorialSteps)
end)

if not success then
    -- Fallback to server location
    success, result = pcall(function()
        return require(ServerScriptService.Core.TutorialSteps)
    end)
    
    if not success then
        debugPrint("TutorialSteps module not found, creating default tutorials")
        -- We'll define the tutorials directly in this file instead
        TutorialSteps = {}
    else
        TutorialSteps = result
    end
else
    TutorialSteps = result
end

-- Data structures
local PlayerTutorialProgress = {}
local PlayerTutorialSettings = {}
local RegisteredTutorialSteps = {}
local TutorialSequences = {}
local ActiveTutorials = {}

-- Type definitions
export type TutorialStep = {
    name: string,
    description: string,
    triggerCondition: (Player) -> boolean,
    completionCondition: (Player) -> boolean,
    action: (Player) -> (),
    cleanup: (Player) -> (),
    prerequisiteSteps: {string},
    category: string,
    importance: number,
    timeEstimate: number,
    requiresInteraction: boolean,
}

export type TutorialSequence = {
    name: string,
    description: string,
    steps: {string},
    unlockCondition: (Player) -> boolean,
    category: string,
    importance: number
}

export type TutorialSettings = {
    enabled: boolean,
    showHighlights: boolean,
    showPopups: boolean,
    autoStart: boolean,
    completedTutorials: {string}
}

--[[ Tutorial Step Management ]]--

-- Register a tutorial step
function TutorialManager.registerTutorialStep(step: TutorialStep)
    if RegisteredTutorialSteps[step.name] then
        warn("Tutorial step already registered: " .. step.name)
        return
    end
    
    -- Ensure required fields exist
    if not step.triggerCondition then step.triggerCondition = function() return true end end
    if not step.completionCondition then step.completionCondition = function() return true end end
    if not step.cleanup then step.cleanup = function() end end
    if not step.prerequisiteSteps then step.prerequisiteSteps = {} end
    if not step.importance then step.importance = 5 end -- 1-10 scale
    if not step.timeEstimate then step.timeEstimate = 30 end -- seconds
    
    RegisteredTutorialSteps[step.name] = step
    debugPrint("Registered tutorial step:", step.name)
end

-- Check if a tutorial step is completed
function TutorialManager.isStepCompleted(player: Player, stepName: string): boolean
    local playerProgress = PlayerTutorialProgress[player.UserId]
    if not playerProgress then return false end
    
    return table.find(playerProgress.completedSteps, stepName) ~= nil
end

-- Check if a tutorial step is available
function TutorialManager.isStepAvailable(player: Player, stepName: string): boolean
    local step = RegisteredTutorialSteps[stepName]
    if not step then return false end
    
    -- Check prerequisites
    for _, prerequisite in ipairs(step.prerequisiteSteps) do
        if not TutorialManager.isStepCompleted(player, prerequisite) then
            return false
        end
    end
    
    -- Check trigger condition
    if not step.triggerCondition(player) then
        return false
    end
    
    return true
end

-- Get available tutorial steps for a player
function TutorialManager.getAvailableTutorialSteps(player: Player): {TutorialStep}
    local availableSteps = {}
    
    for name, step in pairs(RegisteredTutorialSteps) do
        if not TutorialManager.isStepCompleted(player, name) and
           TutorialManager.isStepAvailable(player, name) then
            table.insert(availableSteps, step)
        end
    end
    
    -- Sort by importance
    table.sort(availableSteps, function(a, b)
        return a.importance > b.importance
    end)
    
    return availableSteps
end

-- Trigger a tutorial step
function TutorialManager.triggerTutorialStep(player: Player, stepName: string): boolean
    -- Check if tutorial is enabled for this player
    local settings = PlayerTutorialSettings[player.UserId]
    if settings and not settings.enabled then
        return false
    end
    
    -- Check if step exists
    local step = RegisteredTutorialSteps[stepName]
    if not step then
        warn("Tutorial step not found: " .. stepName)
        return false
    end
    
    -- Check if step is available
    if not TutorialManager.isStepAvailable(player, stepName) then
        debugPrint("Tutorial step not available for player:", stepName)
        return false
    end
    
    -- Check if step is already active
    if ActiveTutorials[player.UserId] and ActiveTutorials[player.UserId][stepName] then
        debugPrint("Tutorial step already active:", stepName)
        return false
    end
    
    -- Initialize player's active tutorials if needed
    if not ActiveTutorials[player.UserId] then
        ActiveTutorials[player.UserId] = {}
    end
    
    -- Mark step as active
    ActiveTutorials[player.UserId][stepName] = true
    
    -- Perform the tutorial action
    step.action(player)
    
    -- Notify client
    if EventBridge then
        local tutorialStepStartedEvent = EventBridge:FindFirstChild("TutorialStepStarted")
        if not tutorialStepStartedEvent then
            tutorialStepStartedEvent = Instance.new("RemoteEvent")
            tutorialStepStartedEvent.Name = "TutorialStepStarted"
            tutorialStepStartedEvent.Parent = EventBridge
        end
        
        tutorialStepStartedEvent:FireClient(player, {
            name = step.name,
            description = step.description,
            category = step.category,
            requiresInteraction = step.requiresInteraction
        })
    end
    
    -- Start checking for completion
    if step.completionCondition then
        task.spawn(function()
            while ActiveTutorials[player.UserId] and ActiveTutorials[player.UserId][stepName] do
                if step.completionCondition(player) then
                    TutorialManager.completeStep(player, stepName)
                    break
                end
                task.wait(1)
            end
        end)
    end
    
    return true
end

-- Complete a tutorial step
function TutorialManager.completeStep(player: Player, stepName: string): boolean
    -- Check if player exists
    if not player or not player.Parent then return false end
    
    -- Check if step exists
    local step = RegisteredTutorialSteps[stepName]
    if not step then
        warn("Tutorial step not found: " .. stepName)
        return false
    end
    
    -- Check if step is active
    if not ActiveTutorials[player.UserId] or not ActiveTutorials[player.UserId][stepName] then
        debugPrint("Cannot complete inactive step:", stepName)
        return false
    end
    
    -- Clean up step
    if step.cleanup then
        step.cleanup(player)
    end
    
    -- Remove from active tutorials
    ActiveTutorials[player.UserId][stepName] = nil
    
    -- Add to completed steps
    if not PlayerTutorialProgress[player.UserId] then
        PlayerTutorialProgress[player.UserId] = {
            completedSteps = {},
            activeSequence = nil,
            sequenceProgress = {}
        }
    end
    
    -- Check if already completed
    if not table.find(PlayerTutorialProgress[player.UserId].completedSteps, stepName) then
        table.insert(PlayerTutorialProgress[player.UserId].completedSteps, stepName)
    end
    
    -- Save progress
    TutorialManager.savePlayerProgress(player)
    
    -- Notify client
    if EventBridge then
        local tutorialStepCompletedEvent = EventBridge:FindFirstChild("TutorialStepCompleted") 
        if not tutorialStepCompletedEvent then
            tutorialStepCompletedEvent = Instance.new("RemoteEvent")
            tutorialStepCompletedEvent.Name = "TutorialStepCompleted"
            tutorialStepCompletedEvent.Parent = EventBridge
        end
        
        tutorialStepCompletedEvent:FireClient(player, {
            name = step.name,
            category = step.category
        })
    end
    
    -- Check for next step
    TutorialManager.checkAndTriggerNextStep(player)
    
    return true
end

-- Skip a tutorial step
function TutorialManager.skipStep(player: Player, stepName: string): boolean
    -- Check if step is active
    if not ActiveTutorials[player.UserId] or not ActiveTutorials[player.UserId][stepName] then
        return false
    end
    
    -- Clean up step
    local step = RegisteredTutorialSteps[stepName]
    if step and step.cleanup then
        step.cleanup(player)
    end
    
    -- Remove from active tutorials
    ActiveTutorials[player.UserId][stepName] = nil
    
    -- Don't add to completed steps - it's skipped, not completed
    
    -- Notify client
    if EventBridge then
        local tutorialStepSkippedEvent = EventBridge:FindFirstChild("TutorialStepSkipped")
        if not tutorialStepSkippedEvent then
            tutorialStepSkippedEvent = Instance.new("RemoteEvent")
            tutorialStepSkippedEvent.Name = "TutorialStepSkipped" 
            tutorialStepSkippedEvent.Parent = EventBridge
        end
        
        tutorialStepSkippedEvent:FireClient(player, {
            name = stepName
        })
    end
    
    return true
end

--[[ Tutorial Sequence Management ]]--

-- Register a tutorial sequence
function TutorialManager.registerTutorialSequence(sequence: TutorialSequence)
    if TutorialSequences[sequence.name] then
        warn("Tutorial sequence already registered: " .. sequence.name)
        return
    end
    
    -- Ensure required fields exist
    if not sequence.unlockCondition then sequence.unlockCondition = function() return true end end
    if not sequence.importance then sequence.importance = 5 end
    
    TutorialSequences[sequence.name] = sequence
    debugPrint("Registered tutorial sequence:", sequence.name)
end

-- Start a tutorial sequence
function TutorialManager.startSequence(player: Player, sequenceName: string): boolean
    local sequence = TutorialSequences[sequenceName]
    if not sequence then
        warn("Tutorial sequence not found: " .. sequenceName)
        return false
    end
    
    -- Check if sequence is unlocked
    if not sequence.unlockCondition(player) then
        debugPrint("Tutorial sequence not unlocked for player:", sequenceName)
        return false
    end
    
    -- Initialize player progress if needed
    if not PlayerTutorialProgress[player.UserId] then
        PlayerTutorialProgress[player.UserId] = {
            completedSteps = {},
            activeSequence = nil,
            sequenceProgress = {}
        }
    end
    
    -- Set active sequence
    PlayerTutorialProgress[player.UserId].activeSequence = sequenceName
    
    -- Initialize sequence progress if needed
    if not PlayerTutorialProgress[player.UserId].sequenceProgress[sequenceName] then
        PlayerTutorialProgress[player.UserId].sequenceProgress[sequenceName] = {
            currentStep = 1,
            completed = false
        }
    end
    
    -- Trigger first step
    local currentStep = PlayerTutorialProgress[player.UserId].sequenceProgress[sequenceName].currentStep
    local stepName = sequence.steps[currentStep]
    
    if stepName then
        return TutorialManager.triggerTutorialStep(player, stepName)
    end
    
    return false
end

-- Check and trigger the next step in the active sequence
function TutorialManager.checkAndTriggerNextStep(player: Player): boolean
    -- Check if player has an active sequence
    if not PlayerTutorialProgress[player.UserId] or 
       not PlayerTutorialProgress[player.UserId].activeSequence then
        return false
    end
    
    local sequenceName = PlayerTutorialProgress[player.UserId].activeSequence
    local sequence = TutorialSequences[sequenceName]
    
    if not sequence then
        warn("Active sequence not found: " .. sequenceName)
        return false
    end
    
    -- Get current step index
    local progress = PlayerTutorialProgress[player.UserId].sequenceProgress[sequenceName]
    local nextStepIndex = progress.currentStep + 1
    
    -- Check if there are more steps
    if nextStepIndex <= #sequence.steps then
        -- Move to next step
        progress.currentStep = nextStepIndex
        local nextStepName = sequence.steps[nextStepIndex]
        
        -- Save progress
        TutorialManager.savePlayerProgress(player)
        
        -- Trigger next step
        return TutorialManager.triggerTutorialStep(player, nextStepName)
    else
        -- Sequence completed
        progress.completed = true
        PlayerTutorialProgress[player.UserId].activeSequence = nil
        
        -- Save progress
        TutorialManager.savePlayerProgress(player)
        
        -- Notify client
        if EventBridge then
            local tutorialSequenceCompletedEvent = EventBridge:FindFirstChild("TutorialSequenceCompleted")
            if not tutorialSequenceCompletedEvent then
                tutorialSequenceCompletedEvent = Instance.new("RemoteEvent")
                tutorialSequenceCompletedEvent.Name = "TutorialSequenceCompleted"
                tutorialSequenceCompletedEvent.Parent = EventBridge
            end
            
            tutorialSequenceCompletedEvent:FireClient(player, {
                name = sequenceName,
                category = sequence.category
            })
        end
        
        return true
    end
end

--[[ Player Handling ]]--

-- Initialize player tutorial progress
function TutorialManager.initializePlayer(player: Player)
    debugPrint("Initializing tutorial system for player:", player.Name)
    
    -- Load player progress from data store
    local playerData = nil
    if DataManager then
        playerData = DataManager:getPlayerData(player)
    end
    
    -- Initialize tutorial progress
    PlayerTutorialProgress[player.UserId] = playerData and playerData.tutorialProgress or {
        completedSteps = {},
        activeSequence = nil,
        sequenceProgress = {}
    }
    
    -- Initialize tutorial settings
    PlayerTutorialSettings[player.UserId] = playerData and playerData.tutorialSettings or {
        enabled = true,
        showHighlights = true,
        showPopups = true,
        autoStart = true,
        completedTutorials = {}
    }
    
    -- If player is new, start the welcome sequence
    if #PlayerTutorialProgress[player.UserId].completedSteps == 0 and
       PlayerTutorialSettings[player.UserId].autoStart then
        task.delay(3, function() -- Give time for player to load in
            TutorialManager.startSequence(player, "WelcomeSequence")
        end)
    end
    
    -- Resume any active tutorials
    if PlayerTutorialProgress[player.UserId].activeSequence then
        local sequenceName = PlayerTutorialProgress[player.UserId].activeSequence
        local sequence = TutorialSequences[sequenceName]
        
        if sequence then
            local stepIndex = PlayerTutorialProgress[player.UserId].sequenceProgress[sequenceName].currentStep
            local stepName = sequence.steps[stepIndex]
            
            if stepName then
                task.delay(5, function() -- Give time for player to load in
                    TutorialManager.triggerTutorialStep(player, stepName)
                end)
            end
        end
    end
end

-- Save player tutorial progress
function TutorialManager.savePlayerProgress(player: Player)
    if not DataManager or not player or not PlayerTutorialProgress[player.UserId] then
        return
    end
    
    -- Get current player data
    local playerData = DataManager:getPlayerData(player) or {}
    
    -- Update tutorial data
    playerData.tutorialProgress = PlayerTutorialProgress[player.UserId]
    playerData.tutorialSettings = PlayerTutorialSettings[player.UserId]
    
    -- Save to data store
    DataManager:updatePlayerData(player, "tutorialProgress", playerData.tutorialProgress)
    DataManager:updatePlayerData(player, "tutorialSettings", playerData.tutorialSettings)
end

-- Update player tutorial settings
function TutorialManager.updatePlayerSettings(player: Player, settings)
    if not player or not settings then return end
    
    -- Initialize if needed
    if not PlayerTutorialSettings[player.UserId] then
        PlayerTutorialSettings[player.UserId] = {
            enabled = true,
            showHighlights = true,
            showPopups = true,
            autoStart = true,
            completedTutorials = {}
        }
    end
    
    -- Update settings
    for key, value in pairs(settings) do
        PlayerTutorialSettings[player.UserId][key] = value
    end
    
    -- Save settings
    TutorialManager.savePlayerProgress(player)
    
    -- If tutorials were disabled, cleanup any active tutorials
    if settings.enabled == false then
        TutorialManager.cleanupPlayerTutorials(player)
    end
end

-- Cleanup player tutorials
function TutorialManager.cleanupPlayerTutorials(player: Player)
    if not ActiveTutorials[player.UserId] then return end
    
    -- Cleanup all active tutorials
    for stepName, _ in pairs(ActiveTutorials[player.UserId]) do
        local step = RegisteredTutorialSteps[stepName]
        if step and step.cleanup then
            step.cleanup(player)
        end
    end
    
    -- Clear active tutorials
    ActiveTutorials[player.UserId] = nil
end

-- Handle player leaving
function TutorialManager.playerLeaving(player: Player)
    -- Save progress
    TutorialManager.savePlayerProgress(player)
    
    -- Cleanup tutorials
    TutorialManager.cleanupPlayerTutorials(player)
    
    -- Remove from tracking
    ActiveTutorials[player.UserId] = nil
end

--[[ Default Tutorial Content ]]--

-- Define default tutorial steps and sequences
function TutorialManager.defineDefaultTutorials()
    -- Basic tutorial steps
    TutorialManager.registerTutorialStep({
        name = "MovementTutorial",
        description = "Learn how to move around your gym",
        category = "BasicControls",
        importance = 10,
        action = function(player)
            if EventBridge then
                local showTutorialUIEvent = EventBridge:FindFirstChild("ShowTutorialUI")
                if not showTutorialUIEvent then
                    showTutorialUIEvent = Instance.new("RemoteEvent")
                    showTutorialUIEvent.Name = "ShowTutorialUI"
                    showTutorialUIEvent.Parent = EventBridge
                end
                
                showTutorialUIEvent:FireClient(player, {
                    title = "Moving Around",
                    description = "Use WASD to move around your gym\nUse SPACEBAR to jump\nUse SHIFT to sprint",
                    image = "rbxassetid://7734056100" -- Example asset ID
                })
            end
        end,
        completionCondition = function(player)
            -- Auto-complete after 10 seconds
            return true
        end,
        requiresInteraction = false
    })
    
    TutorialManager.registerTutorialStep({
        name = "CameraTutorial",
        description = "Learn how to control the camera",
        category = "BasicControls",
        importance = 9,
        prerequisiteSteps = {"MovementTutorial"},
        action = function(player)
            if EventBridge then
                local showTutorialUIEvent = EventBridge:FindFirstChild("ShowTutorialUI")
                if showTutorialUIEvent then
                    showTutorialUIEvent:FireClient(player, {
                        title = "Camera Controls",
                        description = "Right-click and drag to rotate the camera\nUse the scroll wheel to zoom in and out",
                        image = "rbxassetid://7734056101" -- Example asset ID
                    })
                end
            end
        end,
        completionCondition = function(player)
            -- Auto-complete after 10 seconds
            return true
        end,
        requiresInteraction = false
    })
    
    TutorialManager.registerTutorialStep({
        name = "BuyingEquipmentTutorial",
        description = "Learn how to buy gym equipment",
        category = "BasicGameplay",
        importance = 8,
        prerequisiteSteps = {"CameraTutorial"},
        action = function(player)
            if EventBridge then
                local showTutorialUIEvent = EventBridge:FindFirstChild("ShowTutorialUI")
                if showTutorialUIEvent then
                    showTutorialUIEvent:FireClient(player, {
                        title = "Buying Equipment",
                        description = "Click on empty spaces with green prompts to buy equipment for your gym",
                        image = "rbxassetid://7734056102", -- Example asset ID
                        highlightSelector = ".BuyPrompt" -- CSS-like selector for UI highlighting
                    })
                end
            end
        end,
        completionCondition = function(player)
            -- Check if player has bought at least one equipment
            local tycoon = player:FindFirstChild("Tycoon")
            if tycoon and tycoon:GetAttribute("EquipmentCount") and tycoon:GetAttribute("EquipmentCount") > 0 then
                return true
            end
            return false
        end,
        requiresInteraction = true
    })
    
    TutorialManager.registerTutorialStep({
        name = "MembershipTutorial",
        description = "Learn about gym members",
        category = "BasicGameplay",
        importance = 7,
        prerequisiteSteps = {"BuyingEquipmentTutorial"},
        action = function(player)
            if EventBridge then
                local showTutorialUIEvent = EventBridge:FindFirstChild("ShowTutorialUI")
                if showTutorialUIEvent then
                    showTutorialUIEvent:FireClient(player, {
                        title = "Gym Members",
                        description = "Members will join your gym automatically as you add equipment.\nKeep them happy to earn more money!",
                        image = "rbxassetid://7734056103" -- Example asset ID
                    })
                end
            end
        end,
        completionCondition = function(player)
            -- Check if player has at least one member
            local tycoon = player:FindFirstChild("Tycoon")
            if tycoon and tycoon:GetAttribute("MembershipCount") and tycoon:GetAttribute("MembershipCount") > 0 then
                return true
            end
            return false
        end,
        requiresInteraction = false
    })
    
    -- Advanced tutorials
    TutorialManager.registerTutorialStep({
        name = "StaffManagementTutorial",
        description = "Learn how to hire and manage staff",
        category = "AdvancedGameplay",
        importance = 6,
        prerequisiteSteps = {"MembershipTutorial"},
        triggerCondition = function(player)
            -- Only trigger if player has enough money
            local leaderstats = player:FindFirstChild("leaderstats")
            if leaderstats and leaderstats:FindFirstChild("Cash") then
                return leaderstats.Cash.Value >= 1000
            end
            return false
        end,
        action = function(player)
            if EventBridge then
                local showTutorialUIEvent = EventBridge:FindFirstChild("ShowTutorialUI")
                if showTutorialUIEvent then
                    showTutorialUIEvent:FireClient(player, {
                        title = "Staff Management",
                        description = "Hire staff to improve your gym's revenue and member satisfaction.\nClick on the Staff button to open the staff management panel.",
                        image = "rbxassetid://7734056104", -- Example asset ID
                        highlightSelector = ".StaffButton"
                    })
                end
            end
        end,
        completionCondition = function(player)
            -- Check if player has hired at least one staff
            local tycoon = player:FindFirstChild("Tycoon")
            if tycoon and tycoon:GetAttribute("StaffCount") and tycoon:GetAttribute("StaffCount") > 0 then
                return true
            end
            return false
        end,
        requiresInteraction = true
    })

    -- Feature-specific tutorials
    TutorialManager.registerTutorialStep({
        name = "AllianceSystemTutorial",
        description = "Learn about the Alliance System",
        category = "FeatureSpecific",
        importance = 5,
        prerequisiteSteps = {"StaffManagementTutorial"},
        triggerCondition = function(player)
            -- Only show after player has reached a certain level
            local tycoon = player:FindFirstChild("Tycoon")
            if tycoon and tycoon:GetAttribute("Level") then
                return tycoon:GetAttribute("Level") >= 5
            end
            return false
        end,
        action = function(player)
            if EventBridge then
                local showTutorialUIEvent = EventBridge:FindFirstChild("ShowTutorialUI")
                if showTutorialUIEvent then
                    showTutorialUIEvent:FireClient(player, {
                        title = "Alliance System",
                        description = "Join forces with other gym owners in an Alliance!\nUnlock unique benefits and participate in challenges together.",
                        image = "rbxassetid://7734056105", -- Example asset ID
                        highlightSelector = ".AllianceButton"
                    })
                end
            end
        end,
        completionCondition = function(player)
            -- Auto-complete after viewing
            return true
        end,
        requiresInteraction = false
    })
    
    TutorialManager.registerTutorialStep({
        name = "SpecializationSystemTutorial",
        description = "Learn about gym specializations",
        category = "FeatureSpecific",
        importance = 5,
        prerequisiteSteps = {"StaffManagementTutorial"},
        triggerCondition = function(player)
            -- Only show after player has enough equipment
            local tycoon = player:FindFirstChild("Tycoon")
            if tycoon and tycoon:GetAttribute("EquipmentCount") then
                return tycoon:GetAttribute("EquipmentCount") >= 10
            end
            return false
        end,
        action = function(player)
            if EventBridge then
                local showTutorialUIEvent = EventBridge:FindFirstChild("ShowTutorialUI")
                if showTutorialUIEvent then
                    showTutorialUIEvent:FireClient(player, {
                        title = "Gym Specializations",
                        description = "Specialize your gym to attract specific types of members!\nEach specialization offers unique bonuses and equipment.",
                        image = "rbxassetid://7734056106", -- Example asset ID
                        highlightSelector = ".SpecializationButton"
                    })
                end
            end
        end,
        completionCondition = function(player)
            -- Auto-complete after viewing
            return true
        end,
        requiresInteraction = false
    })
    
    TutorialManager.registerTutorialStep({
        name = "RebirthSystemTutorial",
        description = "Learn about the Rebirth System",
        category = "FeatureSpecific",
        importance = 4,
        prerequisiteSteps = {"SpecializationSystemTutorial"},
        triggerCondition = function(player)
            -- Only show after player has a high enough level
            local tycoon = player:FindFirstChild("Tycoon")
            if tycoon and tycoon:GetAttribute("Level") then
                return tycoon:GetAttribute("Level") >= 10
            end
            return false
        end,
        action = function(player)
            if EventBridge then
                local showTutorialUIEvent = EventBridge:FindFirstChild("ShowTutorialUI")
                if showTutorialUIEvent then
                    showTutorialUIEvent:FireClient(player, {
                        title = "Rebirth System",
                        description = "Ready for a new challenge?\nRebirth to start fresh with powerful permanent bonuses!",
                        image = "rbxassetid://7734056107", -- Example asset ID
                        highlightSelector = ".RebirthButton"
                    })
                end
            end
        end,
        completionCondition = function(player)
            -- Auto-complete after viewing
            return true
        end,
        requiresInteraction = false
    })
    
    -- Define tutorial sequences
    TutorialManager.registerTutorialSequence({
        name = "WelcomeSequence",
        description = "Welcome to Gym Tycoon! Learn the basics of building your gym empire.",
        category = "Onboarding",
        importance = 10,
        steps = {
            "MovementTutorial",
            "CameraTutorial",
            "BuyingEquipmentTutorial",
            "MembershipTutorial"
        },
        unlockCondition = function(player)
            return true -- Always available
        }
    })
    
    TutorialManager.registerTutorialSequence({
        name = "AdvancedFeaturesSequence",
        description = "Take your gym to the next level with advanced features!",
        category = "Progression",
        importance = 8,
        steps = {
            "StaffManagementTutorial",
            "AllianceSystemTutorial",
            "SpecializationSystemTutorial"
        },
        unlockCondition = function(player)
            -- Only unlock after completing the welcome sequence
            if not PlayerTutorialProgress[player.UserId] then return false end
            
            local completedWelcome = PlayerTutorialProgress[player.UserId].sequenceProgress["WelcomeSequence"]
            return completedWelcome and completedWelcome.completed
        }
    })
    
    TutorialManager.registerTutorialSequence({
        name = "MasterySequence",
        description = "Master advanced gameplay systems and maximize your gym's potential!",
        category = "Mastery",
        importance = 6,
        steps = {
            "RebirthSystemTutorial"
            -- Add more advanced tutorial steps here
        },
        unlockCondition = function(player)
            -- Only unlock at high level
            local tycoon = player:FindFirstChild("Tycoon")
            if tycoon and tycoon:GetAttribute("Level") then
                return tycoon:GetAttribute("Level") >= 10
            end
            return false
        }
    })
}

--[[ Event Handling ]]--

-- Handle remote events
function TutorialManager.setupRemoteEvents()
    if not EventBridge then return end
    
    -- Create remote events
    local skipTutorialEvent = Instance.new("RemoteEvent")
    skipTutorialEvent.Name = "SkipTutorial"
    skipTutorialEvent.Parent = EventBridge
    
    local requestTutorialEvent = Instance.new("RemoteEvent")
    requestTutorialEvent.Name = "RequestTutorial"
    requestTutorialEvent.Parent = EventBridge
    
    local updateTutorialSettingsEvent = Instance.new("RemoteEvent")
    updateTutorialSettingsEvent.Name = "UpdateTutorialSettings"
    updateTutorialSettingsEvent.Parent = EventBridge
    
    -- Create remote functions
    local getTutorialProgressFunction = Instance.new("RemoteFunction")
    getTutorialProgressFunction.Name = "GetTutorialProgress"
    getTutorialProgressFunction.Parent = EventBridge
    
    -- Connect event handlers
    skipTutorialEvent.OnServerEvent:Connect(function(player, stepName)
        if not player then return end
        TutorialManager.skipStep(player, stepName)
    end)
    
    requestTutorialEvent.OnServerEvent:Connect(function(player, tutorialName)
        if not player then return end
        
        if TutorialSequences[tutorialName] then
            TutorialManager.startSequence(player, tutorialName)
        elseif RegisteredTutorialSteps[tutorialName] then
            TutorialManager.triggerTutorialStep(player, tutorialName)
        end
    end)
    
    updateTutorialSettingsEvent.OnServerEvent:Connect(function(player, settings)
        if not player then return end
        TutorialManager.updatePlayerSettings(player, settings)
    end)
    
    -- Set up remote function handlers
    getTutorialProgressFunction.OnServerInvoke = function(player)
        if not player or not PlayerTutorialProgress[player.UserId] then return {} end
        return PlayerTutorialProgress[player.UserId]
    end
}

--[[ Initialization ]]--

function TutorialManager.init(registry)
    CoreRegistry = registry
    
    -- Get dependencies
    EventBridge = CoreRegistry:getSystem("EventBridge")
    DataManager = CoreRegistry:getSystem("DataManager")
    
    -- Define default tutorials
    TutorialManager.defineDefaultTutorials()
    
    -- Set up remote events
    TutorialManager.setupRemoteEvents()
    
    -- Connect player events
    Players.PlayerAdded:Connect(function(player)
        task.delay(2, function() -- Give time for other systems to initialize
            TutorialManager.initializePlayer(player)
        end)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        TutorialManager.playerLeaving(player)
    end)
    
    -- Initialize existing players
    for _, player in pairs(Players:GetPlayers()) do
        task.spawn(function()
            TutorialManager.initializePlayer(player)
        end)
    end
    
    debugPrint("Tutorial Manager initialized (v" .. TutorialManager._version .. ")")
    return true
end

function TutorialManager.start()
    debugPrint("Tutorial Manager started")
    return true
end

-- Legacy support
function TutorialManager.initialize()
    warn("TutorialManager.initialize() is deprecated, use TutorialManager.init() instead")
    return TutorialManager.init()
end

return TutorialManager
