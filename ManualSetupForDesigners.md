## Manual Setup Requirements for Designers

This document outlines the manual steps required by designers in the Roblox environment to ensure that various game scripts, particularly those related to the UI and core systems, function correctly.

### I. Menu Buttons (Managed by `src/client/MenuButtonCreator.client.luau`)

The `MenuButtonCreator.client.luau` script is responsible for creating and managing the main left-side menu buttons.

*   **UI Hierarchy:** The script will automatically create a `ScreenGui` named "MenuButtonsGui" under the player's `PlayerGui`. All menu buttons will be parented to this `ScreenGui`. **Designers should not manually create or modify a `ScreenGui` with this exact name under `PlayerGui`, as it will be managed by the script.**
*   **Icon Assets:** The icons for the menu buttons are loaded from the `src/client/UI/UIElementsData.luau` module.
    *   Ensure that the `UIElementsData.luau` module contains a table named `Icons`.
    *   Within the `Icons` table, ensure that there are entries for each menu button's icon (e.g., `Shop`, `Alliance`, `Gym`, `Stats`, `Leaderboard`, `Competition`, `Data`).
    *   These entries must contain the correct Roblox asset IDs for the desired icons.
*   **Module Locations:** The script requires the UI modules for each menu button (e.g., `ShopMenuUI`, `StatsMenuUI`, `SettingsMenuUI`, `AllianceUI`).
    *   Ensure that these UI module scripts are located in a place where the `loadUIModule` function in `MenuButtonCreator.client.luau` can find them. Placing them directly under the `src/client/UI/` folder is a reliable location.
    *   If a `ModuleLoaderHelper` is used, ensure it is correctly located at `ReplicatedStorage/shared/ModuleLoaderHelper.luau`.
*   **Button Configuration:** The appearance and behavior of the menu buttons are defined in the `MENU_BUTTONS` table within `MenuButtonCreator.client.luau`.
    *   To change the order, position, color, or icon of a menu button, modify the corresponding entry in the `MENU_BUTTONS` table in the script.
    *   Avoid making manual changes to the button instances in the Roblox explorer after the game is running, as these changes may be overwritten by the script.

### II. Menu UI Screens (e.g., `StatsMenuUI.client.luau`, `ShopMenuUI.client.luau`, etc.)

The scripts for individual menu screens (like the Stats, Shop, Gym, Leaderboard, Competition, and Data menus) manage the content and visibility of their respective UI.

*   **UI Hierarchy:** These scripts create their main UI frames (e.g., "StatsMenuFrame") and parent them to the player's `PlayerGui` when the menu is opened for the first time. **Designers should not manually create the main `ScreenGui` or the top-level menu `Frame` for these menus under `PlayerGui`.**
*   **UI Element Names:** Within the main menu frame created by the script, several key UI elements are created and referenced by name (e.g., "TitleBar", "CloseButton", "ScrollingFrame"). If designers are adding content or modifying the layout within these menus, they should be aware of these names to avoid conflicts or disrupting script functionality.
*   **Adding Content:** Designers should add the specific content for each menu (e.g., individual stat displays, shop item templates, leaderboard entries) *inside* the appropriate container within the main menu frame created by the script (e.g., inside the "StatsScrollingFrame" for the Stats menu).
*   **UI Styling:** These scripts rely on a `UIStyle` module for consistent appearance.
    *   Ensure a `UIStyle` module exists at `ReplicatedStorage/src/shared/UIStyle.luau`.
    *   This `UIStyle` module must contain definitions for `colors`, `fonts`, and `cornerRadius` that are referenced in the UI scripts.

### III. Settings Menu (`SettingsMenuUI.client.luau` and `SettingsMenu.luau`)

The `SettingsMenuUI.client.luau` script and the `SettingsMenu.luau` module work together to manage the game's settings interface.

*   **UI Hierarchy (`SettingsMenuUI.client.luau`):** The `SettingsMenuUI.client.luau` script creates a `ScreenGui` named "SettingsMenuGui" under `PlayerGui` to contain the settings UI. **Designers should not manually create a `ScreenGui` with this name under `PlayerGui`.**
*   **Module Dependencies (`SettingsMenuUI.client.luau`):** This script requires the following modules, typically located in a "shared" folder within `ReplicatedStorage`:
    *   `UIStyle` (`ReplicatedStorage/shared/UIStyle.luau`): Provides styling information.
    *   `IconSet` (`ReplicatedStorage/shared/IconSet.luau`): Provides icon asset IDs using a `getAssetId` function.
    *   `ButtonFactory` (`ReplicatedStorage/shared/ButtonFactory.luau`): Used for creating buttons.
    *   `DialogFactory` (`ReplicatedStorage/shared/DialogFactory.luau`): Used for notifications and tooltips.
    *   `SettingsMenu` (`ReplicatedStorage/shared/SettingsMenu.luau`): The core module that builds the settings UI based on configuration.
    Ensure these modules exist and are accessible at these paths.
