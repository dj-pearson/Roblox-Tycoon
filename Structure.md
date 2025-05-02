# Structure Overview

This document outlines the structure of the Gym Tycoon project, highlighting key files and systems. As part of our ongoing consolidation efforts (see `Documentation/ComprehensiveConsolidationPlan.md`), we're working to reduce duplication and improve code organization across the codebase.

## Refactoring Status

| System | Status | Notes |
|--------|--------|-------|
| UI Systems | 🔄 In Progress | Unified framework implemented with centralized components |
| Data Management | 🔄 In Progress (80%) | Core system implemented with bridge for legacy code. Final migration in progress |
| Registry Systems | 🔄 In Progress (90%) | Unified registry with bridges, migration tools, and telemetry implemented. Final testing in progress |
| Event Systems | 🔄 In Progress (80%) | Core modules implemented, migration utilities created, integration in progress |
| Rebirth Systems | 🔄 In Progress (20%) | Analysis complete, consolidation plan created, implementation planning in progress |
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

- **Registry Systems** (🔄 In Progress - April 27, 2025):
  - `src/shared/Registry/RegistryBase.luau`: ✅ Foundational registry with component registration, versioning, and dependency management
  - `src/client/Core/Registry/ClientRegistry.luau`: ✅ Client-specific registry with UI component and input handler management
  - `src/server/Core/Registry/ServerRegistry.luau`: ✅ Server-specific registry with service and system management
  - `src/shared/Registry/SharedRegistry.luau`: ✅ Context-aware registry for cross-context components
  - `src/client/Core/ClientRegistry.client.luau`: Legacy client-side registry (To be migrated)
  - `src/client/Core/ClientRegistryFixer.client.luau`: Legacy client registry repair tools (To be migrated)
  - `src/server/Core/CoreRegistry.server.luau`: Legacy server-side registry (To be migrated)
  - `src/server/Core/CoreRegistryInitializer.server.luau`: Legacy server registry initialization (To be migrated)
  - `src/shared/ClientRegistry.lua`: Legacy shared registry (To be migrated)

- **Data Management** (🔄 In Progress - April 28, 2025):
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

# Consolidation Progress Summary

## April 2025 Milestones

### April 27, 2025 - Registry System Implementation
We completed the Registry System implementation with a unified approach:
- Created a foundational `RegistryBase` with core registry functionality
- Implemented `ClientRegistry` with UI and input handling capabilities
- Built `ServerRegistry` with service and system management features
- Developed `SharedRegistry` with context-aware component access
- Added comprehensive documentation for implementation details and migration strategy

The Registry System now provides a centralized point for component registration, dependency tracking, and lifecycle management across all game contexts.

### April 28, 2025 - Data Management Client Integration
We completed the client integration for the Data Management System:
- Implemented `ClientDataService` for client-side data access
- Added local caching for improved performance
- Created remote function handlers in `DataManager`
- Established proper client-server data flow with security checks
- Developed sample UI components to demonstrate integration

## Next Steps

### Immediate Focus: Event System Implementation
Our current focus is implementing the Event System:
- Creating standardized event type definitions
- Building a foundational event class for consistent behavior
- Developing client and server event management
- Implementing unified client-server event communication

### Future Plans
After completing the Event System, we will:
1. Begin migration of existing components to the new architecture
2. Implement comprehensive integration testing
3. Move on to UI System refactoring
4. Start planning for the gameplay system refactoring (Rebirth, Tile Purchase, Equipment)

# src/client

-   `src/client/AdminAccessRestrictor.client.lua`: Client-side script that controls access to administrative interfaces based on user permissions. It verifies admin credentials and prevents unauthorized access to admin tools, ensuring security for sensitive game management functions.

-   `src/client/AdminButtonCreator.client.luau`: Client-side script that dynamically generates administrative control buttons for authorized users. It creates context-appropriate UI elements with proper styling and functionality based on the user's permission level.

-   `src/client/AdminCommandsExtension.client.luau`: Client-side script that extends the administrative command system with additional functionality. It provides supplementary commands and interfaces that integrate with the core admin system to enhance management capabilities.

-   `src/client/AdminUIFixes.client.luau`: Utility module containing patches for known issues in the admin UI. It addresses edge cases, visual glitches, and interaction problems in the administrative interface without requiring a complete rewrite.

-   `src/client/AllianceClient.client.luau`: Client-side script managing player alliance and cooperation features. It handles UI for alliance formation, communication, shared resources, and collaborative gameplay elements between gym owners.

