--!strict
--[[
    IconSet.luau
    
    A collection of icon assets for use throughout the UI system.
    This module provides consistent icon references and validation.
    
    Created: April 27, 2025
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Try to load the AssetValidator
local AssetValidator
local shared = ReplicatedStorage:FindFirstChild("shared")
if shared and shared:FindFirstChild("AssetValidator") then
    local success, result = pcall(function()
        return require(shared.AssetValidator)
    end)
    if success then
        AssetValidator = result
    end
end

-- IconSet specification with backup assets in case primary assets fail to load
local IconSet = {
    -- Action icons
    add = "rbxassetid://8091674100",                   -- Plus sign
    remove = "rbxassetid://8091936398",                -- Minus sign
    close = "rbxassetid://8093755787",                 -- X symbol
    edit = "rbxassetid://8091676470",                  -- Pencil icon
    save = "rbxassetid://8091785592",                  -- Save/floppy icon
    settings = "rbxassetid://8093766304",              -- Gear icon
    refresh = "rbxassetid://8093832376",               -- Refresh/reload icon
    search = "rbxassetid://8091929903",                -- Magnifying glass
    filter = "rbxassetid://8091679477",                -- Filter funnel icon
    sort = "rbxassetid://8093763902",                  -- Sort arrows
    
    -- Direction icons
    arrowUp = "rbxassetid://8091694354",               -- Up arrow
    arrowDown = "rbxassetid://8091688301",             -- Down arrow
    arrowLeft = "rbxassetid://8091683445",             -- Left arrow
    arrowRight = "rbxassetid://8091686067",            -- Right arrow
    chevronUp = "rbxassetid://8091740293",             -- Up chevron
    chevronDown = "rbxassetid://8091735058",           -- Down chevron
    chevronLeft = "rbxassetid://8091731903",           -- Left chevron
    chevronRight = "rbxassetid://8091737094",          -- Right chevron
    
    -- Status/alert icons
    success = "rbxassetid://8093755457",               -- Checkmark
    warning = "rbxassetid://8093755364",               -- Warning triangle
    error = "rbxassetid://8093755611",                 -- Error symbol
    info = "rbxassetid://8093754900",                  -- Info circle
    help = "rbxassetid://8093754757",                  -- Question mark
    locked = "rbxassetid://8092194193",                -- Lock icon
    unlocked = "rbxassetid://8092194494",              -- Unlocked icon
    
    -- Media controls
    play = "rbxassetid://8091990871",                  -- Play button
    pause = "rbxassetid://8091987045",                 -- Pause button
    stop = "rbxassetid://8091990025",                  -- Stop button
    skipForward = "rbxassetid://8091982713",           -- Skip forward
    skipBack = "rbxassetid://8091982401",              -- Skip backward
    volume = "rbxassetid://8091992171",                -- Volume/sound icon
    mute = "rbxassetid://8091992525",                  -- Muted volume icon
    
    -- Game-specific icons
    coin = "rbxassetid://8092007134",                  -- Coin/currency
    gem = "rbxassetid://8092007403",                   -- Gem/premium currency
    timer = "rbxassetid://8092003443",                 -- Clock/timer
    trophy = "rbxassetid://8092002346",                -- Trophy/achievement
    star = "rbxassetid://8092001502",                  -- Star
    heart = "rbxassetid://8092006355",                 -- Heart/life
    character = "rbxassetid://8092213308",             -- Player character
    leaderboard = "rbxassetid://8092204656",           -- Leaderboard
    
    -- UI element icons
    home = "rbxassetid://8093762863",                 -- Home button
    menu = "rbxassetid://8093763464",                 -- Hamburger menu
    more = "rbxassetid://8092135293",                 -- Three dots/more
    share = "rbxassetid://8092094273",                -- Share icon
    link = "rbxassetid://8092126251",                 -- Link/chain icon
    calendar = "rbxassetid://8092210444",             -- Calendar
    notification = "rbxassetid://8092093329",         -- Bell/notification
    
    -- Object icons
    folder = "rbxassetid://8092122054",               -- Folder
    file = "rbxassetid://8092122825",                 -- File
    image = "rbxassetid://8092125039",                -- Image/picture
    trash = "rbxassetid://8092094793",                -- Trash can/delete
    tag = "rbxassetid://8092095626",                  -- Tag/label
    list = "rbxassetid://8092128264",                 -- List view
    grid = "rbxassetid://8092130144",                 -- Grid view
    
    -- Fallback icon (used when requested icon doesn't exist)
    fallback = "rbxassetid://8091927367"              -- Default fallback icon
}

-- Function to validate all icons and replace broken ones
function IconSet:validateAll()
    if not AssetValidator then
        print("AssetValidator not found, skipping icon validation")
        return
    end
    
    for name, assetId in pairs(self) do
        if type(assetId) == "string" and assetId:match("^rbxassetid://") then
            if not AssetValidator:validateImageAsset(assetId) then
                warn("Icon '" .. name .. "' with asset ID " .. assetId .. " failed validation")
                -- Use fallback if the original asset is invalid
                self[name] = self.fallback
            end
        end
    end
    
    print("IconSet: Finished validating all icons")
end

-- Function to get an icon with validation
function IconSet:getIcon(iconName)
    local icon = self[iconName]
    
    if not icon then
        warn("Icon '" .. iconName .. "' not found in IconSet")
        return self.fallback
    end
    
    -- Validate using AssetValidator if available
    if AssetValidator then
        if typeof(icon) == "string" and icon:match("^rbxassetid://") then
            if not AssetValidator:validateImageAsset(icon) then
                warn("Icon '" .. iconName .. "' with asset ID " .. icon .. " failed validation")
                return self.fallback
            end
        end
    end
    
    return icon
end

-- Function to create an icon instance
function IconSet:createIcon(iconName, options)
    options = options or {}
    
    local iconAsset = self:getIcon(iconName)
    local icon = Instance.new("ImageLabel")
    
    icon.Name = options.name or (iconName .. "Icon")
    icon.Size = options.size or UDim2.new(0, 24, 0, 24)
    icon.Position = options.position or UDim2.new(0, 0, 0, 0)
    icon.AnchorPoint = options.anchorPoint or Vector2.new(0, 0)
    icon.BackgroundTransparency = 1
    icon.Image = iconAsset
    icon.ImageColor3 = options.color or Color3.new(1, 1, 1)
    
    if options.parent then
        icon.Parent = options.parent
    end
    
    return icon
end

-- Function to preload common icons
function IconSet:preloadCommonIcons()
    if not AssetValidator then return end
    
    local commonIcons = {
        "close", "info", "warning", "error", "success",
        "arrowUp", "arrowDown", "arrowLeft", "arrowRight",
        "home", "settings", "menu"
    }
    
    for _, iconName in ipairs(commonIcons) do
        local icon = self[iconName]
        if icon and typeof(icon) == "string" then
            AssetValidator:preloadImageAsync(icon)
        end
    end
    
    print("IconSet: Preloaded common icons")
end

-- Register with ClientRegistry if available
local function registerWithClientRegistry()
    if not shared then return end
    
    local clientRegistryModule = shared:FindFirstChild("ClientRegistry")
    if not clientRegistryModule then return end
    
    local success, clientRegistry = pcall(function()
        return require(clientRegistryModule)
    end)
    
    if success and clientRegistry and typeof(clientRegistry.registerUIComponent) == "function" then
        clientRegistry:registerUIComponent("IconSet", IconSet)
        print("IconSet registered with ClientRegistry")
    end
end

-- Try to register with ClientRegistry and preload common icons
task.spawn(function()
    registerWithClientRegistry()
    
    -- Allow some time for AssetValidator to be registered if it wasn't available immediately
    if not AssetValidator then
        wait(1)
        if shared and shared:FindFirstChild("AssetValidator") then
            local success, result = pcall(function()
                return require(shared.AssetValidator)
            end)
            if success then
                AssetValidator = result
                IconSet:preloadCommonIcons()
            end
        end
    else
        IconSet:preloadCommonIcons()
    end
end)

return IconSet
