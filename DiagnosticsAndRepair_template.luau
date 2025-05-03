local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Diagnostic functions for each category
local diagnostics = {
    TycoonStructure = function()
        local results = {
            status = "OK",
            issues = {}
        }
        
        -- Add your TycoonStructure diagnostic code here
        
        return results
    end,
    
    CoreRegistry = function()
        local results = {
            status = "OK",
            issues = {}
        }
        
        -- Add your CoreRegistry diagnostic code here
        
        return results
    end,
    
    DataPersistence = function()
        local results = {
            status = "OK",
            issues = {}
        }
        
        -- Add your DataPersistence diagnostic code here
        
        return results
    end,
    
    BuyTileSystem = function()
        local results = {
            status = "OK",
            issues = {}
        }
        
        -- Add your BuyTileSystem diagnostic code here
        
        return results
    end,
    
    FolderStructure = function()
        local results = {
            status = "OK",
            issues = {}
        }
        
        -- Check required folders
        local requiredFolders = {
            {parent = ReplicatedStorage, name = "shared"},
            {parent = ReplicatedStorage, name = "EventBridge"},
            {parent = ServerScriptService, name = "Core"},
            {parent = ServerScriptService, name = "Server"},
            {parent = ServerStorage, name = "GymParts"}
        }
        
        for _, folderInfo in ipairs(requiredFolders) do
            local folder = folderInfo.parent:FindFirstChild(folderInfo.name)
            if not folder then
                table.insert(results.issues, folderInfo.name .. " folder not found in " .. folderInfo.parent:GetFullName())
                results.status = "WARNING"
            elseif not folder:IsA("Folder") then
                table.insert(results.issues, folderInfo.name .. " in " .. folderInfo.parent:GetFullName() .. " is not a Folder")
                results.status = "ERROR"
            end
        end
        
        return results
    end
}

-- Repair functions for each category
local repairs = {
    CoreRegistry = function()
        -- Add your CoreRegistry repair code here
    end,
    
    DataPersistence = function()
        -- Add your DataPersistence repair code here
    end,
    
    BuyTileSystem = function()
        -- Add your BuyTileSystem repair code here
    end,
    
    TycoonStructure = function()
        -- Add your TycoonStructure repair code here
    end,
    
    FolderStructure = function()
        -- Add your FolderStructure repair code here
    end
}

-- Run all diagnostics and return results
local function runAllDiagnostics()
    local results = {}
    
    for name, diagFunc in pairs(diagnostics) do
        if typeof(diagFunc) == "function" then
            print("[DiagnosticsAndRepair] Running diagnostics: " .. name)
            results[name] = diagFunc()
        end
    end
    
    return results
end

-- Run a specific repair
local function runRepair(name)
    if repairs[name] and typeof(repairs[name]) == "function" then
        print("[DiagnosticsAndRepair] Running repair for: " .. name)
        return repairs[name]()
    else
        print("[DiagnosticsAndRepair] No repair available for: " .. name)
        return false
    end
end

-- Run all available repairs
local function repairAll()
    local results = {}
    
    for name, repairFunc in pairs(repairs) do
        if typeof(repairFunc) == "function" then
            print("[DiagnosticsAndRepair] Repairing: " .. name)
            results[name] = repairFunc()
        end
    end
    
    return results
end

-- Return the module
return {
    diagnostics = diagnostics,
    repairs = repairs,
    runAllDiagnostics = runAllDiagnostics,
    runRepair = runRepair,
    repairAll = repairAll
}
