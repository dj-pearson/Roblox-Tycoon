# Roblox Explorer - Full Folder Structure (Updated April 18, 2025)

Includes all top-level services and main contents within each one.

---

## Workspace

- Camera
- Terrain
- GuiFolder (Used for shared values like basketball scorekeeping)
- Start
- SpawnLocation
- Tycoons (Player gym instances)

## Players

## Lighting

## MaterialService

- Custom Materials for the game

## NetworkClient

## ReplicatedFirst

## ReplicatedStorage

- UIModules
  - AchievementNotification
  - AchievementsMenu
  - CompetitionUI
  - JobsUI
  - MilestonesMenu
  - RevenueDisplay
  - SatisfactionDisplay (UI module for member satisfaction)
  - SaunaTemperatureUI
  - SeasonalEventsUI
  - SettingsMenu
  - SpecializationMenu
  - SpecializationsUI
  - StaffManagementUI
  - TemperatureDisplay
  - UIComponent
  - UIModuleTemplate
  - UIStyle

## ServerScriptService

- Connectors
  - GymTycoonConnector (Bridge between new architecture and legacy code)
  - GymTycoonInit
  - SystemManager
- Core
  - AchievementSystem
  - AdminDashboardSystem (Dashboard for administrator controls)
  - BasketballSystem (Manages basketball courts and gameplay)
  - BuyTileSystem (Handles equipment purchasing)
  - CompetitionSystem
  - ConfigManager (Centralized configuration management)
  - CoreRegistry (Central dependency management)
  - DataManager (Unified data storage system)
  - EventBridge (Event management)
  - GymSpecializationSystem
  - GymTycoonConnector
  - InitializeCore
  - JobSystem (Staff hiring and management)
  - LegacyBridge (Compatibility layer for old scripts)
  - MemoryStoreManager (Temporary data storage with caching)
  - MemberSatisfactionSystem (Member satisfaction and retention system)
  - MilestoneSystem (Player achievements)
  - NPCSystem (NPC management)
  - PerformanceManager (Server performance management)
  - PerformanceOptimizationFramework (Coordinates all performance systems)
  - PerformanceProfiler (Performance monitoring and metrics)
  - RevenueSystem (Gym income and members)
  - SatisfactionEventHandler (Handles member satisfaction events)
  - SaunaSystem (Sauna temperature and effects)
  - SeasonalSystem (Seasonal events)
  - ServerRunner.server
  - SpecializationSystem (Gym specializations)
  - SystemBootstrap (System initialization)
  - TaskScheduler (Distributes processing load across frames)
  - TestingFramework
  - Tests
    - DataManagerTests
    - EventBridgeTests
    - RunTests
    - TestLauncher
  - TycoonSystem (Tycoon management)
- Data
  - DataSystemIntegration
  - EnhancedDataStorageSystem
  - GymTycoonDataManager
  - PlayerDataManager
- Enhancements
  - DailyRewardsSystem
  - EventSystem
  - GymVisits
  - JobSystem
  - RebirthSystem
  - StaffManagementSystem
  - UnifiedNPCSystem
- Essentials
  - Accrued Dues
  - AdminCommands
  - BuyTile
  - EventBridge
  - FrontDeskPrompt
  - GymMilestonesSystem
  - GymRevenueSystem
  - GymSpecializationSystem
  - Leaderstats
  - PlayerActivityReceiver
  - PlayerCharacterCheck
  - PlayerProgressRestoration
  - PlayerSanctionSystem
  - SpecializationIntegration
  - SystemConfig
  - SystemConnector
  - UnifiedTycoonSystem
- Fixes
  - Cleanup
  - ErrorSuppressor
  - FrontDeskFix
  - ResetButtonHandler
  - Sauna_Steam_Error
  - StartupTileVerification
- Model Function
  - Basketball
  - PoolSwimmingSystem
  - SaunaTemperatureSystem
  - SteamSauna

## ServerStorage

- BuyTiles (Equipment templates)
- CommandScripts (Admin commands)
- Elliptical_Upgrade
- GymParts (Physical gym components)
  - 2nd Floor
    - Basketball
  - 3rd Floor
    - Massage and Wellness
  - Roof
    - Track Area
- GymTemplate (Base tycoon template)
- NPC_Character (NPC models)
- ScriptBoneyard (Unused scripts)
- SurfaceGui (UI components)
- Treadmill_Upgrade
- Unused GUI
- Unused Models
- UnusedScripts

## StarterGui

- CleanGymController
- DirectResetButton
- RebirthUI
- ResetButton
- SatisfactionButton (Button to open satisfaction panel)
- StatsGui
- TemperatureDisplay (Sauna temperature UI)

## StarterPack

## StarterPlayer

- StarterCharacterScripts
- StarterPlayerScripts
  - BasketballClient (Client-side basketball system)
  - ClientBootstrap (Client initialization system)
  - CompetitionClient
  - JobClient (Staff management client)
  - PlayerActivityTracker
  - SaunaTemperatureClient
  - SeasonalClient (Seasonal events client)
  - SpecializationClient (Gym specialization client)
  - TileSound
  - ClientCore
    - AdminDashboardClient (Admin interface client)
    - AchievementClient
    - AchievementClientLoader.client
    - ClientPerformanceManager (Client-side performance optimization)
    - CompetitionClient
    - CompetitionClientLoader.client
    - RevenueClient (Client-side revenue management)
    - RevenueClientLoader.client
    - SatisfactionClient (Client-side satisfaction controller)
    - SaunaClient
  - Core
    - ClientBootstrap.client (Client initialization)
    - ClientEventBridge (Client-side event system)
    - ClientRegistry (Client dependency system)
    - NotificationSystem
    - RebirthClient
    - TycoonClient
    - UIHub (Centralized UI management system)
    - UIManager (UI management system)

## Teams

## SoundService

## TextChatService

## Unused

- CelebrityTrainerSystem
- CompetitionSystem
- CompetitionUI
- DataClear
- DataStorageSystem
- DynamicEconomyBalancer
- EquipmentUpgrades
- GymMembershipDisplay
- NPC_Movement
- NPCSpawner
- NPCSystemIntegration
- RevenueDisplay
- RevenueDisplayGui
- SeasonalSpecializationSystem
