# NPC Movement System Rewrite Instructions

## Overall Goal

The goal of the `NPC_Movement` system is to manage the behavior of Non-Player Characters (NPCs) within a gym tycoon environment. NPCs should be able to:

1.  **Move:** Navigate around the gym, including between floors.
2.  **Use Equipment:** Interact with gym equipment based on their preferences and the specialization of the gym.
3.  **Rest:** Take breaks when they are tired.
4. **Target Gyms** Move to the correct gym, based on their specialization.
5. **Interact:** Interact with the elements inside the gyms, such as sitting on chairs.

The system should be efficient, organized, and easy to understand.

## File Replacement

1.  **Open File:** Open the `src/server/Core/NPC_Movement.server.luau` file in your code editor.
2.  **Delete All Content:** Completely delete *all* existing code in the file.
3.  **Paste New Code:** Paste the entire code provided below into the `NPC_Movement.server.luau` file.
4. **Save:** Save the `NPC_Movement.server.luau` file.

**New Code:**
```
lua
--[[
    This module handles NPC movement within a tycoon gym environment.
    It is responsible for directing NPCs to use equipment, rest, or move between floors.
]]

local CollectionService = game:GetService("CollectionService")

local CONFIG = {
	equipmentTargetChance = 0.7,
}

local equipmentCache = {}

-- Function to find all equipment in a tycoon
local function cacheEquipment(tycoon)
	if equipmentCache[tycoon] then return equipmentCache[tycoon] end

	local equipment = {}

	-- Look for equipment models with the EquipmentId attribute and the IsInteractive attribute set to true
	for _, descendant in pairs(tycoon:GetDescendants()) do
		if descendant:IsA("Model") and descendant:GetAttribute("EquipmentId") and descendant:GetAttribute("IsInteractive") then
			table.insert(equipment, descendant)
		end
	end

	debug("Cached " .. #equipment .. " equipment pieces in " .. tycoon.Name)
	equipmentCache[tycoon] = equipment
	return equipment
end

--Get the correct stats
local function GetStats(npc)
	return npc:FindFirstChild("Stats")
end

-- Check if the NPC can use equipment or should rest
local function canUseEquipment(npc)
    -- Get the stats of the NPC
    local stats = GetStats(npc)

    -- Check if the NPC is tired (energy is 0)
    if stats and stats.Energy.Value <= 0 then
        return false -- NPC is too tired
    end

    -- Random check to decide if NPC will use equipment or rest
    return math.random() < CONFIG.equipmentTargetChance -- 70% chance to use equipment
end

--Make the NPC rest
local function restNPC(npc)
	local floors = findFloors(npc.Parent.Parent)
	if #floors == 0 then return end

	local floor = floors[math.random(1, #floors)]
	local size = floor.Size
	local cf = floor.CFrame

	local offsetX = (math.random() - 0.5) * (size.X - 4)  -- Keep away from edges
	local offsetZ = (math.random() - 0.5) * (size.Z - 4)

	local targetPosition = cf * CFrame.new(offsetX, size.Y/2 + 3, offsetZ)
	moveNPCToTarget(npc, targetPosition.Position)
end

--Function to find any gym with a specialization
local function findGymBySpecialization(specialization)
	--Look for any gym that has the tag Tycoon, and the tag of the correct specialization
	local gyms = CollectionService:GetTagged("Tycoon")
	for _, gym in ipairs(gyms) do
		if CollectionService:HasTag(gym, "SpecializationType_"..specialization) then
			return gym
		end
	end

	return nil
end

-- Function to find matching equipment based on specialization
local function findMatchingEquipment(npc, specialization)
	local tycoon = npc.Parent.Parent
	local equipment = cacheEquipment(tycoon)

	local matchingEquipment = {}
	for _, equip in pairs(equipment) do
		--Check if the equipment has the correct specialization tag
		if equip:IsA("Model") and equip:GetAttribute("EquipmentId") and CollectionService:HasTag(equip, specialization) then
			table.insert(matchingEquipment, equip)
		end
	end

	if #matchingEquipment == 0 then return nil end
	return matchingEquipment[math.random(1, #matchingEquipment)]
end

--Function to make the NPC move to the equipment
local function moveToEquipment(npc, equipment)
    if not equipment then return end -- Ensure equipment is valid
    local targetPosition = findTargetPosition(equipment)
    moveNPCToTarget(npc, targetPosition)
end

-- Function to find the target position of the model
local function findTargetPosition(model)
	--Check if the target is a seat
	if model:GetAttribute("InteractionType") == "Seat" then
		local position = model.Position
		return Vector3.new(position.X, position.Y + 2, position.Z) -- Return a position above the seat
	else
		-- Calculate a position in front of the model (adjust offset as needed)
		local offset = model.CFrame.LookVector * -4 -- Offset to be in front of the model
		return model.Position + Vector3.new(offset.X, 0, offset.Z) -- Return position in front of the equipment
	end
end

-- Move the NPC to the given target
local function moveNPCToTarget(npc, targetPosition)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local rootPart = npc:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	humanoid:MoveTo(targetPosition)
	npc:SetAttribute("NextMoveTime", os.time() + 3)
end

-- Function to move the NPC to the correct target
local function moveToTarget(npc)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local targetGym = findGymBySpecialization(npc:GetAttribute("SpecializationPreference"))
	if not targetGym then
		restNPC(npc)
		return
	end

	local floors = findFloors(targetGym)
	if #floors == 0 then
		restNPC(npc)
		return
	end

	local floor = floors[math.random(1, #floors)]
	local size = floor.Size
	local cf = floor.CFrame
	local offsetX = (math.random() - 0.5) * (size.X - 4)  -- Keep away from edges
	local offsetZ = (math.random() - 0.5) * (size.Z - 4)
	local targetPosition = cf * CFrame.new(offsetX, size.Y/2 + 3, offsetZ)

	moveNPCToTarget(npc, targetPosition.Position)
end

-- Function to find all the floors inside the target
local function findFloors(target)
	local floors = {}
	for _, descendant in pairs(target:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("IsFloor") then
			table.insert(floors, descendant)
		end
	end
	return floors
end

--Function to interact with an element
local function interactWithElement(npc, interactiveElement)
	local targetPosition = findTargetPosition(interactiveElement)

	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local rootPart = npc:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Check if the NPC is close enough to interact
	local distance = (rootPart.Position - targetPosition).Magnitude
	if distance <= 6 then
		-- Interact with the element
		--npc:SetAttribute("TargetType", "interacting")
		--return
		if interactiveElement:GetAttribute("InteractionType") == "Seat" then
			npc:SetAttribute("TargetType", "sitting")
			humanoid.Sit = true
			task.wait(10)
			humanoid.Sit = false
			npc:SetAttribute("TargetType", nil)
		else
			--Do nothing for now
		end
	else
		-- Move closer to the element
		humanoid:MoveTo(targetPosition)
	end
end

-- Function to find the nearest interactive element
local function findNearestInteractiveElement(npc)
	local rootPart = npc:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local nearbyParts = workspace:GetPartsInPart(rootPart, OverlapParams.new())
	local nearestElement = nil
	local nearestDistance = math.huge

	for _, part in ipairs(nearbyParts) do
		if part:GetAttribute("IsInteractive") then
			local distance = (rootPart.Position - part.Position).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearestElement = part
			end
		end
	end
	return nearestElement
end

-- Function to check if an NPC should start moving
local function checkNPCMovement(npc)
	-- Skip if NPC is already moving
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Check if it's time to move
	local nextMoveTime = npc:GetAttribute("NextMoveTime") or 0
	if os.time() < nextMoveTime then return end

	local npcPreference = npc:GetAttribute("SpecializationPreference") or "no_preference"

	-- Check for nearby interactive elements first
	local interactiveElement = findNearestInteractiveElement(npc)
	if interactiveElement then
		interactWithElement(npc, interactiveElement) -- Interact if close enough
		return -- Skip normal movement this cycle
	end

	-- Check if the NPC can use equipment or should rest (if not already interacting)
	if not canUseEquipment(npc) then
		restNPC(npc)
		return
	end

	-- If we get here the NPC can try to use a piece of equipment
	local targetEquipment
	if npcPreference ~= "no_preference" then
		targetEquipment = findMatchingEquipment(npc, npcPreference)
	end

	-- If no matching equipment or no preference, use the general target logic
	if targetEquipment then
		moveToEquipment(npc, targetEquipment)
	else
		moveToTarget(npc)
	end
end

-- Function to setup the NPC
local function setupNPC(npc)
	npc.PrimaryPart = npc:WaitForChild("HumanoidRootPart")

	-- Update movement every second
	while true do
		checkNPCMovement(npc)
		task.wait(1)
	end
end

return {
	setupNPC = setupNPC,
}
```
## Code Breakdown

