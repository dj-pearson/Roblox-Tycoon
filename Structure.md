# Structure Overview

This document outlines the structure of the Gym Tycoon project, highlighting key files and systems. As part of our ongoing consolidation efforts (see `Documentation/ComprehensiveConsolidationPlan.md`), we're working to reduce duplication and improve code organization across the codebase.

## Refactoring Status

| System | Status | Notes |
|--------|--------|-------|
| UI Systems | ✅ Completed | Unified framework implemented with centralized components |
| Data Management | ✅ Completed | Comprehensive data system with caching and client integration |
| Registry Systems | ✅ Completed | Unified registry system with client, server and shared implementations |
| Event Systems | 🔄 In Progress | Design document created, implementation started |
| Rebirth Systems | ⏳ To Be Planned | Analysis phase not yet started |
| Tile Purchase Systems | ⏳ To Be Planned | Analysis phase not yet started |
| Equipment Systems | ⏳ To Be Planned | Analysis phase not yet started |

# src root

-`src/GameSystem.lua`: Core game system module that serves as an entry point for the game's primary functionality. It coordinates between major subsystems, handles game state management, and provides a high-level API for common game operations. The module bridges between server, client, and shared code components and serves as the main orchestrator for game initialization and runtime behavior.

# src/StarterGui

-   `src/StarterGui/RebirthUI.client.luau`: Client-side script for the primary rebirth system interface. It displays rebirth options, prerequisites, benefits, and confirmation dialogs. The script handles visual feedback during the rebirth process and animates the transition to the reborn state.

-   `src/StarterGui/RebirthUIFixes.luau`: Utility module containing patches for known issues in the rebirth UI. It addresses edge cases, visual glitches, and interaction problems without requiring a complete rewrite of the main UI script. The module is applied at runtime to fix specific rebirth interface problems.

-   `src/StarterGui/RebirthUI_Enhanced.client.luau`: Upgraded version of the rebirth interface with additional features. It extends the basic rebirth UI with detailed statistics, rebirth history, and specialized options for advanced players. The script represents a significant enhancement over the original rebirth interface.

-   `src/StarterGui/ResetButton.client.luau`: Client-side script implementing a custom character reset button. It provides a more controlled reset experience than the default Roblox reset, with appropriate animations and data preservation. The script integrates with the game's systems to ensure safe character resetting.

-   `src/StarterGui/SatisfactionButton.server.luau`: Server-side script managing interactive satisfaction feedback controls. It processes player interactions with satisfaction rating buttons and records the feedback for analysis. The script helps gather player sentiment data about different game features.

-   `src/StarterGui/StatsGui.client.luau`: Client-side script for displaying key player statistics. It shows gym metrics, player progress, and performance indicators in a compact, always-visible interface. The script updates in real-time as game values change to provide immediate feedback.

-   `src/StarterGui/BuilderBoostPurchaseGui.client.luau`: Client-side script for the builder boost purchase interface. It allows players to purchase temporary boosts that accelerate building and development of their gym. The script handles purchase confirmation, displays boost effects and duration, and communicates with the server to apply purchased boosts.

-   `src/StarterGui/CleanGymController.client.luau`: Client-side script that manages the gym cleanliness system interface. It displays cleanliness levels, highlights areas needing attention, and provides controls for cleaning activities. The script communicates with server-side cleanliness systems and updates visuals to reflect current gym conditions.

-   `src/StarterGui/DirectResetButton.server.luau`: Server-side script that manages a direct character reset feature. It provides a way for players to reset their character state without using the standard Roblox reset function, offering more control over the reset process and its consequences in the game context.

-   `src/StarterGui/DoubleMemberPurchaseGui.client.luau`: Client-side script for purchasing double member promotions. It displays the benefits, costs, and duration of membership boosts that double the rate of member visits. The script handles purchase confirmation and communicates with the server to apply the boost effects.

-   `src/StarterGui/MainMenuUI.client.luau`: Primary client-side script for the main menu interface. It creates and manages the main menu structure, handles navigation between different sections, and provides access to core game features. The script responds to player input and game state changes to update the menu accordingly.

