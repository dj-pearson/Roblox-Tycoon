# UI Module Design Document

## Overview
This document outlines the design for the UI Module, which will serve as the primary interface for players to interact with the game. It details the necessary components, their functionality, design principles, and how they connect to the backend systems.

## Design Principles

*   **Clarity:** The UI should be clear and easy to understand, minimizing the cognitive load on the player.
*   **Consistency:** Design elements and interactive behaviors should be consistent across the entire UI.
*   **Responsiveness:** The UI should react dynamically to user actions, providing feedback and clear indications of state changes.
* **Accessibility:** The UI should be accessible to all users, including those with visual impairments.
* **Visual Appeal:** The UI should be visually engaging, enhancing the player's immersion in the game world.
* **Branding:** The UI will follow a modern, clean, and professional aesthetic, using a color scheme of blues, grays, and white.
* **Animation:** Use simple but effective animations where needed to help provide context to actions.
* **Visual Indicators:** Provide context where needed, add visual indicators to help improve overall player experience.

## UI Components

### 0. Standard UI Elements

For consistency across all UI components, the following patterns should be used:

#### 0.1 Common Style Module
* All UI elements will use the `UIStyle.applyStyle()` function to maintain consistent appearance.
* The `UIStyle` module contains the following key properties:
  * **Colors:** Primary branding colors, background colors, text colors, button colors.
  * **Fonts:** Standard fonts for different text types (headers, body, buttons).
  * **Animations:** Standard animation settings for consistent UI interactions.
  * **Icons:** Access to standard icon assets via AssetIDs.

#### 0.2 Standard Close Button
* **Appearance:** 
  * "X" symbol with `UIStyle.Colors.Danger` background.
  * Corner radius of UDim.new(0.5, 0) for circular appearance.
  * Position in top right corner (typically UDim2.new(1, -10, 0, 10)).
* **Behavior:**
  * On click: Hide parent UI container.
  * Optional fade-out animation via TweenService.
* **Implementation:**
```lua
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -10, 0, 10)
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.Text = "X"
closeButton.ZIndex = 12
closeButton.Parent = parentFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0.5, 0)
closeCorner.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
    parentFrame.Visible = false
end)
```

#### 0.3 Outside Click Detection
* For modal dialogs, clicking outside the dialog should close it.
* Implementation using an invisible background frame with lower ZIndex.
* Closes parent menu when clicked.

#### 0.4 Container Templates
* **Menu Container:**
  * Background with UICorner (CornerRadius = UDim.new(0, 10))
  * Title bar with text and close button
  * Content area
  * Standard size and position relative to screen
* **Tab System:**
  * Tab buttons at top
  * Content container below
  * Only one tab visible at once
* **Scrolling Container:**
  * ScrollingFrame with proper padding
  * UIListLayout for organized content
  * Dynamic canvas size adjustment

#### 0.5 Icon Integration
* Use standardized icon asset IDs for consistency:
  * Alliance: 128203268160479
  * Community Goals: 97149848004338
  * Challenges: 120333480860384
  * Guest Pass: 110319251186892
  * Tutorial: 98150393120956
  * Settings: 72876573893033
  * Rebirth: 129409029383961
  * Staff Management: 89834599810886
  * Upgrades: 132635366103906
  * Achievements: 79337595530955
  * Admin Functions: 105112405426846

### 1. Menus

#### 1.1 Main Menu
*   **Style:** `UIStyle.applyStyle()`

*   **Layout:** A central hub that provides access to all major game features.
    *   Top: Game logo and player profile (level, name, resources).
    *   Center: Primary buttons (Play, Alliance, Specialization, Seasonal Events, Settings).
    *   Bottom: Social links or announcements.
    * Center: Minigames Button.
*   **Primary Buttons:**
    *   **Play:** Starts the main gameplay. Connects to `GameSystem.startGame()`.
    * **Alliance:** Opens the alliance menu.
    *   **Specialization:** Opens the specialization menu.
    *   **Seasonal Events:** Opens the seasonal events menu.
    *   **Settings:** Opens the settings menu.
    *   **Minigames**: Opens the Minigames Menu. Use `UIStyle.applyStyle()`.
