--!strict
--[[
    UISystemEnhancer.client.luau
    
    Enhanced UI system with fallback mechanisms and improved error handling.
    Provides a robust way to show/hide UI components with multiple fallback paths.
    
    Created: April 30, 2025
    Updated: April 30, 2025 - Added enhanced transitions and chaining
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Configuration
local CONFIG = {
    MAX_RETRIES = 3,
    RETRY_DELAY = 1,
    MAX_INIT_ATTEMPTS = 3,
    UI_TRANSITION_DURATION = 0.3,
    ERROR_DISPLAY_DURATION = 5,
    HEALTH_CHECK_INTERVAL = 30,
    MAX_ERROR_COUNT = 5,
    ERROR_RESET_TIME = 300, -- 5 minutes
    TRANSITION_TYPES = {
        FADE = "fade",
        SLIDE = "slide",
        SCALE = "scale",
        ROTATE = "rotate",
        BOUNCE = "bounce",
        ELASTIC = "elastic",
        SPRING = "spring",
        COMBINED = "combined"
    },
    DEFAULT_TRANSITION = {
        duration = 0.3,
        easing = Enum.EasingStyle.Quad,
        direction = Enum.EasingDirection.Out,
        repeatCount = 0,
        reverses = false,
        delayTime = 0
    }
}

-- Enhanced transition effect configurations
local TRANSITION_EFFECTS = {
    fade = {
        properties = {
            BackgroundTransparency = {from = 1, to = 0},
            TextTransparency = {from = 1, to = 0}
        },
        easing = Enum.EasingStyle.Quad,
        direction = Enum.EasingDirection.Out
    },
    slide = {
        properties = {
            Position = {
                from = UDim2.new(0, -100, 0.5, 0),
                to = UDim2.new(0, 0, 0.5, 0)
            }
        },
        easing = Enum.EasingStyle.Back,
        direction = Enum.EasingDirection.Out
    },
    scale = {
        properties = {
            Size = {
                from = UDim2.new(0, 0, 0, 0),
                to = UDim2.new(1, 0, 1, 0)
            }
        },
        easing = Enum.EasingStyle.Elastic,
        direction = Enum.EasingDirection.Out
    },
    rotate = {
        properties = {
            Rotation = {from = -180, to = 0}
        },
        easing = Enum.EasingStyle.Back,
        direction = Enum.EasingDirection.Out
    },
    bounce = {
        properties = {
            Position = {
                from = UDim2.new(0.5, 0, -0.5, 0),
                to = UDim2.new(0.5, 0, 0.5, 0)
            }
        },
        easing = Enum.EasingStyle.Bounce,
        direction = Enum.EasingDirection.Out
    },
    elastic = {
        properties = {
            Size = {
                from = UDim2.new(0.5, 0, 0.5, 0),
                to = UDim2.new(1, 0, 1, 0)
            }
        },
        easing = Enum.EasingStyle.Elastic,
        direction = Enum.EasingDirection.Out
    },
    spring = {
        properties = {
            Position = {
                from = UDim2.new(0, -50, 0.5, 0),
                to = UDim2.new(0, 0, 0.5, 0)
            }
        },
        easing = Enum.EasingStyle.Back,
        direction = Enum.EasingDirection.Out,
        repeatCount = 1,
        reverses = true
    },
    combined = {
        properties = {
            BackgroundTransparency = {from = 1, to = 0},
            Position = {
                from = UDim2.new(0, -50, 0.5, 0),
                to = UDim2.new(0, 0, 0.5, 0)
            },
            Size = {
                from = UDim2.new(0.8, 0, 0.8, 0),
                to = UDim2.new(1, 0, 1, 0)
            }
        },
        easing = Enum.EasingStyle.Back,
        direction = Enum.EasingDirection.Out
    }
}

-- Transition chain management
local TransitionChain = {
    active = false,
    queue = {},
    currentIndex = 0
}

-- Debug logging with enhanced error tracking
local errorCount = 0
local lastErrorTime = 0
local function log(message, level)
    local prefix = "[UISystemEnhancer]"
    if level == "error" then
        errorCount += 1
        lastErrorTime = os.time()
        warn(prefix .. " ERROR: " .. message)
    elseif level == "warn" then
        warn(prefix .. " WARNING: " .. message)
    else
        print(prefix .. " " .. message)
    end
end

-- Global state tracking for fallback UIs
local fallbackUIs = {}
local isInitializing = false
local initializationAttempts = 0
local MAX_INIT_ATTEMPTS = 3

-- UI State Management
local UIState = {
    activeUIs = {},
    uiStack = {},
    transitions = {},
    errorHistory = {},
    lastHealthCheck = os.time()
}

-- Enhanced UI transition system with chaining and customization
local function applyTransitionEffect(ui, effectType, duration, reverse, customOptions)
    if not ui or not ui.gui then 
        log("Invalid UI or GUI for transition", "error")
        return false 
    end
    
    local effect = TRANSITION_EFFECTS[effectType]
    if not effect then
        log("Invalid transition effect type: " .. tostring(effectType), "error")
        return false
    end
    
    -- Merge custom options with defaults
    local options = table.clone(CONFIG.DEFAULT_TRANSITION)
    if customOptions then
        for key, value in pairs(customOptions) do
            options[key] = value
        end
    end
    
    -- Create tween info with custom options
    local tweenInfo = TweenInfo.new(
        duration or options.duration,
        effect.easing or options.easing,
        effect.direction or options.direction,
        options.repeatCount,
        options.reverses,
        options.delayTime
    )
    
    -- Prepare properties for tweening
    local properties = {}
    for prop, values in pairs(effect.properties) do
        if reverse then
            properties[prop] = values.from
        else
            properties[prop] = values.to
        end
    end
    
    -- Create and play tween with error handling
    local success, tween = pcall(function()
        return TweenService:Create(ui.gui, tweenInfo, properties)
    end)
    
    if not success then
        log("Failed to create tween: " .. tostring(tween), "error")
        return false
    end
    
    -- Handle tween completion
    tween.Completed:Connect(function()
        if reverse then
            cleanupFallbackUI(ui.name)
        end
    end)
    
    -- Play tween with error handling
    success, err = pcall(function()
        tween:Play()
    end)
    
    if not success then
        log("Failed to play tween: " .. tostring(err), "error")
        return false
    end
    
    return true
end

-- Chain multiple transitions
local function chainTransitions(transitions)
    if TransitionChain.active then
        log("Transition chain already active", "warn")
        return false
    end
    
    TransitionChain.active = true
    TransitionChain.queue = transitions
    TransitionChain.currentIndex = 0
    
    local function playNextTransition()
        TransitionChain.currentIndex += 1
        local transition = TransitionChain.queue[TransitionChain.currentIndex]
        
        if not transition then
            TransitionChain.active = false
            return
        end
        
        local success = applyTransitionEffect(
            transition.ui,
            transition.effectType,
            transition.duration,
            transition.reverse,
            transition.customOptions
        )
        
        if not success then
            log("Failed to apply transition in chain", "error")
            TransitionChain.active = false
            return
        end
        
        -- Schedule next transition
        task.delay(transition.duration + (transition.customOptions and transition.customOptions.delayTime or 0), playNextTransition)
    end
    
    playNextTransition()
    return true
end

-- Enhanced cleanup function with transition chaining
local function cleanupFallbackUI(uiName)
    if fallbackUIs[uiName] then
        local ui = fallbackUIs[uiName]
        
        -- Create cleanup transition chain
        local cleanupChain = {
            {
                ui = ui,
                effectType = CONFIG.TRANSITION_TYPES.FADE,
                duration = CONFIG.UI_TRANSITION_DURATION * 0.5,
                reverse = true
            },
            {
                ui = ui,
                effectType = CONFIG.TRANSITION_TYPES.SCALE,
                duration = CONFIG.UI_TRANSITION_DURATION * 0.5,
                reverse = true,
                customOptions = {
                    delayTime = 0.1
                }
            }
        }
        
        -- Try chained cleanup
        local success = chainTransitions(cleanupChain)
        if not success then
            -- Fallback to immediate cleanup
            cleanupImmediate(uiName)
        end
        
        return true
    end
    return false
end

-- Immediate cleanup without transition
local function cleanupImmediate(uiName)
    if fallbackUIs[uiName] then
        local ui = fallbackUIs[uiName]
        fallbackUIs[uiName] = nil
        
        if ui.gui then
            -- Disconnect all connections first
            for _, connection in ipairs(getconnections(ui.gui.Changed)) do
                connection:Disconnect()
            end
            
            -- Remove from parent
            ui.gui.Parent = nil
            
            -- Destroy with error handling
            local success, err = pcall(function()
                ui.gui:Destroy()
            end)
            
            if not success then
                log("Error destroying fallback UI " .. uiName .. ": " .. tostring(err), "error")
                table.insert(UIState.errorHistory, {
                    time = os.time(),
                    type = "cleanup_error",
                    ui = uiName,
                    error = tostring(err)
                })
            end
        end
        
        -- Remove from active UIs
        UIState.activeUIs[uiName] = nil
        
        log("Cleaned up fallback UI: " .. uiName)
        return true
    end
    return false
end

-- Create fallback UI with enhanced transitions
local function createFallbackUI(uiName)
    if fallbackUIs[uiName] then
        log("Fallback UI already exists: " .. uiName, "warn")
        return fallbackUIs[uiName]
    end
    
    log("Creating fallback UI: " .. uiName)
    
    local fallbackUI = {
        name = uiName,
        gui = nil,
        visible = false
    }
    
    -- Create the UI with error handling
    local success, result = pcall(function()
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = uiName .. "Fallback"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        -- Set initial state for transition
        screenGui.BackgroundTransparency = 1
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0.4, 0, 0.3, 0)
        frame.Position = UDim2.new(0.3, 0, 0.35, 0)
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        frame.BorderSizePixel = 0
        frame.Parent = screenGui
        
        -- Add UI elements with initial transparent state
        local elements = createUIElements(frame)
        for _, element in ipairs(elements) do
            element.BackgroundTransparency = 1
            element.TextTransparency = 1
        end
        
        screenGui.Parent = playerGui
        return screenGui
    end)
    
    if success and result then
        fallbackUI.gui = result
        fallbackUI.visible = true
        fallbackUIs[uiName] = fallbackUI
        UIState.activeUIs[uiName] = fallbackUI
        
        -- Create entrance transition chain
        local entranceChain = {
            {
                ui = fallbackUI,
                effectType = CONFIG.TRANSITION_TYPES.BOUNCE,
                duration = CONFIG.UI_TRANSITION_DURATION * 0.6
            },
            {
                ui = fallbackUI,
                effectType = CONFIG.TRANSITION_TYPES.FADE,
                duration = CONFIG.UI_TRANSITION_DURATION * 0.4,
                customOptions = {
                    delayTime = 0.1
                }
            }
        }
        
        -- Apply entrance transitions
        task.spawn(function()
            task.wait(0.1) -- Small delay to ensure UI is ready
            chainTransitions(entranceChain)
        end)
        
        log("Successfully created fallback UI: " .. uiName)
        return fallbackUI
    else
        log("Failed to create fallback UI: " .. uiName .. " - " .. tostring(result), "error")
        return nil
    end
end

-- Helper function to create UI elements
local function createUIElements(parent)
    local elements = {}
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = parent
    table.insert(elements, corner)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.2, 0)
    title.Position = UDim2.new(0, 0, 0.1, 0)
    title.BackgroundTransparency = 1
    title.Text = "UI System Error"
    title.Font = Enum.Font.SourceSansBold
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 24
    title.Parent = parent
    table.insert(elements, title)
    
    local message = Instance.new("TextLabel")
    message.Size = UDim2.new(0.8, 0, 0.3, 0)
    message.Position = UDim2.new(0.1, 0, 0.4, 0)
    message.BackgroundTransparency = 1
    message.Text = "Failed to load " .. parent.Name .. "\nPlease try again or contact support"
    message.Font = Enum.Font.SourceSans
    message.TextColor3 = Color3.fromRGB(255, 255, 255)
    message.TextSize = 18
    message.TextWrapped = true
    message.Parent = parent
    table.insert(elements, message)
    
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0.4, 0, 0.1, 0)
    closeButton.Position = UDim2.new(0.3, 0, 0.85, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    closeButton.Text = "Close"
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 18
    closeButton.Parent = parent
    table.insert(elements, closeButton)
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 5)
    buttonCorner.Parent = closeButton
    table.insert(elements, buttonCorner)
    
    -- Enhanced close button handling with transition
    closeButton.MouseButton1Click:Connect(function()
        -- Try normal cleanup first
        if not cleanupFallbackUI(parent.Name) then
            -- If that fails, try emergency cleanup
            log("Normal cleanup failed, attempting emergency cleanup", "warn")
            EnhancedUISystem.emergencyCleanup()
        end
    end)
    
    return elements
