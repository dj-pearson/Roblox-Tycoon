# UI Module Design Document

## Overview

This document outlines the design for the UI Module, which will serve as the primary interface for players to interact with the game. It details the necessary components, their functionality, design principles, and how they connect to the backend systems.

## Design Principles

*   **Clarity:** The UI should be clear and easy to understand, minimizing the cognitive load on the player.
*   **Consistency:** Design elements and interactive behaviors should be consistent across the entire UI.
*   **Responsiveness:** The UI should react dynamically to user actions, providing feedback and clear indications of state changes.
*   **Accessibility:** The UI should be accessible to all users, including those with visual impairments.
*   **Visual Appeal:** The UI should be visually engaging, enhancing the player's immersion in the game world.
*   **Branding:** The UI will follow a modern, clean, and professional aesthetic, using a color scheme of blues, grays, and white.
* **Animation:** Use simple but effective animations where needed to help provide context to actions.
* **Visual Indicators:** Provide context where needed, add visual indicators to help improve overall player experience.

## UI Components

### 1. Menus

#### 1.1 Main Menu
*   **Style:** `UIStyle.applyStyle()`

*   **Layout:** A central hub that provides access to all major game features.
    *   Top: Game logo and player profile (level, name, resources).
    *   Center: Primary buttons (Play, Alliance, Specialization, Seasonal Events, Settings).
    *   Bottom: Social links or announcements.
*   **Primary Buttons:**
    *   **Play:** Starts the main gameplay. Connects to `GameSystem.startGame()`.
    *   **Alliance:** Opens the alliance menu.
    *   **Specialization:** Opens the specialization menu.
    *   **Seasonal Events:** Opens the seasonal events menu.
    *   **Settings:** Opens the settings menu.
*   **Design Direction:** Clean, minimalist design with clear visual hierarchy. Prominent buttons with subtle animations on hover.
*   **User Journey:** The Main Menu is the first screen users will see. It should facilitate quick entry into the game or other features.

#### 1.2 Settings Menu
*   **Style:** `UIStyle.applyStyle()`

*   **Layout:** A clear, vertically scrolling list of settings.
    *   **Sound:** Volume sliders for music, sound effects.
    *   **Graphics:** Quality presets (low, medium, high) or individual options (resolution, shadows).
    *   **Controls:** Keybindings, mouse sensitivity.
    *   **Accessibility:** Colorblind modes, text size.
    *   **Language:** Language selection dropdown.
*   **Design Direction:** Functional and organized, utilizing sliders, dropdowns, and checkboxes.
*   **User Journey:** Accessed from the Main Menu or in-game overlay. Provides users with control over their game experience.

### 2. Buttons

#### 1.3 Rebirth Menu
*   **Style:** `UIStyle.applyStyle()`

    *   **Layout:**
        *   **Rebirth Count:** Display the player's current rebirth count. Connects to `RebirthSystem.getRebirthInfo()`. Display the information using a simple numerical text.
        *   **Rebirth Cost:** Show the cost for the next rebirth. Connects to `RebirthSystem.getRebirthInfo()`. Display the information using a numerical text with a dollar icon.
        *   **Rebirth Multiplier:** Display the current revenue multiplier. Connects to `RebirthSystem.getRebirthInfo()`. Display the information using a numerical text with a multiplier icon.
        *   **Rebirth Progress:** Show the progress towards the next rebirth. Connects to `RebirthSystem.getRebirthInfo()`. Display the information using a progress bar with numerical completion.
        *   **Unlocked Features:** Show the unlocked features. Connects to `RebirthSystem.getRebirthInfo()`. Display each feature with the name, description, and icon.
        *   **Active Perks:** Show the active perks. Connects to `RebirthSystem.getRebirthInfo()`. Display each perk with the name, description, and icon.
        *   **Achievements:** Show the achieved achievements and the requirements of the unachieved ones. Connects to `RebirthSystem.getRebirthInfo()`. Display each achievement with the name, description, icon, and if it is achieved or not. If it is not achieved, show the requirements.
        *   **Total Rebirths:** Show the total number of rebirths the player has performed. Connects to `RebirthSystem.getRebirthInfo()`. Display the information using a numerical text.
        *   **Fastest Rebirth Time:** Show the fastest time the player has performed a rebirth. Connects to `RebirthSystem.getRebirthInfo()`. Display the information using a numerical text.
        *   **Current Rebirth Time:** Show the time the player has been in the current rebirth. Connects to `RebirthSystem.getRebirthInfo()`. Display the information using a numerical text.
        *   **Rebirth Button:** A button to perform the rebirth. Connects to `RebirthSystem.performRebirth()`. If the player can not perform the rebirth, the button will be disabled and the reason will be shown in a tooltip.
         * **Features toggle:** A toggle to change between showing the features by the level they are unlocked and the order they were unlocked.
    *   **Design Direction:** Clean, well-organized design that clearly separates the different categories of information.
    *   **User Journey:** Accessed from the Main Menu. Provides the player all information about the Rebirth System.

