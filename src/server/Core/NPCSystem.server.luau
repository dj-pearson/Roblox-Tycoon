--lua
--[[
    NPCSystem.server.luau
    Handles all NPC behaviors, spawning, and movement in the gym.
    Part of the Core systems architecture.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Module dependencies
local CoreRegistry
local EventBridge
local TycoonSystem
local DataManager
local MemberSatisfactionSystem
local RevenueSystem

-- Configuration
local CONFIG = {
    -- Spawning
    maxMembersPerTycoon = 20,
    spawnInterval = 15,  -- seconds between spawn attempts
    spawnChance = 0.7,   -- 70% chance to spawn on each attempt

    -- Member types
    memberTypes = {
        {
            name = "Regular",
            chance = 0.4, -- Reduced chance to make room for new types
            model = "Regular_Member",
            revenueMultiplier = 1,
            satisfactionMultiplier = 1,
            equipmentPreferences = {}, -- Regular members have no specific preferences
            patience = 1, -- Normal patience
            spendingHabits = { drinkChance = 0.1, shopMultiplier = 1 }, -- 10% chance to buy a drink, normal spending
            satisfactionDrivers = { equipment = 1, cleanliness = 0.5, amenities = 0.5 } -- Equally driven by equipment, cleanliness, and amenities
        },
        {
            name = "VIP",
            chance = 0.1, -- Reduced chance, VIPs are less common
            model = "VIP_Member",
            revenueMultiplier = 3, -- Higher revenue
            satisfactionMultiplier = 1.5, -- Higher satisfaction gain/loss
            equipmentPreferences = {}, -- VIPs don't have specific equipment preferences, but value high-quality equipment
            patience = 0.8, -- Slightly less patient, expect better service
            spendingHabits = { drinkChance = 0.2, shopMultiplier = 1.5 }, -- Higher chance to buy drinks, higher spending
            satisfactionDrivers = { equipment = 1.2, cleanliness = 1, amenities = 1.2, exclusivity = 1.5 } -- More driven by quality and exclusivity
        },
        {
            name = "Bodybuilder",
            chance = 0.2,
            model = "Regular_Member", -- Assuming shared models for now, can be changed later
            revenueMultiplier = 1.2,
            satisfactionMultiplier = 1.1,
            equipmentPreferences = {"WeightMachine", "FreeWeights", "BenchPress"}, -- Prefers strength equipment
            patience = 1.1, -- More patient with equipment they want
            spendingHabits = { drinkChance = 0.05, shopMultiplier = 1.2, supplementChance = 0.3 }, -- More likely to buy supplements
            satisfactionDrivers = { equipment = 1.5, cleanliness = 0.3, amenities = 0.7 } -- Highly driven by equipment availability and quality
        },
        {
            name = "Cardio Enthusiast",
            chance = 0.15,
            model = "Regular_Member", -- Assuming shared models for now
            revenueMultiplier = 1.1,
            satisfactionMultiplier = 1,
            equipmentPreferences = {"Treadmill", "Elliptical", "StationaryBike", "RowingMachine"}, -- Prefers cardio equipment
            patience = 0.9, -- Less patient if cardio equipment is busy
            spendingHabits = { drinkChance = 0.25, shopMultiplier = 1.1 }, -- More likely to buy drinks
            satisfactionDrivers = { equipment = 1.4, cleanliness = 0.6, amenities = 0.5 } -- Highly driven by cardio equipment availability and quality
        },
        {
            name = "Senior",
            chance = 0.05, -- Less common
            model = "Regular_Member", -- Assuming shared models for now
            revenueMultiplier = 0.9, -- Slightly lower spending
            satisfactionMultiplier = 0.9, -- Slightly less impacted by minor issues
            equipmentPreferences = {"StationaryBike", "LightWeights", "YogaMats"}, -- Prefers less intense equipment
            patience = 1.5, -- More patient
            spendingHabits = { drinkChance = 0.15, shopMultiplier = 0.9 }, -- Moderate spending
            satisfactionDrivers = { equipment = 0.8, cleanliness = 1.2, amenities = 1.5 } -- More driven by cleanliness and amenities (like rest areas, accessible equipment)
        },
        {
            name = "Student",
            chance = 0.1,
            model = "Regular_Member", -- Assuming shared models for now
            revenueMultiplier = 0.8, -- Lower spending
            satisfactionMultiplier = 1.2, -- More easily satisfied or dissatisfied
            equipmentPreferences = {"FreeWeights", "BasketballHoop"}, -- Prefers popular and social equipment
            patience = 1, -- Normal patience
            spendingHabits = { drinkChance = 0.3, shopMultiplier = 0.8 }, -- More likely to buy drinks/snacks, lower overall spending
            satisfactionDrivers = { equipment = 1.1, cleanliness = 0.4, amenities = 0.8, social = 1.3 } -- Driven by equipment availability and social aspects
        },
    },

    -- Movement
    movementSpeed = 12,         -- walkSpeed for NPCs
    destinationRadius = 4,      -- How close NPC must be to count as "arrived"
    standTime = {5, 15},        -- Range of seconds NPCs will stand at equipment
    useEquipmentChance = 0.85,  -- Chance NPC will use equipment vs just walk around
    maxPathfindingRetries = 3,  -- Max number of times to retry pathfinding

    -- Object pooling
    initialPoolSize = 20,       -- Initial number of NPCs to create in the pool
    poolGrowthRate = 5,         -- How many NPCs to add when pool is empty

    -- Performance
    updateStaggering = 3,       -- Distribute NPC updates across this many frames
    cullingDistance = 100,      -- Distance beyond which NPCs will be culled
    preloadModels = true,       -- Whether to preload NPC models at startup

    -- VIP
    vipUnlockLevel = 3,         -- Gym level needed to start getting VIP members
    activityTypes = { -- Renamed floorNames to activityTypes for clarity and expansion
        {
            name = "Locker Room",
            area = "1st Floor - Locker Room",
            minDuration = 60,
            maxDuration = 180
        },
        {
            name = "Cardio",
            area = "1st Floor - Cardio",
            minDuration = 60, -- seconds
            maxDuration = 180, -- seconds
            equipment = {"Treadmill", "Elliptical", "StationaryBike", "RowingMachine"}
        },
        {
            name = "Strength Training",
            area = "1st Floor - Strength",
            minDuration = 90,
            maxDuration = 240,
            equipment = {"WeightMachine", "FreeWeights", "BenchPress"} -- Added BenchPress
        },
        {
            name = "Kids Gym",
            area = "1st Floor - Kids Gym",
            minDuration = 120,
            maxDuration = 240
        },
        {
            name = "Basketball",
            area = "2nd Floor - Basketball Court",
            minDuration = 180,
            maxDuration = 360,
            equipment = {"BasketballHoop"}
        },
        {
            name = "HIIT",
            area = "2nd Floor - HIIT Room",
            minDuration = 120,
            maxDuration = 240
        },
        {
            name = "Golf",
            area = "2nd Floor - Golf Simulators",
            minDuration = 120,
            maxDuration = 300,
            equipment = {"GolfSimulator"}
        },
        {
            name = "Spin",
            area = "2nd Floor - Spin Room",
            minDuration = 120,
            maxDuration = 240,
            equipment = {"SpinBike", "Spin Class"}
        },
        {
            name = "Yoga",
            area = "3rd Floor - Yoga Studio",
            minDuration = 120,
            maxDuration = 240,
            equipment = {"YogaMats", "YogaBall"}
        },
        {
            name = "Pilates",
            area = "3rd Floor - Pilates Studio",
            minDuration = 120,
            maxDuration = 240
        },

        {
            name = "Personal Training",
            area = "3rd Floor - Personal Training",
            minDuration = 180,
            maxDuration = 300
        },
        {
            name = "Relaxation",
            area = "3rd Floor - Relaxation Area",
            minDuration = 60,
            maxDuration = 180,
            equipment = {"MassageChair", "MeditationPillow"}
        },
        {
            name = "Sauna/Steam",
            area = "3rd Floor - Sauna/Steam Area",
            minDuration = 60,
            maxDuration = 240
        },
        {
            name = "Pool",
            area = "4th Floor - Swimming Pool",
            minDuration = 180,
            maxDuration = 360
        },
        {
            name = "Boxing/MMA",
            area = "4th Floor - Boxing/MMA Area",
            minDuration = 60,
            maxDuration = 180,

            equipment = {"ClimbingWall"}
        },
        {
            name = "Boxing/MMA",
            area = "4th Floor - Boxing/MMA Area",
            minDuration = 120,
            maxDuration = 180,
            equipment = {"PunchingBag"}
        },
                {
            name = "Restaurant",
            area = "4th Floor - Restaurant",
            minDuration = 180,
            maxDuration = 360
        },
        {
            name = "Roof Pool",
            area = "Roof - Pool",
            minDuration = 180,
            maxDuration = 360,
            equipment = {"PoolLoungeChair"}
        },
        {
            name = "Roof Track",
            area = "Roof - Track",
            minDuration = 60,
            maxDuration = 360
        },
        {
            name = "Roof Yoga",
            area = "Roof - Yoga Area",
            minDuration = 120,
            maxDuration = 240
        },
        {
            name = "Roof Basketball",
            area = "Roof - Basketball Courts",
            minDuration = 180,
            maxDuration = 360,
            equipment = {"BasketballHoop"}
        },
        {
            name = "Rooftop Bar",
            area = "Roof - Bar Area",
            minDuration = 60,
            maxDuration = 360,
            equipment = {"BasketballHoop"} -- Assuming bar area has equipment like bar stools, etc.
        },
        {
            name = "Skate Park",
            area = "Outside - Skate Park",
            minDuration = 120,
            maxDuration = 240
        },
        {
            name = "Soccer",
            area = "Outside - Soccer Field",
            minDuration = 180,
            maxDuration = 360
        },
        {
            name = "Tennis",
            area = "Outside - Tennis Courts",
            minDuration = 120,
            maxDuration = 240
        },
        {
            name = "Pickleball",
            area = "Outside - Pickleball Courts",
            minDuration = 120,
            maxDuration = 240
        },
        {
            name = "Outside Climbing",
            area = "Outside - Climbing Wall",
            minDuration = 120,
            maxDuration = 240,
            equipment = {"ClimbingWall"}
        },
        {
            name = "Outside Pool",
            area = "Outside - Pool",
            minDuration = 180,
            maxDuration = 360
        },
        {
            name = "Playground",
            area = "Outside - Playground",
            minDuration = 120,
            maxDuration = 240
        },
          {
              name = "Outside - Rest Area",
              area = "Outside - Rest Area",
              minDuration = 60,
              maxDuration = 360,
              equipment = {"Bench", "OutdoorLoungeChair", "PicnicTable"} -- Examples
          },
    },
    activityPreferenceOrder = {}, -- This might need adjustment based on new member types
    activityWeights = {}, -- This will definitely need adjustment based on new member types
    floorNames = { -- This seems redundant with activityTypes.area, might need refactoring
      "1st Floor - Cardio",
      "1st Floor - Strength",
      "1st Floor - Locker Room",
      "1st Floor - Kids Gym",
      "2nd Floor - Group Fitness",
      "2nd Floor - Spin Room",
      "2nd Floor - Basketball Court",
      "2nd Floor - Golf Simulators",
      "2nd Floor - HIIT Room",
      "3rd Floor - Yoga Studio",
      "3rd Floor - Pilates Studio",
      "3rd Floor - Personal Training",
      "3rd Floor - Relaxation Area",
      "3rd Floor - Sauna/Steam Area",
      "4th Floor - Swimming Pool",
      "4th Floor - Climbing Wall",
      "4th Floor - Boxing/MMA Area",
      "4th Floor - Restaurant",
      "Roof - Pool",
      "Roof - Track",
      "Roof - Yoga Area",
      "Roof - Basketball Courts",
      "Outside - Skate Park",
      "Outside - Soccer Field",
      "Outside - Tennis Courts",
      "Outside - Pickleball Courts",
    },
    npcPreferences = { -- This also needs to be dynamic based on member type preferences
        "Cardio",
        "Strength Training",
        "Group Fitness",
        "Spin",
        "Basketball",
        "Golf",
        "HIIT",
        "Yoga",
        "Pilates",
        "Personal Training",
        "Relaxation",
        "Sauna/Steam",
        "Pool",
        "Climbing",
        "Boxing/MMA",
        "Restaurant",
        "Roof Pool",
        "Roof Track",
        "Roof Yoga",
        "Roof Basketball",
        "Skate Park",
        "Soccer",
        "Tennis",
        "Pickleball",
        "Outside Climbing",
        "Outside Pool",
        "Playground",
        "Locker Room",
        "Kids Gym"
    },

    -- Debug
    debug = false
}

-- Module table
local NPCSystem = {
    _name = "NPCSystem",
    _version = "2.2.0", -- Updated version
    _dependencies = {
        "CoreRegistry",
        "EventBridge",
        "TycoonSystem",
        "DataManager",
        "MemberSatisfactionSystem",
        "RevenueSystem"
    },

    -- Internal state
    _npcPools = {},         -- Object pools for NPCs, separated by tycoon
    _activeTycoons = {},    -- List of active tycoons with NPCs
    _activeNPCs = {},       -- Currently active NPCs
    _spawnTimers = {},      -- Timers for spawning NPCs, keyed by tycoon
    _models = {},           -- Cached NPC models
    _nextUpdateGroup = 0    -- For staggered updates
}
-- Rest of the code remains the same