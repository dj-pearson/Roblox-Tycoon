--[[
    Project Dependencies Visualizer
    
    This script will help you visualize the dependencies between modules in your project.
    It creates a visual representation of module relationships to help you understand
    the project structure and identify potential refactoring opportunities.
    
    Run this as a ServerScript in Studio to see the output in the developer console.
]]

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Configuration
local OUTPUT_GRAPH = true    -- Whether to generate a visual graph representation
local INCLUDE_ALL_MODULES = true  -- Whether to include all modules or just key ones
local FOCUS_ON_DATASTORE = true   -- Whether to focus specifically on DataStore modules

-- Key modules to focus on if not including all
local KEY_MODULE_PATTERNS = {
    "DataStore",
    "Core",
    "Registry",
    "Manager",
    "Controller",
    "Service"
}

-- Colors for different module types
local COLORS = {
    DATASTORE = "#ff9900",  -- Orange
    CORE = "#ff0000",       -- Red
    SERVICE = "#00aaff",    -- Blue
    CONTROLLER = "#00ff00", -- Green
    UI = "#aa00ff",         -- Purple
    DEFAULT = "#aaaaaa"     -- Gray
}

-- Function to determine the color of a module based on its name
local function getModuleColor(moduleName)
    if not moduleName then return COLORS.DEFAULT end
    
    moduleName = string.lower(moduleName)
    
    if string.find(moduleName, "datastore") then
        return COLORS.DATASTORE
    elseif string.find(moduleName, "core") or string.find(moduleName, "registry") then
        return COLORS.CORE
    elseif string.find(moduleName, "service") then
        return COLORS.SERVICE
    elseif string.find(moduleName, "controller") or string.find(moduleName, "manager") then
        return COLORS.CONTROLLER
    elseif string.find(moduleName, "ui") or string.find(moduleName, "gui") then
        return COLORS.UI
    else
        return COLORS.DEFAULT
    end
end

