-- FindGUIInServerStorage.server.luau
-- Script to search for all GUI elements in ServerStorage that might be visible
-- Run this script in-game to find unintended GUIs

local ServerStorage = game:GetService("ServerStorage")

local function printProperties(gui, indent)
    indent = indent or ""
    print(indent .. "- Name: " .. gui.Name)
    print(indent .. "  ClassName: " .. gui.ClassName)
    
    if gui:IsA("GuiObject") then
        print(indent .. "  Position: " .. tostring(gui.Position))
        print(indent .. "  Size: " .. tostring(gui.Size))
        print(indent .. "  Visible: " .. tostring(gui.Visible))
        
        if gui:IsA("Frame") then
            print(indent .. "  BackgroundColor3: " .. tostring(gui.BackgroundColor3))
            print(indent .. "  BackgroundTransparency: " .. tostring(gui.BackgroundTransparency))
        end
        
        if gui:IsA("TextLabel") then
            print(indent .. "  Text: " .. gui.Text)
            print(indent .. "  TextColor3: " .. tostring(gui.TextColor3))
        end
    end
    
    if gui:IsA("BillboardGui") then
        print(indent .. "  Adornee: " .. (gui.Adornee and gui.Adornee:GetFullName() or "nil"))
        print(indent .. "  AlwaysOnTop: " .. tostring(gui.AlwaysOnTop))
        print(indent .. "  Size: " .. tostring(gui.Size))
    end
end

local function examineInstance(instance, indent)
    indent = indent or ""
    
    -- Check if this instance is a GUI element
    if instance:IsA("ScreenGui") or instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") then
        print("\n" .. indent .. "Found GUI element:")
        printProperties(instance, indent .. "  ")
        
        -- Check if it contains a Label child
        local labelChild = instance:FindFirstChild("Label")
        if labelChild then
            print(indent .. "  Contains a child named 'Label':")
            printProperties(labelChild, indent .. "    ")
        end
        
        -- Check for Frame objects with grey backgrounds
        for _, child in pairs(instance:GetDescendants()) do
            if child:IsA("Frame") then
                local color = child.BackgroundColor3
                -- Check if the color is approximately grey
                if math.abs(color.R - color.G) < 0.1 and math.abs(color.G - color.B) < 0.1 and color.R > 0.2 and color.R < 0.8 then
                    print(indent .. "  Contains a Frame with grey background:")
                    printProperties(child, indent .. "    ")
                end
            end
        end
    end
    
    -- Search all descendants recursively
    for _, child in pairs(instance:GetChildren()) do
        examineInstance(child, indent .. "  ")
    end
end

print("======== SEARCHING FOR GUI ELEMENTS IN SERVERSTORRAGE ========")
examineInstance(ServerStorage)
print("======== SEARCH COMPLETE ========")

-- Also look for BillboardGuis named "Label" in the entire workspace
print("\n======== SEARCHING FOR BILLBOARDGUIS NAMED 'LABEL' IN WORKSPACE ========")
local labelGuis = {}
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("BillboardGui") and obj.Name == "Label" then
        table.insert(labelGuis, obj)
        print("Found 'Label' BillboardGui in workspace:")
        print("  Path: " .. obj:GetFullName())
        printProperties(obj, "  ")
    end
end
print("Found " .. #labelGuis .. " BillboardGuis named 'Label' in workspace")

-- Check for scripts that might be creating BillboardGuis at runtime
print("\n======== CHECKING FOR SCRIPTS THAT CREATE BILLBOARDGUIS ========")
local function isRelevantScript(script)
    if not script:IsA("LuaSourceContainer") then
        return false
    end
    
    local success, source = pcall(function()
        return script.Source
    end)
    
    if not success or not source then
        return false
    end
    
    -- Check if the script creates a BillboardGui with name "Label"
    return string.find(source, "BillboardGui") and string.find(source, "Name = \"Label\"")
end

local relevantScripts = {}
for _, obj in pairs(game:GetDescendants()) do
    if isRelevantScript(obj) then
        table.insert(relevantScripts, obj)
        print("Found script that may create 'Label' BillboardGuis:")
        print("  Path: " .. obj:GetFullName())
    end
end
print("Found " .. #relevantScripts .. " scripts that might create 'Label' BillboardGuis")

-- Create a function that can be used to remove all Label GUIs
_G.RemoveAllLabelGuis = function()
    local count = 0
    for _, obj in pairs(workspace:GetDescendants()) do
        if (obj:IsA("BillboardGui") or obj:IsA("SurfaceGui")) and obj.Name == "Label" then
            obj:Destroy()
            count = count + 1
        end
    end
    print("Removed " .. count .. " 'Label' GUI objects from workspace")
    return count
end

print("Created global function _G.RemoveAllLabelGuis() to remove all 'Label' GUIs")
