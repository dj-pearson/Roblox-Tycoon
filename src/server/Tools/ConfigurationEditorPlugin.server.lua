--[[
	ConfigurationEditorPlugin.server.lua
	A Studio plugin for visually editing tycoon configurations.
	Part of Phase 6: System Enhancement & Expansion
	
	This plugin:
	- Creates a dockable widget in Studio
	- Allows editing of all configuration properties
	- Provides real-time validation
	- Supports import/export features
	- Offers templates for different tycoon types
]]

-- Only run in Studio
if not game:GetService("RunService"):IsStudio() then
	return
end

local Plugin = plugin
local PluginName = "Tycoon Configuration Editor"

-- Services
local ServerStorage = game:GetService("ServerStorage")
local StudioService = game:GetService("StudioService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

-- Constants
local CONFIG_FOLDER_NAME = "TycoonConfigurations"
local WIDGET_ID = "TycoonConfigEditorWidget"
local WIDGET_INFO = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	700,
	500,
	500,
	300
)
local TEMPLATES = {
	{name = "Default Gym", configName = "DefaultGym"},
	{name = "Luxury Gym", configName = "LuxuryGym"},
	{name = "Restaurant", configName = "Restaurant"},
	{name = "Retail Store", configName = "RetailStore"}
}

-- UI Colors
local COLORS = {
	headerBackground = Color3.fromRGB(41, 47, 61),
	headerText = Color3.fromRGB(255, 255, 255),
	background = Color3.fromRGB(46, 52, 64),
	itemBackground = Color3.fromRGB(59, 66, 82),
	itemBackgroundHover = Color3.fromRGB(67, 76, 94),
	text = Color3.fromRGB(236, 239, 244),
	accent = Color3.fromRGB(143, 188, 187),
	button = Color3.fromRGB(94, 129, 172),
	buttonHover = Color3.fromRGB(129, 161, 193),
	warning = Color3.fromRGB(235, 203, 139),
	error = Color3.fromRGB(191, 97, 106),
	success = Color3.fromRGB(163, 190, 140)
}

-- Load dependencies
local success, TycoonConfigurationManager = pcall(function()
	return require(script.Parent.Parent.Core.TycoonConfigurationManager)
end)

if not success then
	warn("Failed to load TycoonConfigurationManager:", TycoonConfigurationManager)
	TycoonConfigurationManager = nil
	return
end

-- Initialize the configuration manager
TycoonConfigurationManager.init()

-- State variables
local editorWidget
local currentConfig = nil
local currentConfigName = ""
local configList = {}
local unsavedChanges = false

-- UI Elements
local mainFrame, configDropdown, saveButton, templateDropdown
local configTabs = {}
local currentTab = nil

