# BuyTileSystem Documentation

## Overview
The BuyTileSystem is a core component of the Roblox Fitness Center Tycoon that manages the purchasing and placement of gym equipment. This system handles equipment templates, pricing calculations, placement logic, and integration with other core systems.

## System Architecture

### Core Components
1. **Status Management**
   - Tracks system state: UNINITIALIZED, INITIALIZING, INITIALIZED, DEGRADED, FAILED
   - Maintains initialization errors and dependency status
   - Provides status query methods through public API

2. **Dependency Management**
   - Required Dependencies:
     - EventBridge: Handles cross-system communication
     - DataManager: Manages data persistence
     - TycoonSystem: Controls tycoon-related functionality
   - Implements retry mechanism for dependency acquisition
   - Graceful degradation when non-critical dependencies are unavailable

3. **Equipment Management**
   - Template caching
   - Price calculation with progression scaling
   - Special equipment handling
   - Equipment placement and positioning logic

### Configuration
```lua
local CONFIG = {
    debugEnabled = true,          -- Toggle debug logging
    equipmentFolder = "GymEquipment", -- Equipment templates location
    
    -- Pricing Configuration
    baseTilePrice = 100,          -- Base equipment price
    priceIncreaseFactor = 1.1,    -- Price scaling per purchase
    specialEquipmentMultiplier = 2, -- Special equipment price multiplier
    
    -- Equipment Constraints
    maxEquipmentPerTycoon = 100,  -- Maximum equipment per tycoon
    
    -- Performance Settings
    staggeredPlacement = true,    -- Enable staggered placement
    placementDelay = 0.1,         -- Delay between placements
    
    -- Dependency Configuration
    maxRetries = 5,              -- Maximum dependency retry attempts
    retryDelay = 1,              -- Delay between retries
}
```

## Initialization Process
1. System starts in UNINITIALIZED state
2. Initialization begins:
   - Attempts to acquire dependencies with retry mechanism
   - Loads equipment templates
   - Sets up remote events
3. System transitions to:
   - INITIALIZED: All components loaded successfully
   - DEGRADED: Some non-critical components failed
   - FAILED: Critical components unavailable

## Public API

### Core Functions
```lua
-- Initialize the system
initialize() -> boolean

-- Get current system status
getStatus() -> SystemStatus

-- Get initialization errors
getInitializationErrors() -> {string}

-- Calculate price for equipment
calculateTilePrice(player: Player, tileId: string) -> number

-- Handle purchase request
handleBuyTileRequest(player: Player, tileId: string) -> boolean

-- Place equipment in tycoon
placeEquipment(player: Player, tileId: string) -> boolean

-- Restore equipment from saved data
restoreEquipment(player: Player, equipmentList: {string}) -> boolean
```

### Utility Functions
```lua
-- Get available equipment templates
getEquipmentTemplates() -> {[string]: Model}

-- Get equipment prices
getEquipmentPrices() -> {[string]: number}
```

## Error Handling
The system implements comprehensive error handling:
1. **Logging Levels**
   - INFO: General operation information
   - WARNING: Non-critical issues
   - ERROR: Critical failures

2. **Error Recovery**
   - Automatic retry for dependency acquisition
   - Graceful degradation for non-critical failures
   - Cash refunds for failed purchases
   - Fallback positioning system

## Integration Points

### EventBridge Integration
- TilePurchased: Fired when equipment is purchased
- TilePurchasedClient: Notifies client of purchase
- BuyTile: Remote event for purchase requests

### DataManager Integration
- recordEquipmentPurchase: Records purchase history
- Equipment restoration during player data loading

### TycoonSystem Integration
- Equipment placement in tycoon space
- Tycoon attribute updates
- Equipment count tracking

## Troubleshooting Guide

### Common Issues

1. **System in Degraded State**
   - Check initialization errors via `getInitializationErrors()`
   - Verify CoreRegistry availability
   - Check required dependencies status

2. **Equipment Template Loading Failures**
   - Verify GymEquipment folder exists in ReplicatedStorage
   - Check template models have required attributes
   - Ensure templates are properly configured

3. **Purchase Failures**
   - Verify player has sufficient funds
   - Check tycoon reference exists
   - Ensure equipment limit not exceeded
   - Check placement position availability

4. **Placement Issues**
   - Verify EquipmentSpots folder structure
   - Check floor parts naming convention
   - Ensure proper CFrame calculations
   - Verify PrimaryPart configuration

### Diagnostic Steps
1. Check system status: `BuyTileSystem.getStatus()`
2. Review initialization errors
3. Verify dependency availability
4. Check equipment template loading
5. Monitor purchase and placement logs

## Performance Considerations

1. **Template Caching**
   - Templates cached during initialization
   - Avoid runtime template loading

2. **Staggered Placement**
   - Configurable delay between placements
   - Prevents performance spikes during bulk operations

3. **Event Handling**
   - Protected calls for event operations
   - Asynchronous effect processing

## Maintenance Tasks

### Regular Maintenance
1. Monitor initialization success rate
2. Check dependency health
3. Verify template loading
4. Review error logs
5. Update configuration as needed

### System Updates
1. Backup configuration
2. Test dependency compatibility
3. Verify template compatibility
4. Update documentation
5. Test all core functions

## Version History

### v2.0.0 (Current)
- Added comprehensive status tracking
- Implemented dependency retry mechanism
- Enhanced error handling and logging
- Added performance optimizations
- Improved documentation

### v1.0.0 (Legacy)
- Basic equipment purchasing
- Simple placement system
- Limited error handling
- Basic dependency management 