*   **Design Direction:** Clean, minimalist design with clear visual hierarchy. Prominent buttons with subtle animations on hover.
*   **User Journey:** The Main Menu is the first screen users will see. It should facilitate quick entry into the game or other features.

#### 1.2 Settings Menu

        * Created the file `MainMenuUI.client.luau`.
        * Created the layout (Top, Center, Bottom sections).
        * Created all the buttons using `ButtonFactory`.
        * Connected the button click events. Each button prints a message in the output, except for the play button, that triggers the `GameSystem.startGame()` function.

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
#### 1.4 Minigames Menu
*   **Layout:**
    *   A list of available mini-games. Use `MiniGameSystem.GetAvailableGames` to get the available minigames.
    *   Each mini-game will have a button to start it. Use `UIStyle.applyStyle()`.
    *   Each mini-game will have a description.
    *   Each minigame will have a image or video.
    *   A back button to return to the Main Menu.
* **Design Direction:**
    *   Clean and well-organized.
    *   Each mini-game should have a clear button with its name.
    * The description of the minigame should be clear and detailed.
*   **User Journey:**
    *   Accessed from the Main Menu.
    *   Provides a list of available mini-games and allows the player to select one to start.
*   **Backend Connection:**
    *   `MiniGameSystem.GetAvailableGames`


#### 1.3 Rebirth Menu
*   **Style:** `UIStyle.applyStyle()`

* **Layout:**
* **Rebirth Count:** Display the player's current rebirth count. Connects to `RebirthSystem.getRebirthInfo()`. Display the information using a simple numerical text.
* **Rebirth Cost:** Show the cost for the next rebirth. Connects to `RebirthSystem.getRebirthInfo()`. Display the information using a numerical text with a dollar icon.
* **Rebirth Multiplier:** Display the current revenue multiplier. Connects to `RebirthSystem.getRebirthInfo()`. Display the information using a numerical text with a multiplier icon.
* **Rebirth Progress:** Show the progress towards the next rebirth. Connects to `RebirthSystem.getRebirthInfo()`. Display the information using a progress bar with numerical completion.
* **Unlocked Features:** Show the unlocked features. Connects to `RebirthSystem.getRebirthInfo()`. Display each feature with the name, description, and icon.
* **Active Perks:** Show the active perks. Connects to `RebirthSystem.getRebirthInfo()`. Display each perk with the name, description, and icon.
* **Achievements:** Show the achieved achievements and the requirements of the unachieved ones. Connects to `RebirthSystem.getRebirthInfo()`. Display each achievement with the name, description, icon, and if it is achieved or not. If it is not achieved, show the requirements.
* **Total Rebirths:** Show the total number of rebirths the player has performed. Connects to `RebirthSystem.getRebirthInfo()`. Display the information using a numerical text.
* **Fastest Rebirth Time:** Show the fastest time the player has performed a rebirth. Connects to `RebirthSystem.getRebirthInfo()`. Display the information using a numerical text.
* **Current Rebirth Time:** Show the time the player has been in the current rebirth. Connects to `RebirthSystem.getRebirthInfo()`. Display the information using a numerical text.
* **Rebirth Button:** A button to perform the rebirth. Connects to `RebirthSystem.performRebirth()`. If the player can not perform the rebirth, the button will be disabled and the reason will be shown in a tooltip.
* **Features toggle:** A toggle to change between showing the features by the level they are unlocked and the order they were unlocked.
* **Design Direction:** Clean, well-organized design that clearly separates the different categories of information.
* **User Journey:** Accessed from the Main Menu. Provides the player all information about the Rebirth System.