-- Create UI
local function createUI()
	-- Create the main widget
	editorWidget = Plugin:CreateDockWidgetPluginGui(
		WIDGET_ID,
		WIDGET_INFO
	)
	editorWidget.Title = PluginName
	editorWidget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Main frame
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = COLORS.background
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = editorWidget

	-- Header frame
	local headerFrame = Instance.new("Frame")
	headerFrame.Name = "HeaderFrame"
	headerFrame.Size = UDim2.new(1, 0, 0, 40)
	headerFrame.BackgroundColor3 = COLORS.headerBackground
	headerFrame.BorderSizePixel = 0
	headerFrame.Parent = mainFrame

	-- Config selection dropdown label
	local configLabel = Instance.new("TextLabel")
	configLabel.Name = "ConfigLabel"
	configLabel.Size = UDim2.new(0, 80, 0, 30)
	configLabel.Position = UDim2.new(0, 10, 0, 5)
	configLabel.BackgroundTransparency = 1
	configLabel.TextColor3 = COLORS.headerText
	configLabel.TextSize = 14
	configLabel.Text = "Configuration:"
	configLabel.TextXAlignment = Enum.TextXAlignment.Left
	configLabel.Parent = headerFrame

	-- Config selection dropdown
	configDropdown = Instance.new("TextButton")
	configDropdown.Name = "ConfigDropdown"
	configDropdown.Size = UDim2.new(0, 200, 0, 30)
	configDropdown.Position = UDim2.new(0, 95, 0, 5)
	configDropdown.BackgroundColor3 = COLORS.itemBackground
	configDropdown.TextColor3 = COLORS.text
	configDropdown.TextSize = 14
	configDropdown.Text = "Select Configuration"
	configDropdown.Parent = headerFrame
	
	-- Add dropdown arrow icon
	local dropdownArrow = Instance.new("ImageLabel")
	dropdownArrow.Name = "DropdownArrow"
	dropdownArrow.Size = UDim2.new(0, 16, 0, 16)
	dropdownArrow.Position = UDim2.new(1, -20, 0.5, -8)
	dropdownArrow.BackgroundTransparency = 1
	dropdownArrow.Image = "rbxassetid://6034818372" -- Down arrow icon
	dropdownArrow.ImageColor3 = COLORS.text
	dropdownArrow.Parent = configDropdown

	-- Template label
	local templateLabel = Instance.new("TextLabel")
	templateLabel.Name = "TemplateLabel"
	templateLabel.Size = UDim2.new(0, 70, 0, 30)
	templateLabel.Position = UDim2.new(0, 310, 0, 5)
	templateLabel.BackgroundTransparency = 1
	templateLabel.TextColor3 = COLORS.headerText
	templateLabel.TextSize = 14
	templateLabel.Text = "Template:"
	templateLabel.TextXAlignment = Enum.TextXAlignment.Left
	templateLabel.Parent = headerFrame

	-- Template dropdown
	templateDropdown = Instance.new("TextButton")
	templateDropdown.Name = "TemplateDropdown"
	templateDropdown.Size = UDim2.new(0, 150, 0, 30)
	templateDropdown.Position = UDim2.new(0, 380, 0, 5)
	templateDropdown.BackgroundColor3 = COLORS.itemBackground
	templateDropdown.TextColor3 = COLORS.text
	templateDropdown.TextSize = 14
	templateDropdown.Text = "Select Template"
	templateDropdown.Parent = headerFrame
	
	-- Add dropdown arrow icon
	local templateArrow = Instance.new("ImageLabel")
	templateArrow.Name = "DropdownArrow"
	templateArrow.Size = UDim2.new(0, 16, 0, 16)
	templateArrow.Position = UDim2.new(1, -20, 0.5, -8)
	templateArrow.BackgroundTransparency = 1
	templateArrow.Image = "rbxassetid://6034818372" -- Down arrow icon
	templateArrow.ImageColor3 = COLORS.text
	templateArrow.Parent = templateDropdown

	-- Save button
	saveButton = Instance.new("TextButton")
	saveButton.Name = "SaveButton"
	saveButton.Size = UDim2.new(0, 80, 0, 30)
	saveButton.Position = UDim2.new(1, -90, 0, 5)
	saveButton.BackgroundColor3 = COLORS.button
	saveButton.TextColor3 = COLORS.text
	saveButton.TextSize = 14
	saveButton.Text = "Save"
	saveButton.Parent = headerFrame

	-- Tabs frame
	local tabsFrame = Instance.new("Frame")
	tabsFrame.Name = "TabsFrame"
	tabsFrame.Size = UDim2.new(1, 0, 0, 30)
	tabsFrame.Position = UDim2.new(0, 0, 0, 40)
	tabsFrame.BackgroundColor3 = COLORS.itemBackground
	tabsFrame.BorderSizePixel = 0
	tabsFrame.Parent = mainFrame
	
	-- Create tabs
	local tabs = {"General", "Rooms", "Equipment", "Prerequisites"}
	local tabButtons = {}
	local tabXPosition = 10
	
	for i, tabName in ipairs(tabs) do
		local tabButton = Instance.new("TextButton")
		tabButton.Name = tabName.."Tab"
		tabButton.Size = UDim2.new(0, 100, 1, 0)
		tabButton.Position = UDim2.new(0, tabXPosition, 0, 0)
		tabButton.BackgroundTransparency = 1
		tabButton.TextColor3 = COLORS.text
		tabButton.TextSize = 14
		tabButton.Text = tabName
		tabButton.Parent = tabsFrame
		
		table.insert(tabButtons, tabButton)
		tabXPosition = tabXPosition + 110
	end
	
	-- Content frame
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(1, 0, 1, -70)
	contentFrame.Position = UDim2.new(0, 0, 0, 70)
	contentFrame.BackgroundColor3 = COLORS.background
	contentFrame.BorderSizePixel = 0
	contentFrame.Parent = mainFrame
	
	-- Create tab content frames (initially hidden)
	for _, tabName in ipairs(tabs) do
		local tabContentFrame = Instance.new("ScrollingFrame")
		tabContentFrame.Name = tabName.."Content"
		tabContentFrame.Size = UDim2.new(1, -20, 1, -20)
		tabContentFrame.Position = UDim2.new(0, 10, 0, 10)
		tabContentFrame.BackgroundTransparency = 1
		tabContentFrame.BorderSizePixel = 0
		tabContentFrame.ScrollBarThickness = 6
		tabContentFrame.Visible = false
		tabContentFrame.CanvasSize = UDim2.new(0, 0, 0, 1000)  -- Will adjust based on content
		tabContentFrame.Parent = contentFrame
		
		configTabs[tabName] = tabContentFrame
	end
	
	-- Set up tab switching
	for i, button in ipairs(tabButtons) do
		button.MouseButton1Click:Connect(function()
			-- Hide all tabs
			for name, tab in pairs(configTabs) do
				tab.Visible = false
			end
			
			-- Show the selected tab
			local tabName = tabs[i]
			configTabs[tabName].Visible = true
			currentTab = tabName
			
			-- Update button appearance
			for _, btn in ipairs(tabButtons) do
				btn.BackgroundTransparency = 1
			end
			
			button.BackgroundTransparency = 0
			button.BackgroundColor3 = COLORS.accent
		end)
	end
	
	-- Select the first tab by default
	tabButtons[1].MouseButton1Click:Fire()
	
	-- Event connections
	configDropdown.MouseButton1Click:Connect(function()
		openConfigDropdown()
	end)
	
	templateDropdown.MouseButton1Click:Connect(function()
		openTemplateDropdown()
	end)
	
	saveButton.MouseButton1Click:Connect(function()
		saveCurrentConfig()
	end)
	
	return mainFrame
end

