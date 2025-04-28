-- UIComponents.luau
-- Central module for UI components and styling
-- Created: April 28, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-- Constants and configuration
local VERSION = "1.0.0"
local DEBUG = true
local DEFAULT_FONT = Enum.Font.GothamMedium
local DEFAULT_TEXT_SIZE = 14
local DEFAULT_BUTTON_COLOR = Color3.fromRGB(48, 48, 48)
local DEFAULT_TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local DEFAULT_ACCENT_COLOR = Color3.fromRGB(0, 120, 215)
local DEFAULT_ERROR_COLOR = Color3.fromRGB(231, 76, 60)
local DEFAULT_SUCCESS_COLOR = Color3.fromRGB(46, 204, 113)
local DEFAULT_WARNING_COLOR = Color3.fromRGB(241, 196, 15)
local DEFAULT_BACKGROUND_COLOR = Color3.fromRGB(36, 36, 36)

-- Local logging function
local function log(message, level)
	level = level or "Info"
	if not DEBUG and level ~= "Error" then return end
	print(string.format("[UIComponents][%s] %s", level, message))
end

-- Safe require function that won't throw errors
local function safeRequire(moduleScript)
	if not moduleScript then
		return nil
	end
	
	if not moduleScript:IsA("ModuleScript") then
		return nil
	end
	
	local success, result = pcall(function()
		return require(moduleScript)
	end)
	
	if success then
		return result
	else
		return nil
	end
end

-- Safe wait for child function with timeout
local function safeWaitForChild(parent, childName, timeout)
	timeout = timeout or 5
	local startTime = os.clock()
	
	while os.clock() - startTime < timeout do
		local child = parent:FindFirstChild(childName)
		if child then
			return child
		end
		wait(0.1)
	end
	
	return nil -- Timed out
end

-- Try to find the ModuleLoader
local function getModuleLoader()
	local shared = ReplicatedStorage:FindFirstChild("shared")
	if shared and shared:FindFirstChild("ModuleLoader") then
		return safeRequire(shared.ModuleLoader)
	end
	
	local src = ReplicatedStorage:FindFirstChild("src")
	if src and src:FindFirstChild("shared") and src.shared:FindFirstChild("ModuleLoader") then
		return safeRequire(src.shared.ModuleLoader)
	end
	
	return nil
end

-- UIComponents object
local UIComponents = {
	_version = VERSION,
	_styles = {}, -- Style definitions
	_icons = {}, -- Icon references
	_components = {}, -- Reusable components
	_templateCache = {}, -- Cache of template instances
}

-- Style definitions
UIComponents._styles = {
	font = DEFAULT_FONT,
	textSize = DEFAULT_TEXT_SIZE,
	buttonColor = DEFAULT_BUTTON_COLOR,
	textColor = DEFAULT_TEXT_COLOR,
	accentColor = DEFAULT_ACCENT_COLOR,
	errorColor = DEFAULT_ERROR_COLOR,
	successColor = DEFAULT_SUCCESS_COLOR,
	warningColor = DEFAULT_WARNING_COLOR,
	backgroundColor = DEFAULT_BACKGROUND_COLOR,
}

-- Load style overrides from other modules if available
local function loadStyleOverrides()
	local moduleLoader = getModuleLoader()
	if moduleLoader then
		local uiStyle = moduleLoader:GetModule("UIStyle")
		if uiStyle then
			for key, value in pairs(uiStyle) do
				UIComponents._styles[key] = value
			end
			log("Loaded style overrides from UIStyle")
		else
			log("UIStyle module not found, using fallback", "Warning")
		end
	else
		log("ModuleLoader not found, using default styles", "Warning")
	end
end

-- Validate asset ID and offer fallbacks
function UIComponents:ValidateAssetID(assetId, fallbackId)
	if not assetId then
		return fallbackId
	end
	
	-- Try to convert string format ("rbxassetid://123456") to number
	local idNumber
	if type(assetId) == "string" then
		local match = string.match(assetId, "%d+")
		if match then
			idNumber = tonumber(match)
		else
			return fallbackId
		end
	else
		idNumber = assetId
	end
	
	-- For now, just return the input ID - in a real implementation,
	-- we might check against a list of known-bad IDs
	return assetId
end

-- Create a button with standardized styling
function UIComponents:CreateButton(text, size)
	local button = Instance.new("TextButton")
	button.Size = size or UDim2.new(0, 120, 0, 40)
	button.BackgroundColor3 = self._styles.buttonColor
	button.TextColor3 = self._styles.textColor
	button.Font = self._styles.font
	button.TextSize = self._styles.textSize
	button.Text = text or "Button"
	button.AutoButtonColor = true
	
	-- Add corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button
	
	return button
