# Project Requirements Document (PRD)

This document serves as the central repository for all project information, guiding the development and evolution of the game. It includes completed features, remaining tasks, new feature ideas, and ongoing refinements.

## 1. Completed Features

-   **Core Gameplay Loop:**
    -   Players can join the game, navigate the environment, and interact with basic objects.
    -   Implemented a basic resource gathering and expenditure system.
-   **Gym Tycoon Core Mechanics:**
    -   Players can purchase gym equipment, expand their gym space, and attract members.
    -   Basic revenue and member satisfaction systems are in place.
-   **NPC System:**
    -   NPC members can populate the gym and interact with equipment.
    -   Implemented basic AI for NPC member behavior.
-   **UI Foundations:**
    -   Implemented a basic main menu and in-game HUD.
    -   Core UI elements for managing gym and member info.
-   **Data Persistence:**
    -   Player data (gym progress, resources, etc.) is saved and loaded between sessions.
-   **Basic Progression:**
    - Players can gain levels, unlock new items, and expand the gym.
- **Seasonal Events System:**
    - A core seasonal event system is implemented, allowing the addition of events.
- **Specialization system**
    - Core systems for specializations are implemented.
- [x] Refine Specialization System
- **Alliance System**
    - Base functionality for Alliances are implemented.
- **Rebirth System**

   - Players can rebirth their progress.

   - **Refine Specialization System**
    - **Description:** Ensure the specialization system is fine tuned and implemented in every
    - **Priority:** High
    - **Notes:** Ensure this system works in tandem with the NPC system.
-   **Tutorial System:**
    -   **Description:** Develop a tutorial system to guide new players through the game's
    -   **Priority:** Medium
    -   **Notes:** Should be interactive and adaptable to different player progression.
- **Refine Alliance System**
    - **Description:** Improve and refine the base functionality of Alliances, add events, and
    - **Priority:** High
    - **Notes:** Alliances need more functionality to be impactful.
- [ ] 
- **Refine Rebirth System**
    - **Description:** Ensure Rebirth System properly rewards players .
    - **Priority:** High
    - **Notes:** Ensure balancing is appropriate to keep players engaged.

## 2. Remaining Tasks/Features

-   **Multiplayer Features:**
    -   **Description:** Implement features like visiting other player's gyms or competing in events.
    -   **Priority:** Medium
    -   **Notes:** Requires server-side enhancements for handling multiple players.

## 3. New Feature Ideas

-   **Custom Gym Layouts:**
    -   **Description:** Allow players to customize the layout and design of their gyms with
    -   **Benefits:** Increased player creativity and engagement.
-   **Staff Management System:**
    -   **Description:** Introduce a system where players can hire, train, and manage staff
    -   **Benefits:** Adds depth to gameplay and resource management.
-   **Equipment Upgrades and Customization:**
    -   **Description:** Allow players to upgrade and customize their gym equipment for
    -   **Benefits:** Provides more progression paths and customization options.
-   **Mini-Games and Competitions:**
    -   **Description:** Introduce mini-games or events where players can compete for rewards.
    -   **Benefits:** Adds variety and competitive elements to the gameplay.
- **Player vs Player (PVP) modes**
    - **Description:** Allow players to compete against each other.
    - **Benefits:** Adds competitive gameplay.
- **Community Goals**
    - **Description:** Allow the community to work together to complete shared goals.
    - **Benefits:** Adds community engagement and team based play.
- **Guest Pass System**
    - **Description:** Allow players to issue temporary guest passes to others.
    - **Benefits:** Adds a team building element.
- **Staff Training System**
    - **Description:** Allow players to train staff to increase their effectiveness.
    - **Benefits:** Adds more depth to the Staff Management feature.
- **Alliance challenges**
    - **Description:** Introduce challenges for Alliances to complete, rewarding players.
    - **Benefits:** Team goals and playability.
- **Trading System**
    - **Description:** Allow players to trade resources, items, or other assets with each other.
    - **Benefits:** Add more player interactions.
- **Research & Development System:**
    - **Description:** Introduce a system where players can invest in research to unlock new equipment tiers, unique staff skills, marketing strategies, or even permanent gym-wide passive bonuses.
    - **Benefits:** Adds a long-term strategic goal beyond just earning money and expanding space. Provides a sink for excess resources and a clear progression path.
    - **Implementation Notes:** Could include research trees or categories (e.g., Equipment Tech, Marketing, Staff Training, Member Comfort).

