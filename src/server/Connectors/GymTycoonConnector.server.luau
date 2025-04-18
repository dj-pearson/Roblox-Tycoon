-- GymTycoonConnector.luau
-- Bridge between existing tycoon code and the new system architecture
-- Place in ServerScriptService/Connectors

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Connect to CoreRegistry and systems
local CoreRegistry = require(ServerScriptService.Core.CoreRegistry)
local TycoonSystem = CoreRegistry.getSystem("TycoonSystem")
local EventBridge = CoreRegistry.getSystem("EventBridge")
local BuyTileSystem = CoreRegistry.getSystem("BuyTileSystem")

-- Configuration
local CONFIG = {
	debugEnabled = true,

	-- Front Desk
	frontDeskAttempts = 5,  -- Number of attempts to find front desk
	frontDeskRetryDelay = 1, -- Delay between attempts in seconds

	-- Legacy scripts
	legacyScriptNames = {
		"UnifiedTycoonSystem", 
		"GymRevenueSystem",
		"FrontDeskPrompt",
		"RevenueDisplay"
	},

	-- Events to bridge between systems
	eventsToForward = {
		"DuesCollected",
		"TycoonCreated",
		"TycoonStarted",
		"VisitorEntered",
		"VisitorLeft"
	}
}

-- Create the connector
local GymTycoonConnector = {
	-- State tracking
	legacySystemsFound = {},
	bridgedEvents = {}
}

-- Debug function
local function log(...)
	if CONFIG.debugEnabled then
		print("[GymTycoonConnector]", ...)
	end
end

-- Initialize the connector
function GymTycoonConnector:initialize()
	log("Initializing GymTycoonConnector...")

	-- Find legacy systems
	self:findLegacySystems()

	-- Set up event bridging
	self:setupEventBridging()

	-- Connect to new system events
	self:connectNewSystemEvents()

	-- Bridge RemoteEvents
	self:bridgeRemoteEvents()

	log("GymTycoonConnector initialized")
	return true
end