-   `src/client/AprilFixesClientStartup.client.luau`: Client-side bootstrap script that applies critical fixes implemented in April 2025. It ensures that client systems receive necessary patches at game startup to maintain stability and feature functionality.

-   `src/client/BasketballClient.client.luau`: Client-side script managing basketball minigame features. It handles player interactions with basketball equipment, scoring, physics, and visual feedback for the recreational basketball feature in gyms.

-   `src/client/ClientBootstrap.client.luau`: Primary client initialization script that sets up the client environment, loads essential modules, and orchestrates the startup sequence. It ensures proper loading order and initialization of all client systems.

-   `src/client/ClientCore/`: Directory containing core client-side systems and modules that form the foundation of the client architecture. These modules handle essential client functionality like input, UI, camera control, and local player state.

-   `src/client/ClientRegistry.luau`: Client-side module that manages registration and retrieval of client components and services. It provides a centralized system for organizing, accessing, and tracking client-side game elements and their dependencies.

-   `src/client/ClientRegistryFixer.client.luau`: Utility script that detects and repairs issues with the client registry. It identifies missing or corrupt registry entries and attempts to restore them to maintain client functionality.

-   `src/client/ClientRegistryPreloader.client.luau`: Client-side script that preloads essential registry components before other systems initialize. It ensures that critical services are available early in the startup process to prevent dependency errors.

-   `src/client/ClientUISystem.client.luau`: Client-side script implementing the core UI system architecture. It provides the framework for UI components, handling element creation, state management, animations, and user interactions.

-   `src/client/CompetitionClient.client.luau`: Client-side script managing the gym competition and challenge features. It displays leaderboards, competitor information, and handles participation in competitive events between gym owners.

-   `src/client/Core/`: Directory containing foundational client systems that are essential to game functionality. These modules implement core mechanics like player controls, camera management, and client-side simulation.

-   `src/client/DarkOverlayFix.client.luau`: Utility script that addresses an issue with dark overlays appearing incorrectly in the UI. It provides a targeted fix for visual glitches in overlay elements without requiring substantial UI system changes.

-   `src/client/Data/`: Directory containing client-side data management modules. These handle local data caching, client-server data synchronization, and data display formatting for client interfaces.

-   `src/client/DataManagementUI.client.luau`: Client-side script providing an interface for data management operations. It allows players (primarily developers and admins) to view and manipulate data structures for testing and debugging purposes.

-   `src/client/EquipmentUpgradeUI.client.luau`: Client-side script implementing the equipment upgrade interface. It displays available upgrades, requirements, benefits, and handles the upgrade purchase process for gym equipment.

-   `src/client/ErrorHandlerClient.client.luau`: Client-side error handling system that catches, logs, and responds to runtime errors. It implements graceful degradation, user feedback, and error reporting to help diagnose and address issues.

-   `src/client/GymTycoonMenuUI.client.luau`: Client-side script for the main tycoon game menu. It provides access to gym management features, specialization choices, staff management, and other tycoon gameplay systems through a unified interface.

-   `src/client/JobClient.client.luau`: Client-side script managing the job system interface. It displays available staff positions, requirements, application processes, and current staff performance for the gym's employment system.

-   `src/client/Main.client.luau`: Primary client entry point that bootstraps the entire client-side game environment. It initializes core systems, controls loading sequence, and establishes communication with server-side components.

-   `src/client/MainMenuUILoader.client.luau`: Client-side script that loads and initializes the main menu interface. It handles the loading of menu assets, populates dynamic content, and ensures menu components are properly connected before display.

-   `src/client/MembershipBoostClient.client.luau`: Client-side script for the membership boost feature. It displays boost options, manages activation of membership promotion features, and communicates with the server to apply boost effects.

-   `src/client/MenuButtonCreator.client.luau`: Utility module that generates standardized menu buttons. It creates consistently styled and properly functioning UI elements for navigation menus throughout the game interface.

-   `src/client/Phase3ClientLoader.client.luau`: Client-side loader for Phase 3 features and content. It initializes new systems and content introduced in the third development phase, ensuring proper integration with existing game elements.

-   `src/client/PlayerActivityTracker.client.luau`: Client-side module that records player activity metrics. It monitors gameplay patterns, feature usage, and time investment to provide analytics data for game optimization.

-   `src/client/ReputationClient.client.luau`: Client-side script managing the gym reputation system interface. It displays current reputation levels, factors affecting reputation, and options for improving the gym's standing in the community.

-   `src/client/SaunaTemperatureClient.client.luau`: Client-side script specifically handling sauna temperature display and controls. It shows current temperature, allows adjustment controls, and displays effects on gym members within sauna areas.

