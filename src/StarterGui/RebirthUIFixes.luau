--[[
    RebirthUIFixes.luau
    This is a helper file to fix GothamItalic font references in RebirthUI.client.luau
    
    Instructions:
    1. Execute this script to fix all font references in RebirthUI
    2. The script will automatically find and replace deprecated font references
]]

local StarterGui = game:GetService("StarterGui")
local rebirthUI = StarterGui:FindFirstChild("RebirthUI")

-- Function to recursively traverse and fix font references
local function fixFonts(parent)
    for _, obj in pairs(parent:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            -- Fix GothamItalic references
            if obj.Font == Enum.Font.GothamItalic then
                print("Fixing GothamItalic font reference in: " .. obj:GetFullName())
                obj.Font = Enum.Font.Gotham
            end
            
            -- Fix GothamSemibold references
            if obj.Font == Enum.Font.GothamSemibold then
                print("Fixing GothamSemibold font reference in: " .. obj:GetFullName())
                obj.Font = Enum.Font.GothamMedium
            end
        end
    end
end

-- Execute the fix
if rebirthUI then
    print("Found RebirthUI, fixing font references...")
    fixFonts(rebirthUI)
    print("Font references fixed successfully!")
else
    print("RebirthUI not found. Please ensure the GUI is loaded.")
end

print("Font fix script completed.")
