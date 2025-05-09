# Phase 3 UI Migration Guide

## Overview
Phase 3 focuses on eliminating "Other UI Scripts" - these are UI scripts that aren't in StarterGui or StarterPlayerScripts but might be in ReplicatedStorage, PlayerScripts, or other locations.

## Important Changes for Phase 3

1. **Enhanced Search Algorithm**:
   - Now specifically searches in ReplicatedStorage and PlayerScripts
   - Targets the client/UI directories more thoroughly
   - Still finds scripts that have already been disabled

2. **Scripts to Eliminate in Phase 3**:
   - MainMenuUI (duplicates in other locations)
   - MainMenuUILoader 
   - AchievementsUI
   - RebirthUI (duplicates in other locations)
   - GuestPassUI
   - GymMenuUI
   - PlayerStatsDisplay
   - ProgressBar

## Step-by-Step Process

### Step 1: Run Phase 3 Disable Test
1. Open Roblox Studio with your game
2. Verify the script is set to:
   ```lua
   local eliminate = false
   local phase = 3
   ```
3. Run the ImprovedUIScriptEliminator script
4. Check the Output window to see what scripts were found

### Step 2: Test the Game
1. Ensure UIToggleSystem.UseNewUISystem = true
2. Play the game in Studio
3. Test all UI functions still work correctly:
   - Main menu 
   - Achievements system
   - Rebirth mechanics
   - Guest pass features
   - Gym menu
   - Player stats
   - Progress bar functionality

### Step 3: If Testing is Successful, Proceed to Elimination
1. Update the script to:
   ```lua
   local eliminate = true
   local phase = 3
   ```
2. Run the script again to permanently remove the scripts
3. Test the game again to ensure everything still works

### Step 4: Review Special Cases
While working on Phase 3, continue examining the special case scripts:
- TemperatureDisplay
- DoubleMemberPurchaseGui
- BuilderBoostPurchaseGui

For each:
1. Check if their functionality is already covered in the new UI system
2. If not, plan how to incorporate their functionality
3. Once functionality is migrated, add them to the Phase 3 elimination list

## Troubleshooting

### If Scripts Aren't Found
1. Try running the UIScriptFinder to locate all remaining UI scripts
2. Check if they're already in a .disabled state
3. Manually search in ReplicatedStorage and PlayerScripts folders

### If UI Functionality is Missing
1. Set UIToggleSystem.UseNewUISystem = false to verify the issue
2. Check if the missing functionality is from one of the scripts being disabled
3. Ensure the new UI system implements all required functionality

## Final Migration Steps

Once Phase 3 is successfully completed:
1. Run a final test session with multiple players
2. Document all performance improvements
3. Remove the UIToggleSystem and migration tools
4. Update documentation to reference only the new UI system
5. Optional: Move the backups to a long-term storage solution
