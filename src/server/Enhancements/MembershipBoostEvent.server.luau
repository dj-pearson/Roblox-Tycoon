-- src/server/Enhancements/MembershipBoostEvent.server.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Fix incorrect path reference for EventSystem
local EventSystem
local success, result = pcall(function()
    -- Try to find EventSystem in the correct location
    return require(script.Parent.EventSystem)
end)

if success then
    EventSystem = result
else
    -- Try alternative paths
    success, result = pcall(function()
        return require(ServerScriptService.server.Enhancements.EventSystem)
    end)
    
    if not success then
        -- Last attempt
        success, result = pcall(function()
            return require(ServerScriptService.Enhancements.EventSystem)
        end)
        
        if not success then
            -- Create a simple EventSystem if not found
            warn("EventSystem not found, creating a basic implementation")
            EventSystem = {
                events = {},
                
                addEvent = function(self, event)
                    table.insert(self.events, event)
                    print("Added event to EventSystem:", event.eventName)
                    return true
                end,
                
                removeEvent = function(self, event)
                    for i, e in ipairs(self.events) do
                        if e == event then
                            table.remove(self.events, i)
                            print("Removed event from EventSystem:", event.eventName)
                            return true
                        end
                    end
                    return false
                end,
                
                getEvents = function(self)
                    return self.events
                end
            }
        else
            EventSystem = result
        end
    else
        EventSystem = result
    end
end

local MembershipBoostEvent = {}
MembershipBoostEvent.__index = MembershipBoostEvent

function MembershipBoostEvent.new()
	local self = setmetatable({}, MembershipBoostEvent)
	self.eventName = "MembershipBoost"
	self.boostMultiplier = 1.5 -- 50% boost
	self.isActive = false
	self.endTime = 0
	self.eventDuration = 0
	self.eventFrequency = 0
	self.eventTypes = {
		"Random",
		"Scheduled",
	}
	self.eventLengths = {
		"FewHours",
		"FullDay",
		"FullWeekend",
	}

	self.remoteEvent = Instance.new("RemoteEvent")
	self.remoteEvent.Name = "MembershipBoostEventRemote"
	self.remoteEvent.Parent = ReplicatedStorage

	self.eventData = {
		eventType = "Random", -- Default to random
		eventLength = "FullWeekend", -- Default to full weekend
		eventStartTime = nil,
	}

	return self
end

function MembershipBoostEvent:notifyPlayers(message)
	for _, player in ipairs(Players:GetPlayers()) do
		-- You would send this to the client to display, for this just print
		print(player.Name, message)
	end
end

function MembershipBoostEvent:startEvent()
	self.isActive = true
	self.eventData.eventStartTime = os.time()
	if self.eventData.eventLength == "FewHours" then
		self.eventDuration = 3 * 60 * 60 -- 3 hours
	elseif self.eventData.eventLength == "FullDay" then
		self.eventDuration = 24 * 60 * 60 -- 24 hours
	elseif self.eventData.eventLength == "FullWeekend" then
		self.eventDuration = 48 * 60 * 60 -- 48 hours
	end

	self.endTime = os.time() + self.eventDuration
	self:notifyPlayers("Membership Boost Event is now LIVE! Enjoy 50% more to members, revenue, satisfaction, and experience!")

	self.remoteEvent:FireAllClients(self.endTime)
end

function MembershipBoostEvent:endEvent()
	self.isActive = false
	self.endTime = 0
	self.eventDuration = 0
	self:notifyPlayers("Membership Boost Event has ended!")
end

function MembershipBoostEvent:checkEventEnd()
	if self.isActive and os.time() >= self.endTime then
		self:endEvent()
	end
end

function MembershipBoostEvent:setEventType(type)
	if table.find(self.eventTypes, type) then
		self.eventData.eventType = type
		print("Event Type set to: ", type)
	else
		warn("Invalid event type:", type)
	end
end

function MembershipBoostEvent:setEventLength(length)
	if table.find(self.eventLengths, length) then
		self.eventData.eventLength = length
		print("Event Length set to: ", length)
	else
		warn("Invalid event length:", length)
	end
end

function MembershipBoostEvent:setEventFrequency(frequency)
	self.eventFrequency = frequency
	print("Event Frequency set to every:", frequency, "days")
end

function MembershipBoostEvent:applyBoost(value)
	return value * self.boostMultiplier
end

function MembershipBoostEvent:handleRandomEvent()
	local randomNumber = math.random(1, self.eventFrequency)
	if randomNumber == 1 then
		print("Starting random Membership Boost Event")
		self:startEvent()
	else
		print("No random event triggered")
	end
end

function MembershipBoostEvent:update()
	self:checkEventEnd()
	if self.eventData.eventType == "Random" then
		if not self.isActive then
			self:handleRandomEvent()
		end
	end
end

local membershipBoost = MembershipBoostEvent.new()

-- Test values
membershipBoost:setEventFrequency(7) -- Test with 7 days to start event.
membershipBoost:setEventType("Random") -- Random or Scheduled
membershipBoost:setEventLength("FullWeekend") -- FewHours, FullDay, FullWeekend

EventSystem:addEvent(membershipBoost)

RunService.Heartbeat:Connect(function()
	membershipBoost:update()
end)

return MembershipBoostEvent