-   `src/StarterGui/RebirthMenuUI.client.luau`: Client-side script for the rebirth system menu. It displays rebirth options, benefits, requirements, and confirmation dialogs. The script calculates potential post-rebirth status and communicates with the server to execute rebirth operations when confirmed.

-   `src/StarterGui/SettingsUI.client.luau`: Client-side script for the game settings interface. It provides controls for adjusting audio, graphics, control schemes, and gameplay preferences. The script saves settings locally and applies changes immediately to enhance the player experience.

-   `src/StarterGui/TemperatureDisplay.client.luau`: Client-side script specifically for displaying temperature information for sauna and pool areas. It shows current temperature, optimal ranges, and effects on gym members. The script includes visual indicators that change color based on temperature conditions.

# src/ServerStorage

-`src/ServerStorage/BuyTiles.rbxmx`: Model file containing the physical assets for purchasable gym tiles. It includes 3D models, textures, and configuration properties for different tile types. This resource file is used by the tile purchasing system to instantiate new tiles when players make purchases.

-`src/ServerStorage/CommandScripts.rbxmx`: Collection of administrative and development command scripts. It contains utilities for debugging, testing, and managing the game environment. These scripts provide authorized users with tools to inspect and manipulate game state.

-`src/ServerStorage/Elliptical_Upgrade.rbxmx`: Model file containing upgraded versions of elliptical training equipment. It includes higher quality 3D models and enhanced interaction points for upgraded equipment. These models are used when players purchase equipment upgrades.

-`src/ServerStorage/NPC_Character.rbxmx`: Template character models for non-player characters. It contains different member types with varied appearances, animations, and properties. These templates are used to instantiate gym members and staff with appropriate visual characteristics.

-`src/ServerStorage/ScriptBoneyard.rbxmx`: Archive of deprecated or replaced scripts kept for reference. It contains code that has been removed from active use but maintained for historical or educational purposes. This collection helps developers understand previous implementation approaches.

-`src/ServerStorage/SurfaceGUI.rbxmx`: Collection of GUI elements designed for mounting on 3D surfaces in the game. It includes screen displays, control panels, and information boards that can be attached to gym objects. These interfaces provide immersive interaction points within the 3D environment.

-`src/ServerStorage/Treadmill_Upgrade.rbxmx`: Model file containing upgraded versions of treadmill equipment. It includes higher quality 3D models with enhanced features and visual effects. These models are used when players purchase treadmill upgrades for their gym.

-`src/ServerStorage/Unused_Models.rbxmx`: Archive of 3D models and assets that were created but not currently used in the game. It contains experimental designs, discontinued equipment types, and alternative visual styles. These assets are preserved for potential future use.

-`src/ServerStorage/Unused_Scripts.rbxmx`: Collection of scripts that were developed but not currently active in the game. It contains experimental features, alternative implementations, and incomplete systems. These scripts are maintained as reference material or for potential future implementation.

## src/server/Essentials

-   `src/server/Essentials/Accrued Dues.server.luau`: Server-side script managing the gym membership payment system. It tracks member dues, handles payment collection schedules, and processes overdue accounts. The script includes configurable payment periods, late fee calculations, and membership suspension logic when payments fall too far behind.

-   `src/server/Essentials/AdminCommands.server.luau`: Server-side script implementing administrative commands for game management. It provides authorized users with tools to inspect game state, modify player data, and troubleshoot issues. The script includes security measures to ensure only proper users can execute administrative functions.

-   `src/server/Essentials/BuyTile.server.luau`: Server-side script handling the core tile purchasing functionality. It processes purchase requests, validates requirements, handles payment, and instantiates new gym tiles. The script includes logic for discounts, special offers, and purchase limitations based on player level.

-   `src/server/Essentials/EquipmentSetupCommands.server.luau`: Server-side script providing commands for configuring and positioning gym equipment. It helps with initial placement, attribute setting, and connection to relevant systems. The script assists developers in rapidly setting up and testing new equipment types.