*   **Settings Configuration (`SettingsMenu.luau`):** The specific settings displayed and managed by the UI are defined in the `DEFAULT_SETTINGS` table within `SettingsMenu.luau`.
    *   To add new settings, remove existing ones, change their titles, descriptions, default values, or types, designers (in coordination with scripters) must modify the `DEFAULT_SETTINGS` table in `SettingsMenu.luau`.
    *   Understand the supported setting types: "toggle" (boolean default), "slider" (min, max, number default), and "dropdown" (table of string options, string default).
    *   Category icons are referenced using `UIStyle.icons.<iconName>`, requiring coordination with `IconSet.luau`.
*   **No Manual Core UI Creation:** Avoid manually creating the individual settings controls (toggles, sliders, dropdowns) within the "SettingsMenuGui". These are generated dynamically by the `SettingsMenu.luau` module based on its configuration.
*   **Settings Persistence:** Settings are saved to and loaded from the player's attributes using a key format like `"Setting_" .. category .. "_" .. setting`.

### IV. Alliance Menu (`AllianceUI.client.luau`)

The `AllianceUI.client.luau` script handles the display and basic interaction for the alliance system UI.

*   **UI Hierarchy (Manual Creation Required):** Unlike some other UI scripts, this script *expects* the alliance UI elements to be pre-existing in the Roblox hierarchy. **Designers must manually create the following UI structure:**
    *   A `ScreenGui` named "AllianceUIFrame" located as a sibling to the `AllianceUI.client.luau` script (e.g., if the script is in `src/client/UI`, the ScreenGui should also be in `src/client/UI`).
    *   Inside "AllianceUIFrame`, a `Frame` named "AllianceFrame".
    *   Within "AllianceFrame" (and potentially "AllianceUIFrame"), create the necessary UI elements for the alliance menu (e.g., buttons for joining, leaving, disbanding, labels for alliance name, frames for member lists). The script looks for elements with specific names like "LeaveAllianceButton", "JoinAllianceButton", "AllianceNameLabel", and "MembersListFrame". Ensure these elements exist and are correctly named for the script to interact with them.
*   **Fallback UI:** The script includes a basic placeholder UI that is created if "AllianceUIFrame" is not found. However, this placeholder is very limited, and the full functionality of the Alliance UI will require the manually created UI elements.
*   **Module Dependencies:** The script attempts to use a `SafeWaitForChild` utility from `ReplicatedStorage/src/shared/SafeWaitForChild.luau`. If you are using this utility, ensure it is in the correct location.
*   **AllianceClient:** The UI is designed to work with an `AllianceClient` module for alliance logic. This is a scripting dependency, but relevant to the overall functionality.

### V. UI Style (`UIStyle.luau`)

The `UIStyle.luau` module is the central source of truth for the game's UI appearance.

*   **Referencing UIStyle:** When creating or modifying any UI elements (whether manually or through scripts), designers should refer to the colors, fonts, sizes, spacing, and border radii defined in `UIStyle.luau` to maintain a consistent visual style.
*   **Modifying Global Style:** To make changes to the game's overall UI theme (e.g., changing the primary accent color, updating fonts), modify the values directly within the `UIStyle.luau` module. This will propagate the changes to all UI elements that use `UIStyle`.
*   **Predefined Names:** Use the predefined names for colors (e.g., `UIStyle.colors.background`, `UIStyle.colors.accent`), fonts (e.g., `UIStyle.fonts.header`, `UIStyle.fonts.body`), and font sizes (e.g., `UIStyle.fontSizes.title`, `UIStyle.fontSizes.body`).
*   **Z-Index Layers:** Follow the `UIStyle.zIndex` recommendations for layering UI elements correctly (e.g., modals on top of tooltips).
*   **Module Location:** Ensure `UIStyle.luau` is located at `ReplicatedStorage/src/shared/UIStyle.luau`.