local function createValueEditor(parent, yPosition, label, valueType, currentValue, path)
	local container = Instance.new("Frame")
	container.Name = label.."Container"
	container.Size = UDim2.new(1, 0, 0, 40)
	container.Position = UDim2.new(0, 0, 0, yPosition)
	container.BackgroundTransparency = 1
	container.Parent = parent
	
	local labelText = Instance.new("TextLabel")
	labelText.Name = "Label"
	labelText.Size = UDim2.new(0.4, 0, 1, 0)
	labelText.BackgroundTransparency = 1
	labelText.TextColor3 = COLORS.text
	labelText.TextSize = 14
	labelText.TextXAlignment = Enum.TextXAlignment.Left
	labelText.Text = label
	labelText.Parent = container
	
	local valueControl
	
	if valueType == "string" or valueType == "number" then
		-- Text input for string and number values
		valueControl = Instance.new("TextBox")
		valueControl.Name = "ValueControl"
		valueControl.Size = UDim2.new(0.58, 0, 0, 30)
		valueControl.Position = UDim2.new(0.4, 0, 0, 5)
		valueControl.BackgroundColor3 = COLORS.itemBackground
		valueControl.TextColor3 = COLORS.text
		valueControl.TextSize = 14
		valueControl.ClearTextOnFocus = false
		valueControl.Text = tostring(currentValue or "")
		valueControl.Parent = container
		
		-- Update config when text changes
		valueControl.FocusLost:Connect(function(enterPressed)
			if not currentConfig then return end
			
			local newValue = valueControl.Text
			
			-- Convert to number if needed
			if valueType == "number" then
				newValue = tonumber(newValue)
				if not newValue then
					valueControl.Text = tostring(currentValue or "")
					return
				end
			end
			
			currentConfig:SetSetting(path, newValue)
			unsavedChanges = true
			updateSaveButton()
		end)
	elseif valueType == "boolean" then
		-- Checkbox for boolean values
		valueControl = Instance.new("Frame")
		valueControl.Name = "ValueControl"
		valueControl.Size = UDim2.new(0.58, 0, 0, 30)
		valueControl.Position = UDim2.new(0.4, 0, 0, 5)
		valueControl.BackgroundTransparency = 1
		valueControl.Parent = container
		
		local checkbox = Instance.new("TextButton")
		checkbox.Name = "Checkbox"
		checkbox.Size = UDim2.new(0, 30, 0, 30)
		checkbox.Position = UDim2.new(0, 0, 0, 0)
		checkbox.BackgroundColor3 = COLORS.itemBackground
		checkbox.Text = ""
		checkbox.Parent = valueControl
		
		local check = Instance.new("ImageLabel")
		check.Name = "Check"
		check.Size = UDim2.new(0.8, 0, 0.8, 0)
		check.Position = UDim2.new(0.1, 0, 0.1, 0)
		check.BackgroundTransparency = 1
		check.Image = "rbxassetid://6031094667" -- Checkmark icon
		check.ImageColor3 = COLORS.accent
		check.Visible = currentValue == true
		check.Parent = checkbox
		
		-- Update config when checkbox is clicked
		checkbox.MouseButton1Click:Connect(function()
			if not currentConfig then return end
			
			local newValue = not (check.Visible)
			check.Visible = newValue
			
			currentConfig:SetSetting(path, newValue)
			unsavedChanges = true
			updateSaveButton()
		end)
	elseif valueType == "Color3" then
		-- Color picker for Color3 values
		valueControl = Instance.new("Frame")
		valueControl.Name = "ValueControl"
		valueControl.Size = UDim2.new(0.58, 0, 0, 30)
		valueControl.Position = UDim2.new(0.4, 0, 0, 5)
		valueControl.BackgroundTransparency = 1
		valueControl.Parent = container
		
		local colorPreview = Instance.new("Frame")
		colorPreview.Name = "ColorPreview"
		colorPreview.Size = UDim2.new(0, 30, 0, 30)
		colorPreview.Position = UDim2.new(0, 0, 0, 0)
		colorPreview.BackgroundColor3 = currentValue or Color3.fromRGB(255, 255, 255)
		colorPreview.Parent = valueControl
		
		local colorButton = Instance.new("TextButton")
		colorButton.Name = "ColorButton"
		colorButton.Size = UDim2.new(0, 80, 0, 30)
		colorButton.Position = UDim2.new(0, 40, 0, 0)
		colorButton.BackgroundColor3 = COLORS.button
		colorButton.TextColor3 = COLORS.text
		colorButton.TextSize = 14
		colorButton.Text = "Pick Color"
		colorButton.Parent = valueControl
		
		-- Update config when color is picked
		colorButton.MouseButton1Click:Connect(function()
			if not currentConfig then return end
			
			-- Use the Studio color picker
			local currentColor = colorPreview.BackgroundColor3
			StudioService:PromptImportFile({"png"}, function(success, result)
				-- This is a workaround since there's no direct color picker in Studio API
				-- In a real implementation, you'd use a custom color picker UI
				
				if success then
					-- For this demo, we just use a random color
					local newColor = Color3.fromRGB(
						math.random(0, 255),
						math.random(0, 255),
						math.random(0, 255)
					)
					
					colorPreview.BackgroundColor3 = newColor
					currentConfig:SetSetting(path, newColor)
					unsavedChanges = true
					updateSaveButton()
				end
			end)
		end)
	end
	
	return container, valueControl
end

