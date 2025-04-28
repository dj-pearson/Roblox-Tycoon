-- UIComponents.luau
-- Library of reusable UI components with standardized styling
-- Created: April 28, 2025

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Constants and configuration
local VERSION = "1.0.0"
local DEBUG = true

-- Standard UI colors and styles
local UIStyle = {
	-- Color palette
	Colors = {
		Primary = Color3.fromRGB(0, 120, 215), -- Blue
		Secondary = Color3.fromRGB(142, 68, 173), -- Purple
		Success = Color3.fromRGB(46, 204, 113), -- Green
		Warning = Color3.fromRGB(241, 196, 15), -- Yellow
		Danger = Color3.fromRGB(231, 76, 60), -- Red
		Info = Color3.fromRGB(52, 152, 219), -- Light Blue
		Light = Color3.fromRGB(236, 240, 241), -- Off White
		Dark = Color3.fromRGB(44, 62, 80), -- Dark Blue
		White = Color3.fromRGB(255, 255, 255),
		Black = Color3.fromRGB(0, 0, 0),
		Background = Color3.fromRGB(245, 245, 245),
		TextPrimary = Color3.fromRGB(44, 62, 80),
		TextSecondary = Color3.fromRGB(127, 140, 141),
		Border = Color3.fromRGB(219, 221, 222)
	},
	
	-- Font styles
	Fonts = {
		Header = Enum.Font.GothamBold,
		Body = Enum.Font.Gotham,
		Button = Enum.Font.GothamSemibold,
		Input = Enum.Font.Gotham
	},
	
	-- Standard sizes
	Sizes = {
		HeaderText = 24,
		SubheaderText = 18,
		BodyText = 14,
		ButtonText = 16,
		Padding = 8,
		BorderRadius = 8,
		BorderSize = 1
	},
	
	-- Animation settings
	Animation = {
		HoverScale = 1.05,
		ClickScale = 0.95,
		HoverDuration = 0.1,
		ClickDuration = 0.05,
		FadeDuration = 0.2
	}
}

-- Local logging function
local function log(message, level)
	level = level or "Info"
	if not DEBUG and level ~= "Error" then return end
	print(string.format("[UIComponents][%s] %s", level, message))
end

-- Get ModuleLoader if available
local function getModuleLoader()
	local shared = ReplicatedStorage:FindFirstChild("shared")
	if shared and shared:FindFirstChild("ModuleLoader") then
		local success, result = pcall(function()
			return require(shared.ModuleLoader)
		end)
		
		if success then
			return result
		end
	end
	
	return nil
end

-- Try to get a module using ModuleLoader
local function getModule(moduleName)
	local moduleLoader = getModuleLoader()
	if moduleLoader then
		return moduleLoader:GetModule(moduleName)
	end
	return nil
end

-- Get UIRegistry if available
local function getUIRegistry()
	return getModule("UIRegistry")
end

-- Get AssetValidator if available
local function getAssetValidator()
	return getModule("AssetValidator")
end

-- Create a tween for an instance
local function createTween(instance, properties, duration, easingStyle, easingDirection)
	local tweenInfo = TweenInfo.new(
		duration or 0.3,
		easingStyle or Enum.EasingStyle.Quad,
		easingDirection or Enum.EasingDirection.Out
	)
	
	local tween = TweenService:Create(instance, tweenInfo, properties)
	return tween
end

-- UIComponents object
local UIComponents = {
	_version = VERSION,
	Style = UIStyle,
	_cache = {}, -- Cache of created components
	_initialized = false
}

-- Initialize UIComponents
function UIComponents:Initialize()
	if self._initialized then
		return true
	end
	
	log("Initializing UIComponents v" .. VERSION)
	
	-- Register with UIRegistry if available
	local uiRegistry = getUIRegistry()
	if uiRegistry then
		uiRegistry:Register("UIComponents", self)
		log("Registered with UIRegistry")
	else
		log("UIRegistry not available, functionality may be limited", "Warning")
	end
	
	-- Register common animations with UIRegistry
	if uiRegistry then
		self:RegisterAnimations(uiRegistry)
	end
	
	-- Register button styling
	self:RegisterButtonStyling()
	
	self._initialized = true
	log("UIComponents initialized")
	
	return true
end

