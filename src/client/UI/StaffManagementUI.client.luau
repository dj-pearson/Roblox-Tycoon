-- src/client/UI/StaffManagementUI.client.luau

local ClientRegistry = require(game:GetService("Players").LocalPlayer.PlayerScripts.Core.ClientRegistry))
local UIHub = ClientRegistry.getSystem("UIHub")
local ClientEventBridge = ClientRegistry.getSystem("ClientEventBridge")

local StaffManagementUI = {}

local staffManagementFrame

function StaffManagementUI:initialize()
    print("[StaffManagementUI] Initialized")

    staffManagementFrame = Instance.new("Frame")
    staffManagementFrame.Name = "StaffManagementFrame"
    staffManagementFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
    staffManagementFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
    staffManagementFrame.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    staffManagementFrame.Visible = false -- Initially hidden
        UIHub:registerUIComponent("StaffManagementUI", staffManagementFrame)

end

function StaffManagementUI:open()
    print("[StaffManagementUI] Open")
    UIHub:showUIComponent("StaffManagementUI")
end

function StaffManagementUI:close()
    print("[StaffManagementUI] Close")
    UIHub:hideUIComponent("StaffManagementUI")
end

ClientRegistry.defineDependencies("StaffManagementUI", {"ClientEventBridge", "UIHub"})
ClientRegistry.registerSystem("StaffManagementUI", StaffManagementUI)

local PublicAPI = {
    initialize = function()
        StaffManagementUI:initialize()
    end,
    open = function()
        StaffManagementUI:open()
    end,
    close = function()
        StaffManagementUI:close()
    end,

}
return PublicAPI