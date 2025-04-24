# Data Persistence Architecture Documentation

## Current Systems Overview

### 1. Core DataManager (`src/server/Core/DataManager.server.luau`)

**Primary Features:**
- Versioned data stores with backup mechanisms
- Session locking to prevent data duplication
- Support for data migration between versions
- Auto-save at 120-second intervals
- Backup creation at 600-second intervals
- Integration with DataThrottler
- Support for secondary data stores (Equipment, Milestones, etc.)

**Strengths:**
- Robust error handling with retry logic
- Comprehensive versioning system
- Well-organized separation of different data types
- Integrated with CoreRegistry for dependency management

**Weaknesses:**
- May conflict with EnhancedDataStorageSystem
- Lacks standardized access methods across all dependent systems

### 2. EnhancedDataStorageSystem (`src/server/Data/EnhancedDataStorageSystem.server.luau`)

**Primary Features:**
- Independent auto-save functionality (60-second interval)
- Backup creation every 5 minutes
- Retry logic for failed operations
- Equipment restoration capabilities

**Strengths:**
- Designed as a drop-in replacement for legacy systems
- Self-contained error handling
- Simple API surface

**Weaknesses:**
- Duplicates functionality from Core DataManager
- May cause race conditions with simultaneous save operations

### 3. NEW: DataAccessLayer (`src/server/Core/DataAccessLayer.server.luau`)

**Primary Features:**
- Standardized interface for accessing player data across all systems
- Unified error handling and retry logic
- Deep copying to prevent accidental data corruption
- Session locking to prevent data duplication
- Configurable auto-save functionality
- Integration with CoreRegistry
- Automatic data validation

**Strengths:**
- Works with both existing Core DataManager and EnhancedDataStorageSystem
- Provides consistent API regardless of underlying system
- Prevents race conditions through session locking
- Handles system dependencies automatically

**Weaknesses:**
- Additional layer of abstraction may slightly impact performance
- Requires systems to be updated to use the new interface

### 4. NEW: VersionedDataStore (`src/server/Core/VersionedDataStore.server.luau`)

**Primary Features:**
- Historical data snapshots with timestamps using OrderedDataStore (Berezaas method)
- Automatic rollback to previous versions if data corruption is detected
- Data integrity validation during save/load operations
- Manual version rollback capabilities
- Efficient cleanup of old versions to save DataStore quota

**Strengths:**
- Highly resilient to data corruption
- Provides full data history for debugging and recovery
- Integrates with DataAccessLayer for unified access

**Weaknesses:**
- Uses more DataStore operations than simpler persistence methods
- Slightly increased complexity in data access patterns

### 5. NEW: DataMigrationUtility (`src/server/Core/DataMigrationUtility.server.luau`)

**Primary Features:**
- Safe migration between any data system (EnhancedDataStorageSystem, DataManager, DataAccessLayer, VersionedDataStore)
- Automatic backup creation before migration
- Data validation during migration process
- Admin command system for triggering migrations
- Migration status tracking and monitoring

**Strengths:**
- Facilitates smooth transition between different data systems
- Provides safety mechanisms to prevent data loss during migration
- Enables gradual system upgrade rather than "big bang" transitions

**Weaknesses:**
- Adds complexity to the overall architecture
- Requires careful monitoring during migration periods

### 6. System-Specific Data Handlers

Various systems implement their own data persistence logic:

- **StaffManagementSystem:** Saves staff data to both DataManager and player attributes
- **RebirthSystem:** Maintains separate player data storage
- **MemberSatisfactionSystem:** Updates player data through DataManager
- **EquipmentUpgradeSystem:** Stores equipment upgrade data

## Enhanced Data Flow Diagram