This section explains each function in the code and how they work together.

### 1. `cacheEquipment(tycoon)`

*   **Purpose:** Finds all interactive equipment within a tycoon and caches it for faster access.
*   **Logic:**
    *   Checks if the equipment for the tycoon is already cached. If so, it returns the cached equipment.
    *   Iterates through all descendants of the tycoon.
    *   Checks if each descendant is a `Model` and has the attributes `EquipmentId` and `IsInteractive`.
    *   Adds matching equipment to the `equipment` table.
    *   Caches the equipment table for the tycoon in `equipmentCache`.
    *   Returns the `equipment` table.
*   **Usage:** Called by `findMatchingEquipment` to get a list of equipment in the current tycoon.

### 2. `GetStats(npc)`

*   **Purpose:** Gets the stats of the NPC
*   **Logic:**
    *   Checks if the NPC has a `Stats` child.
    * Returns the `Stats` if present.
*   **Usage:** Used by `canUseEquipment` to check if the NPC has enough energy.

### 3. `canUseEquipment(npc)`

*   **Purpose:** Determines if an NPC can use equipment or should rest.
*   **Logic:**
    *   Checks if the NPC's `Energy` stat is zero or less. If so, returns `false`.
    *   Randomly determines if the NPC will use equipment based on `CONFIG.equipmentTargetChance` (70% chance).
    *   Returns `true` or `false`.