end

-- Create an icon button
function UIComponents:CreateIconButton(iconId, size)
	local iconIdToUse = self:ValidateAssetID(iconId, "rbxassetid://4483362458") -- Default icon as fallback
	
	local button = Instance.new("ImageButton")
	button.Size = size or UDim2.new(0, 40, 0, 40)
	button.BackgroundColor3 = self._styles.buttonColor
	button.Image = iconIdToUse
	button.AutoButtonColor = true
	
	-- Add corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button
	
	return button
end

-- Create a frame with standard styling
function UIComponents:CreateFrame(size, transparency)
	local frame = Instance.new("Frame")
	frame.Size = size or UDim2.new(0, 200, 0, 200)
	frame.BackgroundColor3 = self._styles.backgroundColor
	frame.BackgroundTransparency = transparency or 0
	
	-- Add corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	return frame
end

-- Create a scrolling frame with standard styling
function UIComponents:CreateScrollingFrame(size)
	local frame = Instance.new("ScrollingFrame")
	frame.Size = size or UDim2.new(0, 200, 0, 200)
	frame.BackgroundColor3 = self._styles.backgroundColor
	frame.ScrollBarThickness = 6
	frame.ScrollBarImageColor3 = self._styles.accentColor
	frame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will auto-adjust as content is added
	
	-- Add corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	-- Add auto-sizing layout
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = frame
	
	-- Auto-update canvas size
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		frame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end)
	
	return frame
end

-- Create a label with standard styling
function UIComponents:CreateLabel(text, size, textSize)
	local label = Instance.new("TextLabel")
	label.Size = size or UDim2.new(0, 200, 0, 30)
	label.BackgroundTransparency = 1
	label.TextColor3 = self._styles.textColor
	label.Font = self._styles.font
	label.TextSize = textSize or self._styles.textSize
	label.Text = text or "Label"
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	
	return label
end

-- Create a header with standard styling
function UIComponents:CreateHeader(text, size)
	local header = self:CreateLabel(text, size, self._styles.textSize * 1.5)
	header.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	return header
end

-- Create a notification
function UIComponents:CreateNotification(title, message, notificationType)
	-- Use relative paths to find the template from either StarterGui or PlayerGui
	local notificationTemplate
	
	-- First, check if the player is in-game
	local player = Players.LocalPlayer
	if player then
		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			notificationTemplate = playerGui:FindFirstChild("NotificationTemplate")
		end
	end
	
	-- If not found, check StarterGui
	if not notificationTemplate then
		notificationTemplate = StarterGui:FindFirstChild("NotificationTemplate")
	end
	
	local notification
	
	-- Use template if found, otherwise create a new one
	if notificationTemplate and notificationTemplate:IsA("ScreenGui") then
		notification = notificationTemplate:Clone()
	else
		-- Create a new notification from scratch
		notification = Instance.new("ScreenGui")
		notification.Name = "Notification"
		notification.ResetOnSpawn = false
		
		local frame = self:CreateFrame(UDim2.new(0, 300, 0, 100))
		frame.Position = UDim2.new(1, -320, 1, -120)
		frame.Parent = notification
		
		local titleLabel = self:CreateHeader(title or "Notification", UDim2.new(1, -20, 0, 30))
		titleLabel.Position = UDim2.new(0, 10, 0, 10)
		titleLabel.Parent = frame
		
		local messageLabel = self:CreateLabel(message or "", UDim2.new(1, -20, 0, 40))
		messageLabel.Position = UDim2.new(0, 10, 0, 50)
		messageLabel.Parent = frame
		
		-- Add close button
		local closeButton = self:CreateButton("X", UDim2.new(0, 30, 0, 30))
		closeButton.Position = UDim2.new(1, -40, 0, 10)
		closeButton.TextColor3 = self._styles.errorColor
		closeButton.Parent = frame
		
		closeButton.MouseButton1Click:Connect(function()
			notification:Destroy()
		end)
	end
	
	-- Set color based on notification type
	local mainFrame = notification:FindFirstChildWhichIsA("Frame")
	if mainFrame then
		if notificationType == "error" then
			mainFrame.BackgroundColor3 = self._styles.errorColor
		elseif notificationType == "success" then
			mainFrame.BackgroundColor3 = self._styles.successColor
		elseif notificationType == "warning" then
			mainFrame.BackgroundColor3 = self._styles.warningColor
		else
			mainFrame.BackgroundColor3 = self._styles.accentColor
		end
	end
	
	-- Set title and message text if they exist
	local titleLabel = notification:FindFirstChild("Title", true)
	if titleLabel then
		titleLabel.Text = title or "Notification"
	end
	
	local messageLabel = notification:FindFirstChild("Message", true)
	if messageLabel then
		messageLabel.Text = message or ""
	end
	
	-- Show the notification
	if player then
		notification.Parent = player.PlayerGui
	else
		notification.Parent = StarterGui
	end
	
	-- Auto-remove after a delay
	local lifespan = 5 -- seconds
	spawn(function()
		wait(lifespan)
		pcall(function()
			notification:Destroy()
		end)
	end)
	
	return notification