- **Marketing and Branding:**
    - **Description:** Allow players to invest in marketing campaigns (local flyers, online ads, celebrity endorsements) to attract more members or specific member archetypes. Introduce a "Gym Brand" or "Reputation" score influenced by marketing, cleanliness, satisfaction, and events.
    - **Benefits:** Provides more control over growth and target audience, adds a new resource expenditure avenue, and makes reputation a more tangible game mechanic.
    - **Implementation Notes:** Marketing options should affect NPC spawn rates and types.
- **Staff Specializations & Skill Trees:**
    - **Description:** Build on the Staff Management System by giving staff members unique roles (Trainer, Manager, Janitor, Receptionist) and skill trees they can progress through via the Staff Training System.
    - **Benefits:** Adds significant depth to the Staff Management feature, allows for min-maxing and strategic staff placement, and provides another layer of progression.
    - **Implementation Notes:** Staff skills could impact revenue, member satisfaction, cleanliness, and security.
- **Dynamic Goal/Quest System:**
    - **Description:** Expand the MilestoneSystem into a more dynamic quest or mission system that generates personalized goals for players based on their current progress, specialization, available equipment, or ongoing events.
    - **Benefits:** Provides players with clear, short-term objectives, encourages exploration of different game mechanics, and makes progression feel more personalized and engaging.
    - **Implementation Notes:** Goals could include "Train X Bodybuilder NPCs," "Earn Y revenue from Cardio equipment," or "Achieve Z member satisfaction for 10 minutes."


## 1. Completed Features

## ... (previous completed features)

-   **Advanced NPC AI:**
    -   **Description:** Improved NPC AI for dynamic and responsive behavior.
    -   **Details:**
        -   Implemented PathfindingService for better NPC movement.
        -   Added wander behavior for NPCs at their destination.
        -   Created a system for NPCs to identify and interact with interactive elements.
        -   Created attributes for models: IsInteractive, InteractionType, and CurrentUsers.
        -   Created a script to add those attributes to all models: `src/server/Core/AttributeSetup.server.luau`.

        - **Member Archetypes & Needs:**
    - **Description:** Expand on the basic member system by introducing different types of members (e.g., Bodybuilders, Cardio Enthusiasts, Seniors, Students, VIPs) with specific equipment preferences, patience levels, spending habits, and satisfaction drivers.
    - **Benefits:** Makes the simulation deeper, rewards players for creating diverse gym layouts catering to different needs, and allows for tailored marketing campaigns.
    - **Implementation Notes:** Integrate with NPC System, GymRevenueSystem, and MemberSatisfactionSystem.

    - **Difficulty Settings / "Chill" Mode:**
    - **Description:** Offer players different difficulty settings at the start or allow them to switch between a standard challenge mode and a more relaxed "Chill" or "Creative" mode.
    - **Benefits:** Caters to a wider audience with different playstyle preferences, from those seeking a challenge to those who just want to build and customize.
    - **Implementation Notes:** Parameters to modify could include starting money, member satisfaction decay, and failure conditions.

## ... (previous completed features)

-   **Dynamic Economy:**
    -   **Description:** Initial implementation of the Dynamic Economy system.
        Resource types defined. Supply and demand tracking. Price adjustment logic.
        Functions to interact with the dynamic economy system (UpdateSupply, UpdateDemand,
        GetResourceData). File: `src/server/Core/DynamicEconomy.server.luau`.
## 4. Security Revisions

-   **Data Security:**
    -   **Vulnerability:** Potential for data breaches or unauthorized access to player data.
    -   **Mitigation:**
        -   Encrypt all sensitive data both in transit and at rest.
        -   Implement strict access controls and logging.
        -   Regularly audit and update security measures.
-   **User Authentication:**
    -   **Vulnerability:** Weak or compromised player accounts.
    -   **Mitigation:**
        -   Enforce strong password policies.
        -   Consider multi-factor authentication.
        -   Monitor for suspicious login activity.
