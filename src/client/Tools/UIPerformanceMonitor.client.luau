--!strict
--[[
    UIPerformanceMonitor.client.luau
    
    A tool to measure UI performance metrics before and after script elimination.
    This will help quantify the improvements from removing redundant UI scripts.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

-- Get UI toggle system
local UIToggleSystem = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UIToggleSystem"))

-- Configure monitoring
local config = {
    enabled = true,
    logInterval = 10, -- Log metrics every 10 seconds
    sampleSize = 30,  -- Number of frames to sample for each metric
    saveResults = true -- Save results to a log
}

-- Performance metrics
local metrics = {
    fps = {},
    memory = {},
    renderTime = {},
    scriptTime = {},
    uiCount = {}
}

-- Current sample data
local currentSamples = {
    fps = {},
    memory = {},
    renderTime = {},
    scriptTime = {},
}

-- Results log
local resultsLog = {
    timestamp = os.time(),
    uiSystem = "Unknown",
    averages = {},
    samples = {}
}

-- Calculate metrics
local function calculateMetrics()
    local function average(t)
        local sum = 0
        for _, v in ipairs(t) do
            sum = sum + v
        end
        return #t > 0 and (sum / #t) or 0
    end
    
    -- Calculate averages
    metrics.fps[#metrics.fps + 1] = average(currentSamples.fps)
    metrics.memory[#metrics.memory + 1] = average(currentSamples.memory)
    metrics.renderTime[#metrics.renderTime + 1] = average(currentSamples.renderTime)
    metrics.scriptTime[#metrics.scriptTime + 1] = average(currentSamples.scriptTime)
    
    -- Count UI elements
    local guiObjects = 0
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player:FindFirstChild("PlayerGui") then
            local function countGuiObjects(parent)
                local count = 0
                for _, child in ipairs(parent:GetChildren()) do
                    if child:IsA("GuiObject") then
                        count = count + 1
                    end
                    count = count + countGuiObjects(child)
                end
                return count
            end
            guiObjects = guiObjects + countGuiObjects(player.PlayerGui)
        end
    end
    metrics.uiCount[#metrics.uiCount + 1] = guiObjects
    
    -- Reset current samples
    currentSamples = {
        fps = {},
        memory = {},
        renderTime = {},
        scriptTime = {},
    }
    
    -- Log the current metrics
    print("==== UI PERFORMANCE METRICS ====")
    print("UI System: " .. (UIToggleSystem.shouldUseNewUI() and "NEW" or "OLD"))
    print("FPS: " .. string.format("%.2f", metrics.fps[#metrics.fps]))
    print("Memory (MB): " .. string.format("%.2f", metrics.memory[#metrics.memory] / 1024 / 1024))
    print("Render Time (ms): " .. string.format("%.2f", metrics.renderTime[#metrics.renderTime] * 1000))
    print("Script Time (ms): " .. string.format("%.2f", metrics.scriptTime[#metrics.scriptTime] * 1000))
    print("UI Object Count: " .. metrics.uiCount[#metrics.uiCount])
    print("===============================")
    
    -- Add to results log
    resultsLog.uiSystem = UIToggleSystem.shouldUseNewUI() and "NEW" or "OLD"
    resultsLog.samples[#resultsLog.samples + 1] = {
        timestamp = os.time(),
        fps = metrics.fps[#metrics.fps],
        memory = metrics.memory[#metrics.memory],
        renderTime = metrics.renderTime[#metrics.renderTime],
        scriptTime = metrics.scriptTime[#metrics.scriptTime],
        uiCount = metrics.uiCount[#metrics.uiCount]
    }
end

-- Sample performance metrics each frame
local function sampleMetrics()
    -- Sample FPS
    currentSamples.fps[#currentSamples.fps + 1] = 1 / RunService.RenderStepped:Wait()
    
    -- Sample memory
    currentSamples.memory[#currentSamples.memory + 1] = Stats:GetTotalMemoryUsageMb() * 1024 * 1024
    
    -- Sample render time
    currentSamples.renderTime[#currentSamples.renderTime + 1] = Stats.RenderStep:GetValue() / 1000
    
    -- Sample script time
    currentSamples.scriptTime[#currentSamples.scriptTime + 1] = Stats.LuaStep:GetValue() / 1000
    
    -- If we have enough samples, calculate metrics
    if #currentSamples.fps >= config.sampleSize then
        calculateMetrics()
    end
end

-- Function to calculate final averages
local function calculateFinalAverages()
    local function average(t)
        local sum = 0
        for _, v in ipairs(t) do
            sum = sum + v
        end
        return #t > 0 and (sum / #t) or 0
    end
    
    resultsLog.averages = {
        fps = average(metrics.fps),
        memory = average(metrics.memory),
        renderTime = average(metrics.renderTime),
        scriptTime = average(metrics.scriptTime),
        uiCount = average(metrics.uiCount)
    }
    
    print("====== FINAL UI PERFORMANCE AVERAGES ======")
    print("UI System: " .. resultsLog.uiSystem)
    print("Average FPS: " .. string.format("%.2f", resultsLog.averages.fps))
    print("Average Memory (MB): " .. string.format("%.2f", resultsLog.averages.memory / 1024 / 1024))
    print("Average Render Time (ms): " .. string.format("%.2f", resultsLog.averages.renderTime * 1000))
    print("Average Script Time (ms): " .. string.format("%.2f", resultsLog.averages.scriptTime * 1000))
    print("Average UI Object Count: " .. string.format("%.2f", resultsLog.averages.uiCount))
    print("===========================================")
end

-- Start monitoring
if config.enabled then
    print("UI Performance Monitor started")
    
    -- Sample every frame
    RunService.RenderStepped:Connect(sampleMetrics)
    
    -- Log at intervals
    spawn(function()
        while true do
            wait(config.logInterval)
            if #currentSamples.fps >= config.sampleSize then
                calculateMetrics()
            end
        end
    end)
    
    -- Calculate final averages when player leaves
    game:GetService("Players").LocalPlayer.AncestryChanged:Connect(function()
        if not game:GetService("Players").LocalPlayer:IsDescendantOf(game) then
            calculateFinalAverages()
        end
    end)
end

return {
    startMonitoring = function()
        config.enabled = true
        print("UI Performance Monitor enabled")
    end,
    
    stopMonitoring = function()
        config.enabled = false
        calculateFinalAverages()
        print("UI Performance Monitor disabled")
    end,
    
    getResults = function()
        return resultsLog
    end
}