-   `src/server/Essentials/EventBridge.server.luau`: Server-side script establishing communication channels between different game systems. It creates a standardized event system for modules to interact without direct dependencies. The script handles event registration, firing, and connection management for efficient inter-system communication.

-   `src/server/Essentials/FrontDeskPrompt.server.luau`: Server-side script managing the interactive front desk area. It handles player interactions with the reception desk, including membership sign-ups, information requests, and gym tours. The script creates an entry point for new players to learn about gym features.

-   `src/server/Essentials/GymMilestonesSystem.server.luau`: Server-side script implementing progression milestones for gym development. It tracks achievement of significant gym improvements, awards appropriate rewards, and manages milestone notifications. The script provides a sense of accomplishment as players build their gym.

-   `src/server/Essentials/GymPartsSetupCommand.luau`: Module providing commands for initializing and configuring gym structural components. It includes functions for setting up walls, floors, and fixed facilities. The script assists developers in creating and testing consistent gym environments.

-   `src/server/Essentials/GymRevenueSystem.server.luau`: Server-side script handling the core financial mechanics of the game. It calculates income from various sources, manages operating expenses, and updates player funds. The script creates the economic foundation that drives the tycoon gameplay loop.

-   `src/server/Essentials/GymSpecializationSystem.server.luau`: Server-side script implementing gym focus area mechanics. It manages specialization selection, specialized equipment bonuses, and member type attraction based on gym focus. The script allows players to differentiate their gym with strategic specialization choices.

-   `src/server/Essentials/Leaderstats.server.luau`: Server-side script creating and updating player leaderboard statistics. It displays key metrics like wealth, gym rating, and member count for competitive comparison. The script ensures leaderboard values stay synchronized with actual player progress.

-   `src/server/Essentials/PlayerActivityReceiver.server.luau`: Server-side script collecting and processing player activity data. It records gameplay patterns, feature usage, and time investment for analytics purposes. The script helps developers understand how players interact with the game.

-   `src/server/Essentials/PlayerCharacterCheck.server.luau`: Server-side script verifying player character integrity. It ensures characters have all required components, fixes missing or broken elements, and resets characters when necessary. The script prevents gameplay issues arising from character state problems.

-   `src/server/Essentials/PlayerProgressRestoration.server.luau`: Server-side script handling recovery of player progress in case of data issues. It provides mechanisms to restore lost progress, fix corrupted saves, or compensate players for technical problems. The script serves as a safety net for data integrity issues.

-   `src/server/Essentials/PlayerSanctionSystem.server.luau`: Server-side script implementing moderation tools for player behavior management. It handles warnings, temporary restrictions, and more severe sanctions for rule violations. The script helps maintain a positive game environment.

-   `src/server/Essentials/SpecializationIntegration.server.luau`: Server-side script connecting the specialization system with other game mechanics. It ensures that specialization choices affect relevant systems like member attraction, equipment effectiveness, and revenue calculations. The script creates cohesive gameplay effects from specialization decisions.

-   `src/server/Essentials/SystemConfig.server.luau`: Server-side script managing global configuration values for game systems. It provides centralized storage and access for settings, thresholds, and constants used throughout the codebase. The script allows developers to easily adjust game parameters without modifying multiple files.

-   `src/server/Essentials/SystemConnector.server.luau`: Server-side script facilitating communication between otherwise independent systems. It establishes connection points, translates data formats, and routes information between different modules. The script reduces direct dependencies while maintaining necessary information flow.

-   `src/server/Essentials/UnifiedTycoonSystem.server.luau`: Server-side script implementing the consolidated tycoon gameplay mechanics. It brings together plot ownership, construction, revenue, and progression elements into a cohesive system. The script provides the core tycoon gameplay experience that drives the game.

# Related Scripts by Purpose

This section groups scripts that serve similar functions across different directories. These groupings can help identify potential duplicate functionality or opportunities for consolidation.

## UI Systems