end

-- Create a dialog with standard styling
function UIComponents:CreateDialog(title, content, buttons)
	local dialog = Instance.new("ScreenGui")
	dialog.Name = "Dialog"
	dialog.ResetOnSpawn = false
	
	-- Create a transparent background overlay
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.Parent = dialog
	
	-- Create the dialog frame
	local frame = self:CreateFrame(UDim2.new(0, 400, 0, 250))
	frame.Position = UDim2.new(0.5, -200, 0.5, -125)
	frame.Parent = dialog
	
	-- Add title
	local titleLabel = self:CreateHeader(title or "Dialog", UDim2.new(1, -20, 0, 40))
	titleLabel.Position = UDim2.new(0, 10, 0, 10)
	titleLabel.Parent = frame
	
	-- Add content
	local contentLabel = self:CreateLabel(content or "", UDim2.new(1, -20, 0, 120))
	contentLabel.Position = UDim2.new(0, 10, 0, 60)
	contentLabel.Parent = frame
	
	-- Add buttons
	local buttonsFrame = Instance.new("Frame")
	buttonsFrame.Size = UDim2.new(1, -20, 0, 40)
	buttonsFrame.Position = UDim2.new(0, 10, 1, -50)
	buttonsFrame.BackgroundTransparency = 1
	buttonsFrame.Parent = frame
	
	-- Add button layout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = buttonsFrame
	
	-- Default buttons if none provided
	buttons = buttons or {
		{text = "OK", callback = function() dialog:Destroy() end}
	}
	
	-- Add each button
	for i, buttonInfo in ipairs(buttons) do
		local button = self:CreateButton(buttonInfo.text, UDim2.new(0, 100, 0, 40))
		button.LayoutOrder = i
		button.Parent = buttonsFrame
		
		button.MouseButton1Click:Connect(function()
			if buttonInfo.callback then
				buttonInfo.callback()
			else
				dialog:Destroy()
			end
		end)
	end
	
	-- Show the dialog
	local player = Players.LocalPlayer
	if player then
		dialog.Parent = player.PlayerGui
	else
		dialog.Parent = StarterGui
	end
	
	return dialog
end

-- Create a progress bar with standard styling
function UIComponents:CreateProgressBar(size, progress)
	local frame = Instance.new("Frame")
	frame.Size = size or UDim2.new(0, 200, 0, 20)
	frame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	frame.Name = "ProgressBar"
	
	-- Add fill bar
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(progress or 0, 0, 1, 0)
	fill.BackgroundColor3 = self._styles.accentColor
	fill.Name = "Fill"
	fill.Parent = frame
	
	-- Add corner radius to both frames
	local corner1 = Instance.new("UICorner")
	corner1.CornerRadius = UDim.new(0, 4)
	corner1.Parent = frame
	
	local corner2 = Instance.new("UICorner")
	corner2.CornerRadius = UDim.new(0, 4)
	corner2.Parent = fill
	
	-- Add methods to update the progress bar
	local progressBarObj = {}
	
	function progressBarObj:SetProgress(value)
		value = math.clamp(value, 0, 1)
		fill.Size = UDim2.new(value, 0, 1, 0)
	end
	
	function progressBarObj:GetProgress()
		return fill.Size.X.Scale
	end
	
	function progressBarObj:SetColor(color)
		fill.BackgroundColor3 = color
	end
	
	function progressBarObj:GetInstance()
		return frame
	end
	
	return progressBarObj
end

-- Get the version of UIComponents
function UIComponents:GetVersion()
	return self._version
end

-- Register UI components with a ClientRegistry if available
local function registerWithClientRegistry()
	local moduleLoader = getModuleLoader()
	if moduleLoader then
		local clientRegistry = moduleLoader:GetModule("ClientRegistry")
		if clientRegistry then
			clientRegistry:Register("UIComponents", UIComponents)
			log("Registered with ClientRegistry")
		else
			log("ClientRegistry not found, skipping registration", "Warning")
		end
	else
		log("ModuleLoader not found, skipping registration", "Warning")
	end
end

-- Initialize UIComponents
loadStyleOverrides()
registerWithClientRegistry()

-- Make globally accessible for debugging
if _G then
	_G.__UIComponents = UIComponents
end

log("UIComponents v" .. VERSION .. " initialized")

return UIComponents
