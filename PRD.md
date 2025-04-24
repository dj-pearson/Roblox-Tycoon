# Gym Tycoon Task Tracker

## Current Focus & Upcoming Tasks

### High Priority Tasks

- **Refine Alliance System**
  - [x] Alliance Progression/Leveling
  - [x] Alliance Roles
  - [x] Alliance Bank/Shared Resources
  - [ ] Alliance Competitions/Challenges
  - [ ] Alliance Communication
  - **Notes:** Alliances need more functionality to be impactful.

- **Refine Specialization System**
  - **Description:** Ensure the specialization system is fine-tuned and implemented in every aspect
  - **Notes:** Ensure this system works in tandem with the NPC system.

- **Refine Rebirth System**
  - **Description:** Ensure Rebirth System properly rewards players
  - **Notes:** Ensure balancing is appropriate to keep players engaged.

- **Advanced NPC AI (In Progress)**
  - [ ] Modify `NPC_Movement.server.luau`: Implement changes to the functions `isInteractiveElement` and `interactWithElement`
  - [ ] Add Functional Scripts to interactive models
  - [ ] Update and Create models: ensure all models have the right attributes
  - [ ] Test: Verify all elements work as intended

### Medium Priority Tasks

- **Tutorial System**
  - **Description:** Develop a tutorial system to guide new players through the game
  - **Notes:** Should be interactive and adaptable to different player progression.

- **Multiplayer Features**
  - **Description:** Implement features like visiting other player's gyms or competing in events
  - **Notes:** Requires server-side enhancements for handling multiple players.

### Data Persistence Implementation Plan