### Core UI Framework
- **Centralized UI System**:
  - `src/client/UI/Core/UISystem.luau`: Main entry point for the UI system that initializes components and provides access to core services
  - `src/client/UI/Core/UIRegistry.luau`: Central registry for UI components with versioning and dependency tracking
  - `src/client/UI/Core/UIManager.luau`: Handles UI operations like showing/hiding, animations, and notifications
  - `src/client/UI/UIHub.luau`: Navigation controller that manages transitions between screens
  - `src/shared/UIStyle.luau`: Centralized styling system with theme support
  - `src/shared/ButtonFactory.luau`: Factory for creating consistently styled buttons

### UI Components
- **Rebirth UI**:
  - `src/client/UI/RebirthUIComponent.luau`: Unified rebirth UI component conforming to the new system
  - `src/StarterGui/RebirthUI.client.luau`: Legacy rebirth interface (to be migrated)
  - `src/StarterGui/RebirthUIFixes.luau`: Legacy patches (to be consolidated)
  - `src/StarterGui/RebirthUI_Enhanced.client.luau`: Legacy enhanced version (to be consolidated)
  - `src/StarterGui/RebirthMenuUI.client.luau`: Legacy menu system (to be consolidated)

- **Main Menu Systems**:
  - `src/client/UI/MainMenuUI.client.luau`: Core menu implementation (to be updated)
  - `src/StarterGui/MainMenuUI.client.luau`: Legacy menu interface (to be migrated)

- **Settings Interfaces**:
  - `src/client/UI/SettingsMenuUI.client.luau`: Main settings component (to be updated)
  - `src/StarterGui/SettingsUI.client.luau`: Legacy settings interface (to be migrated)
  - `src/shared/SettingsMenu.luau`: Legacy shared module (to be consolidated)

- **Statistics Displays**:
  - `src/client/UI/StatisticsDisplay.client.luau`: Detailed stats component (to be updated)
  - `src/StarterGui/StatsGui.client.luau`: Legacy stats interface (to be migrated)

## Core Systems

- **Registry Systems** (✅ Completed - April 27, 2025):
  - `src/shared/Registry/RegistryBase.luau`: ✅ Foundational registry with component registration, versioning, and dependency management
  - `src/client/Core/Registry/ClientRegistry.luau`: ✅ Client-specific registry with UI component and input handler management
  - `src/server/Core/Registry/ServerRegistry.luau`: ✅ Server-specific registry with service and system management
  - `src/shared/Registry/SharedRegistry.luau`: ✅ Context-aware registry for cross-context components
  - `src/client/Core/ClientRegistry.client.luau`: Legacy client-side registry (To be migrated)
  - `src/client/Core/ClientRegistryFixer.client.luau`: Legacy client registry repair tools (To be migrated)
  - `src/server/Core/CoreRegistry.server.luau`: Legacy server-side registry (To be migrated)
  - `src/server/Core/CoreRegistryInitializer.server.luau`: Legacy server registry initialization (To be migrated)
  - `src/shared/ClientRegistry.lua`: Legacy shared registry (To be migrated)

