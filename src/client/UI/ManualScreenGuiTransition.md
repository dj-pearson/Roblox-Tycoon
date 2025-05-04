# Manual ScreenGui Menu System Documentation

## Overview

This document explains how to transition from the current UI system to a manual ScreenGui with ImageButtons for UI elements. The new system provides more direct control over the menu UI elements and helps to standardize the appearance and behavior of buttons.

## Files Created

1. `UIMenuSystem.client.luau` - Main implementation of the ScreenGui menu system
2. `UIMenuSystemTester.client.luau` - A simple script to test the menu implementation

## Implementation Details

### ScreenGui Structure

The menu system creates a hierarchical structure:

```
MenuSystem (ScreenGui)
└── MenuContainer (Frame)
    ├── AllianceButton (ImageButton)
    │   ├── Icon (ImageLabel)
    │   └── Tooltip (Frame)
    │       └── TooltipText (TextLabel)
    ├── CommunityGoalsButton (ImageButton)
    │   └── ...
    └── ... (other buttons)
```

### Asset Usage

The system uses asset IDs from your `UIElements.md` file to create ImageButtons with appropriate icons:

- Alliance: 128203268160479
- Community Goals: 97149848004338
- Challenges: 120333480860384
- Guest Pass: 110319251186892
- Tutorial: 98150393120956
- Settings: 72876573893033
- Rebirth: 129409029383961
- Staff Management: 89834599810886
- Upgrades: 132635366103906
- Achievements: 79337595530955

### Key Features

1. **Consistent Styling**: Uses the existing UIStyle system for colors and styling
2. **Interactive Elements**: 
   - Hover effects with tooltips
   - Click animations
   - Callback functions for each button
3. **Customizable**: All aspects of the menu can be adjusted through the CONFIG table
4. **Integration**: Works with your existing UIRegistry for global access

## How to Use

### Basic Implementation

To implement this menu in your game:

1. Make sure the `UIMenuSystem.client.luau` file is placed in your `src/client/UI` directory
2. Create a reference to it in your main client script:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIMenuSystem = require(ReplicatedStorage:WaitForChild("src"):WaitForChild("client"):WaitForChild("UI"):WaitForChild("UIMenuSystem"))

-- Create the menu
UIMenuSystem.CreateMenuUI()
```

### Customization

#### Modifying Button Appearance

You can customize the appearance of buttons by adjusting the CONFIG table in `UIMenuSystem`:

```lua
-- Example of overriding default configuration
local UIMenuSystem = require(path.to.UIMenuSystem)
UIMenuSystem.CONFIG.buttonSize = UDim2.new(0, 60, 0, 60)
UIMenuSystem.CONFIG.hoverBackgroundColor = Color3.fromRGB(255, 100, 100)

-- Then create the menu
UIMenuSystem.CreateMenuUI()
```

#### Adding New Buttons

To add new buttons to the menu:

1. Update your `UIElements.md` file with new asset IDs and names
2. Add a new entry to the `MENU_ELEMENTS` table in `UIMenuSystem.client.luau`

Example:
```lua
{
    assetId = "YOUR_ASSET_ID",
    name = "NewFeature",
    tooltip = "Description of the new feature",
    position = UDim2.new(0, 20, 0, 720),
    callback = function() print("New feature button clicked") end
}
```

#### Handling Button Clicks

Each button has a callback function that runs when clicked. Modify these functions to implement the desired behavior:

```lua
-- In the MENU_ELEMENTS table:
{
    assetId = "128203268160479",
    name = "Alliance",
    tooltip = "Manage your alliances with other players",
    position = UDim2.new(0, 20, 0, 20),
    callback = function() 
        -- Open the alliance UI instead of just printing
        local AllianceUI = require(path.to.AllianceUI)
        AllianceUI.show()
    end
}
```

## Best Practices

1. **Performance**: ImageButtons are more performance-friendly than complex TextButton hierarchies
2. **Asset Management**: Keep your asset IDs organized in the `UIElements.md` file
3. **Responsiveness**: Consider adding screen size detection to adjust the menu layout on different devices
4. **Accessibility**: Add keyboard shortcuts for menu navigation

## Troubleshooting

Common issues and solutions:

1. **Missing Icons**: Make sure asset IDs are correct and the assets are approved for use in your game
2. **Positioning Issues**: Adjust the position values in the MENU_ELEMENTS table
3. **Loading Errors**: Ensure the correct module paths are used when requiring the UIMenuSystem

## Future Enhancements

Potential improvements to consider:

1. Animated transitions between menu states
2. Collapsible menu for mobile devices
3. Color themes that users can select
4. Badge notifications for specific menu items
5. Drag-and-drop customization of the menu order