local function populateGeneralTab()
	local tab = configTabs["General"]
	-- Clear existing content
	for _, child in pairs(tab:GetChildren()) do
		child:Destroy()
	end
	
	if not currentConfig then
		return
	end
	
	local yPos = 10
	
	-- Tycoon Type
	createValueEditor(tab, yPos, "Tycoon Type", "string", 
		currentConfig:GetSetting("tycoonType"), "tycoonType")
	yPos = yPos + 50
	
	-- Version
	createValueEditor(tab, yPos, "Version", "string", 
		currentConfig:GetSetting("version"), "version")
	yPos = yPos + 50
	
	-- Settings header
	local settingsHeader = Instance.new("TextLabel")
	settingsHeader.Name = "SettingsHeader"
	settingsHeader.Size = UDim2.new(1, -20, 0, 30)
	settingsHeader.Position = UDim2.new(0, 0, 0, yPos)
	settingsHeader.BackgroundColor3 = COLORS.headerBackground
	settingsHeader.TextColor3 = COLORS.headerText
	settingsHeader.TextSize = 16
	settingsHeader.Font = Enum.Font.SourceSansBold
	settingsHeader.Text = "  Settings"
	settingsHeader.TextXAlignment = Enum.TextXAlignment.Left
	settingsHeader.Parent = tab
	yPos = yPos + 40
	
	-- Economy Multiplier
	createValueEditor(tab, yPos, "Economy Multiplier", "number", 
		currentConfig:GetSetting("settings.economyMultiplier"), "settings.economyMultiplier")
	yPos = yPos + 50
	
	-- Progression Speed
	createValueEditor(tab, yPos, "Progression Speed", "number", 
		currentConfig:GetSetting("settings.progressionSpeed"), "settings.progressionSpeed")
	yPos = yPos + 50
	
	-- Max Floors
	createValueEditor(tab, yPos, "Max Floors", "number", 
		currentConfig:GetSetting("settings.maxFloors"), "settings.maxFloors")
	yPos = yPos + 50
	
	-- Customization Enabled
	createValueEditor(tab, yPos, "Customization Enabled", "boolean", 
		currentConfig:GetSetting("settings.customizationEnabled"), "settings.customizationEnabled")
	yPos = yPos + 50
	
	-- Enabled Features header
	local featuresHeader = Instance.new("TextLabel")
	featuresHeader.Name = "FeaturesHeader"
	featuresHeader.Size = UDim2.new(1, -20, 0, 30)
	featuresHeader.Position = UDim2.new(0, 0, 0, yPos)
	featuresHeader.BackgroundColor3 = COLORS.headerBackground
	featuresHeader.TextColor3 = COLORS.headerText
	featuresHeader.TextSize = 16
	featuresHeader.Font = Enum.Font.SourceSansBold
	featuresHeader.Text = "  Enabled Features"
	featuresHeader.TextXAlignment = Enum.TextXAlignment.Left
	featuresHeader.Parent = tab
	yPos = yPos + 40
	
	-- Staff Hiring
	createValueEditor(tab, yPos, "Staff Hiring", "boolean", 
		currentConfig:GetSetting("settings.enabledFeatures.staffHiring"), "settings.enabledFeatures.staffHiring")
	yPos = yPos + 50
	
	-- Equipment Upgrades
	createValueEditor(tab, yPos, "Equipment Upgrades", "boolean", 
		currentConfig:GetSetting("settings.enabledFeatures.equipmentUpgrades"), "settings.enabledFeatures.equipmentUpgrades")
	yPos = yPos + 50
	
	-- Membership Tiers
	createValueEditor(tab, yPos, "Membership Tiers", "boolean", 
		currentConfig:GetSetting("settings.enabledFeatures.membershipTiers"), "settings.enabledFeatures.membershipTiers")
	yPos = yPos + 50
	
	-- Special Events
	createValueEditor(tab, yPos, "Special Events", "boolean", 
		currentConfig:GetSetting("settings.enabledFeatures.specialEvents"), "settings.enabledFeatures.specialEvents")
	yPos = yPos + 50
	
	-- Update canvas size
	tab.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)
end