-- Find legacy systems in the game
function GymTycoonConnector:findLegacySystems()
	for _, scriptName in ipairs(CONFIG.legacyScriptNames) do
		local script = ServerScriptService:FindFirstChild(scriptName) 
			or game:FindFirstChild(scriptName, true)

		if script then
			self.legacySystemsFound[scriptName] = script
			log("Found legacy system: " .. scriptName)
		end
	end

	-- Report found systems
	local count = 0
	for _ in pairs(self.legacySystemsFound) do count = count + 1 end

	log("Found " .. count .. " legacy systems out of " .. #CONFIG.legacyScriptNames)
end

-- Set up event bridging between old and new systems
function GymTycoonConnector:setupEventBridging()
	if not EventBridge then
		log("EventBridge not found, could not set up event bridging")
		return
	end

	for _, eventName in ipairs(CONFIG.eventsToForward) do
		-- Create event if it doesn't exist
		local event = EventBridge:getOrCreateEvent(eventName)

		-- Set up two-way bridging when events fire
		EventBridge:connectEvent(eventName, function(...)
			self:forwardEventToLegacy(eventName, ...)
		end)

		-- Store for later reference
		self.bridgedEvents[eventName] = true
	end

	log("Set up event bridging for " .. #CONFIG.eventsToForward .. " events")
end

-- Connect to events from the new systems
function GymTycoonConnector:connectNewSystemEvents()
	if not EventBridge then return end

	-- Connect to TycoonSystem events
	EventBridge:connectEvent("TycoonCreated", function(player, tycoon)
		self:onTycoonCreated(player, tycoon)
	end)

	-- Connect to BuyTile events
	EventBridge:connectEvent("TilePurchased", function(player, tileId, price)
		self:onTilePurchased(player, tileId, price)
	end)

	log("Connected to new system events")
end

-- Bridge remote events between old and new systems
function GymTycoonConnector:bridgeRemoteEvents()
	if not EventBridge then return end

	local legacyEvents = ReplicatedStorage:FindFirstChild("Events")
	if not legacyEvents then
		log("Legacy events folder not found in ReplicatedStorage")
		return
	end

	-- Find remote events to bridge
	for _, child in ipairs(legacyEvents:GetChildren()) do
		if child:IsA("RemoteEvent") then
			local eventName = child.Name

			-- Bridge from old to new
			child.OnServerEvent:Connect(function(player, ...)
				EventBridge:fireEvent(eventName, player, ...)
			end)

			log("Bridged legacy remote event: " .. eventName)
		end
	end

	log("Remote event bridging complete")
end

-- Forward events from new system to legacy system
function GymTycoonConnector:forwardEventToLegacy(eventName, ...)
	-- Capture varargs in a table for proper handling
	local args = {...}

	-- Find any existing legacy event handlers and trigger them
	for scriptName, script in pairs(self.legacySystemsFound) do
		if typeof(script) == "Instance" and script:IsA("ModuleScript") then
			-- Try to get the module and call the appropriate function
			local success, legacyModule = pcall(function()
				return require(script)
			end)

			if success and typeof(legacyModule) == "table" then
				-- Look for event handler function (common patterns)
				local handlerNames = {
					"on" .. eventName,
					"handle" .. eventName,
					eventName .. "Handler",
					"process" .. eventName
				}

				for _, handlerName in ipairs(handlerNames) do
					if typeof(legacyModule[handlerName]) == "function" then
						-- Call the handler
						task.spawn(function()
							legacyModule[handlerName](unpack(args))
						end)
						log("Forwarded " .. eventName .. " to " .. scriptName .. "." .. handlerName)
					end
				end
			end
		end
	end
end

-- Handle when a tycoon is created
function GymTycoonConnector:onTycoonCreated(player, tycoon)
	if not player or not tycoon then return end

	log("New tycoon created for: " .. player.Name)

	-- Set up any legacy references on the tycoon
	self:setupLegacyReferences(player, tycoon)
end

-- Set up legacy references on a tycoon
function GymTycoonConnector:setupLegacyReferences(player, tycoon)
	if not player or not tycoon then return end

	-- Create legacy value references
	local valueNames = {"TycoonOwner", "Status", "Version"}

	for _, valueName in ipairs(valueNames) do
		if not tycoon:FindFirstChild(valueName) then
			local value = Instance.new("StringValue")
			value.Name = valueName

			if valueName == "TycoonOwner" then
				value.Value = player.Name
			elseif valueName == "Status" then
				value.Value = "Active"
			elseif valueName == "Version" then
				value.Value = "2.0"
			end

			value.Parent = tycoon
		end
	end

	-- Create legacy script references if needed
	if not tycoon:FindFirstChild("TycoonScript") then
		local scriptObject = Instance.new("ObjectValue") 
		scriptObject.Name = "TycoonScript"

		-- Find any legacy tycoon script to reference
		local legacyScript = self.legacySystemsFound["UnifiedTycoonSystem"]
		if legacyScript then
			scriptObject.Value = legacyScript
		end

		scriptObject.Parent = tycoon
	end

	log("Set up legacy references for " .. player.Name .. "'s tycoon")
end

-- Handle when a tile is purchased
function GymTycoonConnector:onTilePurchased(player, tileId, price)
	if not player or not tileId then return end

	-- Update the front desk display if available
	self:updateFrontDesk(player)

	-- Any other legacy integration needed after a purchase
end

-- Update the front desk display for a player
function GymTycoonConnector:updateFrontDesk(player)
	if not player then return end

	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon or not tycoon.Value then return end

	-- Find the front desk
	local attempts = 0
	local frontDesk

	-- Some tycoons might have different front desk naming conventions
	local possibleNames = {"FrontDesk", "DeskFront", "ReceptionDesk", "Desk"}

	while attempts < CONFIG.frontDeskAttempts and not frontDesk do
		attempts = attempts + 1

		for _, name in ipairs(possibleNames) do
			frontDesk = tycoon.Value:FindFirstChild(name, true)
			if frontDesk then break end
		end

		if not frontDesk then
			task.wait(CONFIG.frontDeskRetryDelay)
		end
	end

	if not frontDesk then
		-- No front desk found, possibly not yet loaded or differently named
		return
	end

	-- Update the display
	local duesSign = frontDesk:FindFirstChild("DuesSign") or 
		frontDesk:FindFirstChild("RevenueDisplay") or
		frontDesk:FindFirstChild("MoneyDisplay")

	if duesSign and duesSign:FindFirstChild("SurfaceGui") then
		local textLabel = duesSign.SurfaceGui:FindFirstChild("TextLabel")
		if textLabel then
			-- Get current dues amount
			local accrued = tycoon.Value:GetAttribute("AccruedDues") or 0

			-- Update the text
			textLabel.Text = "$" .. accrued

			-- Update color based on amount
			if accrued > 1000 then
				textLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green for a lot of money
			elseif accrued > 0 then
				textLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow for some money
			else
				textLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White for no money
			end
		end
	end
end

-- Public API for GymTycoonConnector
return {
	initialize = function()
		return GymTycoonConnector:initialize()
	end,

	updateFrontDesk = function(player)
		return GymTycoonConnector:updateFrontDesk(player)
	end,

	onTilePurchased = function(self, player, tileId)
		return GymTycoonConnector:onTilePurchased(player, tileId)
	end,

	forwardEventToLegacy = function(eventName, ...)
		return GymTycoonConnector:forwardEventToLegacy(eventName, ...)
	end,

	getLegacySystems = function()
		return GymTycoonConnector.legacySystemsFound
	end
}