### VI. Icon Set (`IconSet.luau`)

The `IconSet.luau` module provides a centralized collection of icons used throughout the game's UI.

*   **Using Icons:** Designers should use the predefined icon names in `IconSet.luau` (e.g., `IconSet.getIcon("settings")`) when specifying icons for UI elements, rather than using asset IDs directly.
*   **Adding/Changing Icons:** To include new icons or update existing ones, modify the `IconSet.luau` module by adding or changing the asset ID associated with an icon name.
*   **Icon Naming:** Be aware of the existing icon names in the module when requesting or using icons.
*   **Fallback Icon:** The `fallback` icon will be used if a requested icon is not found or its asset is invalid.
*   **AssetValidator (Optional):** The module can utilize an `AssetValidator` at `ReplicatedStorage/shared/AssetValidator.luau` for icon validation and preloading, which is recommended for robustness.
*   **Module Location:** Ensure `IconSet.luau` is located at `ReplicatedStorage/src/shared/IconSet.luau`.

### VII. Asset Validator (`AssetValidator.luau`)

The `AssetValidator.luau` module is a utility for validating and preloading game assets, primarily images used in the UI.

*   **Asset ID Formatting:** The validator checks if asset IDs are in a valid numeric format. Incorrectly formatted IDs may not load correctly.
*   **Asset Preloading:** The module preloads assets to improve loading times and prevent visual issues.
*   **Failed Assets:** If an asset fails to load or validate, the UI element using it might display a fallback or be invisible. While the `getFailedAssets` function is for scripting debugging, designers should be aware that asset loading problems can impact UI appearance.
*   **Common Assets:** The validator preloads a set of common icons (success, error, warning, info) on initialization.
*   **Module Location:** Ensure `AssetValidator.luau` is located at `ReplicatedStorage/shared/AssetValidator.luau`.

### VIII. Button Factory (`ButtonFactory.luau`)

The `ButtonFactory.luau` module provides a standardized way to create various types of buttons with consistent styling, leveraging the `UIStyle` and `IconSet` modules.

*   **Standardized Creation:** Designers should use the functions provided by `ButtonFactory` (e.g., `createButton`, `createIconButton`, `createPrimaryButton`) to create buttons instead of manually configuring `TextButton` instances.
*   **UIStyle Dependency:** Button appearance is primarily controlled by `UIStyle.luau`. Changes to button colors, fonts, etc., should be made in `UIStyle`.
*   **IconSet Dependency:** When creating buttons with icons, use the icon names defined in `IconSet.luau`.
*   **Button Types:** Utilize the specialized creation functions (`createPrimaryButton`, `createDangerButton`, etc.) for buttons with specific semantic meanings.
*   **Configuration Options:** Button appearance and behavior can be customized using the `options` table when calling the creation functions.
*   **Automatic Effects:** Hover effects and shadows are automatically applied by the factory (shadows can be disabled).
*   **Module Location:** Ensure `ButtonFactory.luau` is located at `ReplicatedStorage/shared/ButtonFactory.luau`.

### IX. Dialog Factory (`DialogFactory.luau`)

The `DialogFactory.luau` module is a factory for creating various dialogs and UI elements such as notifications, confirmation dialogs, message dialogs, progress bars, tooltips, and context menus, ensuring a consistent look and feel.

*   **Standardized Creation:** Designers should use the functions provided by `DialogFactory` (e.g., `createNotification`, `createConfirmDialog`, `createTooltip`) to create these UI elements instead of building them manually.
*   **UIStyle Dependency:** The appearance of dialogs and other elements is primarily controlled by `UIStyle.luau`.
*   **IconSet Dependency:** Icons used within dialogs and notifications are sourced from `IconSet.luau`.
*   **Various UI Element Types:** The module provides functions for creating:
    *   Notifications (temporary popups)
    *   Confirmation Dialogs (Yes/No)
    *   Message Dialogs (OK)
    *   Progress Dialogs (with progress bar and optional cancel)
    *   Tooltips (contextual information popups)
    *   Context Menus (right-click menus)