1. **Phase 1: Analysis and Documentation**
   - [ ] Document current data flows and dependencies
   - [ ] Identify all systems that interact with data persistence
   - [ ] Map out ideal data architecture

   #### System Analysis
   
   **DataManager:**
     - Loads Data:
     - Saves Data:
     - Dependencies:
   #### System Analysis
   - **DataManager:**
     - Loads Data:
     - Saves Data:
     - Dependencies:
   - **TycoonSystem:**
     - Loads Data:
     - Saves Data:
     - Dependencies:
   - **NPCSystem:**
     - Loads Data:
     - Saves Data:
     - Dependencies:
   - **RevenueSystem:**
     - Loads Data:
     - Saves Data:
     - Dependencies:

    **DataManager Analysis:**

    **1. Data Loading:**

    *   **Main Data:**
        *   The `DataManager` primarily loads player data from the DataStore using `DataStoreService`.
        *   It attempts to load from multiple versions of the data (versioned keys) using the `getLatestVersionKey` and `loadVersionedData` functions, checking for data corruption along the way.
        *   It falls back to a base key if versioned data is unavailable.
        *   It handles session locks, preventing multiple servers from editing the same player's data simultaneously.
        *   It uses the `migrateDataIfNeeded` function to update a players data if it is an old version, ensuring the system can handle changes to the data format.
        * If the data is encrypted, it uses the players key to decrypt the data.
    *   **Additional Data (Secondary DataStores):**
        *   The `loadAdditionalData` function loads data from separate DataStores for specific categories:
            *   `equipment`: Equipment data.
            *   `milestones`: Milestone data.
            *   `specialty`: Specialization data.
            *   `memberships`: Membership data.
            *   `vips`: VIP data.
            *   `revenue`: Revenue data.
            *   `staff`: Staff data.
            *   `achievements`: Achievements data.
            *   `seasonal`: Seasonal data.
        * It will decrypt any of the secondary data if the player has an encryption key.
    *   **Default Data:**
        *   If no data is found in the DataStore, or if there is a migration, it uses the `getDefaultData` function to create a default data table for a new player.

    **2. Data Saving:**

    *   **Main Data:**
        *   The `saveData` function is responsible for saving player data.
        *   It uses the `getNewVersionKey` function to create a new versioned key for each save.
        *   It utilizes `DataThrottler` (if available) to manage DataStore requests and prevent exceeding API limits, ensuring saves are done in an orderly way.
        *   If `DataThrottler` is not available, it falls back to using `UpdateAsync` directly with the DataStore.
        *   It includes retry logic to handle DataStore failures.
        *   It can perform immediate saves (e.g., when a player leaves) or delayed saves (for regular auto-saves).
        * It will encrypt the players data if they have an encryption key.
        * It updates the players session lock before saving.
    *   **Additional Data (Secondary DataStores):**
        *   The `saveAdditionalData` function saves data to the separate DataStores (equipment, milestones, etc.).
        *   It also uses `DataThrottler` (if available) to queue these saves with a low priority.
        *   If `DataThrottler` is not available, it uses `UpdateAsync` directly.
    * **Backup data**
        * The `backupPlayerData` function is responsible for saving the players full data to the backup data store.
        * The `backupAllPlayerData` function will call the above for all players.

    **3. Dependencies:**

    *   **DataStoreService:** Used for interacting with DataStores.
    *   **HttpService:** Used for JSON encoding/decoding and encryption/decryption.
    *   **Players:** Used for accessing player objects and detecting player join/leave events.
    *   **RunService:** Used to check if the game is running in Studio mode.
    *   **ReplicatedStorage:** Used to locate the shared ModuleLoader.
    *   **ModuleLoader (Optional):** Used for loading other modules (preferred method).
    *   **CoreRegistry:** Used to register the `DataManager` as a system and to access other systems like `EventBridge` and `BuyTileSystem`.
    *   **EventBridge (Optional):** Used to fire server events, such as "PlayerDataReady".
    *   **DataThrottler (Optional):** Used to queue and manage DataStore requests.
    * **BuyTileSystem:** Used to restore players equipment when they rejoin the game.
    * **GymTycoonConnector:** Used as a fallback for when the BuyTileSystem is not available.

    **4. Data Structure:**

    *   The `getDefaultData` function defines the structure of the data stored for each player. This structure includes:
         *   `cash`: Player's in-game currency.
         *   `lastJoin`: Timestamp of the player's last join.
         *   `gymTier`: Player's gym tier.
         *   `equipmentCount`: Number of equipment pieces.
         *   `milestones`: Player's milestones.
         *   `specialization`: Player's specialization.
         *   `equipment`: Array of tileIds for purchased equipment.
         *   `achievements`: Player's achievements.

     - **MilestoneSystem:**
        -   Loads Data:
        -   Saves Data:
        -   Dependencies:
     - **AchievementSystem:**
        -   Loads Data:
        -   Saves Data:
        -   Dependencies:
     - **SpecializationSystem:**
        -   Loads Data:
        -   Saves Data:
        -   Dependencies:
     - **AllianceSystem:**
        -   Loads Data:
        -   Saves Data:
        -   Dependencies:
     - **RebirthSystem:**
        -   Loads Data:
        -   Saves Data:
        -   Dependencies:
     - **LeaderstatsSystem:**
        -   Loads Data:
        -   Saves Data:
        -   Dependencies:
     - **QuestSystem:**
        -   Loads Data:
        -   Saves Data:
        -   Dependencies:
          * `members`: information about the players members.
             * `regular`: The number of regular members.
             * `vip`: The number of vip members.
             * `premium`: The number of premium members.
             * `total`: The total number of members.
         * `revenue`: information about the players revenue.
             * `daily`: Today's revenue.
             * `weekly`: This weeks revenue.
             * `total`: Total revenue.
             * `history`: A history of the players daily revenue.
         * `staff`: The staff the player has.
             * `trainers`: The players trainers.
             * `cleaners`: The players cleaners.
             * `receptionists`: The players receptionists.
         * `gym`: Information about the players gym.
             * `satisfaction`: The current gym satisfaction.
             * `cleanliness`: The current gym cleanliness.
             * `reputation`: The current gym reputation.
         * `competitions`: Information about the players competitions.
             * `participated`: Total number of competitions they participated in.
             * `won`: Total number of competitions they won.
             * `lastParticipation`: The last time they participated in a competition.
         * `rebirth`: Information about the players rebirths.
             * `level`: The players current rebirth level.
             * `points`: The number of rebirth points they have.
         * `seasonal`: Information about the current season.
             * `eventParticipation`: Events they have participated in.
             * `rewards`: Rewards they have earned.
         * `settings`: The players settings.
             * `musicVolume`: The players music volume.
             * `sfxVolume`: The players sound effects volume.
             * `notifications`: If the player has notifications turned on.
        *   `sessionLock`: Timestamp for session lock.
        *   `lastSave`: Timestamp of the last save.
        * `dataVersion`: The data version.
        * `encryptionKey`: The players encryption key.
        * `encryptedData`: The players encrypted data.



















