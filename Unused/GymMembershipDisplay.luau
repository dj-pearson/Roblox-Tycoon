-- GymMembershipDisplay.lua
-- Positioned at the very top center

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Configuration
local CONFIG = {
	updateInterval = 2, -- Update every 2 seconds
	position = UDim2.new(0.5, 0, 0, 0), -- Absolute top center
	size = UDim2.new(0, 300, 0, 35), -- Good height
	debug = true
}

-- Debug function
local function debugPrint(...)
	if CONFIG.debug then
		print("[MembershipDisplay]", ...)
	end
end

-- Format large numbers with commas
local function formatNumber(number)
	local formatted = tostring(number)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return formatted
end

-- Reference to the Stats GUI
local statsGui = script.Parent

-- Find or create display elements
local function setupDisplayElements()
	-- Check if GUI already has the elements we need
	local memberLabel = statsGui:FindFirstChild("MembershipLabel")
	if not memberLabel then
		-- Create membership count label
		memberLabel = Instance.new("TextLabel")
		memberLabel.Name = "MembershipLabel"
		memberLabel.Size = CONFIG.size
		memberLabel.Position = CONFIG.position
		memberLabel.AnchorPoint = Vector2.new(0.5, 0) -- Center horizontally, anchor to top
		memberLabel.BackgroundTransparency = 0.3
		memberLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		memberLabel.TextColor3 = Color3.fromRGB(0, 255, 127) -- Money green color
		memberLabel.Font = Enum.Font.GothamBold
		memberLabel.TextSize = 18
		memberLabel.TextStrokeTransparency = 0.7
		memberLabel.Text = "Members: 0"
		memberLabel.ZIndex = 10 -- Make sure it appears on top
		memberLabel.Parent = statsGui

		-- Add corner radius but only for bottom corners
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = memberLabel
	else
		-- Update position and size if it already exists
		memberLabel.Position = CONFIG.position
		memberLabel.Size = CONFIG.size
		memberLabel.AnchorPoint = Vector2.new(0.5, 0) -- Center horizontally, anchor to top
	end

	return memberLabel
end

-- Update the display with current data
local function updateDisplay()
	local memberLabel = setupDisplayElements()

	-- Get tycoon data
	local tycoon = player:FindFirstChild("Tycoon")
	if not tycoon then 
		memberLabel.Text = "Members: 0"
		return 
	end

	-- Get membership count
	local memberCount = tycoon:GetAttribute("MembershipCount") or 0
	local vipCount = tycoon:GetAttribute("VIPMemberCount") or 0

	-- Update display
	if vipCount > 0 then
		memberLabel.Text = "Members: " .. formatNumber(memberCount) .. " (" .. formatNumber(vipCount) .. " VIP)"
	else
		memberLabel.Text = "Members: " .. formatNumber(memberCount)
	end
end

-- Listen for membership updates from server
local function setupEventListeners()
	local eventBridge = ReplicatedStorage:FindFirstChild("EventBridge")
	if not eventBridge then return end

	local membershipUpdated = eventBridge:FindFirstChild("MembershipUpdated")
	if membershipUpdated then
		membershipUpdated.OnClientEvent:Connect(function()
			updateDisplay()
		end)
		debugPrint("Connected to MembershipUpdated event")
	end
end

-- Initialize the display
local function initialize()
	debugPrint("Initializing membership display")

	-- Set up display elements
	setupDisplayElements()

	-- Set up event listeners
	setupEventListeners()

	-- Update initially
	updateDisplay()

	-- Set up periodic updates as fallback
	spawn(function()
		while wait(CONFIG.updateInterval) do
			updateDisplay()
		end
	end)

	debugPrint("Membership display initialized")
end

-- Start initialization
initialize()