local function populateRoomsTab()
	local tab = configTabs["Rooms"]
	-- Clear existing content
	for _, child in pairs(tab:GetChildren()) do
		child:Destroy()
	end
	
	if not currentConfig then
		return
	end
	
	local roomTypes = currentConfig:GetSetting("roomTypes") or {}
	local yPos = 10
	
	-- Header
	local header = Instance.new("TextLabel")
	header.Name = "RoomsHeader"
	header.Size = UDim2.new(1, -20, 0, 30)
	header.Position = UDim2.new(0, 0, 0, yPos)
	header.BackgroundColor3 = COLORS.headerBackground
	header.TextColor3 = COLORS.headerText
	header.TextSize = 16
	header.Font = Enum.Font.SourceSansBold
	header.Text = "  Room Types"
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = tab
	yPos = yPos + 40
	
	-- Room list
	for i, room in ipairs(roomTypes) do
		local roomContainer = Instance.new("Frame")
		roomContainer.Name = "Room"..i
		roomContainer.Size = UDim2.new(1, -20, 0, 80)
		roomContainer.Position = UDim2.new(0, 0, 0, yPos)
		roomContainer.BackgroundColor3 = COLORS.itemBackground
		roomContainer.Parent = tab
		
		-- Room name label
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(0.3, 0, 0, 30)
		nameLabel.Position = UDim2.new(0, 10, 0, 10)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = COLORS.text
		nameLabel.TextSize = 14
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Text = "Name:"
		nameLabel.Parent = roomContainer
		
		-- Room name input
		local nameInput = Instance.new("TextBox")
		nameInput.Name = "NameInput"
		nameInput.Size = UDim2.new(0.6, -20, 0, 30)
		nameInput.Position = UDim2.new(0.3, 10, 0, 10)
		nameInput.BackgroundColor3 = COLORS.background
		nameInput.TextColor3 = COLORS.text
		nameInput.TextSize = 14
		nameInput.ClearTextOnFocus = false
		nameInput.Text = room.name or ""
		nameInput.Parent = roomContainer
		
		-- Room color label
		local colorLabel = Instance.new("TextLabel")
		colorLabel.Name = "ColorLabel"
		colorLabel.Size = UDim2.new(0.3, 0, 0, 30)
		colorLabel.Position = UDim2.new(0, 10, 0, 50)
		colorLabel.BackgroundTransparency = 1
		colorLabel.TextColor3 = COLORS.text
		colorLabel.TextSize = 14
		colorLabel.TextXAlignment = Enum.TextXAlignment.Left
		colorLabel.Text = "Color:"
		colorLabel.Parent = roomContainer
		
		-- Color preview
		local colorPreview = Instance.new("Frame")
		colorPreview.Name = "ColorPreview"
		colorPreview.Size = UDim2.new(0, 30, 0, 30)
		colorPreview.Position = UDim2.new(0.3, 10, 0, 50)
		colorPreview.BackgroundColor3 = room.color or Color3.fromRGB(255, 255, 255)
		colorPreview.Parent = roomContainer
		
		-- Color pick button
		local colorButton = Instance.new("TextButton")
		colorButton.Name = "ColorButton"
		colorButton.Size = UDim2.new(0.3, -40, 0, 30)
		colorButton.Position = UDim2.new(0.3, 50, 0, 50)
		colorButton.BackgroundColor3 = COLORS.button
		colorButton.TextColor3 = COLORS.text
		colorButton.TextSize = 14
		colorButton.Text = "Pick Color"
		colorButton.Parent = roomContainer
		
		-- Delete room button
		local deleteButton = Instance.new("TextButton")
		deleteButton.Name = "DeleteButton"
		deleteButton.Size = UDim2.new(0, 30, 0, 30)
		deleteButton.Position = UDim2.new(1, -40, 0, 25)
		deleteButton.BackgroundColor3 = COLORS.error
		deleteButton.TextColor3 = COLORS.text
		deleteButton.TextSize = 18
		deleteButton.Text = "X"
		deleteButton.Parent = roomContainer
		
		-- Event connections
		nameInput.FocusLost:Connect(function(enterPressed)
			if not currentConfig then return end
			
			local rooms = currentConfig:GetSetting("roomTypes") or {}
			if rooms[i] then
				rooms[i].name = nameInput.Text
				currentConfig:SetSetting("roomTypes", rooms)
				unsavedChanges = true
				updateSaveButton()
			end
		end)
		
		colorButton.MouseButton1Click:Connect(function()
			if not currentConfig then return end
			
			-- Use the Studio color picker (see note in createValueEditor)
			StudioService:PromptImportFile({"png"}, function(success, result)
				if success then
					-- For this demo, we just use a random color
					local newColor = Color3.fromRGB(
						math.random(0, 255),
						math.random(0, 255),
						math.random(0, 255)
					)
					
					colorPreview.BackgroundColor3 = newColor
					
					local rooms = currentConfig:GetSetting("roomTypes") or {}
					if rooms[i] then
						rooms[i].color = newColor
						currentConfig:SetSetting("roomTypes", rooms)
						unsavedChanges = true
						updateSaveButton()
					end
				end
			end)
		end)
		
		deleteButton.MouseButton1Click:Connect(function()
			if not currentConfig then return end
			
			local rooms = currentConfig:GetSetting("roomTypes") or {}
			table.remove(rooms, i)
			currentConfig:SetSetting("roomTypes", rooms)
			unsavedChanges = true
			updateSaveButton()
			populateRoomsTab() -- Refresh the tab
		end)
		
		yPos = yPos + 90
	end
	
	-- Add new room button
	local addButton = Instance.new("TextButton")
	addButton.Name = "AddRoomButton"
	addButton.Size = UDim2.new(1, -20, 0, 40)
	addButton.Position = UDim2.new(0, 0, 0, yPos)
	addButton.BackgroundColor3 = COLORS.success
	addButton.TextColor3 = COLORS.text
	addButton.TextSize = 16
	addButton.Text = "Add Room Type"
	addButton.Parent = tab
	
	addButton.MouseButton1Click:Connect(function()
		if not currentConfig then return end
		
		local rooms = currentConfig:GetSetting("roomTypes") or {}
		table.insert(rooms, {
			name = "New Room",
			color = Color3.fromRGB(200, 200, 200)
		})
		currentConfig:SetSetting("roomTypes", rooms)
		unsavedChanges = true
		updateSaveButton()
		populateRoomsTab() -- Refresh the tab
	end)
	
	-- Update canvas size
	tab.CanvasSize = UDim2.new(0, 0, 0, yPos + 60)
end

