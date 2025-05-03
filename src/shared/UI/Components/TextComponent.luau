--!strict
--[[
    TextComponent.luau
    
    A reusable text component for the enhanced UI system.
    
    Created: May 4, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import ModuleLoaderHelper
local ModuleLoaderHelper = nil
if ReplicatedStorage:FindFirstChild("shared") and ReplicatedStorage.shared:FindFirstChild("ModuleLoaderHelper") then
    local success, result = pcall(function()
        return require(ReplicatedStorage.shared.ModuleLoaderHelper)
    end)
    
    if success and result then
        ModuleLoaderHelper = result
    else
        warn("[TextComponent] Failed to load ModuleLoaderHelper, using direct requires")
    end
end

-- Load UIComponentBase
local UIComponentBase
if ModuleLoaderHelper then
    UIComponentBase = ModuleLoaderHelper.loadModule("UI/UIComponentBase")
else
    local componentBasePath = ReplicatedStorage:FindFirstChild("shared") and 
                             ReplicatedStorage.shared:FindFirstChild("UI") and 
                             ReplicatedStorage.shared.UI:FindFirstChild("UIComponentBase")
    
    if componentBasePath then
        UIComponentBase = require(componentBasePath)
    end
end

if not UIComponentBase then
    error("[TextComponent] Required dependency UIComponentBase not found")
end

-- Load UIStyleSystem
local UIStyleSystem
if ModuleLoaderHelper then
    UIStyleSystem = ModuleLoaderHelper.loadModule("UI/UIStyleSystem")
else
    local styleSystemPath = ReplicatedStorage:FindFirstChild("shared") and 
                           ReplicatedStorage.shared:FindFirstChild("UI") and 
                           ReplicatedStorage.shared.UI:FindFirstChild("UIStyleSystem")
    
    if styleSystemPath then
        UIStyleSystem = require(styleSystemPath)
    end
end

--[[
    TextComponent - A standardized text component
]]
local TextComponent = setmetatable({}, UIComponentBase)
TextComponent.__index = TextComponent

--[[
    Create a new text component
    @param props - Text properties
    @return - New TextComponent instance
]]
function TextComponent.new(props)
    props = props or {}
    
    local self = UIComponentBase.new(props)
    setmetatable(self, TextComponent)
    
    -- Text-specific properties
    self._type = "TextComponent"
    self._text = props.text or ""
    self._textStyle = props.textStyle or "body" -- heading1, heading2, heading3, body, small
    self._richText = props.richText == true -- Default to false, HTML-like formatting
    self._multiLine = props.multiLine ~= false -- Default to true
    self._textWrapped = props.textWrapped ~= false -- Default to true
    self._textXAlignment = props.textXAlignment or Enum.TextXAlignment.Left
    self._textYAlignment = props.textYAlignment or Enum.TextYAlignment.Top
    self._textSize = props.textSize -- Override text size
    self._font = props.font -- Override font
    self._textColor = props.textColor -- Override text color
    self._autoSize = props.autoSize -- If true, the component will resize to fit text
    self._padding = props.padding -- Text padding
    self._maxLines = props.maxLines -- Maximum number of lines to display
    self._textTruncate = props.textTruncate -- Truncate text if it exceeds maximum size
    self._truncationIndicator = props.truncationIndicator or "..." -- Indicator for truncated text
    
    -- Get style from UIStyleSystem if available
    if UIStyleSystem then
        self._textComponentStyle = UIStyleSystem:createStyle("Text", props.themeOverrides)
    end
    
    return self
end

--[[
    Internal render method - creates the text instance
    @return - The created text instance
]]
function TextComponent:_render()
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = self._name
    textLabel.Size = self._size or UDim2.new(1, 0, 0, 24) -- Default to auto-height
    textLabel.Position = self._position or UDim2.new(0, 0, 0, 0)
    textLabel.AnchorPoint = self._anchorPoint or Vector2.new(0, 0)
    textLabel.BackgroundTransparency = 1 -- Transparent by default
    textLabel.Text = self._text
    textLabel.TextWrapped = self._textWrapped
    textLabel.TextXAlignment = self._textXAlignment
    textLabel.TextYAlignment = self._textYAlignment
    textLabel.RichText = self._richText
    
    -- Apply text styling
    self:_applyTextStyle(textLabel)
    
    -- Add padding if specified
    if self._padding then
        local uiPadding = Instance.new("UIPadding")
        
        if typeof(self._padding) == "number" then
            -- Same padding on all sides
            uiPadding.PaddingLeft = UDim.new(0, self._padding)
            uiPadding.PaddingRight = UDim.new(0, self._padding)
            uiPadding.PaddingTop = UDim.new(0, self._padding)
            uiPadding.PaddingBottom = UDim.new(0, self._padding)
        else
            -- Different padding for each side
            uiPadding.PaddingLeft = typeof(self._padding.left) == "UDim" 
                                and self._padding.left 
                                or UDim.new(0, self._padding.left or 0)
            
            uiPadding.PaddingRight = typeof(self._padding.right) == "UDim" 
                                 and self._padding.right 
                                 or UDim.new(0, self._padding.right or 0)
            
            uiPadding.PaddingTop = typeof(self._padding.top) == "UDim" 
                               and self._padding.top 
                               or UDim.new(0, self._padding.top or 0)
            
            uiPadding.PaddingBottom = typeof(self._padding.bottom) == "UDim" 
                                  and self._padding.bottom 
                                  or UDim.new(0, self._padding.bottom or 0)
        end
        
        uiPadding.Parent = textLabel
    end
    
    -- Auto-size logic
    if self._autoSize then
        -- We'll need to adjust size after the first render
        task.spawn(function()
            task.wait() -- Wait for the next render step
            if textLabel and textLabel:IsDescendantOf(game) then
                self:_adjustAutoSize(textLabel)
            end
        end)
    end
    
    -- Connect to TextBounds changed
    textLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
        if self._autoSize then
            self:_adjustAutoSize(textLabel)
        end
        
        -- Truncate text if needed
        if self._textTruncate and self._maxLines then
            self:_truncateText(textLabel)
        end
    end)
    
    return textLabel
end

--[[
    Apply text style to the label
    @param textLabel - Label to style
]]
function TextComponent:_applyTextStyle(textLabel)
    if self._textComponentStyle then
        -- Use UIStyleSystem styling
        local typography
        
        -- Get typography based on text style
        if self._textStyle == "heading1" or self._textStyle == "heading2" or 
           self._textStyle == "heading3" or self._textStyle == "body" or 
           self._textStyle == "small" or self._textStyle == "button" then
            typography = self._textComponentStyle:getTypography(self._textStyle) or {}
        else
            typography = self._textComponentStyle:getTypography("body") or {}
        end
        
        -- Apply text properties
        textLabel.Font = self._font or typography.font or Enum.Font.Gotham
        textLabel.TextSize = self._textSize or typography.size or 16
        textLabel.TextColor3 = self._textColor or self._textComponentStyle:getColor("text") or Color3.fromRGB(255, 255, 255)
    else
        -- Fallback styling when UIStyleSystem is not available
        local styleSettings = {
            heading1 = {
                font = Enum.Font.GothamBold,
                size = 32,
                color = Color3.fromRGB(255, 255, 255)
            },
            heading2 = {
                font = Enum.Font.GothamBold,
                size = 24,
                color = Color3.fromRGB(255, 255, 255)
            },
            heading3 = {
                font = Enum.Font.GothamBold,
                size = 20,
                color = Color3.fromRGB(255, 255, 255)
            },
            body = {
                font = Enum.Font.Gotham,
                size = 16,
                color = Color3.fromRGB(240, 240, 255)
            },
            small = {
                font = Enum.Font.Gotham,
                size = 14,
                color = Color3.fromRGB(230, 230, 240)
            },
            button = {
                font = Enum.Font.GothamBold,
                size = 16,
                color = Color3.fromRGB(255, 255, 255)
            }
        }
        
        local style = styleSettings[self._textStyle] or styleSettings.body
        
        textLabel.Font = self._font or style.font
        textLabel.TextSize = self._textSize or style.size
        textLabel.TextColor3 = self._textColor or style.color
    end
end

--[[
    Adjust auto-size based on text content
    @param textLabel - Label to adjust
]]
function TextComponent:_adjustAutoSize(textLabel)
    if not textLabel or not textLabel:IsDescendantOf(game) then
        return
    end
    
    local textBounds = textLabel.TextBounds
    local padding = textLabel:FindFirstChild("UIPadding")
    local paddingLeft = padding and padding.PaddingLeft.Offset or 0
    local paddingRight = padding and padding.PaddingRight.Offset or 0
    local paddingTop = padding and padding.PaddingTop.Offset or 0
    local paddingBottom = padding and padding.PaddingBottom.Offset or 0
    
    -- Calculate new size
    local newWidth = textLabel.Size.X -- Keep X dimension as is by default
    local newHeight = UDim2.new(0, textBounds.Y + paddingTop + paddingBottom)
    
    -- If autoSize is "both", adjust width too
    if self._autoSize == "both" or self._autoSize == "width" then
        newWidth = UDim2.new(0, textBounds.X + paddingLeft + paddingRight)
    end
    
    -- If autoSize is "height" or "both" or true, adjust height
    if self._autoSize == "height" or self._autoSize == "both" or self._autoSize == true then
        textLabel.Size = UDim2.new(newWidth.X, newWidth.Y, 0, textBounds.Y + paddingTop + paddingBottom)
    end
    
    -- Trigger size changed event
    self:triggerEvent("onSizeChanged", textLabel.Size)
end

--[[
    Truncate text if it exceeds maximum lines
    @param textLabel - Label to truncate
]]
function TextComponent:_truncateText(textLabel)
    if not self._maxLines or not textLabel or not textLabel:IsDescendantOf(game) then
        return
    end
    
    local textSize = textLabel.TextSize
    local padding = textLabel:FindFirstChild("UIPadding")
    local paddingTop = padding and padding.PaddingTop.Offset or 0
    local paddingBottom = padding and padding.PaddingBottom.Offset or 0
    
    -- Calculate maximum height based on max lines
    local maxHeight = (textSize * self._maxLines) + paddingTop + paddingBottom
    
    -- If text bounds exceed max height, truncate the text
    if textLabel.TextBounds.Y > maxHeight then
        local originalText = self._text
        local truncatedText = originalText
        
        -- Iteratively reduce text until it fits
        while textLabel.TextBounds.Y > maxHeight and #truncatedText > 0 do
            truncatedText = string.sub(truncatedText, 1, #truncatedText - 10) -- Remove 10 characters at a time
            textLabel.Text = truncatedText .. self._truncationIndicator
        end
        
        -- Fine-tune by adding characters back until it doesn't fit
        local baseLength = #truncatedText
        for i = 1, 10 do
            local testLength = baseLength + i
            if testLength <= #originalText then
                local testText = string.sub(originalText, 1, testLength) .. self._truncationIndicator
                textLabel.Text = testText
                
                if textLabel.TextBounds.Y > maxHeight then
                    -- Revert to previous length
                    textLabel.Text = string.sub(originalText, 1, testLength - 1) .. self._truncationIndicator
                    break
                end
            end
        end
    end
end

--[[
    Set text content
    @param text - New text content
    @return - Self for method chaining
]]
function TextComponent:setText(text)
    self._text = text
    
    if self._instance then
        self._instance.Text = text
        
        -- Handle truncation if needed
        if self._textTruncate and self._maxLines then
            self:_truncateText(self._instance)
        end
        
        -- Handle auto-size if needed
        if self._autoSize then
            self:_adjustAutoSize(self._instance)
        end
    end
    
    -- Trigger text changed event
    self:triggerEvent("onTextChanged", text)
    
    return self
end

--[[
    Set text style
    @param textStyle - New text style
    @return - Self for method chaining
]]
function TextComponent:setTextStyle(textStyle)
    self._textStyle = textStyle
    
    if self._instance then
        self:_applyTextStyle(self._instance)
    end
    
    return self
end

--[[
    Set text color
    @param color - New text color
    @return - Self for method chaining
]]
function TextComponent:setTextColor(color)
    self._textColor = color
    
    if self._instance then
        self._instance.TextColor3 = color
    end
    
    return self
end

--[[
    Set rich text
    @param enabled - Rich text enabled state
    @return - Self for method chaining
]]
function TextComponent:setRichText(enabled)
    self._richText = enabled
    
    if self._instance then
        self._instance.RichText = enabled
    end
    
    return self
end

--[[
    Register an onTextChanged handler
    @param handler - Function to call when text changes
    @return - Connection ID
]]
function TextComponent:onTextChanged(handler)
    return self:on("onTextChanged", handler)
end

--[[
    Register an onSizeChanged handler
    @param handler - Function to call when size changes
    @return - Connection ID
]]
function TextComponent:onSizeChanged(handler)
    return self:on("onSizeChanged", handler)
end

return TextComponent
