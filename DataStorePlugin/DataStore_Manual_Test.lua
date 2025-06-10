-- DataStore Manual Test Script
-- Place this in ServerScriptService for testing

print("=== DataStore Manual Test Starting ===")

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- Test 1: Basic DataStore Access
print("\n1. Testing Basic DataStore Access...")
local success1, testStore = pcall(function()
    return DataStoreService:GetDataStore("TestStore")
end)

if success1 then
    print("✓ DataStore access successful")
    print("TestStore object:", testStore)
else
    warn("✗ DataStore access failed:", testStore)
end

-- Test 2: Set Data
if success1 then
    print("\n2. Testing Set Data...")
    local success2, result2 = pcall(function()
        testStore:SetAsync("TestKey", {
            message = "Hello from DataStore!",
            timestamp = os.time(),
            testNumber = 12345
        })
        return "Data set successfully"
    end)
    
    if success2 then
        print("✓ Set data successful:", result2)
    else
        warn("✗ Set data failed:", result2)
    end
end

-- Test 3: Get Data
if success1 then
    print("\n3. Testing Get Data...")
    local success3, result3 = pcall(function()
        return testStore:GetAsync("TestKey")
    end)
    
    if success3 then
        print("✓ Get data successful:")
        if result3 then
            for key, value in pairs(result3) do
                print("  ", key, "=", value)
            end
        else
            print("  No data found (nil)")
        end
    else
        warn("✗ Get data failed:", result3)
    end
end

-- Test 4: OrderedDataStore
print("\n4. Testing OrderedDataStore...")
local success4, orderedStore = pcall(function()
    return DataStoreService:GetOrderedDataStore("TestOrdered")
end)

if success4 then
    print("✓ OrderedDataStore access successful")
    
    -- Try to set some ordered data
    local success4b, result4b = pcall(function()
        orderedStore:SetAsync("Player1", 100)
        orderedStore:SetAsync("Player2", 250)
        orderedStore:SetAsync("Player3", 175)
        return "Ordered data set"
    end)
    
    if success4b then
        print("✓ Ordered data set:", result4b)
        
        -- Try to get sorted data
        local success4c, pages = pcall(function()
            return orderedStore:GetSortedAsync(false, 10)
        end)
        
        if success4c and pages then
            print("✓ Got sorted pages")
            local data = pages:GetCurrentPage()
            print("Top scores:")
            for i, entry in ipairs(data) do
                print("  ", i, entry.key, "=", entry.value)
            end
        else
            warn("✗ Failed to get sorted data:", pages)
        end
    else
        warn("✗ Failed to set ordered data:", result4b)
    end
else
    warn("✗ OrderedDataStore access failed:", orderedStore)
end

-- Test 5: GlobalDataStore
print("\n5. Testing GlobalDataStore...")
local success5, globalStore = pcall(function()
    return DataStoreService:GetGlobalDataStore()
end)

if success5 then
    print("✓ GlobalDataStore access successful")
else
    warn("✗ GlobalDataStore access failed:", globalStore)
end

print("\n=== DataStore Manual Test Complete ===")
print("Copy this script to ServerScriptService to run the test") 