-   `src/client/SeasonalClient.client.luau`: Client-side script managing seasonal event features. It handles UI for time-limited events, special promotions, and seasonal decorations that change throughout the year.

-   `src/client/ShowDoubleMemberUI.client.luau`: Client-side script specifically for the double member promotion interface. It displays the benefits, costs, and provides controls for activating membership promotions that increase gym attendance.

-   `src/client/SoundClient.client.luau`: Client-side sound management system. It handles playback of sound effects, music, ambient audio, and manages volume levels and audio prioritization based on game context.

-   `src/client/SoundSystemFix.client.luau`: Utility script containing patches for the sound system. It addresses issues with audio playback, volume control, and sound synchronization without requiring a complete rewrite of the sound system.

-   `src/client/SpecializationClient.client.luau`: Client-side script for the gym specialization interface. It displays specialization options, benefits, requirements, and handles the selection process for gym focus areas.

-   `src/client/Tests/`: Directory containing client-side test scripts and frameworks. These modules provide automated testing capabilities for client systems to ensure functionality and identify regressions during development.

-   `src/client/TileSound.client.luau`: Client-side script managing audio effects for tile interactions. It plays appropriate sounds when players interact with different types of floor tiles, enhancing the tactile feel of movement through the gym.

-   `src/client/Tools/`: Directory containing utility scripts and helper functions for client-side development. These modules provide commonly used functionality for UI creation, animation, input handling, and other client needs.

-   `src/client/TutorialClient.client.luau`: Client-side script managing the in-game tutorial system. It guides new players through core gameplay mechanics, highlighting features and providing interactive learning experiences.

-   `src/client/UI/`: Directory containing user interface components, screens, and systems. These modules implement the visual elements players interact with, organized according to the UI framework architecture.

-   `src/client/UIAccessRestrictor.client.lua`: Client-side script that restricts access to certain UI elements based on player permissions. It hides or disables features that aren't available to specific players based on their role or progress level.

-   `src/client/UIBootstrapper.client.luau`: Client-side script that initializes the UI system at startup. It loads core UI components, establishes theme settings, and ensures UI services are available to other systems.

-   `src/client/UIComponentLoader.client.luau`: Client-side script that dynamically loads UI components as needed. It implements on-demand loading of UI elements to improve performance and manage memory usage efficiently.

-   `src/client/UILoader.client.luau`: Legacy client-side script for UI initialization. It manages the loading sequence of UI components and ensures they're properly connected to data sources before display.

-   `src/client/UISystem.client.luau`: Core client-side UI system implementation. It provides the architectural foundation for UI creation, management, and interaction throughout the game.

-   `src/client/UISystemDebugger.client.luau`: Development tool for diagnosing issues with the UI system. It provides inspection capabilities, performance metrics, and error tracing specifically for UI components.

-   `src/client/UISystemEnhancer.client.luau`: Client-side script that extends the UI system with additional features. It adds capabilities like advanced animations, special effects, and improved interaction models to the base UI system.

-   `src/client/UISystemPatcher.client.luau`: Utility script that applies targeted fixes to the UI system. It addresses specific issues in UI behavior without requiring changes to the core system architecture.

-   `src/client/UISystemRegistration.client.luau`: Client-side script handling registration of UI components with the UI system. It manages the addition of new UI elements to ensure proper integration with the overall UI framework.

-   `src/client/UISystemTester.client.luau`: Automated testing tool for UI components and behaviors. It runs validation checks on UI elements to verify proper functionality and appearance across different scenarios.

# src/shared

-   `src/shared/AchievementNotification.luau`: Shared module for displaying achievement notifications across client and server contexts. It defines the visual appearance and behavior of popups that appear when players reach milestones or accomplish significant goals.

-   `src/shared/AchievementsMenu.luau`: Shared module implementing the achievements menu interface. It displays completed and in-progress achievements, requirements, rewards, and progress tracking for player accomplishments.

-   `src/shared/AssetValidator.luau`: Utility module that verifies the existence and integrity of game assets. It checks for missing textures, models, or sounds and provides fallback options to prevent errors when assets are unavailable.

-   `src/shared/ButtonFactory.luau`: Factory module for creating standardized buttons across the UI. It ensures consistent styling, behavior, and interaction patterns for buttons throughout different interface components.

-   `src/shared/ClientRegistry.lua`: Shared legacy registry module for tracking and accessing client components. It provides registration and retrieval functions used by both server and client code to reference client-side systems.