```
[Player Joins] --> [DataAccessLayer.LoadPlayerData] --> [Apply to Player]
                --> [PlayerProgressRestoration]     --> [Restore Equipment]
                
[Auto-Save Interval] --> [DataAccessLayer.SavePlayerData] --> [Save to Active System]
                     --> [VersionedDataStore.SaveData]    --> [Create History Point]
                     
[Player Leaves] --> [DataAccessLayer.SavePlayerData] --> [Save Data]
                --> [DataAccessLayer.ReleaseSessionLock] --> [Clean Up]
                
[Game Shutdown] --> [DataAccessLayer.SavePlayerData] --> [Save All Data]
                --> [VersionedDataStore.HandleShutdown] --> [Create History Points]
                
[Data Corruption Detected] --> [VersionedDataStore.LoadPreviousVersion] --> [Rollback Data]
```

## Dependencies

### DataAccessLayer Dependencies
- CoreRegistry (optional)
- DataManager or EnhancedDataStorageSystem (at least one required)

### VersionedDataStore Dependencies
- CoreRegistry (optional)
- DataAccessLayer (optional but recommended)

### DataMigrationUtility Dependencies
- CoreRegistry (optional)
- DataAccessLayer (optional)
- DataManager (optional)
- EnhancedDataStorageSystem (optional)
- VersionedDataStore (optional)

## Previous Known Issues (Now Resolved)

1. ✅ **PlayerProgressRestoration Error**: Fixed with improved data retrieval logic and fallbacks
2. ✅ **Multiple Simultaneous Saves**: Resolved through session locking in DataAccessLayer
3. ✅ **Inconsistent Save Paths**: Standardized through DataAccessLayer unified interface
4. ✅ **Potential Race Conditions**: Eliminated with coordinated auto-save through DataAccessLayer

## Current Implementation Status

1. ✅ **DataAccessLayer**: Implemented - Provides standardized data access interface
2. ✅ **PlayerProgressRestoration**: Fixed - Now properly retrieves and restores player data
3. ✅ **VersionedDataStore**: Implemented - Offers historical data snapshots and rollback
4. ✅ **DataMigrationUtility**: Implemented - Facilitates safe transition between systems
5. ⬜ **System Migration**: In Progress - Systems being updated to use DataAccessLayer
6. ⬜ **Legacy System Deprecation**: Pending - EnhancedDataStorageSystem to be phased out

## Updated Consolidation Path

1. Use DataAccessLayer as the standardized interface for all data operations
2. Gradually migrate from EnhancedDataStorageSystem to VersionedDataStore for critical data
3. Update all systems to use DataAccessLayer instead of direct DataManager or EnhancedDataStorageSystem calls
4. Implement consistent session locking to prevent data duplication
5. Complete data migration for all active players
6. Deprecate EnhancedDataStorageSystem once migration is complete

## System-by-System Integration Plan

### StaffManagementSystem
- Update to use DataAccessLayer for all data operations
- Remove direct attribute storage or make it a fallback only
- Migrate existing data through DataMigrationUtility

### RebirthSystem
- Integrate with DataAccessLayer
- Store rebirth data as part of the main player data structure
- Use VersionedDataStore for critical rebirth progress

### MemberSatisfactionSystem
- Update to use DataAccessLayer
- Add validation before saves
- Implement proper error handling for data operations

### EquipmentUpgradeSystem
- Update to use DataAccessLayer consistently
- Ensure proper initialization order for data loading
- Use VersionedDataStore for equipment data to prevent loss

### PlayerProgressRestoration
- Already updated to use DataAccessLayer with fallbacks
- Implementing multi-level fallback for data retrieval
- Added improved tycoon detection and restoration

## Future Considerations

1. **Data Analytics System**: Track player data changes over time using the version history
2. **Admin Dashboard**: Create an in-game interface for data management and recovery
3. **Cloud Backup**: Implement external backup system for critical player data
4. **Cross-Server Data Synchronization**: For multi-server deployments and seamless server transfers
5. **Automated Testing**: Create test suite for data integrity and performance

## Contact

For any questions or issues regarding this data persistence architecture, please contact the development team.

Last Updated: April 23, 2025
