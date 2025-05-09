--[[
    Folder Structure Analyzer
    
    This script analyzes and displays the current folder structure of the Roblox game.
    It provides a comprehensive overview of your project organization to help with
    reorganization planning.
    
    Run this as a ServerScript to see the output in the developer console.
]]

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Ensure this only runs in Studio
if not RunService:IsStudio() then return end

-- Locations to analyze
local locationsToAnalyze = {
    game.Workspace,
    game.ServerStorage,
    game.ReplicatedStorage,
    game.ServerScriptService,
    game.StarterGui,
    game.StarterPlayer,
    game.StarterPack,
    game.Lighting,
    game.ReplicatedFirst,
    game.SoundService
}

-- Configuration
local MAX_DEPTH = 10        -- Maximum depth to analyze
local IGNORE_NAMES = {      -- Instance names to ignore
    "Terrain",
    "Camera",
    "Baseplate"
}

local OUTPUT_TO_FILE = true -- Whether to output to a file in ServerStorage

-- Custom serialization function with limit options
local function serializeInstance(instance, depth, maxDepth, output, prefix)
    depth = depth or 0
    output = output or {}
    prefix = prefix or ""
    
    -- Check if we've reached max depth
    if depth > maxDepth then
        table.insert(output, prefix .. "...")
        return output
    end
    
    -- Skip ignored instances
    for _, ignoreName in ipairs(IGNORE_NAMES) do
        if instance.Name == ignoreName then
            return output
        end
    end
    
    -- Get instance name and class
    local className = instance.ClassName
    local name = instance.Name
    
    -- Format the line based on instance type
    local line = prefix .. name
    
    -- Add class type for specific instance types
    if className == "Script" or className == "LocalScript" or className == "ModuleScript" then
        line = line .. " [" .. className .. "]"
    end
    
    table.insert(output, line)
    
    -- Get children sorted alphabetically
    local children = {}
    for _, child in ipairs(instance:GetChildren()) do
        table.insert(children, child)
    end
    
    -- Sort alphabetically, but put folders first
    table.sort(children, function(a, b)
        local aIsFolder = a.ClassName == "Folder" or a.ClassName == "Model"
        local bIsFolder = b.ClassName == "Folder" or b.ClassName == "Model"
        
        if aIsFolder and not bIsFolder then
            return true
        elseif not aIsFolder and bIsFolder then
            return false
        else
            return a.Name:lower() < b.Name:lower()
        end
    end)
    
    -- Serialize children
    for _, child in ipairs(children) do
        serializeInstance(child, depth + 1, maxDepth, output, prefix .. "    ")
    end
    
    return output
end

-- Function to get module dependencies
local function getModuleDependencies(moduleScript)
    local dependencies = {}
    
    -- Try to require the module and analyze its source
    local success, result = pcall(function()
        -- Get the source code
        local source = moduleScript.Source
        
        -- Look for require statements using simple pattern matching
        for line in string.gmatch(source, "[^\r\n]+") do
            -- Match common require patterns
            local requirePath = string.match(line, "require%(([^%)]+)%)")
            if requirePath then
                table.insert(dependencies, requirePath)
            end
        end
        
        return dependencies
    end)
    
    if success then
        return result
    else
        return {"Error analyzing dependencies: " .. tostring(result)}
    end
end

