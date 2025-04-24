
local ServerScriptService = game:GetService("ServerScriptService")

-- Try to load DataAccessLayer
local DataAccessLayer
local function loadDataAccessLayer()
    -- Try CoreRegistry first
    local CoreRegistry
    pcall(function()
        CoreRegistry = require(ServerScriptService:FindFirstChild("Core"):FindFirstChild("CoreRegistry"))
    end)
    
    if CoreRegistry then
        DataAccessLayer = CoreRegistry:GetSystem("DataAccessLayer")
        if DataAccessLayer then
            return DataAccessLayer
        end
    end
    
    -- Try direct load
    pcall(function()
        DataAccessLayer = require(ServerScriptService:FindFirstChild("Core"):FindFirstChild("DataAccessLayer"))
    end)
    
    return DataAccessLayer
end

DataAccessLayer = loadDataAccessLayer()

CHECK_IN_TIME = 2
local function CheckInMember(dataManager, staffData, member)
    -- 1. Load Member Data using DataAccessLayer if available, fallback to legacy method
    local memberData
    if DataAccessLayer then
        memberData = DataAccessLayer:GetPlayerData(member.Value, "MemberData")
    else
        -- Legacy method
        memberData = dataManager:LoadData(member.Value, "MemberData") 
    end
    
    -- 2. Efficiency Time Reduction
    local efficiencyLevel = staffData.EfficiencyLevel or 0
    local checkInTime = CHECK_IN_TIME - (efficiencyLevel * 0.1)

    task.wait(checkInTime) -- Simulate the check-in time
    -- 3. VIP Conversion
	if not memberData.isVIP then
		local vipConversionLevel = staffData.VIPConversionLevel or 0
		local randomNumber = math.random()
		if randomNumber <= vipConversionLevel * 0.01 then
			print("Converting member to VIP")
			-- TODO: Add logic to convert member to VIP
		end
	end
    return true
end

local StaffSystem = {}

StaffSystem.CheckInMember = CheckInMember
function StaffSystem:GiveStaffXP(staffMember, skill, xp)
    print("Giving staff", staffMember, "XP in", skill, ":", xp)
end