- **Data Management** (✅ Completed - April 28, 2025):
  - `src/shared/Data/DataTypes.luau`: ✅ Standardized data type definitions with validation
  - `src/shared/Data/DataConstants.luau`: ✅ Centralized constants and configuration values
  - `src/shared/Data/SetupRemotes.luau`: ✅ Remote object initialization for client-server communication
  - `src/server/Core/Data/DataManager.luau`: ✅ Central data coordination layer with remote handling
  - `src/server/Core/Data/DataPersistence.luau`: ✅ Robust storage with error handling and retry logic
  - `src/server/Core/Data/PlayerDataService.luau`: ✅ Player-focused data operations and session management
  - `src/server/Core/Data/DataMigration.luau`: ✅ Data format migration and version compatibility tools
  - `src/server/Core/Data/TycoonDataService.luau`: ✅ Gym-specific data operations for tycoon mechanics
  - `src/server/Core/Data/DataCache.luau`: ✅ Multi-level caching with LRU eviction for performance
  - `src/server/Core/Data/DataAnalytics.luau`: ✅ Performance monitoring and usage analytics
  - `src/client/Data/ClientDataService.luau`: ✅ Client-side data access with local caching
  - `src/client/UI/Components/PlayerStatsDisplay.luau`: ✅ Example UI component integration with reactive updates
  - `src/server/Core/DataManager.server.luau`: Legacy primary data system (To be migrated)
  - `src/server/Core/DataAccessLayer.server.luau`: Legacy data access abstraction (To be migrated)
  - `src/server/Core/DataBackup.server.luau`: Legacy backup functionality (To be migrated)
  - `src/server/Core/DataSystemInitializer.server.luau`: Legacy data system setup (To be migrated)
  - `src/server/Core/DataThrottler.server.luau`: Legacy data operation rate limiting (To be migrated)
  - `src/server/Data/EnhancedDataStorageSystem.server.luau`: Legacy advanced storage techniques (To be migrated)
  - `src/server/Data/PlayerDataManager.server.luau`: Legacy player-specific data management (To be migrated)
  - `src/server/Data/GymTycoonDataManager.server.luau`: Legacy tycoon-related data (To be migrated)
  - `src/client/DataManagementUI.client.luau`: Legacy data management interface (To be migrated)

- **Event Systems** (🔄 In Progress - Started April 28, 2025):
  - `src/shared/Events/EventTypes.luau`: Definitions of event types and type checking (In Progress)
  - `src/shared/Events/EventBase.luau`: Base event class with common functionality (In Progress)
  - `src/client/Core/Events/ClientEvents.luau`: Client-side events management (Planned)
  - `src/server/Core/Events/ServerEvents.luau`: Server-side events management (Planned)
  - `src/shared/Events/EventBridge.luau`: Unified client-server communication (Planned)
  - `src/client/Core/ClientEvents.client.luau`: Legacy client event system (To be migrated)
  - `src/client/Core/ClientEventBridge.client.luau`: Legacy client-server communication (To be migrated)
  - `src/server/Core/EventBridge.server.luau`: Legacy server event handling (To be migrated)
  - `src/server/Core/EventCreator.server.luau`: Legacy event creation system (To be migrated)
  - `src/server/Essentials/EventBridge.server.luau`: Legacy essential events communication (To be migrated)

## Game Features

- **Rebirth Systems**:
  - `src/client/Core/RebirthClient.client.luau`: Client-side rebirth controller
  - `src/server/Core/RebirthSystem.server.luau`: Server-side rebirth processing
  - `src/server/Enhancements/RebirthSystem.server.luau`: Enhanced rebirth features

- **Tile Purchase Systems**:
  - `src/server/Essentials/BuyTile.server.luau`: Core tile purchasing
  - `src/server/Core/BuyTileSystem.server.luau`: Main tile system
  - `src/server/Core/BuyTileProgressionManager.server.luau`: Tile progression
  - `src/server/Core/BuyTileHelper.lua`: Helper functions for tile purchases
  - `src/server/Connectors/BuyTileConfigGenerator.server.luau`: Tile configuration
  - `src/server/Connectors/BuyTileHitboxGenerator.server.luau`: Tile hitbox setup
  - `src/server/Connectors/AutoBuyTileSetup.server.luau`: Automated tile purchasing

- **Equipment Systems**:
  - `src/server/Core/EquipmentManager.server.luau`: Main equipment management
  - `src/server/Core/EquipmentUpgradeSystem.server.luau`: Equipment upgrades
  - `src/server/Core/EquipmentMaintenanceSystem.server.luau`: Equipment maintenance
  - `src/server/Legacy/EquipmentSetup.server.luau`: Legacy equipment setup
  - `src/server/Legacy/EquipmentUpgradeSystem.server.luau`: Legacy upgrade system
  - `src/server/Model Function/EquipmentSetup.server.luau`: Physical equipment setup
  - `src/client/EquipmentUpgradeUI.client.luau`: Upgrade interface