-- Register common animations with UIRegistry
function UIComponents:RegisterAnimations(uiRegistry)
	-- Fade in animation
	uiRegistry:RegisterAnimation("FadeIn", function(instance, duration)
		duration = duration or UIStyle.Animation.FadeDuration
		
		if instance:IsA("GuiObject") then
			instance.Visible = true
			instance.BackgroundTransparency = 1
			
			if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
				instance.TextTransparency = 1
			end
			
			if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
				instance.ImageTransparency = 1
			end
			
			-- Create and play tween
			local tween = createTween(instance, {
				BackgroundTransparency = instance.BackgroundTransparency,
				TextTransparency = 0,
				ImageTransparency = 0
			}, duration)
			
			tween:Play()
			return tween
		end
		
		return nil
	end)
	
	-- Fade out animation
	uiRegistry:RegisterAnimation("FadeOut", function(instance, duration, callback)
		duration = duration or UIStyle.Animation.FadeDuration
		
		if instance:IsA("GuiObject") then
			local properties = {
				BackgroundTransparency = 1
			}
			
			if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
				properties.TextTransparency = 1
			end
			
			if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
				properties.ImageTransparency = 1
			end
			
			-- Create and play tween
			local tween = createTween(instance, properties, duration)
			
			-- Set up completion callback
			tween.Completed:Connect(function()
				instance.Visible = false
				if callback then
					callback()
				end
			end)
			
			tween:Play()
			return tween
		end
		
		return nil
	end)
	
	-- Scale animation
	uiRegistry:RegisterAnimation("Scale", function(instance, scale, duration)
		scale = scale or 1.05
		duration = duration or 0.1
		
		if instance:IsA("GuiObject") then
			-- Create and play tween
			local tween = createTween(instance, {
				Size = UDim2.fromScale(scale, scale) * instance.Size
			}, duration)
			
			tween:Play()
			return tween
		end
		
		return nil
	end)
	
	-- Hover effect animation
	uiRegistry:RegisterAnimation("HoverEffect", function(instance, hoverColor)
		if instance:IsA("GuiObject") then
			-- Store original color
			local originalColor = instance.BackgroundColor3
			
			-- Set hover color
			instance.BackgroundColor3 = hoverColor or UIStyle.Colors.Light
			
			-- Create and play tween
			local tween = createTween(instance, {
				BackgroundColor3 = originalColor
			}, UIStyle.Animation.HoverDuration)
			
			tween:Play()
			return tween
		end
		
		return nil
	end)
	
	log("Registered animations with UIRegistry")
}