-   `src/shared/ClientRegistry.luau`: Updated shared registry module (Luau version) for managing client components. It offers improved type safety and performance compared to the legacy Lua version.

-   `src/shared/CompetitionUI.luau`: Shared module implementing competition interface components. It defines the visual elements used to display competition information, leaderboards, and participation controls that appear in multiple contexts.

-   `src/shared/CoreRegistryAccess.luau`: Utility module providing simplified access to the core registry. It offers helper functions to retrieve and interact with registered components without requiring direct registry manipulation.

-   `src/shared/CoreRegistryDiagnostic.luau`: Diagnostic tool for analyzing and troubleshooting registry issues. It provides functions to validate registry integrity, identify missing dependencies, and generate reports on registry state.

-   `src/shared/Data/`: Directory containing shared data structures, type definitions, and constants used across client and server contexts. These modules establish common data formats for consistent cross-context communication.

-   `src/shared/DataValidator.luau`: Utility module for validating data structures against expected schemas. It ensures that data passed between systems conforms to required formats and contains all necessary fields with appropriate types.

-   `src/shared/DialogFactory.luau`: Factory module for creating standardized dialog boxes. It generates consistently styled confirmation prompts, alerts, and information dialogs used throughout the game interface.

-   `src/shared/ErrorHandlingUtility.luau`: Shared error handling utility providing standardized error recording, formatting, and response functions. It creates a consistent approach to error management across different game systems.

-   `src/shared/EventBridge.luau`: Core communication module that facilitates event-based messaging between different systems. It provides a structured way for game components to publish and subscribe to events without direct dependencies.

-   `src/shared/Events/`: Directory containing event type definitions, base classes, and utility functions for the event system. These modules establish the foundation for event-driven communication throughout the game.

-   `src/shared/GymAutomation.luau`: Shared module defining automation capabilities for gym management. It provides functions for scheduling routine operations, automatic maintenance, and hands-off gym optimization.

-   `src/shared/IconSet.luau`: Resource module containing references to game icons and visual indicators. It centralizes icon management to ensure consistent visual language across different interface components.

-   `src/shared/JobsUI.luau`: Shared module implementing job system interface components. It defines the visual elements used to display job listings, applications, staff management, and performance evaluation features.

-   `src/shared/MenuContainer.luau`: Base interface container for menu components across the game. It provides standard layout, navigation, and animation behaviors used by various menu screens throughout the interface.

-   `src/shared/MilestonesMenu.luau`: Shared module implementing the milestones display interface. It shows progression achievements, upcoming goals, and rewards for reaching significant development points in gym management.

-   `src/shared/ModuleFallbackGenerator.luau`: Utility that creates default implementations when requested modules are missing. It prevents crashes by providing basic functionality substitutes when dependencies cannot be loaded.

-   `src/shared/ModuleLoader.luau`: Core module loading system that handles dependency resolution, caching, and error recovery. It provides a robust way to require modules with additional safety and performance features.

-   `src/shared/ModuleLoaderExample.luau`: Example implementation demonstrating proper use of the module loading system. It serves as a reference for developers implementing new modules that need to use the loader.

-   `src/shared/ModuleLoaderHelper.luau`: Helper functions extending the core module loader functionality. It provides convenience methods for common module loading patterns and specialized loading behaviors.

-   `src/shared/ModuleScriptAccessor.luau`: Utility for accessing module scripts in various contexts. It provides a consistent API for locating and requiring modules regardless of their location in the game hierarchy.

-   `src/shared/ModuleTemplate.luau`: Template file establishing the standard structure for new modules. It demonstrates proper initialization, public interface definition, and internal implementation patterns.

-   `src/shared/Registry/`: Directory containing the registry system implementation. These modules provide the framework for component registration, dependency management, and service discovery across the game.

-   `src/shared/replicatedStorage/`: Directory mirroring content placed in Roblox's ReplicatedStorage. These assets and modules are accessible from both server and client contexts for shared functionality.

-   `src/shared/ReputationUI.luau`: Shared module implementing reputation system interface components. It defines the visual elements used to display gym reputation information and factors affecting community standing.

-   `src/shared/RevenueDisplay.luau`: Shared module implementing the revenue display interface. It visualizes income sources, expenses, and profit trends for the gym's financial management features.

-   `src/shared/SafeRequire.luau`: Utility function that wraps Lua's require with additional error handling. It prevents script failures when modules can't be loaded and provides fallback options for missing dependencies.

