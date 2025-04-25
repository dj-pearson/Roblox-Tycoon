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
  * **Design:** Clear and distinguishable with a question mark or tutorial icon.
* **Close Button:**
  * **Functionality:** Closes the current menu or pop up.
  * **Backend Connection:** None (UI only).
  * **Placement:** Various Menus and pop ups.
  * **Design:** Simple and noticeable.

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

### 5. Staff Management UI

* **Style:** `UIStyle.applyStyle()`

#### 5.1 Staff Management Menu
* **Layout:**
  * **Staff Overview:** Shows all hired staff with key statistics.
  * **Hire New Staff:** Interface for recruiting different types of staff.
  * **Training Interface:** UI for staff skill development and upgrading.
  * **Assignment Panel:** Controls for assigning staff to different areas.
  * **Staff Details View:** In-depth view of individual staff member attributes.
* **Design Direction:**
  * Professional layout with clear staff categories and hierarchy.
  * Color-coding for different staff types (trainers, cleaners, receptionists).
  * Card-based UI for staff members with avatar, stats, and quick actions.
  * Clear visual indicators for staff status (working, training, idle).
* **Backend Connection:**
  * `StaffSystem.getAllStaffMembers()`
  * `StaffSystem.hireStaff(positionId)`
  * `StaffSystem.trainStaff(staffId, skill)`
  * `StaffSystem.assignStaff(staffId, location)`
* **Placement:**
  * Accessed from a dedicated "Staff" button in the main menu.
  * Full-screen modal with tabs for different staff functions.

#### 5.2 Staff Cards
* **Layout:**
  * **Avatar/Image:** Visual representation of the staff member.
  * **Name & Level:** Staff member's name and current level.
  * **Type Indicator:** Icon representing staff role/type.
  * **Key Stats:** Efficiency, skill level, specialization.
  * **Status Indicator:** Current activity status (working, training, idle).
  * **Quick Actions:** Buttons for common actions (train, assign, details).
* **Design Direction:**
  * Compact but informative card layout.
  * Consistent sizing and information hierarchy.
  * Clear visual distinction between different staff types.
  * Status indicators with appropriate colors (green for active, yellow for training, etc.).
* **Backend Connection:**
  * Individual staff data from `StaffSystem.getStaffInfo(staffId)`.
  * Status updates through `StaffSystem.getStaffStatus(staffId)`.
* **Placement:**
  * Arranged in a grid or list within the Staff Management Menu.
  * Scrollable container for larger staff rosters.

#### 5.3 Training Facility Interface
* **Layout:**
  * **Available Training Options:** List of skills that can be trained.
  * **Training Cost:** Cost for each training session.
  * **Training Duration:** Time required for training completion.
  * **Benefits Preview:** Preview of stats improvement after training.
  * **Training Queue:** List of staff members currently in training.
* **Design Direction:**
  * Clean, educational-themed interface.
  * Progress indicators for ongoing training sessions.
  * Clear cost/benefit presentation for each training option.
  * Timer displays for training completion.
* **Backend Connection:**
  * `StaffSystem.getTrainingOptions(staffId)`
  * `StaffSystem.startTraining(staffId, trainingId)`
  * `StaffSystem.getTrainingProgress(staffId)`
  * **Completed UI Components:**
    * ✅ Created the base UI
    * ✅ Created Staff Overview, Hire Staff, Training and Assignments Panels.
    * ✅ Created all functions to update the UI.
    * ✅ Added test code to test the UI.
* **Placement:**
  * Dedicated tab within the Staff Management Menu.
  * Modal dialog for confirming training actions.

### 6. Equipment Management UI

* **Style:** `UIStyle.applyStyle()`

