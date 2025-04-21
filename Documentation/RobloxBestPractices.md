# Roblox Luau Development Best Practices

## Table of Contents

1. [Luau Coding Standards](#luau-coding-standards)
2. [Roblox Studio Elements](#roblox-studio-elements)
3. [Project Setup & Implementation](#project-setup--implementation)
4. [Performance Optimization](#performance-optimization)
5. [UI Design & Implementation](#ui-design--implementation)
6. [Data Management](#data-management)
7. [Security Practices](#security-practices)

---

## Luau Coding Standards

### Naming Conventions

#### Variables and Functions

- Use camelCase for local variables and functions: `localPlayer`, `calculateDistance()`
- Use PascalCase for module names, classes, and constructors: `PlayerManager`, `UIController`
- Use ALL_CAPS for constants: `MAX_PLAYERS`, `DEFAULT_SPEED`

```lua
local DEFAULT_SPEED = 16
local function calculateDistance(point1, point2)
    -- Function implementation
end
local PlayerManager = {}
```

#### Services and Instances

- Use PascalCase for service references: `ReplicatedStorage`, `RunService`
- Use descriptive names that reflect purpose: `healthDisplay` instead of `display1`

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playerGui = player:WaitForChild("PlayerGui")
local healthDisplay = playerGui:WaitForChild("HealthDisplay")
```

### Code Organization

#### Module Structure

- Begin with service declarations
- Follow with import statements
- Define constants
- Declare the main module table
- Implement methods and functionality
- Return the module at the end

```lua
-- Service declarations
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Import dependencies
local Utilities = require(ReplicatedStorage.Modules.Utilities)

-- Constants
local MAX_DISTANCE = 100
local UPDATE_INTERVAL = 0.1

-- Module declaration
local MyModule = {}

-- Implementation
function MyModule:initialize()
    -- Initialization logic
end

function MyModule:update(dt)
    -- Update logic
end

-- Return module
return MyModule
```

#### Script Separation

- Separate concerns into different scripts/modules
- Use require() for shared functionality
- Client-specific code in `*.client.luau`
- Server-specific code in `*.server.luau`
- Shared code in standard `*.luau` files

### Commenting

#### Best Practices

- Add a file header comment that explains the script's purpose
- Use comments to explain WHY something is done, not WHAT is done
- Document functions with parameters and return values
- Add TODO comments for future work items

```lua
--[[
    PlayerManager.luau
    Handles player state management and interactions

    Author: YourName
    Date: April 2025
]]

-- Utility to check if a player is eligible for an upgrade
-- @param player (Player) - The player to check
-- @param upgradeId (string) - The ID of the upgrade
-- @return (boolean) - Whether the player is eligible
local function isEligibleForUpgrade(player, upgradeId)
    -- TODO: Add cooldown checks
    return player.Level.Value >= UPGRADE_REQUIREMENTS[upgradeId]
end
```

### Error Handling

#### Guidelines

- Use pcall() for operations that might fail
- Provide meaningful error messages
- Implement proper fallback behavior
- Log errors appropriately for debugging

```lua
local success, result = pcall(function()
    return dangerousOperation()
end)

if not success then
    warn("Failed to perform operation: " .. tostring(result))
    -- Implement fallback behavior
end
```

### Function Design

#### Best Practices

- Keep functions small and focused on a single task
- Limit function complexity
- Use early returns to simplify logic
- Avoid deep nesting

```lua
-- Good: Early returns simplify logic
function canPlayerPurchase(player, itemId)
    if not itemExists(itemId) then
        return false
    end

    if not hasRequiredLevel(player, itemId) then
        return false
    end

    return player.Currency.Value >= getItemPrice(itemId)
end

-- Avoid: Deep nesting makes code harder to understand
function canPlayerPurchaseBad(player, itemId)
    if itemExists(itemId) then
        if hasRequiredLevel(player, itemId) then
            if player.Currency.Value >= getItemPrice(itemId) then
                return true
            else
                return false
            end
        else
            return false
        end
    else
        return false
    end
end
```

### Type Safety

#### Luau Type Checking

- Use type annotations when available
- Export and define types for complex structures
- Check types with `assert` for better debugging

```lua
local function calculateDamage(weapon: string, level: number): number
    assert(type(weapon) == "string", "Weapon must be a string")
    assert(type(level) == "number", "Level must be a number")

    return WEAPON_BASE_DAMAGE[weapon] * (1 + level * 0.1)
end
```

---

## Roblox Studio Elements

### Instance Structure

#### Instance Naming

- Use PascalCase for container instances: `PlayerUI`, `GameAssets`
- Use clear, descriptive names
- Include instance type in name when useful: `MainFrame`, `TitleText`

#### Instance Hierarchy

- Organize instances logically
- Use folders to group related items
- Keep hierarchy clean and not too deep

```
Workspace
├── Map
│   ├── Terrain
│   ├── Decorations
│   └── SpawnLocations
├── Players
└── NPCs
    ├── Enemies
    └── Friendly
```

### Remote Events & Functions

#### Patterns

- Use verb-noun naming: `UpdatePlayerStats`, `RequestItemPurchase`
- Create a dedicated folder in ReplicatedStorage
- Document the expected parameters and return values

```lua
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local updateStatsEvent = remotes:WaitForChild("UpdatePlayerStats")
local purchaseItemFunction = remotes:WaitForChild("RequestItemPurchase")
```

#### Security

- Validate all inputs on the server
- Never trust client data
- Implement rate limiting

```lua
-- Server
purchaseItemFunction.OnServerInvoke = function(player, itemId)
    -- Validate input
    if type(itemId) ~= "string" then
        return {success = false, message = "Invalid item ID"}
    end

    -- Rate limiting
    if isPlayerRateLimited(player) then
        return {success = false, message = "Too many requests, please wait"}
    end

    -- Process purchase
    return processItemPurchase(player, itemId)
end
```

### Custom Properties & Attributes

#### When to Use

- Use attributes for configurable values
- Use values for dynamic data that changes frequently
- Use ObjectValues for references

```lua
-- Setting up attributes
spawnPoint:SetAttribute("TeamID", 1)
spawnPoint:SetAttribute("RespawnTime", 5)

-- Using values for dynamic data
local healthValue = Instance.new("NumberValue")
healthValue.Name = "Health"
healthValue.Value = 100
healthValue.Parent = character
```

---

## Project Setup & Implementation

### Project Structure

#### Folders and Organization

- Organize by feature or module type
- Keep related files together
- Use consistent naming across the project

```
src/
├── client/
│   ├── ui/
│   ├── controllers/
│   └── effects/
├── server/
│   ├── services/
│   ├── systems/
│   └── commands/
└── shared/
    ├── constants/
    ├── enums/
    └── utilities/
```

### Development Workflow

#### Version Control

- Use Git for version control
- Create meaningful commit messages
- Use branches for features/fixes

#### Testing

- Test in isolation when possible
- Create test scripts for complex systems
- Document edge cases and how they're handled

### Adding New Features

#### Process

1. Plan the feature scope and requirements
2. Identify dependencies and potential impacts
3. Create necessary UI elements
4. Implement server-side functionality
5. Connect client and server with proper validation
6. Test extensively, including edge cases
7. Document new systems

#### Example: Adding a New UI Component

```lua
-- 1. Create the UI component module
local UIComponent = {}

-- 2. Define required dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UIStyle = require(ReplicatedStorage.Shared.UIStyle)

-- 3. Initialize function to set up the component
function UIComponent:initialize(parent)
    self.frame = Instance.new("Frame")
    self.frame.Size = UDim2.new(0, 200, 0, 100)
    self.frame.BackgroundColor3 = UIStyle.backgroundColor
    self.frame.Parent = parent

    -- Add additional UI elements

    return self
end

-- 4. Methods to handle component-specific logic
function UIComponent:update(data)
    -- Update UI based on data
end

function UIComponent:hide()
    self.frame.Visible = false
end

function UIComponent:show()
    self.frame.Visible = true
end

-- 5. Clean up resources when done
function UIComponent:destroy()
    self.frame:Destroy()
    self.frame = nil
end

return UIComponent
```

---

## Performance Optimization

### Client-Side Optimization

#### Rendering

- Use `:IsDescendantOf(game)` to check if an instance is still in the game
- Limit UI updates to necessary changes
- Use RunService.Heartbeat instead of while loops
- Disable invisible UI with `Visible = false` rather than destroying

```lua
RunService.Heartbeat:Connect(function(dt)
    -- Only update visible UI elements
    if uiElement.Visible then
        updateUI(uiElement, dt)
    end
end)
```

#### Memory Management

- Clean up connections when they're no longer needed
- Use weak tables for caches that don't need to prevent garbage collection
- Limit the use of tables that grow indefinitely

```lua
local connection = RunService.Heartbeat:Connect(function() end)

-- Disconnect when done
connection:Disconnect()
connection = nil
```

### Server-Side Optimization

#### Data Processing

- Process in batches when possible
- Use task.spawn for operations that can run concurrently
- Cache results of expensive operations

```lua
-- Cache expensive results
local cache = {}

local function getExpensiveData(key)
    if cache[key] then
        return cache[key]
    end

    local result = performExpensiveOperation(key)
    cache[key] = result
    return result
end
```

#### Instance Management

- Use object pools for frequently created/destroyed objects
- Limit instance creation in performance-critical sections
- Use CollectionService for tagging and filtering

---

## UI Design & Implementation

### UI Structure

#### Hierarchy

- Group related elements in frames
- Use consistent sizing and positioning
- Implement responsive UI with scale and offset

```lua
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.8, 0, 0.5, 0)  -- 80% of parent width, 50% of parent height
frame.Position = UDim2.new(0.1, 0, 0.25, 0)  -- Centered
```

#### Styling

- Create a shared UIStyle module
- Implement themes for easy visual updates
- Use consistent colors and fonts

```lua
-- UIStyle.luau
local UIStyle = {
    backgroundColor = Color3.fromRGB(36, 36, 36),
    primaryColor = Color3.fromRGB(0, 120, 215),
    accentColor = Color3.fromRGB(255, 185, 0),
    textColor = Color3.fromRGB(255, 255, 255),

    defaultFont = Enum.Font.SourceSansBold,
    headerFont = Enum.Font.GothamBold,

    cornerRadius = UDim.new(0, 8),
}

return UIStyle
```

### UI Interaction

#### Input Handling

- Debounce rapid inputs
- Provide visual feedback for interactions
- Handle touch and mouse input appropriately

```lua
local button = Instance.new("TextButton")
local debounce = false

button.MouseButton1Click:Connect(function()
    if debounce then return end
    debounce = true

    -- Visual feedback
    button.BackgroundColor3 = UIStyle.accentColor

    -- Process the click
    processButtonClick()

    -- Reset the button
    task.delay(0.2, function()
        button.BackgroundColor3 = UIStyle.primaryColor
        debounce = false
    end)
end)
```

---

## Data Management

### Data Stores

#### Best Practices

- Use session locks for critical data
- Implement retry logic for failed operations
- Keep DataStore keys consistent
- Cache data to reduce API calls

```lua
local DataStoreService = game:GetService("DataStoreService")
local playerData = DataStoreService:GetDataStore("PlayerData")

-- Saving data with retries
local function saveData(userId, data)
    local success = false
    local attempts = 0
    local result

    while not success and attempts < 3 do
        attempts = attempts + 1
        success, result = pcall(function()
            return playerData:SetAsync(userId, data)
        end)

        if not success then
            warn("Failed to save data (attempt " .. attempts .. "): " .. tostring(result))
            task.wait(1) -- Wait before retrying
        end
    end

    return success
end
```

#### Data Versioning

- Include version numbers in saved data
- Implement migration strategies for updates
- Document data structure changes

```lua
local function loadPlayerData(userId)
    local data = getFromDataStore(userId) or createDefaultData()

    -- Handle data versioning
    if data.version < CURRENT_DATA_VERSION then
        data = migrateData(data)
    end

    return data
end
```

### Memory Storage

#### Efficient Patterns

- Use tables for in-memory data
- Implement indexing for faster lookups
- Clean up data when no longer needed

---

## Security Practices

### Anti-Exploitation

#### Client-Server Trust

- Never trust client-provided data
- Validate all inputs on the server
- Use server-authoritative design for game logic

```lua
-- Server-side validation
local function handleDamageRequest(player, targetId, damageAmount)
    -- Verify the player can actually deal damage
    if not canPlayerAttack(player) then
        return
    end

    -- Verify the target exists and is valid
    local target = findTarget(targetId)
    if not target then
        return
    end

    -- Verify damage amount is reasonable
    local expectedDamage = calculateExpectedDamage(player, target)
    if math.abs(damageAmount - expectedDamage) > 0.1 * expectedDamage then
        -- Log potential exploitation attempt
        logSuspiciousActivity(player.UserId, "damage value manipulation")
        damageAmount = expectedDamage
    end

    -- Apply the validated damage
    applyDamage(target, damageAmount)
end
```

#### Remote Event Security

- Implement rate limiting for remote calls
- Track and limit frequency of high-impact operations
- Use remote functions instead of events for operations requiring validation

---

## Additional Resources

### Official Documentation

- [Roblox Developer Hub](https://developer.roblox.com)
- [Luau Documentation](https://luau-lang.org/documentation)

### Community Resources

- [Roblox Developer Forum](https://devforum.roblox.com)
- [RDC Presentations](https://www.youtube.com/playlist?list=PLi-VnF3Ij2pKEHRVLDqt0gw9bIIzCa4CX)

---

This document serves as a reference guide for Roblox Luau development. For specific questions or clarification, please refer to the official documentation or community resources.