-   `src/shared/SafeRequireModule.luau`: Enhanced version of SafeRequire with additional features for module management. It includes dependency tracking, logging, and performance metrics for module loading.

-   `src/shared/SafeWait.luau`: Utility function providing a safer alternative to Roblox's wait function. It includes timeout handling, yielding management, and more consistent behavior across different contexts.

-   `src/shared/SafeWaitForChild.luau`: Utility function enhancing Roblox's WaitForChild with additional safety features. It includes timeout handling, error recovery, and instance validation to prevent common pitfalls.

-   `src/shared/SatisfactionDisplay.luau`: Shared module implementing the member satisfaction interface. It visualizes gym member happiness levels, contributing factors, and suggested improvements for gym management.

-   `src/shared/SaunaTemperatureUI.luau`: Shared module implementing the sauna temperature control interface. It provides temperature visualization, adjustment controls, and effect indicators for sauna facilities.

-   `src/shared/SeasonalEventsUI.luau`: Shared module implementing seasonal event interfaces. It provides visual components for time-limited events, special promotions, and seasonal activities that change throughout the year.

-   `src/shared/SettingsMenu.luau`: Shared module implementing the settings menu interface. It provides controls for adjusting game options, audio levels, graphical settings, and other player preferences.

-   `src/shared/SoundAssetValidator.luau`: Utility module that verifies sound assets before use. It checks for missing audio files and provides fallback sounds to prevent errors when audio resources are unavailable.

-   `src/shared/SoundSystemManager.luau`: Shared module managing sound playback across the game. It provides functions for playing sounds with consistent volume handling, prioritization, and positioning in 3D space.

-   `src/shared/SpecializationMenu.luau`: Shared module implementing the gym specialization selection interface. It displays specialization options, benefits, requirements, and handles the selection process for gym focus areas.

-   `src/shared/SpecializationsUI.luau`: Enhanced version of the specialization interface components. It provides more detailed visualization of specialization effects, comparison tools, and advanced configuration options.

-   `src/shared/StaffManagementUI.luau`: Shared module implementing the staff management interface. It provides components for hiring, firing, assigning, and monitoring staff members who operate gym facilities.

-   `src/shared/SystemDiagnostics.luau`: Utility module providing diagnostic functions for game systems. It includes performance monitoring, status checking, and troubleshooting tools for developers and admin users.

-   `src/shared/TemperatureDisplay.client.luau`: Client-side implementation of the temperature display interface. It visualizes temperature values for various gym facilities and their effects on member comfort.

-   `src/shared/UIComponent.luau`: Base class for UI components in the component system. It defines the standard lifecycle, property handling, and rendering behavior expected of all UI elements.

-   `src/shared/UIComponents.luau`: Collection of reusable UI components for common interface elements. It provides pre-built buttons, panels, sliders, and other controls that maintain consistent styling and behavior.

-   `src/shared/UIModuleTemplate.luau`: Template file establishing the standard structure for new UI modules. It demonstrates proper UI component initialization, lifecycle management, and event handling patterns.

-   `src/shared/UIRegistry.luau`: Registry module specifically for tracking and accessing UI components. It provides functions for registering, retrieving, and managing user interface elements throughout the game.

-   `src/shared/UIStyle.luau`: Style definition module establishing visual consistency across the UI. It defines colors, fonts, spacing, animations, and other visual properties used throughout the interface.

-   `src/shared/UIUtils.luau`: Utility functions for common UI operations. It provides helpers for layout calculations, element positioning, state management, and other frequently needed UI manipulation tasks.

-   `src/shared/UniversalSystemFinder.luau`: Utility for locating system implementations across different contexts. It provides a consistent way to find and access systems regardless of where they're implemented in the game architecture.

-   `src/shared/WaitForChildScanner.luau`: Enhanced instance-finding utility that systematically searches for child objects. It provides more thorough and configurable searching capabilities than standard WaitForChild functions.

# src/server

-   `src/server/AdminDashboardSystem.server.luau`: Server-side implementation of the administration dashboard. It provides backend processing for admin commands, monitoring tools, and management functions accessed through the admin interface.

-   `src/server/AdminUIRestrictorTest.server.luau`: Server-side test script for the admin UI access restriction system. It validates that unauthorized users cannot access admin features and confirms proper functionality of permission controls.

-   `src/server/April29FixesTester.server.luau`: Server-side test script for validating the April 29, 2025 fixes. It runs a series of tests to ensure that the implemented fixes resolve their target issues without introducing new problems.