*   **Configuration:** Content and behavior can be customized using options tables or arguments when calling the creation functions.
*   **Automatic Animations:** Some elements (notifications, tooltips) include built-in animations.
*   **Modal Overlays:** Dialogs automatically include a background overlay to indicate they are modal.
*   **Parenting:** Elements are automatically parented to dedicated `ScreenGui` instances (`DialogGui`, `NotificationGui`, `TooltipGui`, `ContextMenuGui`) under `PlayerGui`. **Do not manually create ScreenGuis with these names under `PlayerGui`.**
*   **Context Menu Closing:** Context menus automatically close when the user clicks outside them.
*   **Module Location:** Ensure `DialogFactory.luau` is located at `ReplicatedStorage/shared/DialogFactory.luau`.

### X. UI Elements Data (`UIElementsData.luau`)

The `UIElementsData.luau` module serves as a central data container, primarily for mapping descriptive icon names to their corresponding Roblox asset IDs. This module is a resource for scripts that need to reference icons.

*   **Icon Asset IDs:** The `Icons` table within this module is the designated location for storing Roblox asset IDs for various icons used throughout the UI.
*   **Key-Value Mapping:** Icons are stored as key-value pairs, where the key is a descriptive string name for the icon (e.g., "Settings", "Upgrades") and the value is the Roblox asset ID string (e.g., `"rbxassetid://..."`).
*   **Referenced by Scripts:** Other scripts, particularly those involved in creating UI elements with icons (like `MenuButtonCreator.client.luau`), will require this module to retrieve icon asset IDs based on the icon's name.
*   **Adding/Updating Icons:** To add a new icon or change an existing one used in the UI, the corresponding entry in the `Icons` table in `UIElementsData.luau` must be added or updated with the correct Roblox asset ID.
*   **Module Location:** Ensure `UIElementsData.luau` is located at `src/client/UI/UIElementsData.luau`.

### XI. Module Loader Helper (`ModuleLoaderHelper.luau`)

The `ModuleLoaderHelper.luau` module is a utility designed to assist scripts in reliably loading other modules within the Roblox environment. It provides functions for finding modules by name, safely requiring them with error handling, waiting for instances, and resolving instance paths.

*   **Purpose:** This module simplifies the process of requiring other scripts and modules, making the codebase more robust against issues like modules not being immediately available or incorrect file paths.
*   **No Direct Designer Interaction:** Designers typically will not need to interact with `ModuleLoaderHelper.luau` directly. It is a tool used by scripters.
*   **Module Location:** The helper module itself needs to be accessible to scripts that use it. Ensure it is located at `ReplicatedStorage/shared/ModuleLoaderHelper.luau`.
*   **Impact on Module Organization:** While `ModuleLoaderHelper` adds flexibility in finding modules, maintaining a consistent and logical folder structure for your modules within `ReplicatedStorage` and `ServerScriptService` is still highly recommended. This makes it easier for both scripts and developers to locate modules.
*   **Error Awareness:** The helper includes error handling for failed module loads. If you encounter issues where a script is reporting that a module could not be found or loaded, it might indicate a problem with the module's location or name as expected by the script using `ModuleLoaderHelper`.

### XII. Safe Wait For Child (`SafeWaitForChild.luau`)

The `SafeWaitForChild.luau` module provides safer alternatives to Roblox's built-in `WaitForChild` function, incorporating timeout functionality to prevent scripts from yielding indefinitely. It also offers functions for waiting for instances of a specific class, any of a list of children, all of a list of children, or a complete path of children.

*   **Purpose:** This module is a scripting utility that helps ensure scripts can reliably find and interact with instances in the Roblox hierarchy, even if those instances load asynchronously.
*   **No Direct Designer Interaction:** Designers will not directly use or modify this module. Its functionality is primarily for scripters.
*   **Dependency for Scripts:** Scripts that utilize the `SafeWaitForChild` functions depend on this module being located at `ReplicatedStorage/shared/SafeWaitForChild.luau`.
*   **Impact on Hierarchy and Naming:** The effectiveness of this module relies on the correct naming and hierarchical structure of instances in the Roblox environment. If scripts are waiting for instances that are not present or incorrectly named, even with the timeout, they will not be found, and the script's functionality may be affected. Designers should ensure that instances expected by scripts are correctly set up in the game world or UI.
*   **Timeout Awareness:** The functions in `SafeWaitForChild` have a default timeout (5 seconds). If an instance that a script is waiting for does not appear within this time, the wait will time out, a warning will be printed, and the function will return `nil`. If you observe warnings related to `SafeWaitForChild` timeouts, it may indicate that instances are not loading or being created as quickly as expected, or that there is an issue with their intended location or name.