### 2. Buttons
#### 2.5 Rebirth Button
* **Functionality:** Initiates the rebirth process. Checks if the player has enough cash to rebirth. If yes, triggers `RebirthSystem.performRebirth()`. If not, displays a tooltip with the reason why the player cannot rebirth.
* **Backend Connection:** `RebirthSystem.performRebirth()`.
* **Suggested Placement:** Rebirth Menu.
* **Design:** Prominent, with a clear indication of the required cost. Should be disabled if the player cannot rebirth, and display a tooltip with the reason why.




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


## UI Module To-Do List

## Implemented

### Settings Menu
    *   **File Creation:** Created the `SettingsUI.client.luau` file to handle the Settings Menu UI logic.
    *   **Layout:** Implemented the Main Frame and the Scrolling frame to allow scrolling.
    *   **Sections:** Created all the sections (`Sound`, `Graphics`, `Controls`, `Accessibility`, `Language`) with their respective labels.
    *   **Sound:** Created the `Music Volume` and `Sound Effects Volume` sliders, and implemented their functionality to update their labels.
    *   **Graphics:** Created the `Quality Presets` dropdown, and the `Shadows` checkbox.
    *   **Controls:** Created the `Mouse Sensitivity` slider, and implemented it's functionality to update it's label.
    *   **Accessibility:** Created the `Colorblind Mode` checkbox.
    *   **Language:** Created the `Language` dropdown.
    * **Connection with Main Menu**: Connected the `Settings` button in the main menu to load this ui.
    * **Close Button**: Added a close button.

### Rebirth Button

    *   **File Creation:** Created the `RebirthMenuUI.client.luau` file to handle the Rebirth Menu UI logic.
    *   **Layout:** Implemented the Main Frame, the Rebirth Button and the Rebirth Cost label.
    *   **Functionality:** Created a function to update the Rebirth Button state.
    *   **Eligibility Check:** The `updateRebirthButtonState` function checks if the player has enough cash to rebirth.
    *   **Tooltip:** Implemented a tooltip if the player cannot rebirth.
    *   **Button State:** The Rebirth button is disabled if the player cannot rebirth, and it's enabled if the player has enough cash.
    *   **Backend Connection:** Connected the button to `RebirthSystem.performRebirth()` to perform the rebirth.
    *   **UI Update:** The UI is updated if the player's cash changes.
    * **Connection with Main Menu**: Connected the `Rebirth Menu` button in the main menu to load this ui.
    * **Close Button**: Added a close button.

### Close Button
    *   **File Creation:** Created the `CloseButtonFactory.lua` file to handle the Close Button creation.
    *   **Functionality:** The `createCloseButton` function creates the close button and adds the functionality of closing the ui.
    *   **Implementation:** Added the close button to the Settings Menu UI and the Rebirth Menu UI.

## To-Do

### Main Menu

*   **Improve Layout:** Evaluate the current layout and make improvements as needed.
*   **Add more buttons:** Add any missing button.

### Tutorial System

*   **UI Design:** Create the UI elements for the tutorial system (e.g., pop-ups, overlays, tooltips).
*   **Functionality:** Implement the logic to guide the user through the game.
*   **Backend Connection:** Connect the UI to `TutorialSystem.showTutorial()`.
*   **Placement:** Determine the best place to start the tutorial (Settings Menu or Main Menu).
*   **Design:** Ensure the tutorial UI is clear and distinguishable.

### Admin Dashboard UI

*   **Players Tab:** Fully implement player management features (e.g., kick, ban, mute, teleport, view player details).
*   **Game Settings Tab:** Implement functionality to change game settings (e.g., modify multipliers, enable/disable features).
*   **Server Stats Tab:** Display relevant server statistics (e.g., player count, uptime, resource usage).
*   **Commands Tab:** Add more commands for various actions.
* **UI Improvements:** Improve the overall UI based on our UI modules.

### Rebirth Menu UI

*   **Tabbed Interface:** Implement the tabbed interface (`Main`, `Features`, `Perks`, `Achievements`).
*   **Rebirth Statistics:** Display rebirth statistics (count, cost, multiplier, progress).
*   **Unlockable Content:** Implement the system to display unlockable content.
*   **Card Displays:** Create card displays for features, perks, and achievements.
*   **Animations:** Add animations and transitions.
*   **Backend Connection:** Add more connections to the `RebirthSystem`.