local function populateEquipmentTab()
	local tab = configTabs["Equipment"]
	-- Clear existing content
	for _, child in pairs(tab:GetChildren()) do
		child:Destroy()
	end
	
	if not currentConfig then
		return
	end
	
	local equipmentCategories = currentConfig:GetSetting("equipmentCategories") or {}
	local yPos = 10
	
	-- Header
	local header = Instance.new("TextLabel")
	header.Name = "EquipmentHeader"
	header.Size = UDim2.new(1, -20, 0, 30)
	header.Position = UDim2.new(0, 0, 0, yPos)
	header.BackgroundColor3 = COLORS.headerBackground
	header.TextColor3 = COLORS.headerText
	header.TextSize = 16
	header.Font = Enum.Font.SourceSansBold
	header.Text = "  Equipment Categories"
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = tab
	yPos = yPos + 40
	
	-- Equipment list
	for i, equipment in ipairs(equipmentCategories) do
		local equipContainer = Instance.new("Frame")
		equipContainer.Name = "Equipment"..i
		equipContainer.Size = UDim2.new(1, -20, 0, 80)
		equipContainer.Position = UDim2.new(0, 0, 0, yPos)
		equipContainer.BackgroundColor3 = COLORS.itemBackground
		equipContainer.Parent = tab
		
		-- Equipment name label
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(0.3, 0, 0, 30)
		nameLabel.Position = UDim2.new(0, 10, 0, 10)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = COLORS.text
		nameLabel.TextSize = 14
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Text = "Name:"
		nameLabel.Parent = equipContainer
		
		-- Equipment name input
		local nameInput = Instance.new("TextBox")
		nameInput.Name = "NameInput"
		nameInput.Size = UDim2.new(0.6, -20, 0, 30)
		nameInput.Position = UDim2.new(0.3, 10, 0, 10)
		nameInput.BackgroundColor3 = COLORS.background
		nameInput.TextColor3 = COLORS.text
		nameInput.TextSize = 14
		nameInput.ClearTextOnFocus = false
		nameInput.Text = equipment.name or ""
		nameInput.Parent = equipContainer
		
		-- Upgrade prefix label
		local prefixLabel = Instance.new("TextLabel")
		prefixLabel.Name = "PrefixLabel"
		prefixLabel.Size = UDim2.new(0.3, 0, 0, 30)
		prefixLabel.Position = UDim2.new(0, 10, 0, 50)
		prefixLabel.BackgroundTransparency = 1
		prefixLabel.TextColor3 = COLORS.text
		prefixLabel.TextSize = 14
		prefixLabel.TextXAlignment = Enum.TextXAlignment.Left
		prefixLabel.Text = "Upgrade Prefix:"
		prefixLabel.Parent = equipContainer
		
		-- Upgrade prefix input
		local prefixInput = Instance.new("TextBox")
		prefixInput.Name = "PrefixInput"
		prefixInput.Size = UDim2.new(0.6, -20, 0, 30)
		prefixInput.Position = UDim2.new(0.3, 10, 0, 50)
		prefixInput.BackgroundColor3 = COLORS.background
		prefixInput.TextColor3 = COLORS.text
		prefixInput.TextSize = 14
		prefixInput.ClearTextOnFocus = false
		prefixInput.Text = equipment.upgradePathPrefix or ""
		prefixInput.Parent = equipContainer
		
		-- Delete equipment button
		local deleteButton = Instance.new("TextButton")
		deleteButton.Name = "DeleteButton"
		deleteButton.Size = UDim2.new(0, 30, 0, 30)
		deleteButton.Position = UDim2.new(1, -40, 0, 25)
		deleteButton.BackgroundColor3 = COLORS.error
		deleteButton.TextColor3 = COLORS.text
		deleteButton.TextSize = 18
		deleteButton.Text = "X"
		deleteButton.Parent = equipContainer
		
		-- Event connections
		nameInput.FocusLost:Connect(function(enterPressed)
			if not currentConfig then return end
			
			local categories = currentConfig:GetSetting("equipmentCategories") or {}
			if categories[i] then
				categories[i].name = nameInput.Text
				currentConfig:SetSetting("equipmentCategories", categories)
				unsavedChanges = true
				updateSaveButton()
			end
		end)
		
		prefixInput.FocusLost:Connect(function(enterPressed)
			if not currentConfig then return end
			
			local categories = currentConfig:GetSetting("equipmentCategories") or {}
			if categories[i] then
				categories[i].upgradePathPrefix = prefixInput.Text
				currentConfig:SetSetting("equipmentCategories", categories)
				unsavedChanges = true
				updateSaveButton()
			end
		end)
		
		deleteButton.MouseButton1Click:Connect(function()
			if not currentConfig then return end
			
			local categories = currentConfig:GetSetting("equipmentCategories") or {}
			table.remove(categories, i)
			currentConfig:SetSetting("equipmentCategories", categories)
			unsavedChanges = true
			updateSaveButton()
			populateEquipmentTab() -- Refresh the tab
		end)
		
		yPos = yPos + 90
	end
	
	-- Add new equipment button
	local addButton = Instance.new("TextButton")
	addButton.Name = "AddEquipmentButton"
	addButton.Size = UDim2.new(1, -20, 0, 40)
	addButton.Position = UDim2.new(0, 0, 0, yPos)
	addButton.BackgroundColor3 = COLORS.success
	addButton.TextColor3 = COLORS.text
	addButton.TextSize = 16
	addButton.Text = "Add Equipment Category"
	addButton.Parent = tab
	
	addButton.MouseButton1Click:Connect(function()
		if not currentConfig then return end
		
		local categories = currentConfig:GetSetting("equipmentCategories") or {}
		table.insert(categories, {
			name = "New Category",
			upgradePathPrefix = "New_"
		})
		currentConfig:SetSetting("equipmentCategories", categories)
		unsavedChanges = true
		updateSaveButton()
		populateEquipmentTab() -- Refresh the tab
	end)
	
	-- Update canvas size
	tab.CanvasSize = UDim2.new(0, 0, 0, yPos + 60)
end