-   `src/server/AprilFixesController.server.luau`: Server-side script that manages the application of April 2025 fixes. It orchestrates the loading and initialization of fix modules in the proper sequence to ensure compatibility.

-   `src/server/AprilFixesStartup.server.luau`: Server-side bootstrap script that applies critical fixes implemented in April 2025. It ensures that server systems receive necessary patches at game startup to maintain stability.

-   `src/server/AprilFixesTestSuite.server.luau`: Comprehensive test suite for April 2025 fixes. It provides automated validation of all implemented fixes, generating reports on their effectiveness and potential side effects.

-   `src/server/BuildOrderVisualizer.server.luau`: Development tool for visualizing gym construction order. It creates visual indicators showing the sequence in which gym elements should be built, helping to identify optimal progression paths.

-   `src/server/BuyTileFixer.server.luau`: Server-side utility script that repairs issues with the tile purchasing system. It identifies and resolves common problems like incorrect pricing, missing visual feedback, or placement errors.

-   `src/server/BuyTilePositionFixer.server.luau`: Server-side script specifically addressing tile positioning issues. It corrects placement problems, alignment errors, and collision inconsistencies in the tile purchase system.

-   `src/server/BuyTileSystem.server.luau`: Core implementation of the tile purchasing functionality. It handles the full lifecycle of tile purchases, from selection to payment processing to physical instantiation in the world.

-   `src/server/ClientFixDistributor.server.luau`: Server-side script that distributes client-side fixes to players. It identifies which clients need which fixes and ensures the proper fix scripts are sent to each connected player.

-   `src/server/Connectors/`: Directory containing integration modules that connect different systems together. These modules establish communication pathways between otherwise independent game systems to create cohesive gameplay.

-   `src/server/Core/`: Directory containing foundational server systems that are essential to game functionality. These modules implement core server-side mechanics and provide services used by multiple game features.

-   `src/server/CoreRegistryEarlyLoader.server.luau`: Server-side script that loads critical registry components before other systems initialize. It ensures that essential services are available early in the startup process.

-   `src/server/CoreRegistryPreloader.server.luau`: Server-side script that preloads registry components to optimize startup performance. It prepares frequently used components in advance to reduce initialization delays.

-   `src/server/CriticalFixesStartup.server.luau`: High-priority bootstrap script that applies essential fixes at game startup. It focuses on critical issues that could prevent proper game operation if not immediately addressed.

-   `src/server/Data/`: Directory containing server-side data management modules. These handle data persistence, player data management, and server-side data processing for game mechanics.

-   `src/server/DataManagement/`: Directory containing specialized data management modules for specific game systems. These provide tailored data handling for features with unique storage or processing requirements.

-   `src/server/DiagnosticsAndRepair.server.luau`: Server-side utility for diagnosing and repairing game state issues. It identifies common problems and applies automated fixes to restore proper operation without developer intervention.

-   `src/server/Enhancements/`: Directory containing optional modules that enhance base game systems. These add additional features, optimizations, or capabilities to core gameplay without modifying the original implementations.

-   `src/server/EnsureFixScriptsAutorun.server.luau`: Server-side script that validates the automatic execution of fix scripts. It confirms that critical fixes are being properly applied during startup and addresses any loading failures.

-   `src/server/Essentials/`: Directory containing core server-side scripts essential to game operation. These modules implement fundamental game mechanics required for basic functionality.

-   `src/server/Examples/`: Directory containing example implementations of various systems. These serve as reference material and templates for developers creating new features or extending existing ones.

-   `src/server/Fixes/`: Directory containing patch scripts addressing specific issues. These targeted fixes resolve individual problems without requiring changes to core system implementations.

-   `src/server/FixesBootstrap/`: Directory containing scripts that manage the loading and application of fix modules. These orchestrate the fix application process to ensure compatibility and proper sequencing.

-   `src/server/FixesBootstrap.server.luau`: Main server-side script that initializes and manages the fix system. It provides the framework for detecting issues and applying appropriate fixes based on game state.

-   `src/server/FixesManager.server.luau`: Server-side script that coordinates the application of multiple fixes. It handles dependency management, conflict resolution, and execution ordering for fix modules.

-   `src/server/FolderSetup.server.luau`: Server-side utility for establishing the expected folder structure at runtime. It creates and organizes necessary folders to ensure components can locate their expected resources.

-   `src/server/GymAutomation/`: Directory containing modules implementing automated gym management features. These provide capabilities for scheduling routine operations and hands-off optimization of gym facilities.

-   `src/server/GymAutomation.server.luau`: Server-side implementation of the gym automation system. It processes automation rules, executes scheduled tasks, and manages the operation of gym systems without direct player intervention.

