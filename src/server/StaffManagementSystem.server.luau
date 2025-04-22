
CHECK_IN_TIME = 2
local function CheckInMember(dataManager, staffData, member)
    -- 1. Load Member Data
    local memberData = dataManager:LoadData(member.Value, "MemberData")
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

