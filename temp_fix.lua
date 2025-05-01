-- This is a temporary script to fix the EventBridge.luau file
local file = "c:/Users/dpearson/OneDrive/Documents/RobloxProject/src/shared/replicatedStorage/EventBridge.luau"
local content = io.open(file, "r"):read("*all")

-- Fix 1: Line 252 - handleEventFromServer function
content = content:gsub(
    "task%.spawn%(function%(%)%s*local%s+success,%s+result%s*=%s*pcall%(handler,%s*%.%.%.%)",
    "local args = table.pack(...)\n        task.spawn(function()\n            local success, result = pcall(function()\n                return handler(table.unpack(args, 1, args.n))\n            end)"
)

-- Fix 2: Line 569 - onServerEvent handler
content = content:gsub(
    "task%.spawn%(function%(%)%s*local%s+success,%s+result%s*=%s*pcall%(callback,%s*player,%s*%.%.%.%)",
    "local args = table.pack(...)\n        task.spawn(function()\n            local success, result = pcall(function()\n                return callback(player, table.unpack(args, 1, args.n))\n            end)"
)

-- Fix 3: Line 757 - invokeServer function
content = content:gsub(
    "local%s+success,%s+result%s*=%s*pcall%(function%(%)%s*return%s+remote:InvokeServer%(%.%.%.%)",
    "local args = table.pack(...)\n    local success, result = pcall(function()\n        return remote:InvokeServer(table.unpack(args, 1, args.n))"
)

-- Fix 4: Line 804 - invokeClient function
content = content:gsub(
    "local%s+success,%s+result%s*=%s*pcall%(function%(%)%s*return%s+remote:InvokeClient%(client,%s*%.%.%.%)",
    "local args = table.pack(...)\n    local success, result = pcall(function()\n        return remote:InvokeClient(client, table.unpack(args, 1, args.n))"
)

io.open(file, "w"):write(content)
print("Fixed EventBridge.luau file")
