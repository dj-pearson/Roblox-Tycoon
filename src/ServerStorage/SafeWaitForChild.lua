lua
local function SafeWaitForChild(parent, childName)
  local child = parent:FindFirstChild(childName)
  if child then
    return child
  end
  local startTime = tick()
  while tick() - startTime < 5 do
    child = parent:FindFirstChild(childName)
    if child then
      return child
    end
    task.wait()
  end
  print("SafeWaitForChild timed out waiting for", childName)
  return nil
end