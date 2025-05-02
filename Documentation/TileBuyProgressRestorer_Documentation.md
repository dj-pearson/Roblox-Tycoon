# TileBuyProgressRestorer Module Documentation

## Overview

The TileBuyProgressRestorer module is a dedicated system for ensuring that players' buy tile progression state is correctly maintained when they leave and rejoin the game. It specifically addresses an issue where buy tiles would reset to tile #1 instead of showing the next available buy tile after the player's last purchase.

**Created:** May 2, 2025

## Problem Solved

When players left and rejoined the game, the BuyTile system wasn't correctly recalling their previous progress, causing these issues:

1. Buy tiles would reappear starting from tile #1 instead of continuing where the player left off
2. Players couldn't easily find the next tile to purchase
3. Progression information was lost between sessions
4. Poor player experience due to inconsistent state

## Key Features

- **Progression State Tracking**: Effectively tracks the highest tile ID purchased by a player
- **Next Buy Tile Positioning**: Ensures the next buy tile appears after the last purchased one
- **Multiple Data Source Support**: Reliably finds purchased tiles using multiple methods:
  - Primary method: DataManager player data
  - Secondary method: Tycoon purchases folder
  - Tertiary method: Model ID attributes in the tycoon
- **CoreRegistry Integration**: Proper integration with the game's system registry
- **Automatic Initialization**: Automatically fixes progression when players join
- **Fallback Systems**: Works with both new BuyTileSystem and legacy BuyTile module

## Technical Implementation

### Highest Tile ID Detection

The module implements a robust algorithm for finding the highest purchased tile ID:

```lua
function TileBuyProgressRestorer.getHighestTileId(player)
    -- Try DataManager first
    local playerData = DataManager.getPlayerData(player)
    -- Check purchased tiles in data
    
    -- If not found, check tycoon purchases folder
    local purchasesFolder = tycoon.Value:FindFirstChild("Purchases")
    -- Check boolean values for purchase records
    
    -- If still not found, check model attributes in tycoon
    for _, model in ipairs(tycoon.Value:GetDescendants()) do
        if model:GetAttribute("ID") or model:GetAttribute("TileID") then
            -- Check for highest ID
        end
    end
end
```

### Next Buy Tile Spawning

Once the highest purchased tile ID is found, the next tile is spawned:

```lua
function TileBuyProgressRestorer.spawnNextBuyTile(player)
    local highestTileId = TileBuyProgressRestorer.getHighestTileId(player)
    local nextTileId = highestTileId + 1
    
    -- Try BuyTileSystem first
    BuyTileSystem.spawnBuyTile(nextTileId)
    
    -- Fallback to original module if needed
    if not success then
        originalBuyTile.spawnBuyTile(nextTileId)
    end
end
```

## Integration with Other Systems

The TileBuyProgressRestorer integrates with these systems:

1. **BuyTilePositionFixer**: Works together to ensure both position and progression are correct
2. **CoreRegistry**: Registers itself and finds other systems
3. **DataManager**: Accesses player data for progression information
4. **BuyTileSystem**: Uses the enhanced tile spawning capabilities
5. **EventBridge**: Fires events when progression is restored (if available)

## Usage Instructions

The module initializes automatically and handles player join events. No manual intervention is required.

For testing or manual restoration, these functions are available:

- `TileBuyProgressRestorer.getHighestTileId(player)` - Returns the highest tile ID purchased by a player
- `TileBuyProgressRestorer.spawnNextBuyTile(player)` - Spawns the next buy tile for a player
- `TileBuyProgressRestorer.fixPlayerProgression(player)` - Fixes a player's entire buy tile progression

## Verification and Testing

To verify the module is working correctly:

1. Have a player purchase several buy tiles (e.g. tiles #1-30)
2. Have the player leave and rejoin the game
3. Confirm that tile #31 is the next available buy tile, not tile #1
4. Check the output logs for TileBuyProgressRestorer messages

## Conclusion

The TileBuyProgressRestorer provides a robust solution for maintaining buy tile progression between player sessions, ensuring a consistent and enjoyable player experience. It addresses a critical issue with minimal overhead and reliable operation.

---

**Author:** GitHub Copilot  
**Last Updated:** May 2, 2025
