-- src/client/UI/TutorialUI.client.luau

local TutorialUI = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local TutorialFrame = Instance.new("Frame")
TutorialFrame.Name = "TutorialFrame"
TutorialFrame.Size = UDim2.new(0.4, 0, 0.2, 0)
TutorialFrame.Position = UDim2.new(0.3, 0, 0.7, 0)
TutorialFrame.BackgroundColor3 = Color3.new(0, 0, 0)
TutorialFrame.BackgroundTransparency = 0.5
TutorialFrame.BorderSizePixel = 0
TutorialFrame.Visible = false

local TutorialText = Instance.new("TextLabel")
TutorialText.Name = "TutorialText"
TutorialText.Size = UDim2.new(0.9, 0, 0.8, 0)
TutorialText.Position = UDim2.new(0.05,0,0.1,0)
TutorialText.BackgroundColor3 = Color3.new(1, 1, 1)
TutorialText.BackgroundTransparency = 1
TutorialText.TextColor3 = Color3.new(1, 1, 1)
TutorialText.TextSize = 20
TutorialText.TextWrapped = true
TutorialText.TextScaled = true
TutorialText.Font = Enum.Font.SourceSansBold
TutorialText.Text = "Default Tutorial Text"
TutorialText.Parent = TutorialFrame

local HighlightFrame = Instance.new("Frame")
HighlightFrame.Name = "HighlightFrame"
HighlightFrame.BackgroundColor3 = Color3.new(1,1,0)
HighlightFrame.BorderSizePixel = 0
HighlightFrame.ZIndex = 10
HighlightFrame.Visible = false
HighlightFrame.Parent = PlayerGui

function TutorialUI.displayTutorial(step, text, target)
	TutorialFrame.Visible = true
	TutorialText.Text = text or "This is a tutorial step. Please follow the instructions."

	print("Displaying tutorial:", step, text, target) -- Test print
	if target then
		local targetGui = PlayerGui:FindFirstChild(target) or target
		if targetGui then
			HighlightFrame.Visible = true
			HighlightFrame.Size = targetGui.AbsoluteSize
			HighlightFrame.Position = UDim2.fromOffset(targetGui.AbsolutePosition.X,targetGui.AbsolutePosition.Y)
		else
			HighlightFrame.Visible = false
		end
	else
		HighlightFrame.Visible = false
	end
end

function TutorialUI.hideTutorial()
	TutorialFrame.Visible = false
	HighlightFrame.Visible = false
end

function TutorialUI.initialize()
	TutorialFrame.Parent = PlayerGui
end

return TutorialUI