-   **Anti-Cheat Measures:**
    -   **Vulnerability:** Players using cheats or exploits to gain an unfair advantage.
    -   **Mitigation:**
        -   Implement server-side validation for all critical actions.
        -   Use anti-cheat software to detect and prevent cheating.
        -   Regularly update and improve anti-cheat systems.
-   **Preventing Exploits:**
    -   **Vulnerability:** Exploits in game mechanics or code vulnerabilities.
    -   **Mitigation:**
        -   Conduct regular code reviews and security audits.
        -   Patch any discovered vulnerabilities promptly.
        -   Monitor for and respond to exploit reports from players.

## 5. Performance Refinements

-   **Lag:**
    -   **Issue:** High latency or lag spikes during gameplay.
    -   **Approach:**
        -   Optimize network code to reduce latency.
        -   Implement client-side prediction for smoother movement.
        -   Reduce the frequency of server updates where possible.
-   **Loading Times:**
    -   **Issue:** Slow loading times when entering the game or new areas.
    -   **Approach:**
        -   Optimize asset loading to reduce file sizes and load times.
        -   Implement asynchronous loading to load assets in the background.
        -   Use data compression techniques to reduce transfer times.
-   **Memory Usage:**
    -   **Issue:** High memory usage leading to crashes or performance issues.
    -   **Approach:**
        -   Optimize memory management to release unused resources.
        -   Reduce the size of game assets.
        -   Implement dynamic asset loading/unloading.
-   **Device Optimization:**
    -   **Issue:** Poor performance on low-end devices.
    -   **Approach:**
        -   Implement graphics settings to adjust quality.
        -   Optimize code for efficiency and reduced resource usage.
        -   Consider lower detail models for less powerful devices.
-   **Spatial Partitioning for Dynamic Elements:**
    -   **Issue:** Performance bottlenecks with many NPCs and interactive objects.
    -   **Approach:**
        -   Implement spatial data structures (like a grid or quadtree) on the server.
        -   Allow faster querying of objects within a certain radius, crucial for NPC AI pathfinding.
        -   Integrate with NPC System and Unified Interaction System.
-   **Aggressive Client-Side Rendering Optimizations:**
    -   **Issue:** Poor client-side performance on various devices.
    -   **Approach:**
        -   Implement manual or automated render distance management for less important visual details.
        -   Add level-of-detail (LOD) for models.
        -   Implement culling objects based on visibility frustum.
        -   Focus on supporting a wider range of device capabilities.

## 6. General Code Cleanup

-   **Code Formatting:**
    -   **Area:** Inconsistent code formatting throughout the project.
    -   **Strategy:**
        -   Adopt a consistent code style guide.
        -   Use code formatting tools to enforce style automatically.
-   **Reducing Duplication:**
    -   **Area:** Redundant code blocks performing similar functions.
    -   **Strategy:**
        -   Identify and refactor duplicated code into reusable functions.
        -   Create shared utility libraries for common tasks.
-   **Naming Conventions:**
    -   **Area:** Inconsistent or unclear variable and function names.
    -   **Strategy:**
        -   Establish clear naming conventions.
        -   Refactor existing code to use the new conventions.
-   **Removing Dead Code:**
    -   **Area:** Unused or obsolete code segments.
    -   **Strategy:**
        -   Use static analysis tools to identify dead code.
        -   Remove dead code to improve clarity and reduce clutter.

## 7. Code Consolidation

-   **Redundant Functions:**
    -   **Component:** Similar functions in different modules (e.g., resource management, UI updates).
    -   **Consolidation:** Consolidate these functions into shared utility modules.
    -   **Benefits:** Reduced codebase size, easier maintenance, fewer bugs.
-   **Shared Libraries:**
    -   **Component:** Common code elements for the game's core mechanics.
    -   **Consolidation:** Create shared libraries for common systems.
    -   **Benefits:** Improved code reuse, easier updates, and better consistency.
-   **UI Element Creation:**
    - **Component:** Creating new UI elements.
    - **Consolidation:** Create templates and base objects for UI creation.
    - **Benefits:** Faster UI creation and maintainability.
-   **Unified Interactive Object System:**
    - **Component:** Standardize the interface and logic for any object in the game that a player or NPC can interact with (equipment, front desk, vending machines, mini-game stations, staff).
    - **Consolidation:** Build on the attributes already introduced (IsInteractive, InteractionType, CurrentUsers) to create a unified system.
    - **Benefits:** Reduces code duplication across different interactive items, makes it easier to add new interactive objects, improves maintainability.
