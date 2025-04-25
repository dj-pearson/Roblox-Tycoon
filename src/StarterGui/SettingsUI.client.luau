--lua
--[[
    SettingsUI.client.luau
    Handles the creation and functionality of the Settings Menu UI.

    Updated: Today
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")


-- Import modern UI framework components
local UIStyle = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("UIStyle"))
local ButtonFactory = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("ButtonFactory"))
local SliderFactory = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("SliderFactory"))
local DropdownFactory = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("DropdownFactory"))
local CheckBoxFactory = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("shared"):WaitForChild("CheckBoxFactory"))

local function updateSliderValueLabel(slider, label) label.Text = "Value: " .. slider.Value end


local function createSettingsMenuUI()
	-- Create the main container for the settings menu
	local settingsFrame = UIStyle.createFrame({
		name = "SettingsFrame",
		size = UDim2.new(0, 500, 0, 400),
		position = UDim2.new(0.5, -250, 0.5, -200),
		zIndex = UIStyle.ZIndex.Standard,
	})
	
	-- Create the scrolling frame
	local settingsScrollingFrame = Instance.new("ScrollingFrame")
	settingsScrollingFrame.Name = "SettingsScrollingFrame"
	settingsScrollingFrame.Size = UDim2.new(1, -20, 1, -20)
	settingsScrollingFrame.Position = UDim2.new(0, 10, 0, 10)
	settingsScrollingFrame.BackgroundTransparency = 1
	settingsScrollingFrame.Parent = settingsFrame

	-- Sound Section
	local soundSection = Instance.new("Frame")
	soundSection.Name = "SoundSection"
	soundSection.Size = UDim2.new(1, -20, 0, 150)
	soundSection.Position = UDim2.new(0, 10, 0, 10)
	soundSection.BackgroundTransparency = 1	
	soundSection.Parent = settingsScrollingFrame
	
	-- Sound Section Label
	local soundSectionLabel = Instance.new("TextLabel")
	soundSectionLabel.Name = "SoundSectionLabel"
	soundSectionLabel.Size = UDim2.new(1, 0, 0, 30)
	soundSectionLabel.Position = UDim2.new(0, 0, 0, 0)
	soundSectionLabel.Text = "Sound"
	soundSectionLabel.Font = Enum.Font.GothamBold
	soundSectionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	soundSectionLabel.TextSize = 18
	soundSectionLabel.BackgroundTransparency = 1
	soundSectionLabel.Parent = soundSection
	
	-- Music Volume Slider
	local musicVolumeSlider = SliderFactory.createSlider({
		name = "MusicVolumeSlider",
		size = UDim2.new(1, 0, 0, 30),
		position = UDim2.new(0, 0, 0, 40),
		initialValue = 0.5,
	})
	musicVolumeSlider.Parent = soundSection
	-- Music volume value Label
	local musicVolumeLabel = Instance.new("TextLabel")
	musicVolumeLabel.Name = "MusicVolumeLabel"
	musicVolumeLabel.Size = UDim2.new(0, 100, 0, 30)
	musicVolumeLabel.Position = UDim2.new(1, 0, 0, 40)
	musicVolumeLabel.Text = "Value: 0.5"
	musicVolumeLabel.Font = Enum.Font.Gotham
	musicVolumeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	musicVolumeLabel.TextSize = 14
	musicVolumeLabel.BackgroundTransparency = 1
	musicVolumeLabel.Parent = soundSection
	
	

	
	-- Sound Effects Volume Slider
	local soundEffectsVolumeSlider = SliderFactory.createSlider({
		name = "SoundEffectsVolumeSlider",
		size = UDim2.new(1, 0, 0, 30),
		position = UDim2.new(0, 0, 0, 80),
		initialValue = 0.5,
	})
	soundEffectsVolumeSlider.Parent = soundSection
	
	-- Sound effects volume value Label
	local soundEffectsVolumeLabel = Instance.new("TextLabel")
	soundEffectsVolumeLabel.Name = "SoundEffectsVolumeLabel"
	soundEffectsVolumeLabel.Size = UDim2.new(0, 100, 0, 30)
	soundEffectsVolumeLabel.Position = UDim2.new(1, 0, 0, 80)
	soundEffectsVolumeLabel.Text = "Value: 0.5"
	soundEffectsVolumeLabel.Font = Enum.Font.Gotham
	soundEffectsVolumeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	soundEffectsVolumeLabel.TextSize = 14
	soundEffectsVolumeLabel.BackgroundTransparency = 1
	soundEffectsVolumeLabel.Parent = soundSection
	
	-- Graphics Section
	local graphicsSection = Instance.new("Frame")
	graphicsSection.Name = "GraphicsSection"
	graphicsSection.Size = UDim2.new(1, -20, 0, 150)
	graphicsSection.Position = UDim2.new(0, 10, 0, 160)
	graphicsSection.BackgroundTransparency = 1
	graphicsSection.Parent = settingsScrollingFrame
	
	-- Graphics Section Label
	local graphicsSectionLabel = Instance.new("TextLabel")
	graphicsSectionLabel.Name = "GraphicsSectionLabel"
	graphicsSectionLabel.Size = UDim2.new(1, 0, 0, 30)
	graphicsSectionLabel.Position = UDim2.new(0, 0, 0, 0)
	graphicsSectionLabel.Text = "Graphics"
	graphicsSectionLabel.Font = Enum.Font.GothamBold
	graphicsSectionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	graphicsSectionLabel.TextSize = 18
	graphicsSectionLabel.BackgroundTransparency = 1
	graphicsSectionLabel.Parent = graphicsSection
	
	-- Quality Presets Dropdown
	local qualityPresetsDropdown = DropdownFactory.createDropdown({
		name = "QualityPresetsDropdown",
		size = UDim2.new(1, 0, 0, 30),
		position = UDim2.new(0, 0, 0, 40),
		options = {"Low", "Medium", "High"},
	})
	qualityPresetsDropdown.Parent = graphicsSection
	-- Shadows Checkbox
	local shadowsCheckBox = CheckBoxFactory.createCheckBox({name = "ShadowsCheckBox", size = UDim2.new(1,0,0,30), position = UDim2.new(0,0,0,80)})
	shadowsCheckBox.Parent = graphicsSection
	
	-- Controls Section Container
	local controlsSection = Instance.new("Frame")
	controlsSection.Name = "ControlsSection"
	controlsSection.Size = UDim2.new(1, -20, 0, 150)
	controlsSection.Position = UDim2.new(0, 10, 0, 320)
	controlsSection.BackgroundTransparency = 1
	controlsSection.Parent = settingsScrollingFrame

	-- Controls Section Label
	local controlsSectionLabel = Instance.new("TextLabel")
	controlsSectionLabel.Name = "ControlsSectionLabel"
	controlsSectionLabel.Size = UDim2.new(1, 0, 0, 30)
	controlsSectionLabel.Position = UDim2.new(0, 0, 0, 0)
	controlsSectionLabel.Text = "Controls"
	controlsSectionLabel.Font = Enum.Font.GothamBold
	controlsSectionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	controlsSectionLabel.TextSize = 18
	controlsSectionLabel.BackgroundTransparency = 1
	controlsSectionLabel.Parent = controlsSection

	-- Mouse Sensitivity Slider
	local mouseSensitivitySlider = SliderFactory.createSlider({
		name = "MouseSensitivitySlider",
		size = UDim2.new(1, 0, 0, 30),
		position = UDim2.new(0, 0, 0, 40),
		initialValue = 0.5,
	})
	mouseSensitivitySlider.Parent = controlsSection

	-- Mouse Sensitivity Value Label
	local mouseSensitivityLabel = Instance.new("TextLabel")
	mouseSensitivityLabel.Name = "MouseSensitivityLabel"
	mouseSensitivityLabel.Size = UDim2.new(0, 100, 0, 30)
	mouseSensitivityLabel.Position = UDim2.new(1, 0, 0, 40)
	mouseSensitivityLabel.Parent = controlsSection

	-- Accessibility Section
	local accessibilitySection = Instance.new("Frame")
	accessibilitySection.Name = "AccessibilitySection"
	accessibilitySection.Size = UDim2.new(1, -20, 0, 100)
	accessibilitySection.Position = UDim2.new(0, 10, 0, 480)
	accessibilitySection.BackgroundTransparency = 1
	accessibilitySection.Parent = settingsScrollingFrame

	-- Accessibility Section Label
	local accessibilitySectionLabel = Instance.new("TextLabel")
	accessibilitySectionLabel.Name = "AccessibilitySectionLabel"
	accessibilitySectionLabel.Size = UDim2.new(1, 0, 0, 30)
	accessibilitySectionLabel.Position = UDim2.new(0, 0, 0, 0)
	accessibilitySectionLabel.Text = "Accessibility"
	accessibilitySectionLabel.Font = Enum.Font.GothamBold
	accessibilitySectionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	accessibilitySectionLabel.TextSize = 18
	accessibilitySectionLabel.BackgroundTransparency = 1
	accessibilitySectionLabel.Parent = accessibilitySection

	-- Colorblind Mode Checkbox
	local colorblindModeCheckBox = CheckBoxFactory.createCheckBox({name = "ColorblindModeCheckBox", size = UDim2.new(1, 0, 0, 30), position = UDim2.new(0, 0, 0, 40)})
	colorblindModeCheckBox.Parent = accessibilitySection

		-- Language Section Container
	local languageSection = Instance.new("Frame")
	languageSection.Name = "LanguageSection"
	languageSection.Size = UDim2.new(1, -20, 0, 100)
	languageSection.Position = UDim2.new(0, 10, 0, 600)
	languageSection.BackgroundTransparency = 1
	languageSection.Parent = settingsScrollingFrame

	-- Language Section Label
	local languageSectionLabel = Instance.new("TextLabel")
	languageSectionLabel.Name = "LanguageSectionLabel"
	languageSectionLabel.Size = UDim2.new(1, 0, 0, 30)
	languageSectionLabel.Position = UDim2.new(0, 0, 0, 0)
	languageSectionLabel.Text = "Language"
	languageSectionLabel.Font = Enum.Font.GothamBold
	languageSectionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	languageSectionLabel.TextSize = 18
	languageSectionLabel.BackgroundTransparency = 1
	languageSectionLabel.Parent = languageSection

	-- Language Dropdown
	local languageDropdown = DropdownFactory.createDropdown({
		name = "LanguageDropdown",
		size = UDim2.new(1, 0, 0, 30),
		position = UDim2.new(0, 0, 0, 40),
		options = {"English", "Spanish", "French"},
	})
	languageDropdown.Parent = languageSection
	return settingsFrame