-- Function to scan all ModuleScripts in the game
local function analyzeProjectDependencies()
    local output = {
        "Project Dependencies Analysis",
        "============================="
    }
    
    -- Find all module scripts in the game
    local moduleScripts = {}
    local dependencies = {}
    
    local function findModuleScripts(parent, basePath)
        basePath = basePath or ""
        
        for _, child in ipairs(parent:GetChildren()) do
            local path = basePath .. (basePath ~= "" and "/" or "") .. child.Name
            
            if child:IsA("ModuleScript") then
                local shouldInclude = INCLUDE_ALL_MODULES
                
                if not shouldInclude and FOCUS_ON_DATASTORE then
                    shouldInclude = string.find(string.lower(path), "datastore") ~= nil
                end
                
                if not shouldInclude then
                    for _, pattern in ipairs(KEY_MODULE_PATTERNS) do
                        if string.find(string.lower(path), string.lower(pattern)) then
                            shouldInclude = true
                            break
                        end
                    end
                end
                
                if shouldInclude then
                    table.insert(moduleScripts, {
                        Path = path,
                        Name = child.Name,
                        Instance = child
                    })
                end
            end
            
            findModuleScripts(child, path)
        end
    end
    
    -- Locations to search
    local locations = {
        game:GetService("ReplicatedStorage"),
        game:GetService("ServerStorage"),
        game:GetService("ServerScriptService")
    }
    
    for _, location in ipairs(locations) do
        findModuleScripts(location, location.Name)
    end
    
    table.insert(output, "Found " .. #moduleScripts .. " module scripts to analyze")
      -- Analyze dependencies
    for _, module in ipairs(moduleScripts) do
        local source
        local success, err = pcall(function()
            source = module.Instance.Source
            return true
        end)
        
        if not success then
            print("Warning: Could not get source for module " .. module.Path .. ": " .. tostring(err))
            source = ""
        end
        
        local moduleDependencies = {}
        
    -- Look for require statements
        for line in string.gmatch(source or "", "[^\r\n]+") do
            -- Match require patterns
            local requirePath = string.match(line, "require%(([^%)]+)%)")
            if requirePath then
                table.insert(moduleDependencies, requirePath)
            end
        end
        
        dependencies[module.Path] = {
            RawDependencies = moduleDependencies,
            ResolvedDependencies = {}
        }
    end
    
    -- Resolve dependencies to actual module paths
    for modulePath, deps in pairs(dependencies) do
        for _, rawDep in ipairs(deps.RawDependencies) do
            -- Try to resolve the dependency to an actual module
            for _, module in ipairs(moduleScripts) do
                if string.find(rawDep, module.Name, 1, true) then
                    table.insert(deps.ResolvedDependencies, module.Path)
                    break
                end
            end
        end
    end
    
    -- Output text representation
    table.insert(output, "")
    table.insert(output, "Module Dependencies:")
    table.insert(output, "------------------")
    
    for _, module in ipairs(moduleScripts) do
        table.insert(output, module.Path)
        
        local deps = dependencies[module.Path]
        if deps and #deps.ResolvedDependencies > 0 then
            table.insert(output, "  Dependencies:")
            for _, dep in ipairs(deps.ResolvedDependencies) do
                table.insert(output, "    - " .. dep)
            end
        else
            table.insert(output, "  No dependencies found.")
        end
    end
    
    -- Generate graph representation
    if OUTPUT_GRAPH then
        local graphData = {
            nodes = {},
            edges = {}
        }
          -- Add nodes
        for _, module in ipairs(moduleScripts) do
            local moduleName = module.Name or "Unknown"
            table.insert(graphData.nodes, {
                id = module.Path or ("Unknown_" .. tostring(#graphData.nodes + 1)),
                label = moduleName,
                color = getModuleColor(moduleName)
            })
        end
        
        -- Add edges
        for modulePath, deps in pairs(dependencies) do
            for _, dep in ipairs(deps.ResolvedDependencies) do
                table.insert(graphData.edges, {
                    from = modulePath,
                    to = dep
                })
            end
        end
        
        -- Convert to DOT format for visualization
        local dotGraph = "digraph ProjectStructure {\n"
        dotGraph = dotGraph .. "  graph [rankdir=LR];\n"
          -- Add nodes
        for _, node in ipairs(graphData.nodes) do
            local color = string.sub(node.color, 2) -- Remove # from color
            dotGraph = dotGraph .. '  "' .. node.id .. '" [label="' .. node.label .. '", style=filled, fillcolor="#' .. color .. '"];\n'
        end
        
        -- Add edges
        for _, edge in ipairs(graphData.edges) do
            dotGraph = dotGraph .. '  "' .. edge.from .. '" -> "' .. edge.to .. '";\n'
        end
        
        dotGraph = dotGraph .. "}\n"
        
        -- Create an instructions file for using the graph
        local instructions = [[
To visualize the project dependencies graph:

1. Copy the DOT graph data saved in ServerStorage
2. Visit https://dreampuf.github.io/GraphvizOnline/ or any other online Graphviz tool
3. Paste the graph data and visualize

Alternatively, you can use the Graphviz software locally if installed:
1. Save the DOT data to a file with .dot extension
2. Run: dot -Tpng graph.dot -o project_structure.png

Color Legend:
- Orange: DataStore modules
- Red: Core/Registry modules
- Blue: Service modules
- Green: Controller/Manager modules
- Purple: UI modules
- Gray: Other modules
]]
          -- Save to ServerStorage
        local success, err = pcall(function()
            local serverStorage = game:GetService("ServerStorage")
            
            -- Save DOT graph
            local graphValue = Instance.new("StringValue")
            graphValue.Name = "ProjectGraph_DOT_" .. os.date("%Y%m%d_%H%M%S")
            graphValue.Value = dotGraph
            graphValue.Parent = serverStorage
            
            -- Save instructions
            local instructionsValue = Instance.new("StringValue")
            instructionsValue.Name = "GraphVisualization_Instructions"
            instructionsValue.Value = instructions
            instructionsValue.Parent = serverStorage
            
            table.insert(output, "")
            table.insert(output, "Graph visualization data saved to ServerStorage/" .. graphValue.Name)
            table.insert(output, "Follow instructions in ServerStorage/GraphVisualization_Instructions to visualize")
        end)
        
        if not success then
            table.insert(output, "")
            table.insert(output, "Warning: Failed to save graph data to ServerStorage: " .. tostring(err))
        end
    end
    
    return output, moduleScripts, dependencies
end

-- Function to analyze dependency clusters
local function analyzeModuleClusters(moduleScripts, dependencies)
    local output = {
        "Module Cluster Analysis",
        "======================="
    }
    
    -- Create a graph representation for cluster analysis
    local graph = {}
    for _, module in ipairs(moduleScripts) do
        graph[module.Path] = {}
    end
    
    for modulePath, deps in pairs(dependencies) do
        graph[modulePath] = deps.ResolvedDependencies
    end
    
    -- Find strongly connected components (clusters)
    local clusters = {}
    local visited = {}
    
    local function dfs(node, currentCluster)
        if visited[node] then return end
        
        visited[node] = true
        table.insert(currentCluster, node)
        
        for _, neighbor in ipairs(graph[node] or {}) do
            dfs(neighbor, currentCluster)
        end
    end
    
    -- Find clusters
    for node, _ in pairs(graph) do
        if not visited[node] then
            local cluster = {}
            dfs(node, cluster)
            
            if #cluster > 1 then
                table.insert(clusters, cluster)
            end
        end
    end
    
    -- Sort clusters by size
    table.sort(clusters, function(a, b)
        return #a > #b
    end)
    
    -- Output clusters
    table.insert(output, "")
    table.insert(output, "Found " .. #clusters .. " module clusters")
    
    for i, cluster in ipairs(clusters) do
        table.insert(output, "")
        table.insert(output, "Cluster " .. i .. " (" .. #cluster .. " modules):")
        
        -- Categorize modules in cluster
        local categories = {}
        
        for _, modulePath in ipairs(cluster) do
            local moduleName = string.match(modulePath, "[^/]+$") or modulePath
            
            local category = "Other"
            
            if string.find(string.lower(moduleName), "datastore") then
                category = "DataStore"
            elseif string.find(string.lower(moduleName), "core") then
                category = "Core"
            elseif string.find(string.lower(moduleName), "service") then
                category = "Service"
            elseif string.find(string.lower(moduleName), "controller") then
                category = "Controller"
            elseif string.find(string.lower(moduleName), "ui") or string.find(string.lower(moduleName), "gui") then
                category = "UI"
            end
            
            categories[category] = categories[category] or {}
            table.insert(categories[category], modulePath)
        end
        
        -- Output by category
        for category, modules in pairs(categories) do
            table.insert(output, "  " .. category .. " (" .. #modules .. "):")
            
            for _, modulePath in ipairs(modules) do
                table.insert(output, "    - " .. modulePath)
            end
        end
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
    local success, err = pcall(function()
        local serverStorage = game:GetService("ServerStorage")
        
        -- Create a StringValue to store the report
        local reportValue = Instance.new("StringValue")
        reportValue.Name = "DependencyAnalysisReport_" .. os.date("%Y%m%d_%H%M%S")
        
        -- Join all lines
        reportValue.Value = table.concat(reportLines, "\n")
        
        -- Store in ServerStorage
        reportValue.Parent = serverStorage
        
        print("\nReport saved to ServerStorage/" .. reportValue.Name)
    end)
    
    if not success then
        print("Warning: Failed to save report to ServerStorage: " .. tostring(err))
    end
end

-- Run the analysis
local reportLines, moduleScripts, dependencies = analyzeProjectDependencies()

-- Run cluster analysis
local clusterOutput = analyzeModuleClusters(moduleScripts, dependencies)

-- Add cluster analysis to main report
for _, line in ipairs(clusterOutput) do
    table.insert(reportLines, line)
end

-- Output the combined report
outputReport(reportLines)

print("Project dependencies analysis complete! Check the output above.")