-   `src/server/GymAutomationLoader.server.luau`: Server-side script that initializes the gym automation system. It loads automation rules, schedules recurring tasks, and establishes communication with other systems for coordinated automation.

-   `src/server/GymAutomationManager.server.luau`: Server-side manager for the gym automation system. It provides high-level control over automation features, handles failure recovery, and ensures performance optimization.

-   `src/server/Legacy/`: Directory containing older implementations maintained for backward compatibility. These modules use outdated approaches but are preserved to support existing features that haven't been migrated.

-   `src/server/MigrationTest.server.luau`: Server-side test script for validating data and system migrations. It confirms that transitions between old and new implementations maintain data integrity and feature functionality.

-   `src/server/MigrationUtils.server.luau`: Utility functions supporting data and system migrations. It provides tools for transforming data formats, redirecting references, and managing the transition between different implementations.

-   `src/server/Model Function/`: Directory containing scripts that implement functionality for specific 3D models. These modules define how physical objects in the gym behave and interact with players.

-   `src/server/Phase3Loader.server.luau`: Server-side loader for Phase 3 features and content. It initializes new systems and content introduced in the third development phase, ensuring proper integration with existing game elements.

-   `src/server/Regular_Member.luau`: Module defining the behavior and properties of standard gym members. It implements movement patterns, facility preferences, and interaction logic for regular gym patrons.

-   `src/server/SharedFolderSetup.server.luau`: Server-side utility establishing shared resource folders. It creates and organizes folders accessible from both server and client contexts to facilitate cross-context resource sharing.

-   `src/server/SocialFeatures/`: Directory containing modules implementing social interaction features. These handle player communication, collaboration, competition, and other inter-player social mechanics.

-   `src/server/StaffManagementSystem.server.luau`: Server-side implementation of the staff management system. It processes staff hiring, assignment, performance evaluation, and payment mechanics for gym employees.

-   `src/server/SystemBridge.luau`: Server-side bridge module facilitating communication between different game systems. It establishes standardized interfaces for systems to interact without creating direct dependencies.

-   `src/server/Systems/`: Directory containing domain-specific system implementations. These modules provide dedicated functionality for particular gameplay features or mechanics.

-   `src/server/SystemsBootstrap.server.luau`: Server-side script that initializes the game's system architecture. It handles the startup sequence for system modules, ensuring proper dependency resolution and initialization order.

-   `src/server/SystemsSetup/`: Directory containing initialization modules for different game systems. These handle the setup process for specific gameplay mechanics and establish necessary resources.

-   `src/server/Tests/`: Directory containing server-side test scripts and frameworks. These modules provide automated testing capabilities for server systems to ensure functionality and identify regressions.

-   `src/server/TestSuite.server.luau`: Comprehensive server-side test suite controlling the execution of all automated tests. It runs validation checks on server systems, generates reports, and identifies potential issues.

-   `src/server/Tools/`: Directory containing utility scripts and helper functions for server-side development. These modules provide commonly used functionality for system implementation, data management, and server operations.

-   `src/server/TutorialSteps/`: Directory containing script modules for the in-game tutorial system. These implement individual steps in the tutorial sequence, providing guided learning experiences for new players.

-   `src/server/TycoonValidationTool.server.luau`: Server-side utility for validating tycoon game state integrity. It checks for inconsistencies in ownership, revenue, progression, and other tycoon-specific mechanics.

-   `src/server/UIFixesCoordinator.server.luau`: Server-side script coordinating the application of UI fixes. It identifies which UI components need patching and ensures the proper fixes are applied to maintain interface functionality.

-   `src/server/UISystemTester.server.luau`: Server-side component of the UI testing framework. It validates server aspects of UI functionality, particularly for interfaces that rely on server data or processing.

-   `src/server/Utilities/`: Directory containing general-purpose utility functions and helper modules. These provide reusable functionality that supports multiple server systems and operations.

-   `src/server/VIP_Member.luau`: Module defining the behavior and properties of VIP gym members. It implements preferences, perks, and interaction patterns specific to premium gym patrons.

# src/Functionality

-   `src/Functionality/`: Directory containing modules that implement specific gameplay features. These modules provide self-contained functionality that can be enabled or disabled independently of core systems.

# src/ModelScaleRenamer.lua

-   `src/ModelScaleRenamer.lua`: Utility script for renaming model parts based on scale. It automatically generates appropriate names for resized models to maintain consistent naming conventions and improve organization.

