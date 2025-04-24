--!strict -
--[[
    MigrationTest.server.luau
    Test script for validating the data migration utilities
    Part of Phase 3 of the Consolidation Plan
]]

local ServerScriptService = game:GetService("ServerScriptService")
-- ReplicatedStorage will be used in future expansion
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get necessary modules
local MigrationUtils = require(ServerScriptService:WaitForChild("Core"):WaitForChild("MigrationUtils"))

-- Sample data in old formats
local sampleData = {
    equipmentData = {
        -- Old nested format
        {
            equipment = {
                ["Treadmill_1"] = {
                    level = 2,
                    xp = 150,
                    upgrades = {
                        ["speed"] = true,
                        ["incline"] = true
                    },
                    attributes = {
                        capacity_max = 2,
                        usage_time = 60,
                        member_only = false
                    }
                },
                ["BenchPress_1"] = {
                    level = 3,
                    xp = 320,
                    upgrades = {
                        ["weight"] = true,
                        ["comfort"] = true
                    },
                    attributes = {
                        capacity_max = 1,
                        usage_time = 90,
                        member_only = true
                    }
                }
            }
        },
        -- Old flat format
        {
            ["Elliptical_1"] = {
                level = 1,
                xp = 0,
                attributes = {
                    capacity_max = 1,
                    usage_time = 45
                }
            },
            ["StairMaster_1"] = {
                level = 2,
                upgrades = {
                    ["steps"] = true
                }
            }
        }
    },
    
    tileData = {
        -- Old nested format
        {
            tiles = {
                ["Floor1_Tile1"] = {
                    purchased = true,
                    purchaseTime = 1630000000,
                    category = "Floor",
                    floor = 1
                },
                ["Floor1_Tile2"] = {
                    purchased = false,
                    category = "Wall",
                    floor = 1
                }
            }
        },
        -- Old flat format
        {
            ["Floor2_Tile1"] = true,
            ["Floor2_Tile2"] = {
                purchased = true,
                isPurchased = true, -- Variant naming
                timestamp = 1640000000, -- Variant naming
                floorNumber = 2 -- Variant naming
            }
        }
    },
    
    progressionData = {
        -- Old format 1
        {
            floors = {
                [1] = {
                    unlocked = true,
                    progress = 100,
                    completed = true
                },
                [2] = {
                    unlocked = true,
                    progress = 50,
                    completed = false
                }
            },
            milestones = {
                ["first_equipment"] = true,
                ["ten_members"] = {
                    completed = true,
                    progress = 10,
                    completionTime = 1635000000
                }
            }
        },
        -- Old format 2
        {
            floorProgress = {
                [3] = {
                    isUnlocked = true,
                    progress = 10
                }
            },
            achievements = {
                ["first_competition"] = false,
                ["celebrity_trainer"] = {
                    completed = false,
                    progress = 1
                }
            },
            features = {
                ["basketball_courts"] = true,
                ["swimming_pool"] = false
            }
        }
    }
}

-- Run migration tests
local function RunMigrationTests()
    print("==========================================")
    print("RUNNING DATA MIGRATION TESTS")
    print("==========================================")
      -- Test equipment data migration
    print("\n----- EQUIPMENT DATA MIGRATION TESTS -----")
    for i, oldData in ipairs(sampleData.equipmentData) do
        print("\nTesting equipment format " .. i)
        local migratedData = MigrationUtils.MigrateEquipmentData(oldData)
        print("Migration result: " .. (MigrationUtils.ValidateEquipmentData(migratedData) and "PASSED" or "FAILED"))
        
        -- Count the number of keys in the table
        local itemCount = 0
        for _ in pairs(migratedData) do
            itemCount += 1
        end
        print("Items migrated: " .. tostring(itemCount))
    end
      -- Test tile data migration
    print("\n----- TILE DATA MIGRATION TESTS -----")
    for i, oldData in ipairs(sampleData.tileData) do
        print("\nTesting tile format " .. i)
        local migratedData = MigrationUtils.MigrateTileData(oldData)
        print("Migration result: " .. (MigrationUtils.ValidateTileData(migratedData) and "PASSED" or "FAILED"))
        
        -- Count the number of keys in the table
        local itemCount = 0
        for _ in pairs(migratedData) do
            itemCount += 1
        end
        print("Items migrated: " .. tostring(itemCount))
    end
      -- Test progression data migration
    print("\n----- PROGRESSION DATA MIGRATION TESTS -----")
    for i, oldData in ipairs(sampleData.progressionData) do
        print("\nTesting progression format " .. i)
        local migratedData = MigrationUtils.MigrateProgressionData(oldData)
        print("Migration result: " .. (MigrationUtils.ValidateProgressionData(migratedData) and "PASSED" or "FAILED"))
        
        -- Count the number of floor keys in the table
        local floorCount = 0
        for _ in pairs(migratedData.floors) do
            floorCount += 1
        end
        print("Floors migrated: " .. tostring(floorCount))
    end
    
    -- Test rollback functionality
    print("\n----- ROLLBACK FUNCTIONALITY TESTS -----")
    local oldEquipmentData = sampleData.equipmentData[1]
    MigrationUtils.MigrateEquipmentData(oldEquipmentData)
    local rolledBackData = MigrationUtils.RollbackMigration("equipment")
    print("Rollback test: " .. (rolledBackData == oldEquipmentData and "PASSED" or "FAILED"))
    
    print("\n==========================================")
    print("MIGRATION TESTS COMPLETE")
    print("==========================================")
end

-- Create command to run migration tests
local function SetupTestCommands()
    -- Register a function to run tests in Studio
    if game:GetService("RunService"):IsStudio() then
        -- Create a BindableFunction to allow testing from command bar
        local testFunction = Instance.new("BindableFunction")
        testFunction.Name = "RunMigrationTests"
        testFunction.OnInvoke = RunMigrationTests
        testFunction.Parent = game:GetService("ServerScriptService")
        
        print("Migration test command registered. Run game.ServerScriptService.RunMigrationTests:Invoke() to test migrations.")
    end
end

-- Run setup
SetupTestCommands()