*   **Usage:** Called by `checkNPCMovement` to decide whether an NPC should target equipment or rest.

### 4. `restNPC(npc)`

*   **Purpose:** Moves an NPC to a random location on a floor to rest.
*   **Logic:**
    *   Finds all the floors on the gym.
    * Chooses a random floor.
    * Generates a random position on the floor.
    * Makes the NPC move to that position.
*   **Usage:** Called by `checkNPCMovement` when an NPC needs to rest, or when they cannot move to the correct gym.

### 5. `findGymBySpecialization(specialization)`

*   **Purpose:** Finds a gym with a specific specialization tag.
*   **Logic:**
    *   Uses `CollectionService:GetTagged("Tycoon")` to get all gyms.
    *   Iterates through each gym.
    *   Checks if the gym has a tag of `SpecializationType_` followed by the provided specialization.
    *   Returns the matching gym or `nil`.
*   **Usage:** Called by `moveToTarget` to find the correct gym for an NPC.

### 6. `findMatchingEquipment(npc, specialization)`

*   **Purpose:** Finds a piece of equipment that matches the given specialization tag.
*   **Logic:**
    *   Gets all equipment in the NPC's tycoon using `cacheEquipment`.
    *   Iterates through each piece of equipment.
    *   Checks if the equipment is a `Model`, has the `EquipmentId` attribute, and has a matching specialization tag.
    *   Adds matching equipment to the `matchingEquipment` table.
    *   Returns a random piece of matching equipment or `nil` if none are found.
*   **Usage:** Called by `checkNPCMovement` to find equipment that matches the NPC's preferred specialization.

### 7. `moveToEquipment(npc, equipment)`

*   **Purpose:** Moves the NPC to a specific piece of equipment.
*   **Logic:**
    * Gets the correct `targetPosition` of the equipment.
    * Moves the NPC to that `targetPosition`.
*   **Usage:** Called by `checkNPCMovement` when an NPC is going to use a piece of equipment.

### 8. `findTargetPosition(model)`

*   **Purpose:** Calculates the target position for a given model.
*   **Logic:**
    *   Checks if the target has the attribute `InteractionType` with the value `Seat`.
        *   If so, it returns a position slightly above the seat.
    *   If not, it calculates a position in front of the model (offset by 4 studs).
    *   Returns the calculated target position.
*   **Usage:** Used by `moveToEquipment` and `interactWithElement` to find the correct position.

### 9. `moveNPCToTarget(npc, targetPosition)`

*   **Purpose:** Moves the NPC to the specified target position.
*   **Logic:**
    *   Checks if the NPC has a `Humanoid` and `HumanoidRootPart`.
    *   Uses `humanoid:MoveTo` to move the NPC.
    *   Sets the `NextMoveTime` attribute to prevent the NPC from immediately moving again.
*   **Usage:** Called by multiple functions (e.g., `moveToEquipment`, `moveToTarget`, `restNPC`).

### 10. `moveToTarget(npc)`

*   **Purpose:** Moves the NPC to the correct gym and floor.
*   **Logic:**
    *   Finds the correct gym for the NPC, based on their specialization, using `findGymBySpecialization`.
    *   If no gym is found, calls `restNPC` and returns.
    *   Finds a random floor in the target gym.
    *   Calculates a random target position on that floor.
    *   Moves the NPC to the target position using `moveNPCToTarget`.
*   **Usage:** Called by `checkNPCMovement` when the NPC needs to move to the correct gym.