### 2. Buttons
#### 2.5 Rebirth Button
    *   **Functionality:** Initiates the rebirth process. Checks if the player has enough cash to rebirth. If yes, triggers `RebirthSystem.performRebirth()`. If not, displays a tooltip with the reason why the player cannot rebirth.
    *   **Backend Connection:** `RebirthSystem.performRebirth()`.
    *   **Suggested Placement:** Rebirth Menu.
    *   **Design:** Prominent, with a clear indication of the required cost. Should be disabled if the player cannot rebirth, displaying a tooltip with the reason why.



#### 2.1 Alliance Buttons

*   **Join Alliance Button**
    *   **Functionality:** Initiates the process of joining an alliance. If the player isn't in one, the button opens the Alliance menu. If they are already in one, it will show the alliance information.
    *   **Backend Connection:** `AllianceSystem.joinAlliance()`.
    *   **Suggested Placement:** Main Menu, social tab.
    *   **Design:** Prominent, using a unique icon to indicate alliances. The button should animate upon hover.
*   **Leave Alliance Button**
    *   **Functionality:** Prompts confirmation before leaving the current alliance.
    *   **Backend Connection:** `AllianceSystem.leaveAlliance()`.
    *   **Suggested Placement:** Alliance info panel, within the Alliance menu.
    *   **Design:** Clear, but slightly less prominent than the "Join" button. Confirmation pop-up with 'Yes' or 'No' should be present.
*   **View Alliance Info Button**
    * **Functionality:** Opens a menu with the details of the current alliance the player is in.
    * **Backend Connection:** `AllianceSystem.getAllianceInfo()`.
    * **Suggested Placement:** Main Menu, social tab.
    * **Design:** Simple but noticeable.

#### 2.2 Seasonal Event Buttons

*   **Seasonal Event Participation Button**
    *   **Functionality:** Allows the player to join or leave a seasonal event. The button will display current status (joined or not) and animate when the event is active.
    *   **Backend Connection:** `SeasonalSystem.joinEvent()`, `SeasonalSystem.leaveEvent()`.
    *   **Suggested Placement:** Main Menu, events tab.
    *   **Design:** Themed to the current seasonal event. The button should change based on if the player is participating or not.

#### 2.3 Specialization Buttons

*   **Specialization Selection Buttons**
    *   **Functionality:** Allows players to choose a specialization. Should open to a confirmation menu when a button is pressed.
    *   **Backend Connection:** `SpecializationSystem.selectSpecialization(specializationId)`.
    *   **Suggested Placement:** Specialization Menu.
    *   **Design:** Each button should have a distinct color and icon, clearly representing the specialization.

#### 2.4 General Buttons

* **Reset Button:**
  * **Functionality:** Allows player to reset their game and start over. Confirmation box should appear before reset occurs.
  * **Backend Connection:** `GameSystem.reset()`.
  * **Placement:** Settings Menu.
  * **Design:** Clear and distinguishable.
*   **Confirm Button:**
    *   **Functionality:** Confirms actions like purchase, specialization selection, etc.
    *   **Backend Connection:** Varies.
    *   **Suggested Placement:** Various menus and pop-ups.
    *   **Design:** Standard button style, using green or a positive color to represent acceptance.
*   **Cancel Button:**
    *   **Functionality:** Cancels actions, closes menus.
    *   **Backend Connection:** None (UI only).
    *   **Suggested Placement:** Various menus and pop-ups.
    *   **Design:** Standard button style, using red or a negative color to represent a cancellation.
* **Tutorial Button:**
  * **Functionality:** Opens the tutorial menu and steps through how to play the game.
  * **Backend Connection:** `TutorialSystem.showTutorial()`.
  * **Placement:** Settings Menu or Main Menu.
  * **Design:** Clear and Distinguishable.
* **Close Button:**
  * **Functionality:** Closes the current menu or pop up.
  * **Backend Connection:** None (UI only).
  * **Placement:** Various Menus and pop ups.
  * **Design:** simple and noticeable.

### 3. Input Fields

*   **Alliance Search Field:**
    *   **Functionality:** Allows players to search for alliances by name.
    *   **Backend Connection:** `AllianceSystem.searchAlliance(searchQuery)`.
    *   **Suggested Placement:** Alliance Menu.
    *   **Design:** Standard text input field with a search icon.
* **Admin Command Input:**
  * **Functionality:** Allows admins to enter commands to affect the game.
  * **Backend Connection:** `AdminSystem.executeCommand(command)`.
  * **Placement:** Admin Dashboard.
  * **Design:** Standard text input field with ability to run commands.

### 4. Interactive Elements