-   **Centralized Game Data Configuration:**
    - **Component:** All configurable game data (equipment stats, prices, upgrade paths, staff costs/stats, event parameters).
    - **Consolidation:** Leverage the ConfigurationGenerator and DataManager to load and manage all game data through a single, robust system.
    - **Benefits:** Easier balancing and tuning, faster iteration on game parameters, reduced risk of inconsistencies, and cleaner code.

## 8. Other

-   **Documentation:**
    -   **Note:** Ensure all new features and code changes are properly documented.
- **Review Systems**
-    **Note:** Make sure all systems are constantly reviewed, updated, and properly tested.
- **Testing Framework**
-    **Note:** Add proper testing framework and write tests for all implemented systems.

## Remaining Steps for Advanced NPC AI

- Modify `NPC_Movement.server.luau`: Implement the changes to the functions `isInteractiveElement` and `interactWithElement` as well as how they are used in other functions in the code.
- Add Functional Scripts: Add functional scripts to the models that need them.
- Update and Create models: make sure all models have the right attributes.
- Test: Make sure all elements work as intended.
- **Testing Framework**
    - **Note:** Add proper testing framework and write tests for all implemented systems.

## Refine Alliance System
- [ ] 
- **Description:** Improve and refine the base functionality of Alliances, add events, and
    -   **Priority:** High
    -   **Notes:** Alliances need more functionality to be impactful.

    - [x] **Alliance Progression/Leveling:**
        -   **Concept:** Alliances can gain experience points (XP) by completing activities or participating in events.
        -   **Benefits:** As alliances level up, they could unlock:
            -   Larger member capacity.
            -   Unique alliance cosmetic items (e.g., custom banners, titles).
            -   Passive bonuses (e.g., increased gym revenue for all members, reduced equipment costs).
            - Access to new special events.
        -   **Implementation Notes:**
            -   Add an `xp` attribute to the alliance data.
            -   Create a system for awarding XP (e.g., daily quests, participating in competitions).
            -   Define level-up thresholds and rewards.

    -   [x] **Alliance Roles:**
        -   **Concept:** Introduce different roles within alliances (e.g., Leader, Officer, Member).
        -   **Benefits:**
            -   Officers can help manage the alliance (e.g., invite/kick members, manage events).
            -   Creates a sense of hierarchy and responsibility.
        -   **Implementation Notes:**
            -   Add a `roles` field to the alliance data (e.g., a table of `userId` to `role`).
            -   Modify existing functions (e.g., `InvitePlayer`, `DisbandAlliance`) to respect roles.
            -   Add a new function to change the role of a player.

    -   [x] **Alliance Bank/Shared Resources:**
        -   **Concept:** Alliances can have a shared bank where members can contribute resources (e.g., in-game currency, special items).
        -   **Benefits:**
            -   Allows alliances to pool resources for shared goals (e.g., purchasing a special item, starting an event).
        -   **Implementation Notes:**
            -   Add a `bank` attribute to the alliance data (e.g., a table of resource type to amount).
            -   Create functions to deposit and withdraw resources.

    -   [ ] **Alliance Competitions/Challenges:**
        -   **Concept:** Introduce alliance-versus-alliance or alliance-versus-environment challenges.
        -   **Examples:**
            -   **Gym Revenue Race:** Alliances compete to earn the most gym revenue in a given time.
            -   **Member Satisfaction Challenge:** Alliances try to maximize the overall satisfaction of their members.
            -   **Cooperative Goals:** Alliances work together to achieve a common goal (e.g., collectively train X number of NPCs).
        -   **Benefits:**
            -   Encourages competition and cooperation.
            -   Provides a sense of accomplishment.
        -   **Implementation Notes:**
            -   Integrate with existing game systems (e.g., `CompetitionSystem`, `RevenueSystem`).
            -   Define the rules and rewards for each event type.

    -   [ ] **Alliance Communication:**
        -   **Concept:** A way to communicate with all the members of the alliance.
        -   **Benefits:**
            -   Allows the alliance to strategize.
            -   Makes it easier to organize events.
        -   **Implementation Notes:**
            -   Use of existing in game chat system.
            -   Create a specific channel for the alliance.