- **Tycoon Core Systems**:
  - `src/client/Core/TycoonClient.client.luau`: Client-side tycoon controller
  - `src/server/Core/TycoonSystem.server.luau`: Core tycoon implementation
  - `src/server/Essentials/UnifiedTycoonSystem.server.luau`: Consolidated tycoon mechanics
  - `src/server/Connectors/GymTycoonConnector.server.luau`: Tycoon system interface
  - `src/server/Connectors/GymTycoonInit.server.luau`: Tycoon initialization

- **NPC Systems**:
  - `src/server/Core/NPCSystem.server.luau`: Main NPC management
  - `src/server/Core/NPCAnimationSystem.server.luau`: NPC animations
  - `src/server/Core/NPCSystemPerformance.server.luau`: Performance-optimized NPC system
  - `src/server/Core/NPCInteractionTest.server.luau`: NPC interaction testing
  - `src/server/Core/NPC_Movement.server.luau`: NPC movement logic
  - `src/server/Enhancements/UnifiedNPCSystem.server.luau`: Enhanced NPC behavior

- **Specialization Systems**:
  - `src/client/SpecializationClient.client.luau`: Client-side specialization interface
  - `src/server/Core/GymSpecializationSystem.server.luau`: Gym specialization logic
  - `src/server/Core/SpecializationSystem.server.luau`: Core specialization system
  - `src/server/Core/SpecializationNPC.server.luau`: Specialized NPC behavior
  - `src/server/Essentials/SpecializationIntegration.server.luau`: Integration with other systems
  - `src/shared/SpecializationMenu.luau`: Shared specialization interface
  - `src/shared/SpecializationsUI.luau`: Extended specialization interface

- **Satisfaction and Member Systems**:
  - `src/client/ClientCore/SatisfactionClient.client.luau`: Client satisfaction controller
  - `src/server/Core/MemberSatisfactionSystem.server.luau`: Member satisfaction processing
  - `src/server/Core/SatisfactionEventHandler.server.luau`: Satisfaction event management
  - `src/client/UI/MemberSatisfactionUI.client.luau`: Satisfaction interface
  - `src/shared/SatisfactionDisplay.luau`: Shared satisfaction components

- **Competition Systems**:
  - `src/client/ClientCore/CompetitionClient.client.luau`: Client competition controller
  - `src/client/CompetitionClient.client.luau`: Another client competition script
  - `src/client/ClientCore/CompetitionClientLoader.client.luau`: Competition client loader
  - `src/server/Core/CompetitionSystem.server.luau`: Server-side competition logic
  - `src/shared/CompetitionUI.luau`: Shared competition interface

## Utilities and Helpers

- **Module Loading Systems**:
  - `src/shared/ModuleLoader.luau`: Core module loading system
  - `src/shared/ModuleLoaderHelper.luau`: Helper functions for module loading
  - `src/shared/ModuleLoaderExample.luau`: Example implementation
  - `src/server/Core/ModuleLoaderHelper.server.luau`: Server-specific module loading

- **Safety Utilities**:
  - `src/shared/SafeRequire.luau`: Safe module requiring
  - `src/shared/SafeWait.luau`: Enhanced waiting function
  - `src/shared/SafeWaitForChild.luau`: Enhanced child instance finding
  - `src/client/Tools/WaitForChildFinder.client.luau`: Client-side child finding

## Testing and Admin

- **Testing Systems**:
  - `src/server/Core/Tests/RunTests.server.luau`: Test orchestration
  - `src/server/Core/Tests/TestLauncher.server.luau`: Test environment setup
  - `src/server/Core/Tests/IntegrationTests.server.luau`: Integration test suite
  - `src/server/Tests/DataSystemTest.server.luau`: Data system testing

- **Admin Tools**:
  - `src/server/Core/AdminDashboardSystem.server.luau`: Admin dashboard backend
  - `src/client/ClientCore/AdminDashboardClient.client.luau`: Admin dashboard interface
  - `src/client/UI/AdminControlsUI.client.luau`: Admin control panel
  - `src/server/Essentials/AdminCommands.server.luau`: Admin command system