## Implementation Progress (Updated April 24, 2025)

### Completed Components

1. **Core UI Modules**:
   * ✅ **UIStyle.luau** - Centralized styling module with consistent colors, fonts, animations, and helper functions
   * ✅ **IconSet.luau** - Complete icon management system with standardized asset IDs and utility functions
   * ✅ **ButtonFactory.luau** - Button creation system with consistent styling and behavior
   * ✅ **DialogFactory.luau** - Standardized dialogs, notifications, and modal windows

2. **Icon Integration**:
   * ✅ Implemented standard icon asset IDs for all UI elements
   * ✅ Created helper functions for adding icons to UI elements
   * ✅ Added the Admin Functions icon (ID: 105112405426846)

3. **Admin Dashboard UI**:
   * ✅ Created base UI framework with tabs (Players, Game Settings, Server Stats, Commands)
   * ✅ Implemented command execution system
   * ✅ Added player management functionality
   * ✅ Updated to use the new UI modules (UIStyle, IconSet, ButtonFactory, DialogFactory)
   * ✅ Added confirmation dialogs for critical actions (kick, ban, shutdown)
   * ✅ Improved visual consistency with other UI elements

4. **Rebirth Menu UI**:
   * ✅ Created tabbed interface for rebirth information (Main, Features, Perks, Achievements)
   * ✅ Implemented rebirth statistics display (count, cost, multiplier, progress)
   * ✅ Added unlockable content display system
   * ✅ Built feature, perk, and achievement card displays
   * ✅ Added animation and transition effects
   * ✅ Implemented connections to RebirthSystem backend

5. **Minigames Menu UI**:
   * ✅ Created minigame selection interface with list and details panels
   * ✅ Implemented minigame card display with images, difficulty levels, and rewards
   * ✅ Added detailed minigame information display
   * ✅ Integrated with MiniGameSystem backend (with fallback for development)
   * ✅ Built responsive UI with animations and transitions
   * ✅ Added loading states and error handling

### In Progress

1. **Main Menu UI**:
   * ✅ Created central hub layout with primary game features
   * ✅ Implemented modern design with animations and transitions
   * ✅ Added player profile section for displaying player info
   * ✅ Integrated all major feature buttons (Play, Alliance, Specialization, Events, Minigames, Settings)
   * ✅ Implemented proper styling using UIStyle for consistent appearance
   * ✅ Added icon integration with IconSet
   * 🔄 Finalizing connections to relevant backend systems
   * 🔄 Adding performance optimizations and error handling

2. **Settings Menu UI**:
   * ✅ Created modern settings layout with multiple categories
   * ✅ Implemented toggle, slider, and dropdown settings controls
   * ✅ Added animation and transition effects
   * ✅ Integrated with new UI modules
   * ✅ Implemented settings persistence using Player attributes
   * ✅ Added accessibility and interface options
   * 🔄 Finalizing connections to game systems for settings application
   

### Remaining Tasks

1. **UI Components**:
   * Implement remaining standard UI components
   * Complete the Main Menu integration
   * Add tooltips and help system throughout UI (low priority)

2. **Functionality Improvements**:
   * Add tooltips to explain various game features
   * Implement proper notifications for game events
   * Create comprehensive tutorial UI elements
   * Add visual feedback for player actions

### Next Implementation Steps

1. Update Rebirth UI to fully use modern UI components (high priority)
2. Complete Main Menu connections to backend systems (medium priority)
3. Add tooltips and help system throughout UI (low priority)

## Conclusion

This document serves as a guide for the UI development team. It covers the essential UI components, their interactions, and the necessary backend connections. By adhering to these guidelines and the stated design principles, the team can create a cohesive, intuitive, and visually appealing user interface that enhances the overall player experience.