### 11. `findFloors(target)`

*   **Purpose:** Finds all the floors in a target model (e.g., a gym).
*   **Logic:**
    *   Iterates through all descendants of the `target`.
    *   Checks if each descendant is a `BasePart` and has the `IsFloor` attribute.
    *   Adds matching parts to the `floors` table.
    *   Returns the `floors` table.
*   **Usage:** Called by `restNPC` and `moveToTarget` to find floors in a gym.

### 12. `interactWithElement(npc, interactiveElement)`

*   **Purpose:** Makes the NPC interact with an interactive element.
*   **Logic:**
    * Gets the `targetPosition` of the element.
    * Check if the NPC is close enough to interact.
    * If it is, it will do the interaction.
    * If it's a seat, it will make the NPC sit on it.
    * If not, for now, it will not do anything.
    * If the NPC is too far away, it will make the NPC move closer to the element.
* **Usage:** Called by `checkNPCMovement` when an interactive element is nearby.

### 13. `findNearestInteractiveElement(npc)`

*   **Purpose:** Finds the nearest interactive element to the NPC.
*   **Logic:**
    * Gets the `HumanoidRootPart` of the NPC.
    * Gets every element nearby.
    * Checks if the element has the attribute `IsInteractive`.
    * Returns the nearest `interactiveElement`, if present.
* **Usage:** Called by `checkNPCMovement` to check if an interactive element is nearby.

### 14. `checkNPCMovement(npc)`

*   **Purpose:** The main function that controls NPC movement and behavior.
*   **Logic:**
    *   Checks if the NPC is already moving (has a `NextMoveTime` attribute).
    *   Gets the NPC's specialization preference.
    * Check if there is an interactiveElement nearby.
    * If not, Check if the NPC can use equipment.
    * If the NPC can, try to find a matching equipment for it.
    * If not, it will move the NPC to the correct target, based on their gym.
*   **Usage:** Called by `setupNPC` every second to update the NPC's state.

### 15. `setupNPC(npc)`

*   **Purpose:** Sets up the NPC for movement and behavior.
*   **Logic:**
    *   Sets the NPC's `PrimaryPart` to its `HumanoidRootPart`.
    *   Starts an infinite loop that calls `checkNPCMovement` every second.
*   **Usage:** Called when an NPC is created or initialized.

## Logic Flow

Here's a step-by-step breakdown of the logic flow within the `checkNPCMovement` function:

1.  **Is it Time to Move?**
    *   Check if the NPC has the attribute `NextMoveTime`.
    *   If `os.time()` is less than `NextMoveTime`, the NPC is not ready to move yet, so exit the function.
2. **Check for nearby interactions:**
    * Try to find the nearest element that can be interacted.
    * If an element is found, interact with it, and skip the normal movement this cycle.
3.  **Can Use Equipment?**
    *   Call `canUseEquipment(npc)` to check if the NPC is able to use equipment.
    *   If `false`, call `restNPC(npc)` and exit the function (NPC needs to rest).
4.  **Find Matching Equipment (if applicable):**
    *   If the NPC has a `SpecializationPreference`, call `findMatchingEquipment(npc, npcPreference)` to find equipment that matches that specialization.
5.  **Move to Target:**
    *   If `findMatchingEquipment` returned equipment, call `moveToEquipment(npc, targetEquipment)`.
    *   If no matching equipment was found (or the NPC has no preference), call `moveToTarget(npc)` to move to the correct gym.

## Function List

*   **`cacheEquipment(tycoon)`:** Finds and caches all interactive equipment within a tycoon.
*   **`GetStats(npc)`:** Gets the stats of the NPC
*   **`canUseEquipment(npc)`:** Determines if an NPC can use equipment or should rest.
*   **`restNPC(npc)`:** Moves an NPC to a random location on a floor to rest.
*   **`findGymBySpecialization(specialization)`:** Finds a gym with a specific specialization tag.
*   **`findMatchingEquipment(npc, specialization)`:** Finds a piece of equipment that matches the given specialization tag.
*   **`moveToEquipment(npc, equipment)`:** Moves the NPC to a specific piece of equipment.
*   **`findTargetPosition(model)`:** Calculates the target position for a given model.
*   **`moveNPCToTarget(npc, targetPosition)`:** Moves the NPC to the specified target position.
*   **`moveToTarget(npc)`:** Moves the NPC to the correct gym and floor.
*   **`findFloors(target)`:** Finds all the floors in a target model (e.g., a gym).
*   **`checkNPCMovement(npc)`:** The main function that controls NPC movement and behavior.
* **`interactWithElement(npc, interactiveElement)`:** Makes the NPC interact with an interactive element.
* **`findNearestInteractiveElement(npc)`:** Finds the nearest interactive element to the NPC.
*   **`setupNPC(npc)`:** Sets up the NPC for movement and behavior.

