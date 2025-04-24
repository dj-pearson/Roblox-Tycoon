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
  - **Description:** Generate personalized goals based on player progress and specialization
  - **Implementation Notes:** Goals like "Train X Bodybuilder NPCs" or "Achieve Z member satisfaction for 10 minutes"

## Recently Completed Features

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
