--[[
    WaitForChildFinder.luau
    
    A tool to find unsafe WaitForChild calls in the current Roblox place.
    This helps identify potential infinite yield issues and suggests replacements
    using the SafeWaitForChild utility.
    
    Created: April 26, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

-- Configuration
local DEFAULT_TIMEOUT = 5

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WaitForChildFinderUI"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 600, 0, 400)
mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local cornerRadius = Instance.new("UICorner")
cornerRadius.CornerRadius = UDim.new(0, 8)
cornerRadius.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Name = "TitleText"
titleText.Size = UDim2.new(1, 0, 1, 0)
titleText.BackgroundTransparency = 1
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 18
titleText.TextColor3 = Color3.fromRGB(240, 240, 255)
titleText.Text = "WaitForChild Finder"
titleText.Parent = titleBar

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(240, 240, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.Parent = titleBar

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = closeButton

local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -20, 1, -60)
contentFrame.Position = UDim2.new(0, 10, 0, 50)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local statusText = Instance.new("TextLabel")
statusText.Name = "StatusText"
statusText.Size = UDim2.new(1, 0, 0, 30)
statusText.BackgroundTransparency = 1
statusText.Font = Enum.Font.Gotham
statusText.TextSize = 14
statusText.TextColor3 = Color3.fromRGB(240, 240, 255)
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Text = "Status: Ready to scan"
statusText.Parent = contentFrame

local startButton = Instance.new("TextButton")
startButton.Name = "StartButton"
startButton.Size = UDim2.new(0, 150, 0, 40)
startButton.Position = UDim2.new(0, 0, 0, 40)
startButton.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
startButton.Text = "Start Scan"
startButton.TextColor3 = Color3.fromRGB(240, 240, 255)
startButton.Font = Enum.Font.GothamBold
startButton.TextSize = 16
startButton.Parent = contentFrame

local buttonStartCorner = Instance.new("UICorner")
buttonStartCorner.CornerRadius = UDim.new(0, 8)
buttonStartCorner.Parent = startButton

local timeoutLabel = Instance.new("TextLabel")
timeoutLabel.Name = "TimeoutLabel"
timeoutLabel.Size = UDim2.new(0, 170, 0, 30)
timeoutLabel.Position = UDim2.new(0, 170, 0, 45)
timeoutLabel.BackgroundTransparency = 1
timeoutLabel.Font = Enum.Font.Gotham
timeoutLabel.TextSize = 14
timeoutLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
timeoutLabel.TextXAlignment = Enum.TextXAlignment.Left
timeoutLabel.Text = "Default Timeout (s):"
timeoutLabel.Parent = contentFrame

local timeoutInput = Instance.new("TextBox")
timeoutInput.Name = "TimeoutInput"
timeoutInput.Size = UDim2.new(0, 60, 0, 30)
timeoutInput.Position = UDim2.new(0, 350, 0, 45)
timeoutInput.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
timeoutInput.TextColor3 = Color3.fromRGB(240, 240, 255)
timeoutInput.Font = Enum.Font.Gotham
timeoutInput.TextSize = 14
timeoutInput.Text = tostring(DEFAULT_TIMEOUT)
timeoutInput.Parent = contentFrame

local timeoutCorner = Instance.new("UICorner")
timeoutCorner.CornerRadius = UDim.new(0, 4)
timeoutCorner.Parent = timeoutInput

local resultsLabel = Instance.new("TextLabel")
resultsLabel.Name = "ResultsLabel"
resultsLabel.Size = UDim2.new(1, 0, 0, 30)
resultsLabel.Position = UDim2.new(0, 0, 0, 90)
resultsLabel.BackgroundTransparency = 1
resultsLabel.Font = Enum.Font.GothamBold
resultsLabel.TextSize = 16
resultsLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
resultsLabel.TextXAlignment = Enum.TextXAlignment.Left
resultsLabel.Text = "Results:"
resultsLabel.Parent = contentFrame

local resultsScrollFrame = Instance.new("ScrollingFrame")
resultsScrollFrame.Name = "ResultsScrollFrame"
resultsScrollFrame.Size = UDim2.new(1, 0, 1, -130)
resultsScrollFrame.Position = UDim2.new(0, 0, 0, 120)
resultsScrollFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
resultsScrollFrame.BorderSizePixel = 0
resultsScrollFrame.ScrollBarThickness = 8
resultsScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
resultsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
resultsScrollFrame.Parent = contentFrame

local resultsPadding = Instance.new("UIPadding")
resultsPadding.PaddingLeft = UDim.new(0, 10)
resultsPadding.PaddingRight = UDim.new(0, 10)
resultsPadding.PaddingTop = UDim.new(0, 10)
resultsPadding.PaddingBottom = UDim.new(0, 10)
resultsPadding.Parent = resultsScrollFrame

local resultsLayout = Instance.new("UIListLayout")
resultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
resultsLayout.Padding = UDim.new(0, 5)
resultsLayout.Parent = resultsScrollFrame

local resultsCorner = Instance.new("UICorner")
resultsCorner.CornerRadius = UDim.new(0, 8)
resultsCorner.Parent = resultsScrollFrame

-- Tracking variables
local isScanning = false
local scanResults = {
    totalScripts = 0,
    scriptsWithIssues = 0,
    totalIssues = 0,
    issues = {}
}

-- Create a result item for the UI
local function createResultItem(scriptName, lineNumber, code, suggestion)
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = "ResultItem"
    itemFrame.Size = UDim2.new(1, 0, 0, 80)
    itemFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    itemFrame.BorderSizePixel = 0
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 4)
    itemCorner.Parent = itemFrame
    
    local scriptLabel = Instance.new("TextLabel")
    scriptLabel.Name = "ScriptLabel"
    scriptLabel.Size = UDim2.new(1, -20, 0, 20)
    scriptLabel.Position = UDim2.new(0, 10, 0, 5)
    scriptLabel.BackgroundTransparency = 1
    scriptLabel.Font = Enum.Font.GothamBold
    scriptLabel.TextSize = 14
    scriptLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
    scriptLabel.TextXAlignment = Enum.TextXAlignment.Left
    scriptLabel.Text = scriptName .. " (Line " .. lineNumber .. ")"
    scriptLabel.Parent = itemFrame
    
    local codeLabel = Instance.new("TextLabel")
    codeLabel.Name = "CodeLabel"
    codeLabel.Size = UDim2.new(1, -20, 0, 20)
    codeLabel.Position = UDim2.new(0, 10, 0, 25)
    codeLabel.BackgroundTransparency = 1
    codeLabel.Font = Enum.Font.Code
    codeLabel.TextSize = 12
    codeLabel.TextColor3 = Color3.fromRGB(255, 200, 120)
    codeLabel.TextXAlignment = Enum.TextXAlignment.Left
    codeLabel.Text = code
    codeLabel.Parent = itemFrame
    
    local suggestionLabel = Instance.new("TextLabel")
    suggestionLabel.Name = "SuggestionLabel"
    suggestionLabel.Size = UDim2.new(1, -20, 0, 20)
    suggestionLabel.Position = UDim2.new(0, 10, 0, 45)
    suggestionLabel.BackgroundTransparency = 1
    suggestionLabel.Font = Enum.Font.Code
    suggestionLabel.TextSize = 12
    suggestionLabel.TextColor3 = Color3.fromRGB(120, 220, 120)
    suggestionLabel.TextXAlignment = Enum.TextXAlignment.Left
    suggestionLabel.Text = suggestion
    suggestionLabel.Parent = itemFrame
    
    return itemFrame
end

-- Analyze a script for WaitForChild issues
local function analyzeScript(script)
    local issues = {}
    
    -- Get script source (only works in Studio)
    local success, source = pcall(function()
        return script.Source
    end)
    
    if not success or not source then
        return issues
    end
    
    -- Process line by line
    local lineNumber = 1
    for line in source:gmatch("[^\r\n]+") do
        -- Look for WaitForChild patterns
        for parent, childName in line:gmatch("([%w%.:_]+)%s*:%s*WaitForChild%s*%(") do
            -- Extract child name inside quotes
            local childNameMatch = line:match("WaitForChild%s*%(%s*[\"']([^\"']+)[\"']")
            if childNameMatch then
                local timeout = line:match("WaitForChild%s*%(%s*[^,]+,%s*(%d+)")
                local suggestion = "local SafeWaitForChild = require(ReplicatedStorage.shared.SafeWaitForChild)\n"
                
                if childNameMatch:find("%.") then
                    suggestion = suggestion .. "local result = SafeWaitForChild.waitForDescendant(" 
                        .. parent .. ", \"" .. childNameMatch .. "\"" 
                        .. (timeout and (", " .. timeout) or "") .. ")"
                else
                    suggestion = suggestion .. "local result = SafeWaitForChild.waitForChild(" 
                        .. parent .. ", \"" .. childNameMatch .. "\"" 
                        .. (timeout and (", " .. timeout) or "") .. ")"
                end
                
                table.insert(issues, {
                    line = lineNumber,
                    code = line:gsub("^%s+", ""),
                    parent = parent,
                    childName = childNameMatch,
                    timeout = timeout,
                    suggestion = suggestion
                })
            end
        end
        
        lineNumber = lineNumber + 1
    end
    
    return issues
end

-- Scan instance and its descendants recursively
local function scanInstance(instance, results)
    -- Check if this is a script
    if instance:IsA("LuaSourceContainer") then
        results.totalScripts = results.totalScripts + 1
        
        local scriptIssues = analyzeScript(instance)
        
        if #scriptIssues > 0 then
            results.scriptsWithIssues = results.scriptsWithIssues + 1
            results.totalIssues = results.totalIssues + #scriptIssues
            
            results.issues[instance:GetFullName()] = scriptIssues
        end
    end
    
    -- Process children
    for _, child in ipairs(instance:GetChildren()) do
        scanInstance(child, results)
    end
end

-- Clear results UI
local function clearResults()
    for _, child in ipairs(resultsScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
end

-- Display results in the UI
local function displayResults(results)
    clearResults()
    
    -- Add summary
    local summaryFrame = Instance.new("Frame")
    summaryFrame.Name = "SummaryFrame"
    summaryFrame.Size = UDim2.new(1, 0, 0, 60)
    summaryFrame.BackgroundColor3 = Color3.fromRGB(40, 70, 100)
    summaryFrame.BorderSizePixel = 0
    
    local summaryCorner = Instance.new("UICorner")
    summaryCorner.CornerRadius = UDim.new(0, 4)
    summaryCorner.Parent = summaryFrame
    
    local summaryText = Instance.new("TextLabel")
    summaryText.Name = "SummaryText"
    summaryText.Size = UDim2.new(1, -20, 1, 0)
    summaryText.Position = UDim2.new(0, 10, 0, 0)
    summaryText.BackgroundTransparency = 1
    summaryText.Font = Enum.Font.Gotham
    summaryText.TextSize = 14
    summaryText.TextColor3 = Color3.fromRGB(240, 240, 255)
    summaryText.TextXAlignment = Enum.TextXAlignment.Left
    summaryText.TextYAlignment = Enum.TextYAlignment.Center
    summaryText.Text = "Total Scripts: " .. results.totalScripts 
        .. "\nScripts with Issues: " .. results.scriptsWithIssues
        .. "\nTotal Issues: " .. results.totalIssues
    summaryText.Parent = summaryFrame
    
    summaryFrame.Parent = resultsScrollFrame
    
    -- Add each issue
    for scriptPath, issues in pairs(results.issues) do
        local scriptHeader = Instance.new("TextLabel")
        scriptHeader.Name = "ScriptHeader"
        scriptHeader.Size = UDim2.new(1, 0, 0, 30)
        scriptHeader.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        scriptHeader.Font = Enum.Font.GothamBold
        scriptHeader.TextSize = 14
        scriptHeader.TextColor3 = Color3.fromRGB(240, 240, 255)
        scriptHeader.TextXAlignment = Enum.TextXAlignment.Left
        scriptHeader.Text = "  " .. scriptPath .. " (" .. #issues .. " issues)"
        
        local headerCorner = Instance.new("UICorner")
        headerCorner.CornerRadius = UDim.new(0, 4)
        headerCorner.Parent = scriptHeader
        
        scriptHeader.Parent = resultsScrollFrame
        
        for _, issue in ipairs(issues) do
            local resultItem = createResultItem(
                scriptPath,
                issue.line,
                issue.code,
                issue.suggestion
            )
            
            resultItem.Parent = resultsScrollFrame
        end
        
        -- Add spacing
        local spacer = Instance.new("Frame")
        spacer.Name = "Spacer"
        spacer.Size = UDim2.new(1, 0, 0, 10)
        spacer.BackgroundTransparency = 1
        spacer.Parent = resultsScrollFrame
    end
    
    if results.totalIssues == 0 then
        local noIssuesLabel = Instance.new("TextLabel")
        noIssuesLabel.Name = "NoIssuesLabel"
        noIssuesLabel.Size = UDim2.new(1, 0, 0, 40)
        noIssuesLabel.BackgroundTransparency = 0.5
        noIssuesLabel.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
        noIssuesLabel.Font = Enum.Font.Gotham
        noIssuesLabel.TextSize = 16
        noIssuesLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
        noIssuesLabel.Text = "No issues found!"
        
        local noIssuesCorner = Instance.new("UICorner")
        noIssuesCorner.CornerRadius = UDim.new(0, 4)
        noIssuesCorner.Parent = noIssuesLabel
        
        noIssuesLabel.Parent = resultsScrollFrame
    end
    
    -- Add recommendation header
    local recommendHeader = Instance.new("TextLabel")
    recommendHeader.Name = "RecommendHeader"
    recommendHeader.Size = UDim2.new(1, 0, 0, 30)
    recommendHeader.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
    recommendHeader.Font = Enum.Font.GothamBold
    recommendHeader.TextSize = 14
    recommendHeader.TextColor3 = Color3.fromRGB(240, 240, 255)
    recommendHeader.TextXAlignment = Enum.TextXAlignment.Left
    recommendHeader.Text = "  Recommended Actions"
    
    local recHeaderCorner = Instance.new("UICorner")
    recHeaderCorner.CornerRadius = UDim.new(0, 4)
    recHeaderCorner.Parent = recommendHeader
    
    recommendHeader.Parent = resultsScrollFrame
    
    -- Add recommendations
    local recommendations = Instance.new("TextLabel")
    recommendations.Name = "Recommendations"
    recommendations.Size = UDim2.new(1, 0, 0, 120)
    recommendations.BackgroundColor3 = Color3.fromRGB(60, 80, 60)
    recommendations.Font = Enum.Font.Gotham
    recommendations.TextSize = 14
    recommendations.TextColor3 = Color3.fromRGB(240, 240, 255)
    recommendations.TextXAlignment = Enum.TextXAlignment.Left
    recommendations.TextYAlignment = Enum.TextYAlignment.Top
    recommendations.TextWrapped = true
    recommendations.Text = "1. Make sure SafeWaitForChild module exists in ReplicatedStorage.shared\n"
        .. "2. Replace all unsafe WaitForChild calls with SafeWaitForChild.waitForChild\n"
        .. "3. Add proper error handling for cases where children might not exist\n"
        .. "4. Use waitForDescendant for multi-level paths like 'a.b.c'\n"
        .. "5. Set appropriate timeout values for critical vs non-critical components"
    
    local recCorner = Instance.new("UICorner")
    recCorner.CornerRadius = UDim.new(0, 4)
    recCorner.Parent = recommendations
    
    local recPadding = Instance.new("UIPadding")
    recPadding.PaddingLeft = UDim.new(0, 10)
    recPadding.PaddingRight = UDim.new(0, 10)
    recPadding.PaddingTop = UDim.new(0, 10)
    recPadding.PaddingBottom = UDim.new(0, 10)
    recPadding.Parent = recommendations
    
    recommendations.Parent = resultsScrollFrame
end

-- Start the scan
local function startScan()
    if isScanning then return end
    isScanning = true
    
    statusText.Text = "Status: Scanning..."
    clearResults()
    
    -- Reset results
    scanResults = {
        totalScripts = 0,
        scriptsWithIssues = 0,
        totalIssues = 0,
        issues = {}
    }
    
    -- Get the timeout value
    local timeout = tonumber(timeoutInput.Text) or DEFAULT_TIMEOUT
    DEFAULT_TIMEOUT = timeout
    
    -- Perform the scan asynchronously
    task.spawn(function()
        -- Scan main services
        scanInstance(game, scanResults)
        
        -- Update status and display results
        statusText.Text = "Status: Scan complete. Found " .. scanResults.totalIssues .. " issues."
        displayResults(scanResults)
        isScanning = false
    end)
end

-- Connect UI events
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

startButton.MouseButton1Click:Connect(startScan)

-- Game.Players returns an empty array in Studio when not playing
-- so use pcall to handle this case
pcall(function()
    local player = game.Players.LocalPlayer
    if player then
        screenGui.Parent = player.PlayerGui
    else
        screenGui.Parent = game:GetService("StarterGui")
    end
end)

return screenGui