-- Function to analyze scripts and their dependencies
local function analyzeScriptDependencies()
    local moduleScripts = {}
    local output = {"Script Dependency Analysis:", "========================"}
    
    -- Find all ModuleScripts in the game
    local function findModuleScripts(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("ModuleScript") then
                table.insert(moduleScripts, child)
            end
            findModuleScripts(child)
        end
    end
    
    for _, location in ipairs(locationsToAnalyze) do
        findModuleScripts(location)
    end
    
    -- Analyze each module script
    for _, module in ipairs(moduleScripts) do
        local fullPath = module:GetFullName()
        table.insert(output, "\n" .. fullPath)
        
        local dependencies = getModuleDependencies(module)
        if #dependencies > 0 then
            table.insert(output, "  Dependencies:")
            for _, dep in ipairs(dependencies) do
                table.insert(output, "    - " .. tostring(dep))
            end
        else
            table.insert(output, "  No dependencies found.")
        end
    end
    
    return output
end

-- Function to create a report
local function createStructureReport()
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local output = {
        "Project Structure Analysis Report",
        "Generated: " .. timestamp,
        "====================================",
        ""
    }
    
    -- Analyze each location
    for _, location in ipairs(locationsToAnalyze) do
        table.insert(output, "### " .. location.Name .. " ###")
        local locationOutput = serializeInstance(location, 0, MAX_DEPTH)
        for _, line in ipairs(locationOutput) do
            table.insert(output, line)
        end
        table.insert(output, "")
    end
    
    -- Add script dependency analysis
    local dependencyOutput = analyzeScriptDependencies()
    for _, line in ipairs(dependencyOutput) do
        table.insert(output, line)
    end
    
    return output
end

-- Function to output the report
local function outputReport(reportLines)
    -- Print to output
    for _, line in ipairs(reportLines) do
        print(line)
    end
    
    -- Save to file if enabled
    if OUTPUT_TO_FILE then
        local serverStorage = game:GetService("ServerStorage")
        
        -- Create a StringValue to store the report
        local reportValue = Instance.new("StringValue")
        reportValue.Name = "StructureReport_" .. os.date("%Y%m%d_%H%M%S")
        
        -- Join all lines
        reportValue.Value = table.concat(reportLines, "\n")
        
        -- Store in ServerStorage
        reportValue.Parent = serverStorage
        
        print("\nReport saved to ServerStorage/" .. reportValue.Name)
        
        -- Create a ModuleScript with JSON data for easier processing
        local jsonReport = Instance.new("ModuleScript")
        jsonReport.Name = "StructureReportData_" .. os.date("%Y%m%d_%H%M%S")
        
        -- Create a structured report
        local structuredReport = {}
        for _, location in ipairs(locationsToAnalyze) do
            structuredReport[location.Name] = {}
            
            local function processInstance(instance, parentTable)
                local instanceData = {
                    Name = instance.Name,
                    ClassName = instance.ClassName,
                    Children = {}
                }
                
                parentTable[instance.Name] = instanceData
                
                for _, child in ipairs(instance:GetChildren()) do
                    -- Skip ignored instances
                    local skip = false
                    for _, ignoreName in ipairs(IGNORE_NAMES) do
                        if child.Name == ignoreName then
                            skip = true
                            break
                        end
                    end
                    
                    if not skip then
                        processInstance(child, instanceData.Children)
                    end
                end
            end
            
            processInstance(location, structuredReport[location.Name])
        end
        
        -- Serialize to JSON
        local jsonData = HttpService:JSONEncode(structuredReport)
        jsonReport.Source = "return " .. jsonData
        jsonReport.Parent = serverStorage
        
        print("JSON data saved to ServerStorage/" .. jsonReport.Name)
    end
end

-- Run the analysis
local reportLines = createStructureReport()
outputReport(reportLines)

-- Create a separate script for statistics
local function createStatisticsReport()
    local stats = {
        ScriptCount = 0,
        LocalScriptCount = 0,
        ModuleScriptCount = 0,
        FolderCount = 0,
        ModelCount = 0,
        PartCount = 0,
        GuiCount = 0,
        TotalInstanceCount = 0
    }
    
    local function countInstances(parent)
        for _, child in ipairs(parent:GetChildren()) do
            stats.TotalInstanceCount = stats.TotalInstanceCount + 1
            
            if child:IsA("Script") then
                stats.ScriptCount = stats.ScriptCount + 1
            elseif child:IsA("LocalScript") then
                stats.LocalScriptCount = stats.LocalScriptCount + 1
            elseif child:IsA("ModuleScript") then
                stats.ModuleScriptCount = stats.ModuleScriptCount + 1
            elseif child:IsA("Folder") then
                stats.FolderCount = stats.FolderCount + 1
            elseif child:IsA("Model") then
                stats.ModelCount = stats.ModelCount + 1
            elseif child:IsA("BasePart") then
                stats.PartCount = stats.PartCount + 1
            elseif child:IsA("GuiObject") then
                stats.GuiCount = stats.GuiCount + 1
            end
            
            countInstances(child)
        end
    end
    
    for _, location in ipairs(locationsToAnalyze) do
        countInstances(location)
    end
    
    -- Output statistics
    local output = {
        "## Project Statistics ##",
        "Total Instances: " .. stats.TotalInstanceCount,
        "Scripts: " .. stats.ScriptCount,
        "LocalScripts: " .. stats.LocalScriptCount,
        "ModuleScripts: " .. stats.ModuleScriptCount,
        "Folders: " .. stats.FolderCount,
        "Models: " .. stats.ModelCount,
        "Parts: " .. stats.PartCount,
        "GUI Elements: " .. stats.GuiCount
    }
    
    for _, line in ipairs(output) do
        print(line)
    end
    
    if OUTPUT_TO_FILE then
        local serverStorage = game:GetService("ServerStorage")
        
        local statsValue = Instance.new("StringValue")
        statsValue.Name = "StructureStats_" .. os.date("%Y%m%d_%H%M%S")
        statsValue.Value = table.concat(output, "\n")
        statsValue.Parent = serverStorage
        
        print("\nStatistics saved to ServerStorage/" .. statsValue.Name)
    end
end

-- Run statistics report after a slight delay
task.spawn(function()
    wait(1)
    createStatisticsReport()
end)

print("Folder structure analysis complete! Check the output above.")
