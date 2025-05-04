# Primary Part Assignment System Verification Plan

This document outlines the steps to verify that the Primary Part Assignment system is working correctly.

## Prerequisites

- Access to the game in Roblox Studio
- Admin privileges (UserID must match the ADMIN_ID constant)
- Several models without primary parts (or the ability to create test models)

## Test Cases

### Test Case 1: Basic Functionality

**Objective:** Verify that the system can add primary parts to models without them.

**Steps:**
1. Open the game in Roblox Studio
2. Locate the GymParts folder in Workspace
3. Verify that at least some models don't have primary parts
   - Select a model and check the Properties panel
   - "PrimaryPart" should be blank/None
4. Open the Admin Commands UI (either interface)
5. Click the "Add Primary Parts" button
6. Check the feedback message

**Expected Results:**
- Feedback should indicate that models were processed and updated
- The models that previously lacked primary parts should now have them
- A part named "PrimaryReference" should be added to those models
- Properties of the reference part should match specifications (invisible, non-colliding)

### Test Case 2: Global Command

**Objective:** Verify that the global command works properly.

**Steps:**
1. Open the Command Bar in Roblox Studio (Ctrl+Shift+P/Cmd+Shift+P)
2. Reset the test environment by removing any primary parts from test models
3. Execute the command: `_G.AssignPrimaryParts()`
4. Check the output in the Output window

**Expected Results:**
- The function should execute without errors
- Output should indicate how many models were processed and updated
- Models should have primary parts added as expected

### Test Case 3: Remote Function

**Objective:** Verify that the server-side remote function works properly.

**Steps:**
1. Reset the test environment
2. Create a small test script in StarterPlayerScripts:
   ```lua
   wait(2)  -- Wait for game to load
   local remote = game:GetService("ReplicatedStorage"):WaitForChild("AssignPrimaryPartsRemote")
   local result = remote:InvokeServer()
   print("Remote result:", result)
   ```
3. Run the game
4. Check the output

**Expected Results:**
- The remote function should return a result string
- This string should indicate how many models were processed and updated
- Models should have primary parts added as expected

### Test Case 4: Admin UI Buttons

**Objective:** Verify that both admin UIs can trigger the functionality.

**Steps:**
1. Reset the test environment
2. Launch the game with admin privileges
3. Test each admin UI:
   - DataManagementUI admin button (🔧 icon)
   - Floating admin button ("A" button in top-right)
4. Click the "Add Primary Parts" button in each UI
5. Check the feedback messages

**Expected Results:**
- Both UIs should show success feedback
- Feedback should indicate how many models were processed and updated
- Models should have primary parts added as expected

### Test Case 5: Error Handling

**Objective:** Verify that the system handles errors gracefully.

**Steps:**
1. Temporarily rename the GymParts folder to something else
2. Try to run the command via the Admin UI
3. Try to run the global command
4. Restore the original folder name

**Expected Results:**
- Error messages should be clear and informative
- The UI should display appropriate feedback
- The system should not crash or freeze

### Test Case 6: Fallback Implementation

**Objective:** Verify that the system falls back to client-side implementation when needed.

**Steps:**
1. Temporarily disable the RemoteFunction by:
   - Commenting out the RemoteFunction creation in PrimaryPartAssignmentCommand.server.luau
   - OR moving the RemoteFunction to a different location
2. Run the "Add Primary Parts" command from the Admin UI
3. Check the output logs for "Using direct implementation" or similar messages
4. Restore the RemoteFunction

**Expected Results:**
- The system should fall back to client-side implementation
- Models should still have primary parts added
- Output logs should indicate the fallback path was used

### Test Case 7: Multiple Executions

**Objective:** Verify that running the command multiple times doesn't cause issues.

**Steps:**
1. Reset the test environment
2. Run the "Add Primary Parts" command once
3. Run it again immediately after
4. Check the feedback messages

**Expected Results:**
- First execution should report models updated
- Second execution should report zero or very few models updated
- No duplicate primary parts should be created
- No errors should occur

## Verification Checklist

Use this checklist to track your verification progress:

- [ ] Test Case 1: Basic Functionality
- [ ] Test Case 2: Global Command
- [ ] Test Case 3: Remote Function
- [ ] Test Case 4: Admin UI Buttons
- [ ] Test Case 5: Error Handling
- [ ] Test Case 6: Fallback Implementation
- [ ] Test Case 7: Multiple Executions

## Troubleshooting Tips

If you encounter issues during verification:

1. **Check the Output Window**: Look for error messages or warnings
2. **Verify Permissions**: Ensure you have admin privileges
3. **Check Model Structure**: Ensure models are valid and properly structured
4. **Restart Studio**: Some changes might require a restart to take effect
5. **Check Script Errors**: Look for syntax errors in the implementation
6. **Examine Remote Logs**: Use Developer Console to inspect remote call logs

## Report Template

When reporting verification results, please include:

1. Test environment details (Studio version, place file)
2. Which test cases passed or failed
3. Any unexpected behaviors or observations
4. Screenshots of relevant feedback or results
5. Suggestions for improvements or fixes