#### 6.1 Equipment Overview Dashboard
* **Layout:**
  * **Equipment Statistics:** Summary of equipment count, quality, and utilization.
  * **Maintenance Status:** Visual indicators of overall equipment condition.
  * **Revenue Impact:** Display of how equipment affects gym revenue.
  * **Category Performance:** Breakdown of equipment by category and performance.
  * **Status Indicators:** Color-coded status of equipment (Excellent, Good, Fair, Poor, Critical).
* **Design Direction:**
  * Clean, data-driven layout with prominent statistics and status indicators.
  * Consistent color coding: green for excellent condition, yellow for fair, red for poor/critical.
  * Visual charts showing equipment distribution and utilization.
  * Easy navigation to detailed views and management options.
* **Backend Connection:**
  * `EquipmentSystem.getEquipmentStatistics()`
  * `EquipmentSystem.getEquipmentDistribution()`
  * `EquipmentSystem.getMaintenanceStatus()`
* **Placement:**
  * Main tab in the gym management interface.
  * Accessible from primary UI through "Equipment" button.

#### 6.2 Individual Equipment Management
* **Layout:**
  * **Equipment Grid/List:** Display of all equipment items with key stats.
  * **Filtering Options:** Filter by type, status, popularity, or revenue.
  * **Sorting Controls:** Sort by various attributes (age, condition, popularity).
  * **Quick Actions:** One-click maintenance or upgrade options.
  * **Equipment Cards:** Visual representation with image and key metrics.
* **Design Direction:**
  * Card-based interface with clear visual hierarchy.
  * Consistent status indicators across all equipment.
  * Hover states showing additional information and available actions.
  * List and grid view options for different management styles.
* **Backend Connection:**
  * `EquipmentSystem.getAllEquipment()`
  * `EquipmentSystem.performMaintenance(equipmentId)`
  * `EquipmentSystem.upgradeEquipment(equipmentId, upgradeType)`
* **Placement:**
  * Tab or section within the Equipment Management interface.
  * Modal dialogs for detailed equipment information.

#### 6.3 Upgrade and Maintenance Interface
* **Layout:**
  * **Current Status:** Detailed information about selected equipment.
  * **Upgrade Options:** Available upgrades with costs and benefits.
  * **Maintenance Schedule:** Options for routine or emergency maintenance.
  * **Cost Analysis:** Breakdown of costs vs. benefits for different options.
  * **Before/After Comparison:** Visual preview of stat changes after upgrade.
* **Design Direction:**
  * Tabular layout for comparing multiple upgrade options.
  * Progress bars for visualizing potential improvements.
  * Clear cost and benefit information for each option.
  * Confirmation dialogs for expensive upgrades or maintenance.
* **Backend Connection:**
  * `EquipmentSystem.getUpgradeOptions(equipmentId)`
  * `EquipmentSystem.getMaintenanceOptions(equipmentId)`
  * `EquipmentSystem.calculateUpgradeROI(equipmentId, upgradeType)`
* **Placement:**
  * Accessible from equipment cards in the management view.
  * Full-screen modal with tabs for different upgrade categories.

#### 6.4 Equipment Purchasing Interface
* **Layout:**
  * **Equipment Catalog:** Available equipment organized by category.
  * **Comparison Tool:** Side-by-side comparison of similar equipment.
  * **Space Management:** Visual indication of available gym space.
  * **Budget Integration:** Display of current funds and purchase affordability.
  * **Preview Option:** Visual preview of equipment in the gym space.
* **Design Direction:**
  * Store-like catalog layout with clear categorization.
  * Detailed specifications for each equipment option.
  * Visual cues for popular or recommended equipment.
  * Integrated placement preview using gym floor plan.
* **Backend Connection:**
  * `EquipmentSystem.getAvailableEquipment()`
  * `EquipmentSystem.checkPlacement(equipmentId, position)`
  * `EquipmentSystem.purchaseEquipment(equipmentId, position)`
* **Placement:**
  * Dedicated "Purchase Equipment" section accessible from main menu.
  * Integrated with the gym floor editor for placement.

### 7. Member Satisfaction UI