*   **Resource Display:**
    *   **Functionality:** Shows the player's current resources.
    *   **Backend Connection:** Reads data from `PlayerDataManager.getResources()`.
    *   **Suggested Placement:** Top-left corner of the In-Game Overlay.
    *   **Design:** Clean, numerical display with icons representing each resource.
*   **Mini-Map:**
    *   **Functionality:** Shows a small overview of the game world.
    *   **Backend Connection:** Reads data from `GameWorld.getMapData()`.
    *   **Suggested Placement:** Top-right corner of the In-Game Overlay.
    *   **Design:** Simple 2D representation of the game world.
*   **Notification System:**
    * **Functionality:** Shows the player important information that should grab their attention.
    * **Backend Connection:** Reads information from `NotificationSystem.getNotifications()`.
    * **Placement:** Right side of the game window.
    * **Design:** Noticeable.
*   **Progress Bars:**
    *   **Functionality:** Displays the progress towards a goal (e.g., level up, event completion).
    *   **Backend Connection:** Reads data from various backend systems.
    *   **Suggested Placement:** Underneath the relevant goal/task.
    *   **Design:** Simple bar with numerical completion.
*   **Tooltips:**
    *   **Functionality:** Provides additional information about UI elements on hover.
    *   **Backend Connection:** None (UI only).
    *   **Suggested Placement:** All interactive elements.
    *   **Design:** Simple text boxes with clear explanations.
* **Admin Dashboard:**
  * **Functionality:** UI for admins to perform actions and see information about the game.
  * **Backend Connection:** `AdminSystem.*`
  * **Placement:** Only accessable to admins.
  * **Design:** Clean and simple.
*   **Pop-up Windows:**
    *   **Functionality:** Used for notifications, confirmations, and additional information.
    *   **Backend Connection:** Varies.
    *   **Suggested Placement:** Center of the screen.
    *   **Design:** Clear title, relevant text, and a confirm/cancel button.
*   **In-Game Overlay**
    *   **Resource Display:** Shows current money, XP, and other relevant data.
        *   **Backend Connection:** Connect to `PlayerDataManager.getResources()`.
        *   **Placement:** Top left corner.
        *   **Design:** Numerical display with icons.
    *   **Player Level Display:** Current level of player, may include current experience progress.
        *   **Backend Connection:** Connect to `PlayerDataManager.getLevel()`.
        *   **Placement:** Top Middle.
        *   **Design:** Visually noticable.
    *   **Mini-Map:** Overview of the level.
        *   **Backend Connection:** Connect to `GameWorld.getMapData()`.
        *   **Placement:** Top Right.
        *   **Design:** Simple.
    *   **Quest Log** Current quests or objectives.
        * **Backend Connection:** Connect to `QuestSystem.getQuests()`.
        * **Placement:** Right side.
        * **Design:** Visually organized.
    * **Quick Access Menu:** Menu that will allow for easy access to common actions.
        * **Backend Connection:** Various backend systems.
        * **Placement:** Bottom of the screen.
        * **Design:** Customizable by user.
* **Confirmation Boxes:**
  * **Functionality:** A prompt that will appear to confirm if the user really want to commit to an action.
  * **Backend Connection:** Varies.
  * **Placement:** Center of the screen.
  * **Design:** Simple Yes/No style.

## Backend Connections Summary

*   `AllianceSystem.joinAlliance()`: Join Alliance Button.
*   `AllianceSystem.leaveAlliance()`: Leave Alliance Button.
*   `AllianceSystem.searchAlliance(searchQuery)`: Alliance Search Field.
* `AllianceSystem.getAllianceInfo()`: View Alliance Info Button.
*   `SeasonalSystem.joinEvent()`: Seasonal Event Participation Button.
*   `SeasonalSystem.leaveEvent()`: Seasonal Event Participation Button.
*   `SpecializationSystem.selectSpecialization(specializationId)`: Specialization Selection Buttons.
*   `PlayerDataManager.getResources()`: Resource Display.
*   `GameWorld.getMapData()`: Mini-Map.
* `NotificationSystem.getNotifications()`: Notification System.
* `GameSystem.reset()`: Reset Button.
* `TutorialSystem.showTutorial()`: Tutorial Button.
* `PlayerDataManager.getLevel()`: Player Level Display.
* `QuestSystem.getQuests()`: Quest Log.
* `AdminSystem.executeCommand(command)`: Admin Command Input.
* `AdminSystem.*`: Admin Dashboard.
* `GameSystem.startGame()`: Play Button.
* `RebirthSystem.getRebirthInfo()`: Rebirth Menu.
* `RebirthSystem.performRebirth()`: Rebirth Button, Rebirth Menu.
## Conclusion

This document serves as a guide for the UI development team. It covers the essential UI components, their interactions, and the necessary backend connections. By adhering to these guidelines and the stated design principles, the team can create a cohesive, intuitive, and visually appealing user interface that enhances the overall player experience.