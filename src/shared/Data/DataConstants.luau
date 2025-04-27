--!strict
--[[
    DataConstants.luau
    
    Shared constants and default values for the data system.
    Centralizes configuration values and ensures consistency across the codebase.
    
    Features:
    - Global constants for data system settings
    - Game balance parameters
    - Data storage keys and namespaces
    - System configuration defaults
    
    Author: Updated April 27, 2025
]]

local DataConstants = {}

--[[ Data System Constants ]]--

-- Storage Version
DataConstants.STORAGE_VERSION = "1.0.0"  -- Increment for major data format changes

-- Data Store Names
DataConstants.STORES = {
    PLAYER_DATA = "PlayerData_v4",  -- Player core data
    GYM_DATA = "GymData_v3",        -- Gym-specific data
    GLOBAL_DATA = "GlobalData_v2",  -- Global game state
    ANALYTICS = "Analytics_v1",     -- Analytics and metrics
    BACKUP = "DataBackup_v2",       -- Backup data store
    MIGRATIONS = "DataMigrations_v1" -- Migration tracking
}

-- Session Data Keys (temporary data not saved to DataStore)
DataConstants.SESSION_KEYS = {
    LAST_SAVE_TIME = "lastSaveTime",
    SAVE_ATTEMPTS = "saveAttempts",
    SAVE_FAILURES = "saveFailures",
    CONNECTION_QUALITY = "connectionQuality",
    PENDING_TRANSACTIONS = "pendingTransactions"
}

-- DataStore Keys (used for specific global values)
DataConstants.GLOBAL_KEYS = {
    SERVER_VERSION = "serverVersion",
    ECONOMY_MULTIPLIER = "economyMultiplier",
    ACTIVE_EVENTS = "activeEvents",
    DAILY_CHALLENGES = "dailyChallenges",
    LEADERBOARD_LAST_UPDATE = "leaderboardLastUpdate",
    GAME_CONFIG = "gameConfig"
}

-- Player Data Scopes
DataConstants.PLAYER_SCOPES = {
    CORE = "core",           -- Core player data (level, XP, etc.)
    STATS = "stats",         -- Player statistics
    INVENTORY = "inventory", -- Player inventory items
    ACHIEVEMENTS = "achievements", -- Player achievements
    QUESTS = "quests",       -- Active and completed quests
    SOCIAL = "social",       -- Friends, guild, etc.
    SETTINGS = "settings"    -- Player preferences and settings
}

-- Client-Writable Scopes (scopes that can be modified from client)
DataConstants.CLIENT_WRITABLE_SCOPES = {
    [DataConstants.PLAYER_SCOPES.SETTINGS] = true, -- Allow clients to update their settings
    -- Other scopes require server validation
}

-- Auto-Save Configuration
DataConstants.AUTOSAVE = {
    ENABLED = true,          -- Whether auto-save is enabled
    INTERVAL = 120,          -- Save interval in seconds
    STAGGER_RANGE = 30       -- Random stagger time to prevent simultaneous saves
}

-- Rate Limiting
DataConstants.RATE_LIMITS = {
    SAVES_PER_MINUTE = 10,
    LOADS_PER_MINUTE = 8,
    MAX_RETRY_ATTEMPTS = 3,
    RETRY_DELAY = 5  -- Seconds
}

-- Cache Settings
DataConstants.CACHE = {
    PLAYER_CACHE_DURATION = 600,  -- How long to keep player data in cache after disconnect
    MEMORY_CACHE_LIMIT = 100,     -- Maximum number of players to keep in memory
    PRELOAD_KEY_GROUPS = {"CORE", "SETTINGS"},  -- Data groups to preload
    SESSION_LOCK_DURATION = 30    -- How long session locks last
}

--[[ Data Validation Settings ]]--