* **Style:** `UIStyle.applyStyle()`

#### 7.1 Satisfaction Overview Panel
* **Layout:**
  * **Satisfaction Score:** Large numeric display with color-coded satisfaction level.
  * **Status Label:** Text indicating current status (Excellent, Good, Average, Poor, Terrible).
  * **Trend Indicator:** Icon showing if satisfaction is improving or declining.
  * **Key Factors:** Visual breakdown of factors affecting satisfaction.
  * **Member Retention:** Display of current retention rate and its impact.
  * **Revenue Impact:** Display of how satisfaction affects revenue.
* **Design Direction:**
  * Color-coded satisfaction levels (green for excellent, yellow for average, red for poor).
  * Clear visual indicators with icons for different satisfaction factors.
  * Compact but informative layout showing the most important information at a glance.
  * Animated transitions when satisfaction levels change.
* **Backend Connection:**
  * `MemberSatisfactionSystem.GetSatisfaction()`
  * `MemberSatisfactionSystem.GetRevenueFactor()`
  * `MemberSatisfactionSystem.GetRetentionFactor()`
* **Placement:**
  * Accessible from a dedicated button in the main menu or gym status panel.
  * Can be displayed as an overlay during gameplay for quick reference.

#### 7.2 Detailed Satisfaction Breakdown
* **Layout:**
  * **Satisfaction Factors:** Detailed breakdown of all factors affecting satisfaction:
    * **Equipment Density:** Ratio of equipment to members.
    * **Cleanliness:** Current gym cleanliness level.
    * **Staff Ratio:** Staff to member ratio and its impact.
    * **Equipment Quality:** Overall condition of gym equipment.
    * **Amenities:** Level and impact of gym amenities.
  * **Historical Data:** Graph showing satisfaction trend over time.
  * **Member Feedback:** Representative comments from gym members.
* **Design Direction:**
  * Tab-based interface for organizing different aspects of satisfaction data.
  * Bar graphs or gauge displays for visualizing each factor's contribution.
  * Tooltips providing advice on how to improve each factor.
  * Clean, data-focused layout that prioritizes clarity.
* **Backend Connection:**
  * Detailed data from `MemberSatisfactionSystem.GetSatisfactionBreakdown()`
  * Historical data from `MemberSatisfactionSystem.GetSatisfactionHistory()`
* **Placement:**
  * Accessed by clicking "Details" from the Satisfaction Overview Panel.
  * Full-screen modal with tabs for different aspects of satisfaction data.

#### 7.3 Improvement Suggestions Panel
* **Layout:**
  * **Priority Issues:** Highlights factors most negatively affecting satisfaction.
  * **Suggested Actions:** List of specific actions to improve satisfaction.
  * **Cost-Benefit Analysis:** Shows estimated satisfaction improvement vs. cost.
  * **Quick-Fix Options:** Immediate actions that can boost satisfaction.
* **Design Direction:**
  * Problem-solution format with clear visual connection between issues and solutions.
  * Action buttons for immediate implementation of suggestions.
  * Prioritized display with most impactful suggestions at the top.
  * Visual indicators showing potential satisfaction improvement for each action.
* **Backend Connection:**
  * `MemberSatisfactionSystem.GetImprovementSuggestions()`
  * Action buttons connect to appropriate systems (StaffSystem, EquipmentSystem, etc.)
* **Placement:**
  * Tab or section within the Satisfaction Details panel.
  * Can be accessed directly from warning notifications about declining satisfaction.

### 8. Specialized Gym Areas Visualization

* **Style:** `UIStyle.applyStyle()`

#### 8.1 Gym Layout Overview
* **Layout:**
  * **Floor Plan View:** Interactive top-down view of the entire gym.
  * **Area Highlighting:** Color-coded zones for different specializations.
  * **Heatmap Overlay:** Visualization of member traffic and equipment usage.
  * **Status Summary:** At-a-glance view of each area's performance.
  * **Quick Navigation:** Jump directly to specific areas for detailed management.