# Consolidation Strategy for Overlapping Files

Based on our review of the project structure, we've identified several areas with significant code duplication and overlapping functionality. The following strategy outlines how we plan to address these issues for each major system:

## Rebirth System Consolidation

1. **Current State**: Multiple rebirth UI implementations exist (`RebirthUI.client.luau`, `RebirthUIFixes.luau`, `RebirthUI_Enhanced.client.luau`, `RebirthMenuUI.client.luau`) alongside several server-side handlers.

2. **Consolidation Approach**:
   - Create a unified `RebirthSystem` module in `src/server/Systems/RebirthSystem.server.luau`
   - Implement a single client-side controller in `src/client/UI/RebirthUI.client.luau`
   - Migrate all enhancements from `RebirthUI_Enhanced` into the unified implementation
   - Incorporate all fixes from `RebirthUIFixes` directly into the main codebase
   - Deprecate redundant files after confirming full functionality in the unified system

3. **Migration Timeline**:
   - May 5, 2025: Analysis and planning document creation
   - May 8, 2025: Unified server implementation
   - May 12, 2025: Unified client implementation
   - May 15, 2025: Testing and validation
   - May 18, 2025: Full deployment and removal of redundant files

## UI System Consolidation

1. **Current State**: Multiple UI loading mechanisms exist (`UIBootstrapper`, `UILoader`, `UIComponentLoader`, `MainMenuUILoader`) with overlapping functionality.

2. **Consolidation Approach**:
   - Standardize on the `UIBootstrapper` pattern for all UI initialization
   - Refactor component-specific loaders to use the common bootstrapping mechanism
   - Implement a unified loading sequence with proper dependency management
   - Consolidate UI utility functions (currently scattered across multiple files) into the `UIUtils` module
   - Move specialized UI components from StarterGui to the client/UI directory structure
   
3. **Migration Timeline**:
   - May 6, 2025: Complete audit of UI loading dependencies
   - May 9, 2025: Unified bootstrap implementation
   - May 13, 2025: Component migration to new system
   - May 17, 2025: Testing across different client scenarios
   - May 20, 2025: Full deployment and cleanup

## Equipment System Consolidation

1. **Current State**: Equipment functionality is spread across multiple files with significant duplication (`EquipmentManager`, `EquipmentUpgradeSystem`, `EquipmentMaintenanceSystem`).

2. **Consolidation Approach**:
   - Create a comprehensive `EquipmentSystem` module in `src/server/Systems/EquipmentSystem.server.luau`
   - Implement proper separation of concerns with submodules for specific functionality
   - Establish clear interfaces between equipment and other systems (tycoon, revenue, etc.)
   - Unify client interfaces for equipment interaction
   - Standardize equipment data structures and validation
   
3. **Migration Timeline**:
   - May 25, 2025: Analysis and architecture document
   - May 29, 2025: Core equipment system implementation
   - June 3, 2025: Specialized subsystem implementations
   - June 6, 2025: Client interface migration
   - June 10, 2025: Testing and validation
   - June 15, 2025: Full deployment and cleanup

## Tile Purchase System Consolidation

1. **Current State**: Tile purchasing exists in multiple overlapping implementations with various fixes and enhancements added over time.

2. **Consolidation Approach**:
   - Create a unified `TileSystem` module in `src/server/Systems/TileSystem.server.luau`
   - Incorporate all existing fixes into the main implementation
   - Standardize the tile data structure and validation
   - Implement a clear interface for tile configuration and placement
   - Consolidate client-side tile visualization and interaction
   
3. **Migration Timeline**:
   - May 26, 2025: Analysis and architecture document
   - May 30, 2025: Core tile system implementation
   - June 4, 2025: Configuration and progression subsystems
   - June 7, 2025: Client interface migration
   - June 11, 2025: Testing with various tile configurations
   - June 16, 2025: Full deployment and cleanup

## Overall Consolidation Process

Each system consolidation will follow this general process:

1. **Analysis**: Document current implementations, identifying core functionality and enhancements
2. **Architecture**: Design unified system architecture with clear component boundaries
3. **Implementation**: Develop consolidated modules with comprehensive functionality
4. **Migration**: Move dependent systems to use the new consolidated interfaces
5. **Testing**: Verify functionality across all use cases and scenarios
6. **Deployment**: Gradually replace old systems with consolidated implementations
7. **Cleanup**: Remove redundant files and update documentation

This process will be applied systematically across all identified areas of duplication to reduce codebase complexity, improve maintainability, and eliminate potential sources of bugs from inconsistent implementations.