-- Limits and Constraints
DataConstants.LIMITS = {
    MAX_CASH = 1000000000,     -- Maximum cash value
    MAX_LEVEL = 100,           -- Maximum player level
    MAX_REBIRTH = 50,          -- Maximum rebirth level
    MAX_INVENTORY_ITEMS = 500, -- Maximum inventory size
    MAX_GYM_MEMBERS = 200,     -- Maximum gym members
    MAX_EQUIPMENT = 100,       -- Maximum equipment pieces
    MAX_STAFF = 20,            -- Maximum staff members
    MAX_NAME_LENGTH = 50,      -- Maximum name length
    MAX_DESCRIPTION_LENGTH = 1000  -- Maximum description length
}

--[[ Game Balance Constants ]]--

-- Economy
DataConstants.ECONOMY = {
    STARTING_CASH = 1000,
    BASE_MEMBER_INCOME = 10,
    EQUIPMENT_MAINTENANCE_COST = 5,
    STAFF_SALARY_MULTIPLIER = 1.0,
    TAX_RATE = 0.05,
    REBIRTH_MULTIPLIER = 1.5,  -- Income multiplier per rebirth level
    SPECIAL_EVENT_BONUS = 2.0  -- Income multiplier during special events
}

-- Experience and Leveling
DataConstants.EXPERIENCE = {
    BASE_ACTION_XP = 10,
    LEVEL_SCALING_FACTOR = 1.5,  -- How much more XP each level requires
    BASE_LEVEL_REQUIREMENT = 100, -- XP needed for level 1 -> 2
    MEMBER_SATISFACTION_BONUS = 0.2, -- XP bonus for high member satisfaction
    DAILY_BONUS_MULTIPLIER = 1.2   -- Bonus for first login of the day
}

-- Equipment
DataConstants.EQUIPMENT = {
    BASE_DURABILITY = 100,
    USAGE_WEAR = 0.5,          -- Durability loss per use
    REPAIR_EFFECTIVENESS = 0.8, -- % of durability restored per repair
    UPGRADE_COST_MULTIPLIER = 2.5, -- Cost increase per level
    UPGRADE_BENEFIT_MULTIPLIER = 1.5, -- Benefit increase per level
    MAINTENANCE_INTERVAL = 24 * 60 * 60, -- One day in seconds
    BROKEN_THRESHOLD = 10      -- Equipment considered broken below this durability
}

-- Member Behavior
DataConstants.MEMBER_BEHAVIOR = {
    VISIT_FREQUENCY_BASE = 24 * 60 * 60, -- Average time between visits (seconds)
    SATISFACTION_DECAY = 0.02,  -- Daily satisfaction decay
    LOYALTY_GAIN_RATE = 0.05,   -- Loyalty increase per good visit
    CLEANLINESS_IMPORTANCE = 0.3, -- Impact of cleanliness on satisfaction
    EQUIPMENT_VARIETY_BONUS = 0.2, -- Bonus for having diverse equipment
    STAFF_SKILL_IMPACT = 0.25,   -- Impact of staff skill on member satisfaction
    OVERCROWDING_THRESHOLD = 0.8, -- % of capacity that triggers overcrowding penalties
    MEMBERSHIP_DURATION_BASE = 30 * 24 * 60 * 60  -- Base membership duration (30 days)
}

-- Time Constants (in seconds)
DataConstants.TIME = {
    DAY = 24 * 60 * 60,
    WEEK = 7 * 24 * 60 * 60,
    MONTH = 30 * 24 * 60 * 60,
    STAFF_SHIFT = 8 * 60 * 60,
    MEMBER_WORKOUT = 45 * 60,
    EQUIPMENT_USE = 15 * 60,
    MAINTENANCE_TASK = 30 * 60,
    CLEANING_TASK = 15 * 60
}

--[[ Default Values ]]--