* **Design Direction:**
  * Clean, architect-style floor plan with clear boundaries.
  * Intuitive color coding for different area types and status.
  * Smooth zoom and pan controls for navigation.
  * Responsive layout that adapts to different screen sizes.
* **Backend Connection:**
  * `GymLayoutSystem.getFloorPlan()`
  * `GymLayoutSystem.getAreaStatistics()`
  * `GymLayoutSystem.getTrafficData()`
* **Placement:**
  * Dedicated tab in the main management interface.
  * Accessible from a "Gym Layout" button in the main menu.

#### 8.2 Area Detail View
* **Layout:**
  * **Equipment List:** All equipment present in the selected area.
  * **Area Statistics:** Usage, popularity, and revenue metrics.
  * **Member Activity:** Timeline of member activity throughout the day.
  * **Staff Assignment:** Current staff working in this area.
  * **Optimization Tips:** AI-driven suggestions for improvement.
* **Design Direction:**
  * Detailed but clean interface focusing on the selected area.
  * Visual representation of the area with equipment placement.
  * Performance graphs showing historical data and trends.
  * Action buttons for common area management tasks.
* **Backend Connection:**
  * `GymLayoutSystem.getAreaDetails(areaId)`
  * `GymLayoutSystem.getAreaEquipment(areaId)`
  * `GymLayoutSystem.getAreaActivity(areaId)`
* **Placement:**
  * Accessed by clicking on a specific area in the floor plan view.
  * Modal or side panel depending on information density.

#### 8.3 Specialization Configuration
* **Layout:**
  * **Specialization Options:** List of available gym specializations.
  * **Requirements:** Equipment and staff needed for each specialization.
  * **Benefits Preview:** Expected revenue and member satisfaction impact.
  * **Progress Tracker:** Visual indication of progress toward specialization.
  * **Cost Breakdown:** Investment required to achieve specialization.
* **Design Direction:**
  * Card-based interface for different specialization options.
  * Clear visual indicators of benefits and requirements.
  * Step-by-step configuration wizard for new specializations.
  * Before/after comparison views for planning purposes.
* **Backend Connection:**
  * `SpecializationSystem.getAvailableSpecializations()`
  * `SpecializationSystem.getRequirements(specializationId)`
  * `SpecializationSystem.calculateBenefits(specializationId)`
* **Placement:**
  * Tab or section within the area detail view.
  * Accessible from a "Specialize Area" button when viewing an area.

#### 8.4 Area Planning and Expansion
* **Layout:**
  * **Available Space:** Visualization of unused or expandable space.
  * **Expansion Options:** Different ways to expand the current gym.
  * **Cost Projections:** Financial impact of different expansion options.
  * **Phased Planning:** Tools for planning multi-stage gym development.
  * **Template Gallery:** Pre-designed area templates for quick implementation.
* **Design Direction:**
  * Blueprint-style interface for planning new areas.
  * Drag-and-drop equipment placement for easy configuration.
  * Visual indicators of space requirements and constraints.
  * Toggleable overlays for different planning considerations.
* **Backend Connection:**
  * `GymLayoutSystem.getExpansionOptions()`
  * `GymLayoutSystem.calculateExpansionCosts(expansionType)`
  * `GymLayoutSystem.previewExpansion(expansionConfig)`
* **Placement:**
  * Dedicated "Planning" tab in the gym layout interface.
  * Modal dialog for template selection and customization.

### 9. Progression Analytics Dashboard

* **Style:** `UIStyle.applyStyle()`

#### 9.1 Performance Overview
* **Layout:**
  * **Key Performance Indicators:** Revenue, member count, satisfaction, and growth rates.
  * **Time Period Selector:** Options to view data for day, week, month, or all-time.
  * **Comparison Tools:** Compare current performance to previous periods.
  * **Goal Tracking:** Progress toward player-set business goals.
  * **Milestone Timeline:** Visual representation of gym development milestones.