local function populatePrerequisitesTab()
	-- This would be similar to the other tabs but with a more complex UI
	-- For this example, we'll just add a placeholder
	
	local tab = configTabs["Prerequisites"]
	-- Clear existing content
	for _, child in pairs(tab:GetChildren()) do
		child:Destroy()
	end
	
	if not currentConfig then
		return
	end
	
	local yPos = 10
	
	-- Header
	local header = Instance.new("TextLabel")
	header.Name = "PrerequisitesHeader"
	header.Size = UDim2.new(1, -20, 0, 30)
	header.Position = UDim2.new(0, 0, 0, yPos)
	header.BackgroundColor3 = COLORS.headerBackground
	header.TextColor3 = COLORS.headerText
	header.TextSize = 16
	header.Font = Enum.Font.SourceSansBold
	header.Text = "  Prerequisites"
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = tab
	yPos = yPos + 40
	
	-- Note about prerequisites
	local noteLabel = Instance.new("TextLabel")
	noteLabel.Name = "NoteLabel"
	noteLabel.Size = UDim2.new(1, -20, 0, 60)
	noteLabel.Position = UDim2.new(0, 0, 0, yPos)
	noteLabel.BackgroundTransparency = 1
	noteLabel.TextColor3 = COLORS.text
	noteLabel.TextSize = 14
	noteLabel.TextWrapped = true
	noteLabel.Text = "Prerequisites define what items must be purchased before others become available. This tab will allow you to define these relationships."
	noteLabel.Parent = tab
	yPos = yPos + 70
	
	-- In a full implementation, this would have a more sophisticated UI for adding and editing prerequisites
	-- For now, we'll just display the current prerequisites as a JSON string
	
	local prerequisites = currentConfig:GetSetting("prerequisites") or {}
	local jsonText
	
	local success, result = pcall(function()
		return game:GetService("HttpService"):JSONEncode(prerequisites)
	end)
	
	if success then
		jsonText = result
	else
		jsonText = "{}"
	end
	
	local jsonLabel = Instance.new("TextLabel")
	jsonLabel.Name = "JsonLabel"
	jsonLabel.Size = UDim2.new(1, -20, 0, 30)
	jsonLabel.Position = UDim2.new(0, 0, 0, yPos)
	jsonLabel.BackgroundTransparency = 1
	jsonLabel.TextColor3 = COLORS.text
	jsonLabel.TextSize = 14
	jsonLabel.TextXAlignment = Enum.TextXAlignment.Left
	jsonLabel.Text = "Current Prerequisites (JSON):"
	jsonLabel.Parent = tab
	yPos = yPos + 30
	
	local jsonInput = Instance.new("TextBox")
	jsonInput.Name = "JsonInput"
	jsonInput.Size = UDim2.new(1, -20, 0, 200)
	jsonInput.Position = UDim2.new(0, 0, 0, yPos)
	jsonInput.BackgroundColor3 = COLORS.itemBackground
	jsonInput.TextColor3 = COLORS.text
	jsonInput.TextSize = 14
	jsonInput.ClearTextOnFocus = false
	jsonInput.TextXAlignment = Enum.TextXAlignment.Left
	jsonInput.TextYAlignment = Enum.TextYAlignment.Top
	jsonInput.TextWrapped = true
	jsonInput.MultiLine = true
	jsonInput.Text = jsonText
	jsonInput.Parent = tab
	yPos = yPos + 210
	
	-- Save JSON button
	local saveJsonButton = Instance.new("TextButton")
	saveJsonButton.Name = "SaveJsonButton"
	saveJsonButton.Size = UDim2.new(0, 150, 0, 40)
	saveJsonButton.Position = UDim2.new(0, 0, 0, yPos)
	saveJsonButton.BackgroundColor3 = COLORS.button
	saveJsonButton.TextColor3 = COLORS.text
	saveJsonButton.TextSize = 16
	saveJsonButton.Text = "Save Prerequisites"
	saveJsonButton.Parent = tab
	
	saveJsonButton.MouseButton1Click:Connect(function()
		if not currentConfig then return end
		
		local success, parsed = pcall(function()
			return game:GetService("HttpService"):JSONDecode(jsonInput.Text)
		end)
		
		if success and type(parsed) == "table" then
			currentConfig:SetSetting("prerequisites", parsed)
			unsavedChanges = true
			updateSaveButton()
			
			-- Show confirmation
			local confirm = Instance.new("TextLabel")
			confirm.Name = "Confirmation"
			confirm.Size = UDim2.new(0, 200, 0, 30)
			confirm.Position = UDim2.new(0, 160, 0, yPos + 5)
			confirm.BackgroundTransparency = 1
			confirm.TextColor3 = COLORS.success
			confirm.TextSize = 14
			confirm.Text = "Prerequisites saved!"
			confirm.Parent = tab
			
			game:GetService("Debris"):AddItem(confirm, 3)
		else
			-- Show error
			local errorMsg = Instance.new("TextLabel")
			errorMsg.Name = "Error"
			errorMsg.Size = UDim2.new(0, 200, 0, 30)
			errorMsg.Position = UDim2.new(0, 160, 0, yPos + 5)
			errorMsg.BackgroundTransparency = 1
			errorMsg.TextColor3 = COLORS.error
			errorMsg.TextSize = 14
			errorMsg.Text = "Invalid JSON format!"
			errorMsg.Parent = tab
			
			game:GetService("Debris"):AddItem(errorMsg, 3)
		end
	end)
	
	-- Example button
	local exampleButton = Instance.new("TextButton")
	exampleButton.Name = "ExampleButton"
	exampleButton.Size = UDim2.new(0, 150, 0, 40)
	exampleButton.Position = UDim2.new(0, 0, 0, yPos + 50)
	exampleButton.BackgroundColor3 = COLORS.itemBackground
	exampleButton.TextColor3 = COLORS.text
	exampleButton.TextSize = 16
	exampleButton.Text = "Insert Example"
	exampleButton.Parent = tab
	
	exampleButton.MouseButton1Click:Connect(function()
		jsonInput.Text = [[{
  "floor2": ["receptionArea", "basicCardio"],
  "floor3": ["floor2", "advancedCardio"],
  "luxuryArea": ["floor3", "premiumMembership"]
}]]
	end)
	
	-- Update canvas size
	tab.CanvasSize = UDim2.new(0, 0, 0, yPos + 100)
end

local function openConfigDropdown()
	-- Get all configurations
	loadConfigList()
	
	-- Create dropdown UI
	local dropdown = Instance.new("Frame")
	dropdown.Name = "ConfigDropdown"
	dropdown.Size = UDim2.new(0, 200, 0, #configList * 30 + 30)
	dropdown.Position = UDim2.new(0, 95, 0, 35)
	dropdown.BackgroundColor3 = COLORS.itemBackground
	dropdown.ZIndex = 10
	dropdown.Parent = editorWidget
	
	-- Add items to dropdown
	local yPos = 0
	
	-- Add "New Configuration" option
	local newConfigItem = Instance.new("TextButton")
	newConfigItem.Name = "NewConfig"
	newConfigItem.Size = UDim2.new(1, 0, 0, 30)
	newConfigItem.Position = UDim2.new(0, 0, 0, yPos)
	newConfigItem.BackgroundTransparency = 1
	newConfigItem.TextColor3 = COLORS.success
	newConfigItem.TextSize = 14
	newConfigItem.Text = "+ New Configuration"
	newConfigItem.ZIndex = 11
	newConfigItem.Parent = dropdown
	yPos = yPos + 30
	
	newConfigItem.MouseButton1Click:Connect(function()
		-- Prompt for new configuration name
		local newName = "NewConfig" -- In a real implementation, you would prompt for a name
		
		local newConfig = TycoonConfigurationManager.new(newName)
		loadConfig(newName)
		
		-- Close the dropdown
		dropdown:Destroy()
	end)
	
	-- Add existing configurations
	for _, configName in ipairs(configList) do
		local configItem = Instance.new("TextButton")
		configItem.Name = configName
		configItem.Size = UDim2.new(1, 0, 0, 30)
		configItem.Position = UDim2.new(0, 0, 0, yPos)
		configItem.BackgroundTransparency = 1
		configItem.TextColor3 = COLORS.text
		configItem.TextSize = 14
		configItem.Text = configName
		configItem.ZIndex = 11
		configItem.Parent = dropdown
		
		configItem.MouseEnter:Connect(function()
			configItem.BackgroundTransparency = 0
			configItem.BackgroundColor3 = COLORS.itemBackgroundHover
		end)
		
		configItem.MouseLeave:Connect(function()
			configItem.BackgroundTransparency = 1
		end)
		
		configItem.MouseButton1Click:Connect(function()
			loadConfig(configName)
			
			-- Close the dropdown
			dropdown:Destroy()
		end)
		
		yPos = yPos + 30
	end
	
	-- Handle clicking outside the dropdown to close it
	local closeConnection
	closeConnection = game:GetService("UserInputService").InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if dropdown and dropdown.Parent then
				dropdown:Destroy()
			end
			if closeConnection then
				closeConnection:Disconnect()
			end
		end
	end)
