# Admin Command System Documentation

## Overview
The admin command system provides administrators with the ability to perform special actions within the game. These commands help with debugging, visualizing, and managing the game environment.

## Accessing Admin Commands
There are two main ways to access admin commands:

1. **Admin Button in DataManagementUI** - A red wrench button (🔧) appears in the DataManagementUI for admin users. Clicking this button opens a menu with available commands.

2. **Admin Button Overlay** - A draggable blue "A" button appears in the top-right corner of the screen for admin users. This provides access to the same commands through a different interface.

## Available Commands

### Visualization Commands
- **Show Hitboxes** - Makes all hitboxes and collision objects visible by changing their transparency and color.
- **Hide Hitboxes** - Restores the original transparency of hitboxes and collision objects.
- **Add Primary Parts** - Adds invisible primary parts to models that don't have one, particularly useful for models in the GymParts folder.

### Tycoon Structure Commands
- **Process Tycoon** - Processes the tycoon structure.
- **Automate Gym** - Automates gym setup.
- **Show Tycoon Info** - Displays information about the tycoon.

### Buy Tile System Commands
- **Setup BuyTile System** - Sets up the buy tile system.
- **Auto-Setup Buy Tiles** - Automatically sets up buy tiles.
- **Generate Build Order** - Generates the build order for buy tiles.
- **Generate BuyTile Config** - Generates configuration for buy tiles.

### Performance Commands
- **Show Performance Stats** - Displays performance statistics.
- **Hide Performance Stats** - Hides performance statistics.

## Primary Part Assignment Feature

### Purpose
The Primary Part Assignment feature addresses issues with models that don't have a designated primary part. Without a primary part, many Roblox operations on models (like moving or cloning) can behave unpredictably.

### How It Works
When executed, the "Add Primary Parts" command:

1. Scans the "GymParts" folder for all models
2. For each model without a PrimaryPart:
   - Creates an invisible 1x1x1 part called "PrimaryReference"
   - Positions it at the model's bounding box center
   - Sets the part's properties to be non-colliding and transparent
   - Designates this new part as the model's PrimaryPart

### Implementation
The feature follows these principles:

1. **Multiple Execution Paths**:
   - First tries to use a remote function (`AssignPrimaryPartsRemote`)
   - Falls back to direct implementation when remote isn't available
   - Logs detailed information during execution

2. **Feedback Mechanisms**:
   - Shows status updates during processing
   - Provides success/error information after completion
   - Logs execution details in the console

3. **Error Handling**:
   - Gracefully handles missing folders
   - Reports execution errors without crashing
   - Includes counts of processed and updated models

### Usage
To use the Primary Part Assignment feature:

1. Log in as an administrator
2. Open either of the admin command menus
3. Click the "Add Primary Parts" button
4. Check the feedback text for results

## Technical Implementation

The admin command system includes multiple layers:

1. **Server-side Commands** - Commands that must run on the server due to security or performance reasons
2. **Client-side Commands** - Commands that can run directly on the client
3. **Shared Implementations** - A central repository of command implementations in `AdminCommandImplementations.lua`

### Command Execution Flow

Commands follow this execution flow:
1. Check for a global function (_G[commandName])
2. Try using a shared implementation
3. Try using a remote function
4. Fall back to direct implementation
5. Report success or failure

### Files Involved

- `src/client/AdminCommandsExtension.client.luau` - Adds admin commands to DataManagementUI
- `src/client/AdminButtonCreator.client.luau` - Creates a draggable admin button overlay
- `src/shared/AdminCommandImplementations.lua` - Central repository of command implementations
- `src/server/Commands/PrimaryPartAssignmentCommand.server.luau` - Server-side implementation of primary part assignment
- `src/client/PrimaryPartLoader.client.luau` - Client-side helper for primary part assignment
- `src/server/GlobalAdminCommandInitializer.server.luau` - Initializes admin commands on the server
- `src/client/CommandTester.client.luau` - Optional alternative testing interface (disabled by default)

## Troubleshooting

If commands aren't working:

1. Verify you're logged in as an administrator (UserID must match the ADMIN_ID constant)
2. Check the console for error messages (prefixed with "[AdminCommands]" or similar)
3. Ensure all required folders exist (e.g., "GymParts" for primary part assignment)
4. Try using the alternate admin interface if one isn't working

## Future Improvements

Planned improvements for the admin command system:

1. Consolidation of both admin UIs into a single, more powerful interface
2. Addition of parameter support for commands
3. Implementation of permission levels for different admin commands
4. Improved visual feedback and progress indicators for long-running commands