* **Design Direction:**
  * Clean, business dashboard aesthetic with emphasis on data clarity.
  * Interactive charts and graphs that respond to time period selection.
  * Visual indicators for growth (green) and decline (red) in metrics.
  * Consistent numerical formatting for currency and percentages.
* **Backend Connection:**
  * `AnalyticsSystem.getPerformanceMetrics(timeFrame)`
  * `AnalyticsSystem.comparePerformance(currentPeriod, previousPeriod)`
  * `AnalyticsSystem.getGoalProgress()`
* **Placement:**
  * Accessible from main menu via "Analytics" or "Performance" button.
  * Full-screen interface with multiple sections and tabs.

#### 9.2 Revenue Analysis
* **Layout:**
  * **Revenue Breakdown:** Sources of income (memberships, VIPs, equipment, services).
  * **Revenue Trends:** Line graphs showing revenue over time.
  * **Revenue Forecasting:** Projected future revenue based on current trends.
  * **Revenue Optimization:** Suggestions for increasing revenue.
  * **Expense Tracking:** Overview of costs and profit margins.
* **Design Direction:**
  * Financial report style with clear data visualizations.
  * Color-coded pie charts for revenue distribution.
  * Interactive elements allowing drill-down into specific revenue sources.
  * Tabular data with sorting options for detailed analysis.
* **Backend Connection:**
  * `RevenueSystem.getRevenueBreakdown(timeFrame)`
  * `RevenueSystem.getExpenseData(timeFrame)`
  * `AnalyticsSystem.forecastRevenue(days)`
* **Placement:**
  * Tab or section within the Analytics Dashboard.
  * Option to export or share reports.

#### 9.3 Member Analytics
* **Layout:**
  * **Member Demographics:** Breakdown of member types and preferences.
  * **Membership Duration:** Average duration of memberships and churn rate.
  * **Member Growth:** New members vs. lost members over time.
  * **Satisfaction Analysis:** Detailed view of satisfaction factors and trends.
  * **Member Journey Map:** Visualization of typical member progression.
* **Design Direction:**
  * People-focused visualizations with avatar icons and personas.
  * Heat calendar showing busy times and peak attendance.
  * Sentiment indicators showing member satisfaction levels.
  * Journey mapping with milestone indicators and drop-off points.
* **Backend Connection:**
  * `MemberSystem.getMemberDemographics()`
  * `MemberSystem.getMembershipStats()`
  * `MemberSatisfactionSystem.getSatisfactionAnalysis()`
* **Placement:**
  * Dedicated tab within the Analytics Dashboard.
  * Links to related management interfaces (Satisfaction, Staff, etc.).

#### 9.4 Progress & Achievement Tracking
* **Layout:**
  * **Gym Level Progress:** Visual representation of gym level and XP.
  * **Achievement Gallery:** All available and completed achievements.
  * **Rebirth Timeline:** History of rebirths with key metrics for each cycle.
  * **Competitive Rankings:** Position compared to other players (if multiplayer).
  * **Challenge Progress:** Status of active and upcoming challenges.
* **Design Direction:**
  * Achievement showcase with visual rewards and badges.
  * Timeline visualization for long-term progression.
  * Progression bars with clear milestones and rewards.
  * Trophy case aesthetic for competitive accomplishments.
* **Backend Connection:**
  * `AchievementSystem.getAllAchievements()`
  * `ProgressionSystem.getLevelData()`
  * `RebirthSystem.getRebirthHistory()`
  * `CompetitionSystem.getRankings()`
* **Placement:**
  * Tab within Analytics Dashboard or accessible from player profile.
  * Option to share achievements on social platforms.

### 10. Tutorial System UI

* **Style:** `UIStyle.applyStyle()`

