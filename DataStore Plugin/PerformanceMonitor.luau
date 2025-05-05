--luau
-- DataStore Plugin/PerformanceMonitor.luau

local PerformanceMonitor = {}
local performanceData = {} -- Table to store performance data, format: {{operationName, duration, datastoreName, keyName, success}}

function PerformanceMonitor.timeOperation(operationName, func, dataStoreName, keyName)
    local startTime = os.clock() -- Use os.clock() for higher precision timing
    local success, result = pcall(func)
    local endTime = os.clock()
    local duration = endTime - startTime
	
	local data = {
		operationName = operationName,
		duration = duration,
		dataStoreName = dataStoreName,
		keyName = keyName,
		success = success,
	}
	
	table.insert(performanceData, data)

	

    return success, result, duration
end

function PerformanceMonitor.getPerformanceData()
	return performanceData
end

function PerformanceMonitor.getOperationSummary()
	local summary = {}
	for _, data in ipairs(performanceData) do
		local operationName = data.operationName
		if not summary[operationName] then
			summary[operationName] = {
				count = 0,
				totalDuration = 0,
				averageDuration = 0,
			}
		end
		summary[operationName].count += 1
		summary[operationName].totalDuration += data.duration
	end

	-- Calculate average duration
	for operationName, data in pairs(summary) do
		data.averageDuration = data.totalDuration / data.count
	end

	return summary
end



-- You can add functions here later to retrieve and analyze performanceData

return PerformanceMonitor