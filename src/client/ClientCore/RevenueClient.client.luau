-- RevenueClient.client.luau

local RevenueClient = {}
local ClientRegistry = require(game:GetService("Players").LocalPlayer.PlayerScripts.Core.ClientRegistry))
ClientRegistry = require(game:GetService("Players").LocalPlayer.PlayerScripts.Core.ClientRegistry)
ClientEvents = ClientRegistry.getSystem("ClientEventBridge")

function RevenueClient:initialize()
    print("[RevenueClient] Initialized successfully!")
end
ClientRegistry.defineDependencies("RevenueClient", {"ClientEventBridge"})

return RevenueClient