-- Register button styling
function UIComponents:RegisterButtonStyling()
	-- Function to create button hover/click effects
	local function setupButtonEffects(button)
		-- Skip if already set up
		if button:GetAttribute("EffectsInitialized") then
			return
		end
		
		-- Store original properties
		local originalSize = button.Size
		local originalColor = button.BackgroundColor3
		local hoverColor = button.BackgroundColor3:Lerp(UIStyle.Colors.White, 0.2)
		local pressedColor = button.BackgroundColor3:Lerp(UIStyle.Colors.Black, 0.1)
		
		-- Create hover effect
		button.MouseEnter:Connect(function()
			-- Scale up slightly
			createTween(button, {
				Size = originalSize * UDim2.fromScale(UIStyle.Animation.HoverScale, UIStyle.Animation.HoverScale),
				BackgroundColor3 = hoverColor
			}, UIStyle.Animation.HoverDuration):Play()
		end)
		
		-- Create mouse leave effect
		button.MouseLeave:Connect(function()
			-- Return to original size and color
			createTween(button, {
				Size = originalSize,
				BackgroundColor3 = originalColor
			}, UIStyle.Animation.HoverDuration):Play()
		end)
		
		-- Create click effect
		button.MouseButton1Down:Connect(function()
			-- Scale down slightly
			createTween(button, {
				Size = originalSize * UDim2.fromScale(UIStyle.Animation.ClickScale, UIStyle.Animation.ClickScale),
				BackgroundColor3 = pressedColor
			}, UIStyle.Animation.ClickDuration):Play()
		end)
		
		-- Create mouse button up effect
		button.MouseButton1Up:Connect(function()
			-- Return to hover size and color if still hovering
			if button.MouseEnter then
				createTween(button, {
					Size = originalSize * UDim2.fromScale(UIStyle.Animation.HoverScale, UIStyle.Animation.HoverScale),
					BackgroundColor3 = hoverColor
				}, UIStyle.Animation.ClickDuration):Play()
			else
				-- Return to original size and color
				createTween(button, {
					Size = originalSize,
					BackgroundColor3 = originalColor
				}, UIStyle.Animation.ClickDuration):Play()
			end
		end)
		
		-- Mark as initialized
		button:SetAttribute("EffectsInitialized", true)
	end
	
	-- Function to apply button style
	self.StyleButton = function(button, style)
		style = style or "Primary"
		
		-- Apply colors based on style
		if style == "Primary" then
			button.BackgroundColor3 = UIStyle.Colors.Primary
			button.TextColor3 = UIStyle.Colors.White
		elseif style == "Secondary" then
			button.BackgroundColor3 = UIStyle.Colors.Secondary
			button.TextColor3 = UIStyle.Colors.White
		elseif style == "Success" then
			button.BackgroundColor3 = UIStyle.Colors.Success
			button.TextColor3 = UIStyle.Colors.White
		elseif style == "Warning" then
			button.BackgroundColor3 = UIStyle.Colors.Warning
			button.TextColor3 = UIStyle.Colors.Dark
		elseif style == "Danger" then
			button.BackgroundColor3 = UIStyle.Colors.Danger
			button.TextColor3 = UIStyle.Colors.White
		elseif style == "Info" then
			button.BackgroundColor3 = UIStyle.Colors.Info
			button.TextColor3 = UIStyle.Colors.White
		elseif style == "Light" then
			button.BackgroundColor3 = UIStyle.Colors.Light
			button.TextColor3 = UIStyle.Colors.Dark
		elseif style == "Dark" then
			button.BackgroundColor3 = UIStyle.Colors.Dark
			button.TextColor3 = UIStyle.Colors.White
		elseif style == "Outline" then
			button.BackgroundColor3 = UIStyle.Colors.White
			button.TextColor3 = UIStyle.Colors.Primary
			button.BorderSizePixel = UIStyle.Sizes.BorderSize
			button.BorderColor3 = UIStyle.Colors.Primary
		elseif style == "Text" then
			button.BackgroundColor3 = UIStyle.Colors.White
			button.BackgroundTransparency = 1
			button.TextColor3 = UIStyle.Colors.Primary
		end
		
		-- Apply font and size
		button.Font = UIStyle.Fonts.Button
		button.TextSize = UIStyle.Sizes.ButtonText
		
		-- Apply corner radius
		local corner = button:FindFirstChild("UICorner")
		if not corner then
			corner = Instance.new("UICorner")
			corner.Parent = button
		end
		corner.CornerRadius = UDim.new(0, UIStyle.Sizes.BorderRadius)
		
		-- Setup button effects
		setupButtonEffects(button)
		
		return button
	end
	
	log("Registered button styling")
}

-- Create a standard button
function UIComponents:CreateButton(text, size, position, style)
	local button = Instance.new("TextButton")
	button.Text = text or "Button"
	button.Size = size or UDim2.new(0, 200, 0, 50)
	button.Position = position or UDim2.new(0.5, 0, 0.5, 0)
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.AutoButtonColor = false
	
	-- Apply styling
	self.StyleButton(button, style)
	
	-- Add to UIRegistry if available
	local uiRegistry = getUIRegistry()
	if uiRegistry then
		uiRegistry:RegisterTemplate("Button_" .. text, button)
	end
	
	return button
end