end

-- Enhanced emergency cleanup
EnhancedUISystem.emergencyCleanup = function()
    log("Performing emergency UI cleanup")
    
    -- Clean up all fallback UIs
    cleanupAllFallbackUIs()
    
    -- Clean up any ScreenGui with "Gui" suffix
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and string.match(gui.Name, "Gui$") then
            log("Emergency cleanup: Removing " .. gui.Name)
            gui:Destroy()
        end
    end
    
    -- Reset all state
    UIState.activeUIs = {}
    UIState.uiStack = {}
    UIState.transitions = {}
    UIState.errorHistory = {}
    errorCount = 0
    lastErrorTime = 0
    
    -- Restore original UI methods
    restoreOriginalMethods()
    
    -- Reset initialization state
    isInitializing = false
    initializationAttempts = 0
    
    -- Try to reinitialize the UI system
    task.spawn(function()
        task.wait(1)
        initialize()
    end)
    
    return true
end

-- Add cleanup on game close
game:BindToClose(function()
    cleanupAllFallbackUIs()
end)

-- Initialize health check system
task.spawn(function()
    while true do
        performHealthCheck()
        task.wait(CONFIG.HEALTH_CHECK_INTERVAL)
    end
end)

-- Initialize on a slight delay to allow other systems to load first
task.spawn(function()
    task.wait(1) -- Wait 1 second before initializing to allow other systems to load
    initialize()
end)

return UISystemEnhancer
