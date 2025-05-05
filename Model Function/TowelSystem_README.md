# Towel Interaction System
## Setup Instructions

This system provides a complete towel interaction experience for your Roblox game. Players can take towels from racks, store them in an inventory, wear them, and drop them in the world.

### Required Services Setup

1. **Create three RemoteEvents in ReplicatedStorage:**
   - InventoryUpdate
   - InventoryAction  
   - Notification

   *Note: The TowelSystemInitializer will create these for you automatically.*

2. **Move the scripts to their correct locations:**
   - `Towels.luau` → ServerScriptService (as a ModuleScript)  
   - `TowelInventory.client.lua` → StarterPlayerScripts (as a LocalScript)
   - `TowelSystemInitializer.server.lua` → ServerScriptService (as a Script)

3. **Set up towel models in ReplicatedStorage:**
   Create this folder structure:
   ```
   ReplicatedStorage
   └── Assets
       └── Towels
           ├── Regular
           └── Premium
   ```

   Place your towel models inside the "Regular" and "Premium" folders. Each model should:
   - Have a PrimaryPart set
   - Be properly scaled for wearing on a character

4. **Set up towel racks in the workspace:**
   - Create models named "Towels" for each rack in your game
   - Each rack should have a PrimaryPart
   - Add an optional string Attribute "TowelType" set to "Regular" or "Premium"
   - Add an optional number Attribute "Cooldown" to set the cooldown in seconds

### Features

- **Persistence**: Player inventories are saved to DataStore and loaded when they rejoin
- **Inventory UI**: Players can access their inventory with a backpack button
- **Wearing**: Towels can be worn around the neck for 5 minutes before returning to inventory
- **Dropping**: Players can drop towels in the world for others to pick up

### Customization

You can customize various aspects of the system:
- Edit `TOWEL_WEAR_DURATION` in Towels.luau to change how long towels can be worn
- Modify the UI appearance in TowelInventory.client.lua
- Add more towel variants by creating new models in ReplicatedStorage/Assets/Towels

### Troubleshooting

- Ensure all needed RemoteEvents are in ReplicatedStorage/Events
- Check that towel models have PrimaryParts set
- Verify DataStore service is enabled in game settings for persistence to work
- If towels don't appear on characters, check avatar compatibility