-- Default game configuration
DataConstants.DEFAULT_GAME_CONFIG = {
    economyMultiplier = 1.0,
    xpMultiplier = 1.0,
    memberJoinRate = 1.0,
    equipmentCostMultiplier = 1.0,
    eventChance = 0.1,
    specialOffers = {},
    featuresEnabled = {
        rebirth = true,
        staff = true,
        quests = true,
        specialization = true,
        tournaments = true,
        seasonalEvents = true
    },
    tutorialSteps = {
        "welcome",
        "buyTile",
        "placeEquipment",
        "attractMembers",
        "collectRevenue",
        "upgradeEquipment"
    },
    difficultySettings = {
        easy = {
            startingCash = 2000,
            economyMultiplier = 1.2,
            maintenanceCost = 0.8
        },
        normal = {
            startingCash = 1000,
            economyMultiplier = 1.0,
            maintenanceCost = 1.0
        },
        hard = {
            startingCash = 500,
            economyMultiplier = 0.8,
            maintenanceCost = 1.2
        }
    }
}

-- Default player settings
DataConstants.DEFAULT_PLAYER_SETTINGS = {
    sound = 0.5,
    music = 0.5,
    notifications = true,
    tutorial = true,
    cameraSensitivity = 1.0,
    quality = "medium",
    language = "en",
    autoCollect = false,
    showTips = true,
    uiScale = 1.0
}

-- Default gym specializations
DataConstants.SPECIALIZATIONS = {
    GENERAL = {
        name = "General Fitness",
        description = "A well-rounded gym for all fitness needs",
        memberMultiplier = 1.0,
        revenueMultiplier = 1.0,
        memberTypes = "balanced"
    },
    STRENGTH = {
        name = "Strength Training",
        description = "Specialized in weight training and muscle building",
        memberMultiplier = 0.8,
        revenueMultiplier = 1.2,
        memberTypes = "strength"
    },
    CARDIO = {
        name = "Cardio Fitness",
        description = "Focused on cardiovascular health and endurance",
        memberMultiplier = 1.2,
        revenueMultiplier = 0.9,
        memberTypes = "cardio"
    },
    LUXURY = {
        name = "Luxury Fitness",
        description = "Premium equipment and services for discerning clients",
        memberMultiplier = 0.6,
        revenueMultiplier = 1.5,
        memberTypes = "luxury"
    },
    BUDGET = {
        name = "Budget Gym",
        description = "Affordable fitness for the masses",
        memberMultiplier = 1.5,
        revenueMultiplier = 0.7,
        memberTypes = "budget"
    }
}

-- Equipment categories
DataConstants.EQUIPMENT_CATEGORIES = {
    CARDIO = "cardio",
    STRENGTH = "strength",
    FUNCTIONAL = "functional",
    SPECIALIZED = "specialized",
    AMENITY = "amenity"
}

-- Staff roles
DataConstants.STAFF_ROLES = {
    TRAINER = "trainer",
    MAINTENANCE = "maintenance",
    CLEANING = "cleaning",
    RECEPTION = "reception",
    MANAGER = "manager"
}

-- Quest types
DataConstants.QUEST_TYPES = {
    DAILY = "daily",
    WEEKLY = "weekly",
    ACHIEVEMENT = "achievement",
    STORY = "story",
    EVENT = "event"
}

-- Notification categories
DataConstants.NOTIFICATION_CATEGORIES = {
    SYSTEM = "system",
    ECONOMY = "economy",
    MEMBERS = "members",
    EQUIPMENT = "equipment",
    STAFF = "staff",
    QUESTS = "quests",
    EVENTS = "events"
}

--[[ Error Messages ]]--

DataConstants.ERROR_MESSAGES = {
    SAVE_FAILED = "Failed to save data. Please try again later.",
    LOAD_FAILED = "Failed to load data. Please try again.",
    DATA_CORRUPTED = "Data appears to be corrupted. Restoring from backup.",
    SESSION_LOCKED = "This account is already in use on another server.",
    MIGRATION_FAILED = "Failed to migrate data to new format.",
    VALIDATION_FAILED = "Data validation failed: %s",
    RATE_LIMIT = "You're performing this action too frequently. Please wait.",
    BACKUP_FAILED = "Failed to create data backup.",
    PERMISSION_DENIED = "You don't have permission to perform this action.",
    INVALID_OPERATION = "This operation is not valid in the current state."
}

return DataConstants