-- Create a notification
function UIComponents:CreateNotification(title, message, type, duration)
	-- Default values
	type = type or "Info" -- Info, Success, Warning, Error
	duration = duration or 5 -- seconds
	
	-- Create the notification frame
	local notification = Instance.new("Frame")
	notification.Size = UDim2.new(0, 300, 0, 80)
	notification.Position = UDim2.new(1, -20, 0, 20)
	notification.AnchorPoint = Vector2.new(1, 0)
	notification.BackgroundColor3 = UIStyle.Colors.White
	notification.BorderSizePixel = 0
	notification.Name = "Notification"
	
	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UIStyle.Sizes.BorderRadius)
	corner.Parent = notification
	
	-- Add shadow
	local shadow = Instance.new("ImageLabel")
	shadow.Size = UDim2.new(1, 10, 1, 10)
	shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://1316045217" -- Shadow asset
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.7
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(10, 10, 118, 118)
	shadow.Name = "Shadow"
	shadow.ZIndex = -1
	shadow.Parent = notification
	
	-- Add color bar based on type
	local colorBar = Instance.new("Frame")
	colorBar.Size = UDim2.new(0, 5, 1, 0)
	colorBar.BorderSizePixel = 0
	colorBar.Name = "ColorBar"
	
	-- Set color based on type
	if type == "Success" then
		colorBar.BackgroundColor3 = UIStyle.Colors.Success
	elseif type == "Warning" then
		colorBar.BackgroundColor3 = UIStyle.Colors.Warning
	elseif type == "Error" then
		colorBar.BackgroundColor3 = UIStyle.Colors.Danger
	else -- Info
		colorBar.BackgroundColor3 = UIStyle.Colors.Info
	end
	
	colorBar.Parent = notification
	
	-- Add title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 0, 24)
	titleLabel.Position = UDim2.new(0, 15, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = UIStyle.Fonts.Header
	titleLabel.TextSize = UIStyle.Sizes.SubheaderText
	titleLabel.TextColor3 = UIStyle.Colors.TextPrimary
	titleLabel.Text = title or "Notification"
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Name = "Title"
	titleLabel.Parent = notification
	
	-- Add message
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(1, -20, 0, 36)
	messageLabel.Position = UDim2.new(0, 15, 0, 34)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Font = UIStyle.Fonts.Body
	messageLabel.TextSize = UIStyle.Sizes.BodyText
	messageLabel.TextColor3 = UIStyle.Colors.TextSecondary
	messageLabel.Text = message or ""
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextWrapped = true
	messageLabel.Name = "Message"
	messageLabel.Parent = notification
	
	-- Add close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 24, 0, 24)
	closeButton.Position = UDim2.new(1, -15, 0, 10)
	closeButton.BackgroundTransparency = 1
	closeButton.Font = UIStyle.Fonts.Header
	closeButton.TextSize = UIStyle.Sizes.SubheaderText
	closeButton.TextColor3 = UIStyle.Colors.TextSecondary
	closeButton.Text = "×"
	closeButton.Name = "CloseButton"
	closeButton.Parent = notification
	
	-- Set up close button functionality
	closeButton.MouseButton1Click:Connect(function()
		-- Create fade out animation
		local uiRegistry = getUIRegistry()
		if uiRegistry then
			uiRegistry:PlayAnimation("FadeOut", notification, 0.2, function()
				notification:Destroy()
			end)
		else
			notification:Destroy()
		end
	end)
	
	-- Add to UIRegistry if available
	local uiRegistry = getUIRegistry()
	if uiRegistry then
		uiRegistry:RegisterTemplate("Notification_" .. type, notification)
		
		-- Add entrance animation
		notification.Position = UDim2.new(1, 50, 0, 20) -- Start off-screen
		
		-- Create and play entrance tween
		createTween(notification, {
			Position = UDim2.new(1, -20, 0, 20)
		}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
	end
	
	-- Set up auto-close
	if duration > 0 then
		spawn(function()
			wait(duration)
			
			-- Create fade out animation
			local uiRegistry = getUIRegistry()
			if uiRegistry and notification.Parent then
				uiRegistry:PlayAnimation("FadeOut", notification, 0.2, function()
					if notification.Parent then
						notification:Destroy()
					end
				end)
			elseif notification.Parent then
				notification:Destroy()
			end
		end)
	end
	
	return notification
end

-- Create a modal dialog
function UIComponents:CreateModal(title, content, buttons)
	-- Default values
	buttons = buttons or {
		{text = "OK", style = "Primary", callback = function() end}
	}
	
	-- Create the modal background
	local modalBackground = Instance.new("Frame")
	modalBackground.Size = UDim2.new(1, 0, 1, 0)
	modalBackground.BackgroundColor3 = UIStyle.Colors.Black
	modalBackground.BackgroundTransparency = 0.5
	modalBackground.BorderSizePixel = 0
	modalBackground.Name = "ModalBackground"
	
	-- Create the modal frame
	local modalFrame = Instance.new("Frame")
	modalFrame.Size = UDim2.new(0, 400, 0, 250)
	modalFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	modalFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	modalFrame.BackgroundColor3 = UIStyle.Colors.White
	modalFrame.BorderSizePixel = 0
	modalFrame.Name = "ModalFrame"
	modalFrame.Parent = modalBackground
	
	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UIStyle.Sizes.BorderRadius)
	corner.Parent = modalFrame
	
	-- Add shadow
	local shadow = Instance.new("ImageLabel")
	shadow.Size = UDim2.new(1, 20, 1, 20)
	shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://1316045217" -- Shadow asset
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.5
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(10, 10, 118, 118)
	shadow.Name = "Shadow"
	shadow.ZIndex = -1
	shadow.Parent = modalFrame
	
	-- Add title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -40, 0, 50)
	titleLabel.Position = UDim2.new(0, 20, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = UIStyle.Fonts.Header
	titleLabel.TextSize = UIStyle.Sizes.HeaderText
	titleLabel.TextColor3 = UIStyle.Colors.TextPrimary
	titleLabel.Text = title or "Dialog"
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Name = "Title"
	titleLabel.Parent = modalFrame
	
	-- Add separator
	local separator = Instance.new("Frame")
	separator.Size = UDim2.new(1, 0, 0, 1)
	separator.Position = UDim2.new(0, 0, 0, 50)
	separator.BackgroundColor3 = UIStyle.Colors.Border
	separator.BorderSizePixel = 0
	separator.Name = "Separator"
	separator.Parent = modalFrame
	
	-- Add content frame
	local contentFrame = Instance.new("Frame")
	contentFrame.Size = UDim2.new(1, -40, 1, -120)
	contentFrame.Position = UDim2.new(0, 20, 0, 70)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Name = "ContentFrame"
	contentFrame.Parent = modalFrame
	
	-- Add content label if content is a string
	if type(content) == "string" then
		local contentLabel = Instance.new("TextLabel")
		contentLabel.Size = UDim2.new(1, 0, 1, 0)
		contentLabel.BackgroundTransparency = 1
		contentLabel.Font = UIStyle.Fonts.Body
		contentLabel.TextSize = UIStyle.Sizes.BodyText
		contentLabel.TextColor3 = UIStyle.Colors.TextSecondary
		contentLabel.Text = content
		contentLabel.TextWrapped = true
		contentLabel.Name = "ContentLabel"
		contentLabel.Parent = contentFrame
	-- Otherwise, parent the provided content to the content frame
	elseif typeof(content) == "Instance" then
		content.Parent = contentFrame
		
		-- Adjust for full content frame size
		if content:IsA("GuiObject") then
			content.Size = UDim2.new(1, 0, 1, 0)
		end
	end
	
	-- Add button container
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Size = UDim2.new(1, -40, 0, 50)
	buttonContainer.Position = UDim2.new(0, 20, 1, -60)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Name = "ButtonContainer"
	buttonContainer.Parent = modalFrame
	
	-- Add buttons
	local buttonWidth = 100
	local spacing = 10
	local totalWidth = (#buttons * buttonWidth) + ((#buttons - 1) * spacing)
	local startX = (buttonContainer.Size.X.Offset - totalWidth) / 2
	
	for i, buttonInfo in ipairs(buttons) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0, buttonWidth, 0, 40)
		button.Position = UDim2.new(0, startX + (i - 1) * (buttonWidth + spacing), 0, 5)
		button.AnchorPoint = Vector2.new(0, 0)
		button.Text = buttonInfo.text or "Button"
		button.Name = "Button_" .. buttonInfo.text
		button.AutoButtonColor = false
		
		-- Apply styling
		self.StyleButton(button, buttonInfo.style or "Primary")
		
		-- Set up callback
		button.MouseButton1Click:Connect(function()
			if buttonInfo.callback then
				buttonInfo.callback()
			end
			
			-- Create fade out animation
			local uiRegistry = getUIRegistry()
			if uiRegistry then
				uiRegistry:PlayAnimation("FadeOut", modalBackground, 0.2, function()
					modalBackground:Destroy()
				end)
			else
				modalBackground:Destroy()
			end
		end)
		
		button.Parent = buttonContainer
	end
	
	-- Add close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 24, 0, 24)
	closeButton.Position = UDim2.new(1, -20, 0, 13)
	closeButton.BackgroundTransparency = 1
	closeButton.Font = UIStyle.Fonts.Header
	closeButton.TextSize = UIStyle.Sizes.SubheaderText
	closeButton.TextColor3 = UIStyle.Colors.TextSecondary
	closeButton.Text = "×"
	closeButton.Name = "CloseButton"
	closeButton.Parent = modalFrame
	
	-- Set up close button functionality
	closeButton.MouseButton1Click:Connect(function()
		-- Create fade out animation
		local uiRegistry = getUIRegistry()
		if uiRegistry then
			uiRegistry:PlayAnimation("FadeOut", modalBackground, 0.2, function()
				modalBackground:Destroy()
			end)
		else
			modalBackground:Destroy()
		end
	end)
	
	-- Add to UIRegistry if available
	local uiRegistry = getUIRegistry()
	if uiRegistry then
		uiRegistry:RegisterTemplate("Modal_" .. title, modalBackground)
		
		-- Add entrance animation
		modalFrame.Size = UDim2.new(0, 0, 0, 0)
		
		-- Create and play entrance tween
		createTween(modalFrame, {
			Size = UDim2.new(0, 400, 0, 250)
		}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
	end
	
	return modalBackground
end

-- Create a text input field
function UIComponents:CreateTextInput(placeholder, defaultText, size, position)
	-- Default values
	placeholder = placeholder or "Enter text..."
	size = size or UDim2.new(0, 200, 0, 40)
	position = position or UDim2.new(0.5, 0, 0.5, 0)
	
	-- Create input container
	local inputContainer = Instance.new("Frame")
	inputContainer.Size = size
	inputContainer.Position = position
	inputContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	inputContainer.BackgroundColor3 = UIStyle.Colors.White
	inputContainer.BorderSizePixel = UIStyle.Sizes.BorderSize
	inputContainer.BorderColor3 = UIStyle.Colors.Border
	inputContainer.Name = "TextInputContainer"
	
	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UIStyle.Sizes.BorderRadius)
	corner.Parent = inputContainer
	
	-- Create text box
	local textBox = Instance.new("TextBox")
	textBox.Size = UDim2.new(1, -20, 1, 0)
	textBox.Position = UDim2.new(0, 10, 0, 0)
	textBox.BackgroundTransparency = 1
	textBox.Font = UIStyle.Fonts.Input
	textBox.TextSize = UIStyle.Sizes.BodyText
	textBox.TextColor3 = UIStyle.Colors.TextPrimary
	textBox.PlaceholderText = placeholder
	textBox.Text = defaultText or ""
	textBox.ClearTextOnFocus = false
	textBox.ClipsDescendants = true
	textBox.Name = "TextBox"
	textBox.Parent = inputContainer
	
	-- Add focus/unfocus effects
	textBox.Focused:Connect(function()
		createTween(inputContainer, {
			BorderColor3 = UIStyle.Colors.Primary
		}, 0.2):Play()
	end)
	
	textBox.FocusLost:Connect(function()
		createTween(inputContainer, {
			BorderColor3 = UIStyle.Colors.Border
		}, 0.2):Play()
	end)
	
	-- Add to UIRegistry if available
	local uiRegistry = getUIRegistry()
	if uiRegistry then
		uiRegistry:RegisterTemplate("TextInput_" .. placeholder, inputContainer)
	end
	
	return inputContainer