#### 10.1 Tutorial Popup
* **Layout:**
  * **Title Bar:** Clear title indicating the current tutorial step.
  * **Main Content:** Tutorial instructions with supporting images.
  * **Skip Button:** Allows players to skip the current tutorial step.
  * **Navigation:** Next/Previous buttons when applicable.
  * **Progress Indicator:** Shows which step the player is on and how many remain.
  * **Visual Example:** Visual reference showing the tutorial concept in action.
* **Design Direction:**
  * Clean, non-intrusive overlay that doesn't obstruct gameplay.
  * Semi-transparent background to keep game visible.
  * Animated highlighting for UI elements being explained.
  * Smooth entrance and exit animations using TweenService.
  * Slide-in from top with Back easing.
* **Backend Connection:**
  * `TutorialManager.triggerTutorialStep()`
  * `TutorialManager.skipStep()`
  * `TutorialManager.completeStep()`
* **Placement:**
  * Top center of screen, appearing with smooth animation.
* **Implementation Notes:**
  * Dynamic sizing based on content (text and images).
  * Support for interactive elements within tutorial content.
  * Background shadow for better readability against varied game scenes.

#### 10.2 Tutorial Menu
* **Layout:**
  * **Tabs:** Basic Tutorials, Advanced Tutorials, Settings.
  * **Tutorial List:** Scrollable list of available tutorials.
  * **Tutorial Cards:** Name, description, completion status, and start button.
  * **Settings Panel:** Toggle options for tutorial features.
* **Design Direction:**
  * Modern, organized layout with clear hierarchy.
  * Visual indicators for completed vs. available tutorials.
  * Interactive elements to start specific tutorials.
* **Backend Connection:**
  * `TutorialManager.getAvailableTutorialSteps()`
  * `TutorialManager.isStepCompleted()`
  * `TutorialManager.updatePlayerSettings()`
* **Placement:**
  * Centered modal window when accessed from menu.
  
#### 10.3 UI Highlights
* **Functionality:**
  * Highlights specific UI elements that are the focus of a tutorial.
  * Creates a pulsing border or glow effect around target elements.
  * Can highlight 3D objects in the game world (equipment, NPCs, etc.).
* **Design Direction:**
  * Non-intrusive but clearly visible highlights.
  * Animated effects (pulsing, glowing) to draw attention.
  * Color-coded based on action type (interaction, information, etc.).
* **Backend Connection:**
  * Connected to active tutorial steps via `highlightSelector` property.
* **Placement:**
  * Dynamically positioned based on target UI element or 3D object.

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
   * ✅ **Staff Management UI** - The Staff Management UI is now completed
   * ✅ Added accessibility and interface options
   * 🔄 Finalizing connections to game systems for settings application
   
    #### 1.3 Settings Menu Implementation

    *   **File Creation:** Created the `SettingsUI.client.luau` file to handle the Settings Menu UI logic.
    *   **Layout:** Implemented the Main Frame and the Scrolling frame to allow scrolling.
    *   **Sections:** Created all the sections (`Sound`, `Graphics`, `Controls`, `Accessibility`, `Language`) with their respective labels.
    *   **Sound:** Created the `Music Volume` and `Sound Effects Volume` sliders, and implemented their functionality to update their labels.
    *   **Graphics:** Created the `Quality Presets` dropdown, and the `Shadows` checkbox.
    *   **Controls:** Created the `Mouse Sensitivity` slider, and implemented it's functionality to update it's label.
    * **Accessibility:** Created the `Colorblind Mode` checkbox.
    * **Language:** Created the `Language` dropdown.
    * **Connection with Main Menu**: Connected the `Settings` button in the main menu to load this ui.



3. **Rebirth Menu UI Enhancements**:
   * ✅ Updated to fully integrate with UIStyle for consistent appearance
   * ✅ Integrated IconSet for standardized icons
   * ✅ Replaced UIUtils dependency with ButtonFactory and DialogFactory
   * ✅ Improved animation and transition effects
   * ✅ Enhanced tab system with proper styling
   * ✅ Added notifications and feedback using DialogFactory

