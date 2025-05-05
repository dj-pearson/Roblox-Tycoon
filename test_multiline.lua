-- Test file for multiline strings in Lua
local function testStrings()
    -- This is a basic multiline string
    local str1 = [[
This is a
multiline string
]]
    print(str1)
      -- This is a nested multiline string
    local str2 = [[
First level
    [=[
    Second level
    ]=]
End first level
]]
    print(str2)
end

testStrings()