2. **Phase 2: System Consolidation**
   - [ ] Select primary data system (Core DataManager)
   - [ ] Update dependency injection in CoreRegistry
   - [ ] Create wrapper functions for legacy code compatibility

3. **Phase 3: Standardization**
   - [ ] Implement standardized data access layer
   - [ ] Update all systems to use this layer
   - [ ] Add comprehensive logging and error handling

4. **Phase 4: Optimization and Validation**
   - [ ] Implement tiered save strategy
   - [ ] Add data validation framework
   - [ ] Create conflict resolution mechanisms

5. **Phase 5: Testing and Verification**
   - [ ] Test data persistence across all game scenarios
   - [ ] Verify recovery from common failure modes
   - [ ] Document final system architecture





## Feature Ideas (Ready for Implementation)

- **Research & Development System**
  - **Description:** Players can invest in research to unlock new equipment tiers, skills, and bonuses
  - **Implementation Notes:** Could include research trees (Equipment Tech, Marketing, Staff Training, Member Comfort)

- **Marketing and Branding**
  - **Description:** Players invest in marketing campaigns to attract specific member types
  - **Implementation Notes:** Marketing options should affect NPC spawn rates and types

- **Staff Specializations & Skill Trees**
  - **Description:** Give staff members unique roles and progression paths
  - **Implementation Notes:** Staff skills impact revenue, satisfaction, cleanliness, and security

- **Dynamic Goal/Quest System**
  - **Description:** Generate personalized goals and quests based on player progress and specialization.

## Recently Completed Features
- **Dynamic Goal/Quest System (Base Implementation)**
    - Implemented a system to generate goals and quests for players, and added a core module.

- **Advanced NPC AI (Initial Implementation)**
  - Implemented PathfindingService for better NPC movement
  - Added wander behavior for NPCs at their destination
  - Created a system for NPCs to identify and interact with interactive elements
  - Created attributes for models: IsInteractive, InteractionType, and CurrentUsers
  - Created a script to add attributes: `src/server/Core/AttributeSetup.server.luau`

- **Member Archetypes & Needs**
  - Expanded member system with different types (Bodybuilders, Cardio Enthusiasts, etc.)
  - Each type has specific equipment preferences and satisfaction drivers

- **Difficulty Settings / "Chill" Mode**
  - Added different difficulty options for various player preferences

- **Dynamic Economy**
  - Implemented resource types, supply and demand tracking, and price adjustment logic
  - Added functions to interact with the economy (UpdateSupply, UpdateDemand, GetResourceData)

- **Alliance System (Base Implementation)**
  - Base functionality for Alliances are implemented

- **Rebirth System**
  - Players can rebirth their progress

- **Specialization System (Core Implementation)**
  - Core systems for specializations are implemented

## Core Game Features (Previously Completed)

- **Core Gameplay Loop:** Resource gathering and expenditure system
- **Gym Tycoon Mechanics:** Purchase equipment, expand gym space, attract members
- **NPC System:** NPC members can populate the gym and interact with equipment
- **UI Foundations:** Main menu, in-game HUD, and core UI elements
- **Data Persistence:** Player data saved between sessions
- **Basic Progression:** Levels, item unlocks, and gym expansion
- **Seasonal Events System:** Core system for adding events

## Technical Focus Areas

### Security Revisions
- Encrypting sensitive data
- Implementing strict access controls
- Enhancing anti-cheat measures

### Performance Refinements
- Optimizing network code for reduced latency
- Improving loading times
- Managing memory usage better
- Optimizing for low-end devices
- Implementing spatial partitioning for NPCs

### Code Cleanup & Consolidation
- Standardizing code formatting
- Reducing code duplication
- Improving naming conventions
- Removing dead code
- Creating shared libraries and templates
- Building a unified interactive object system

### Testing
- Add proper testing framework
- Write tests for all implemented systems