4. **Tutorial System UI**:
   * ✅ Created comprehensive TutorialManager server implementation
   * ✅ Implemented TutorialClient with responsive UI components
   * ✅ Designed tutorial popup system with animations and highlighting
   * ✅ Added tutorial menu with browsable tutorial catalog
   * ✅ Implemented UI highlighting system for interactive guidance

6. **Member Satisfaction UI**:
   * ✅ Created the Main frame for the UI
   * ✅ Implemented the `Satisfaction Overview Panel`
   * ✅ Added all the UI elements to the `Satisfaction Overview Panel` (`SatisfactionScore`, `StatusLabel`, `TrendIndicator`, `KeyFactors`, `MemberRetentionLabel` and `RevenueImpactLabel`)
   * ✅ Implemented the `updateSatisfactionScore`, `updateStatusLabel`, `updateTrendIndicator`, `updateMemberRetention` and `updateRevenueImpact` functions
   * ✅ Implemented the `addKeyFactor` function to dynamically add the key factors.
   * ✅ Implemented `clearKeyFactors` function to remove all key factors.
   * ✅ Created a testing module to visualize the ui and the update of all values.
   * ✅ Created settings panel for tutorial customization
   * ✅ Integrated with CoreRegistry and EventBridge systems
   * 🔄 Adding additional tutorial content for advanced game features
   * 🔄 Enhancing progression-based tutorial unlocking

## Pending UIs

### Unaddressed UI Files:

*   `src/client/UI/AchievementsTab.client.luau`
*   `src/client/UI/AdminControlsUI.client.luau`
*   `src/client/UI/AllianceUI.client.luau`
*   `src/client/UI/CentralMenuUI.client.luau`
*   `src/client/UI/FeaturesTab.client.luau`
*   `src/client/UI/MainMenuUI.client.luau`
*   `src/client/UI/MainTab.client.luau`
*   `src/client/UI/MinigamesMenuUI.client.luau`
*   `src/client/UI/MultiplierDisplay.client.luau`
*   `src/client/UI/NextUnlockPreview.client.luau`
*   `src/client/UI/PerksTab.client.luau`
*   `src/client/UI/ProgressBar.client.luau`
*   `src/client/UI/RebirthUI.client.luau`
*   `src/client/UI/SettingsMenuUI.client.luau`
*   `src/client/UI/StatisticsDisplay.client.luau`
*   `src/client/UI/TutorialUI.client.luau`
*   `src/client/UI/UIElements.md`
*   `src/client/UI/UIExample.client.luau`
*   `src/client/UI/UIHub.client.luau`
*   `src/client/UI/UIManager.client.luau`
*   `src/client/UI/UIRegistry.client.luau`

### Potential UI Files:
* `src/client/EquipmentUpgradeUI.client.luau`
* `src/client/DataManagementUI.client.luau`
### Remaining Tasks
1. **UI Components**:
   * Implement remaining standard UI components
   * Complete the Main Menu integration
   * Add tooltips and help system throughout UI (low priority)

2. **Functionality Improvements**:
   * Add tooltips to explain various game features
   * Implement proper notifications for game events
   * Add visual feedback for player actions

### Next Implementation Steps

1. Implement Staff Management UI (highest priority)
2. Implement Member Satisfaction UI (high priority)
3. Create Equipment Management UI (high priority)
4. Develop Specialized Gym Areas Visualization (medium priority)
5. Build Progression Analytics Dashboard (medium priority)
6. Complete Main Menu connections to backend systems (medium priority)
7. Add tooltips and help system throughout UI (low priority) 

## Conclusion

This document serves as a guide for the UI development team. It covers the essential UI components, their interactions, and the necessary backend connections. By adhering to these guidelines and the stated design principles, the team can create a cohesive, intuitive, and visually appealing user interface that enhances the overall player experience.