## Key Concepts

*   **`CollectionService`:** Used to tag and retrieve tagged objects (e.g., gyms, equipment).
*   **Attributes:** Used to store additional information on objects (e.g., `EquipmentId`, `IsInteractive`, `IsFloor`, `SpecializationPreference`, `NextMoveTime`, `InteractionType`).
*   **Specialization:** Each gym can have a specialization (e.g., bodybuilding, cardio), and NPCs can have a specialization preference.
*   **Equipment:** Interactive models in the gym (e.g., treadmills, weights). Each equipment must have the `EquipmentId` attribute and the `IsInteractive` attribute.
*   **Floors:** BaseParts within a gym that NPCs can walk on. Each floor must have the `IsFloor` attribute.
* **Interaction:** Elements that the NPC can interact with, like seats. These elements must have the `IsInteractive` attribute and the `InteractionType` attribute.

## Specialization Interaction

The `NPC_Movement` system works closely with the `SpecializationSystem`. Here's how they interact:

1.  **Gym Tagging:** The `SpecializationSystem` is responsible for tagging gyms with their specialization type using `CollectionService`. For example, a bodybuilding gym might have the tag `"SpecializationType_bodybuilding"`.
2.  **NPC Preference:** Each NPC has a `SpecializationPreference` attribute. This attribute will indicate the gym specialization the NPC prefers.
3.  **Gym Selection:** When an NPC needs to move, `moveToTarget(npc)` calls `findGymBySpecialization(npcPreference)` to find a gym with the matching specialization tag.
4.  **Equipment Selection:** When an NPC is in a gym, `findMatchingEquipment` checks if equipment has a specialization tag that matches the NPC's preference.
5. **NPC Stats:** NPCs have stats that can affect their decision making, such as `Energy`.

## Troubleshooting

*   **NPCs Not Moving:**
    *   Make sure `checkNPCMovement` is being called regularly (every second).
    *   Check if the NPC has a `HumanoidRootPart` and a `Humanoid`.
    *   Verify that `NextMoveTime` is being set correctly.
    * Verify that the NPC has a `SpecializationPreference` tag.
    * Verify that the NPC has a `Stats` object.
    * Verify that the gyms have the correct `SpecializationType_` tag.
*   **NPCs Not Using Equipment:**
    *   Ensure equipment has the `EquipmentId` and `IsInteractive` attributes.
    * Verify that the equipment has the correct tags.
    *   Make sure `findMatchingEquipment` is working correctly.
*   **NPCs Not Resting:**
    *   Check if the `Energy` is correctly set.
    *   Verify that the floors have the `IsFloor` attribute.
    *   Make sure `restNPC` is being called when the NPC is too tired.
*   **NPCs Getting Stuck:**
    *   Make sure `moveNPCToTarget` is correctly finding the target position.
    *   Check the logic in `moveToTarget` for errors.
* **NPC not moving to the correct Gym:**
    * Make sure that the gyms have the `Tycoon` tag.
    * Make sure that the gyms have the correct specialization tag, using `SpecializationType_`.
    * Make sure that the NPC has a correct `SpecializationPreference` tag.
    * Check the logic in `findGymBySpecialization`.
* **NPC not interacting with elements:**
    * Make sure that the elements have the `IsInteractive` attribute.
    * Make sure that the elements have the `InteractionType` attribute.
    * Check the logic in `interactWithElement` and `findNearestInteractiveElement`.
    * Check the logic in `checkNPCMovement`.

## Testing

1.  **Spawn NPCs:** Create NPCs and set their `SpecializationPreference` attribute.
2.  **Create Gyms:** Create gyms and tag them with different specializations using `CollectionService`.
3.  **Add Equipment:** Add equipment to the gyms and tag them correctly.
4.  **Add Floors:** Add floors to the gyms and add the `IsFloor` attribute.
5.  **Add Interaction elements:** Add elements that can be interacted with, like seats.
6.  **Run and Observe:** Run the game and watch the NPCs. They should move, use equipment, rest, and follow their specialization preferences.
7.  **Debug:** Use `print` statements (or the debugger) to track the values of variables and the flow of logic.
8.  **Check for Errors:** Look for any error messages in the output window.

By carefully following these instructions, you should be able to successfully rewrite the `NPC_Movement.server.luau` code. Please let me know if you have any further questions.