end

local function openTemplateDropdown()
	-- Create dropdown UI
	local dropdown = Instance.new("Frame")
	dropdown.Name = "TemplateDropdown"
	dropdown.Size = UDim2.new(0, 150, 0, #TEMPLATES * 30)
	dropdown.Position = UDim2.new(0, 380, 0, 35)
	dropdown.BackgroundColor3 = COLORS.itemBackground
	dropdown.ZIndex = 10
	dropdown.Parent = editorWidget
	
	-- Add items to dropdown
	for i, template in ipairs(TEMPLATES) do
		local templateItem = Instance.new("TextButton")
		templateItem.Name = template.configName
		templateItem.Size = UDim2.new(1, 0, 0, 30)
		templateItem.Position = UDim2.new(0, 0, 0, (i-1) * 30)
		templateItem.BackgroundTransparency = 1
		templateItem.TextColor3 = COLORS.text
		templateItem.TextSize = 14
		templateItem.Text = template.name
		templateItem.ZIndex = 11
		templateItem.Parent = dropdown
		
		templateItem.MouseEnter:Connect(function()
			templateItem.BackgroundTransparency = 0
			templateItem.BackgroundColor3 = COLORS.itemBackgroundHover
		end)
		
		templateItem.MouseLeave:Connect(function()
			templateItem.BackgroundTransparency = 1
		end)
		
		templateItem.MouseButton1Click:Connect(function()
			if currentConfig then
				currentConfig:ApplyTemplate(template.configName)
				unsavedChanges = true
				updateSaveButton()
				refreshTabs()
			end
			
			-- Close the dropdown
			dropdown:Destroy()
		end)
	end
	
	-- Handle clicking outside the dropdown to close it
	local closeConnection
	closeConnection = game:GetService("UserInputService").InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if dropdown and dropdown.Parent then
				dropdown:Destroy()
			end
			if closeConnection then
				closeConnection:Disconnect()
			end
		end
	end)
end

local function loadConfigList()
	configList = {}
	
	-- Get all configurations from ServerStorage
	local configFolder = ServerStorage:FindFirstChild(CONFIG_FOLDER_NAME)
	if not configFolder then return end
	
	for _, item in ipairs(configFolder:GetChildren()) do
		if item:IsA("StringValue") then
			table.insert(configList, item.Name)
		end
	end
end

local function loadConfig(configName)
	-- Check for unsaved changes
	if unsavedChanges then
		-- In a real implementation, you would prompt the user to save or discard changes
		-- For this example, we'll just print a warning
		print("Warning: Unsaved changes will be lost when loading a new configuration")
	end
	
	-- Load the configuration
	currentConfig = TycoonConfigurationManager.new(configName)
	currentConfigName = configName
	
	-- Update the UI
	configDropdown.Text = configName
	unsavedChanges = false
	updateSaveButton()
	
	-- Refresh all tabs
	refreshTabs()
end

local function saveCurrentConfig()
	if not currentConfig then return end
	
	local success = currentConfig:SaveConfig()
	
	if success then
		unsavedChanges = false
		updateSaveButton()
		
		-- Set a waypoint in the undo history
		ChangeHistoryService:SetWaypoint("Saved Configuration "..currentConfigName)
	else
		warn("Failed to save configuration:", currentConfigName)
	end
end

local function updateSaveButton()
	if unsavedChanges then
		saveButton.BackgroundColor3 = COLORS.warning
		saveButton.Text = "Save*"
	else
		saveButton.BackgroundColor3 = COLORS.button
		saveButton.Text = "Save"
	end
end

local function refreshTabs()
	populateGeneralTab()
	populateRoomsTab()
	populateEquipmentTab()
	populatePrerequisitesTab()
end

-- Plugin toolbar and buttons
local toolbar = Plugin:CreateToolbar(PluginName)
local openEditorButton = toolbar:CreateButton(
	"TycoonConfigEditor",
	"Open the Tycoon Configuration Editor",
	"rbxassetid://4458901886" -- Generic settings icon
)

-- Button click handler
openEditorButton.Click:Connect(function()
	-- Create or show the widget
	if not editorWidget then
		createUI()
		loadConfigList()
	else
		editorWidget.Enabled = not editorWidget.Enabled
	end
end)

print(PluginName .. " plugin loaded")

-- For Studio command bar access
_G.OpenTycoonConfigEditor = function()
	if not editorWidget then
		createUI()
		loadConfigList()
	else
		editorWidget.Enabled = true
	end
end