end	

local function loadUI()
	-- Create the SettingsUI ScreenGui if it doesn't exist
	local screenGui = PlayerGui:FindFirstChild("SettingsUI")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "SettingsUI"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = PlayerGui
	end

	-- Create the SettingsFrame container
	local settingsFrame = createSettingsMenuUI()
	settingsFrame.Parent = screenGui
	
	-- Get the scrolling frame
	local settingsScrollingFrame = settingsFrame:WaitForChild("SettingsScrollingFrame")
	
	
	-- Get the sound section
	local soundSection = settingsScrollingFrame:WaitForChild("SoundSection")

	-- Connect slider value changes
	local musicVolumeSlider = soundSection:WaitForChild("MusicVolumeSlider")
	local musicVolumeLabel = soundSection:WaitForChild("MusicVolumeLabel")
	musicVolumeSlider:GetPropertyChangedSignal("Value"):Connect(function() updateSliderValueLabel(musicVolumeSlider, musicVolumeLabel) end)
	local soundEffectsVolumeSlider = soundSection:WaitForChild("SoundEffectsVolumeSlider")
	local soundEffectsVolumeLabel = soundSection:WaitForChild("SoundEffectsVolumeLabel")
	soundEffectsVolumeSlider:GetPropertyChangedSignal("Value"):Connect(function() updateSliderValueLabel(soundEffectsVolumeSlider, soundEffectsVolumeLabel) end)
end
	
return {
	loadUI = loadUI,
}