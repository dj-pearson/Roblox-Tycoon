--!strict
--[[
    UIScriptFinder.server.luau
    
    A diagnostic tool to help find UI-related scripts in the game.
    This will output the locations of all UI scripts it finds.
]]

local function findUIScripts()
    print("===== UI SCRIPT FINDER =====")
    print("Searching for UI-related scripts in the game...")
    
    local uiScripts = {}
    
    -- Recursive function to search for UI-related scripts
    local function findScriptsInChildren(parent, path)
        for _, child in ipairs(parent:GetChildren()) do
            local newPath = path .. "/" .. child.Name
            
            -- Check if it's a script and UI-related
            if (child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript")) then
                if child.Name:find("UI") or 
                   child.Name:find("Gui") or 
                   child.Name:match("Menu") or
                   child.Name:match("Dialog") or
                   child.Name:match("Button") or
                   child.Name:match("Display") then
                    
                    table.insert(uiScripts, {
                        path = newPath,
                        type = child.ClassName,
                        name = child.Name
                    })
                end
            end
            
            -- Recursively search children
            if #child:GetChildren() > 0 then
                findScriptsInChildren(child, newPath)
            end
        end
    end
    
    -- Start the search from the game root
    findScriptsInChildren(game, "game")
    
    -- Output the results in an organized way
    print("\nFound " .. #uiScripts .. " UI-related scripts:")
    print("----------------------------")
    
    -- Group by service/location
    local scriptsByService = {}
    for _, script in ipairs(uiScripts) do
        local service = script.path:match("game/([^/]+)")
        if not scriptsByService[service] then
            scriptsByService[service] = {}
        end
        table.insert(scriptsByService[service], script)
    end
    
    -- Display grouped results
    for service, scripts in pairs(scriptsByService) do
        print("\n" .. service .. " (" .. #scripts .. " scripts):")
        for _, script in ipairs(scripts) do
            print("  - " .. script.type .. ": " .. script.path)
        end
    end
    
    print("\n===== UI SCRIPT FINDER COMPLETE =====")
    
    return uiScripts
end

return findUIScripts()