end

-- Create a progress bar
function UIComponents:CreateProgressBar(value, maxValue, size, position, color)
	-- Default values
	value = value or 50
	maxValue = maxValue or 100
	size = size or UDim2.new(0, 200, 0, 20)
	position = position or UDim2.new(0.5, 0, 0.5, 0)
	color = color or UIStyle.Colors.Primary
	
	-- Create container
	local container = Instance.new("Frame")
	container.Size = size
	container.Position = position
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundColor3 = UIStyle.Colors.Light
	container.BorderSizePixel = 0
	container.Name = "ProgressBarContainer"
	
	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UIStyle.Sizes.BorderRadius)
	corner.Parent = container
	
	-- Create fill bar
	local fillBar = Instance.new("Frame")
	fillBar.Size = UDim2.new(value / maxValue, 0, 1, 0)
	fillBar.BackgroundColor3 = color
	fillBar.BorderSizePixel = 0
	fillBar.Name = "FillBar"
	fillBar.Parent = container
	
	-- Add corner rounding to fill bar
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, UIStyle.Sizes.BorderRadius)
	fillCorner.Parent = fillBar
	
	-- Create value label
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(1, 0, 1, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = UIStyle.Fonts.Body
	valueLabel.TextSize = UIStyle.Sizes.BodyText
	valueLabel.TextColor3 = UIStyle.Colors.White
	valueLabel.Text = tostring(value) .. " / " .. tostring(maxValue)
	valueLabel.Name = "ValueLabel"
	valueLabel.Parent = container
	
	-- Add to UIRegistry if available
	local uiRegistry = getUIRegistry()
	if uiRegistry then
		uiRegistry:RegisterTemplate("ProgressBar", container)
		
		-- Register for dynamic updates
		uiRegistry:RegisterDynamicElement(container, function(instance)
			-- This function would update the progress bar if needed
			-- For this example, it doesn't do anything
		end)
	end
	
	-- Update function
	container.UpdateProgress = function(newValue)
		-- Validate value
		newValue = math.clamp(newValue, 0, maxValue)
		
		-- Update fill bar
		createTween(fillBar, {
			Size = UDim2.new(newValue / maxValue, 0, 1, 0)
		}, 0.3):Play()
		
		-- Update label
		valueLabel.Text = tostring(newValue) .. " / " .. tostring(maxValue)
	end
	
	return container
end

-- Create a toggle switch
function UIComponents:CreateToggleSwitch(isOn, size, position, onToggleCallback)
	-- Default values
	isOn = isOn or false
	size = size or UDim2.new(0, 50, 0, 25)
	position = position or UDim2.new(0.5, 0, 0.5, 0)
	
	-- Create container
	local container = Instance.new("Frame")
	container.Size = size
	container.Position = position
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundColor3 = isOn and UIStyle.Colors.Primary or UIStyle.Colors.TextSecondary
	container.BorderSizePixel = 0
	container.Name = "ToggleSwitchContainer"
	
	-- Add corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0) -- Make it fully rounded
	corner.Parent = container
	
	-- Create toggle knob
	local knob = Instance.new("Frame")
	local knobSize = container.Size.Y.Offset * 0.8
	knob.Size = UDim2.new(0, knobSize, 0, knobSize)
	knob.Position = UDim2.new(isOn and 0.8 or 0.2, 0, 0.5, 0)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.BackgroundColor3 = UIStyle.Colors.White
	knob.BorderSizePixel = 0
	knob.Name = "Knob"
	knob.Parent = container
	
	-- Add corner rounding to knob
	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0) -- Make it fully rounded
	knobCorner.Parent = knob
	
	-- Add click functionality
	container.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			isOn = not isOn
			
			-- Animate the transition
			createTween(container, {
				BackgroundColor3 = isOn and UIStyle.Colors.Primary or UIStyle.Colors.TextSecondary
			}, 0.3):Play()
			
			createTween(knob, {
				Position = UDim2.new(isOn and 0.8 or 0.2, 0, 0.5, 0)
			}, 0.3):Play()
			
			-- Call the callback if provided
			if onToggleCallback then
				onToggleCallback(isOn)
			end
		end
	end)
	
	-- Add to UIRegistry if available
	local uiRegistry = getUIRegistry()
	if uiRegistry then
		uiRegistry:RegisterTemplate("ToggleSwitch", container)
	end
	
	-- Public methods
	container.IsOn = function()
		return isOn
	end
	
	container.SetState = function(state)
		if isOn ~= state then
			isOn = state
			
			-- Animate the transition
			createTween(container, {
				BackgroundColor3 = isOn and UIStyle.Colors.Primary or UIStyle.Colors.TextSecondary
			}, 0.3):Play()
			
			createTween(knob, {
				Position = UDim2.new(isOn and 0.8 or 0.2, 0, 0.5, 0)
			}, 0.3):Play()
			
			-- Call the callback if provided
			if onToggleCallback then
				onToggleCallback(isOn)
			end
		end
	end
	
	return container
end

-- Initialize UIComponents
UIComponents:Initialize()

-- Register with ModuleLoader if available
local moduleLoader = getModuleLoader()
if moduleLoader then
	moduleLoader:RegisterPath("UIComponents", "ReplicatedStorage.shared.UIComponents")
	log("Registered with ModuleLoader")
end

return UIComponents
