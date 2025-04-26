--[[
    WaitForChildFinder.lua
    
    A tool to find unsafe WaitForChild calls in Luau scripts and suggest replacements
    using the SafeWaitForChild utility. This helps identify potential infinite yield issues.
    
    Usage:
    - Run this script from the command line: lua WaitForChildFinder.lua <directory>
    - It will scan all .lua/.luau files in the specified directory recursively
    - Results will be output to the console and a report file
    
    Created: April 26, 2025
]]

local fs = require("fs") -- May need to install a filesystem library like LuaFileSystem
local path = require("path")

-- Configuration
local CONFIG = {
    fileExtensions = {".lua", ".luau", ".server.lua", ".server.luau", ".client.lua", ".client.luau"},
    outputFile = "WaitForChildReport.md",
    patterns = {
        waitForChild = ":%s*WaitForChild%s*%(%s*[\"']([^\"']+)[\"']%s*,?%s*([^%)]*%))",
        findFirstChild = ":%s*FindFirstChild%s*%(%s*[\"']([^\"']+)[\"']%s*%)",
        waitForChildWithTimeout = ":%s*WaitForChild%s*%(%s*[\"']([^\"']+)[\"']%s*,%s*(%d+)%s*%)"
    },
    replacementTemplates = {
        waitForChild = "SafeWaitForChild.waitForChild(%s, \"%s\"%s)",
        waitForDescendant = "SafeWaitForChild.waitForDescendant(%s, \"%s\"%s)"
    },
    maxLineLength = 120
}

-- Results tracking
local results = {
    filesScanned = 0,
    filesWithIssues = 0,
    totalIssues = 0,
    issues = {}
}

-- Check if a string ends with any of the specified extensions
local function hasExtension(filename, extensions)
    for _, ext in ipairs(extensions) do
        if filename:sub(-#ext) == ext then
            return true
        end
    end
    return false
end

-- Create a replacement suggestion
local function createReplacement(match, parent, childName, timeout)
    local timeoutStr = ""
    if timeout and timeout ~= "" then
        timeoutStr = ", " .. timeout
    end
    
    -- Check if child name contains dots (indicating descendant path)
    if childName:find("%.") then
        return string.format(
            CONFIG.replacementTemplates.waitForDescendant,
            parent,
            childName,
            timeoutStr
        )
    else
        return string.format(
            CONFIG.replacementTemplates.waitForChild,
            parent,
            childName,
            timeoutStr
        )
    end
end

-- Process a single file
local function processFile(filePath)
    local fileHandle, err = io.open(filePath, "r")
    if not fileHandle then
        print("Error opening file: " .. filePath .. " - " .. (err or "unknown error"))
        return
    end
    
    local content = fileHandle:read("*all")
    fileHandle:close()
    
    local fileIssues = {}
    local lineNumber = 1
    
    -- Process file line by line
    for line in content:gmatch("[^\r\n]+") do
        -- Look for WaitForChild patterns
        for parent, childName, timeout in line:gmatch("([%w%.]+):%s*WaitForChild%s*%(%s*[\"']([^\"']+)[\"']%s*,?%s*([^%)]*%)") do
            table.insert(fileIssues, {
                line = lineNumber,
                code = line:gsub("^%s+", ""),
                pattern = "WaitForChild",
                parent = parent,
                childName = childName,
                timeout = timeout ~= "" and timeout or nil,
                replacement = createReplacement(line, parent, childName, timeout)
            })
        end
        
        -- Look for FindFirstChild without existence check
        for parent, childName in line:gmatch("([%w%.]+):%s*FindFirstChild%s*%(%s*[\"']([^\"']+)[\"']%s*%)") do
            -- Check if this FindFirstChild is part of an if statement or assignment
            local isChecked = line:match("if%s+") or line:match("=%s+") or line:match("local%s+%w+%s*=")
            if not isChecked then
                table.insert(fileIssues, {
                    line = lineNumber,
                    code = line:gsub("^%s+", ""),
                    pattern = "Unchecked FindFirstChild",
                    parent = parent,
                    childName = childName,
                    replacement = createReplacement(line, parent, childName, nil)
                })
            end
        end
        
        lineNumber = lineNumber + 1
    end
    
    -- Update results
    if #fileIssues > 0 then
        results.filesWithIssues = results.filesWithIssues + 1
        results.totalIssues = results.totalIssues + #fileIssues
        results.issues[filePath] = fileIssues
    end
    
    results.filesScanned = results.filesScanned + 1
end

-- Scan directory recursively
local function scanDirectory(directory)
    local items = fs.readdir(directory)
    
    for _, item in ipairs(items) do
        local itemPath = path.join(directory, item)
        local attr = fs.stat(itemPath)
        
        if attr.mode == "directory" then
            -- Skip certain directories
            if item ~= "node_modules" and item ~= ".git" then
                scanDirectory(itemPath)
            end
        elseif attr.mode == "file" and hasExtension(item, CONFIG.fileExtensions) then
            processFile(itemPath)
        end
    end
end

-- Generate report
local function generateReport()
    local fileHandle = io.open(CONFIG.outputFile, "w")
    if not fileHandle then
        print("Error: Could not create report file.")
        return
    end
    
    local report = {}
    table.insert(report, "# WaitForChild Safety Analysis Report")
    table.insert(report, "Generated: " .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(report, "")
    table.insert(report, "## Summary")
    table.insert(report, "- Files scanned: " .. results.filesScanned)
    table.insert(report, "- Files with issues: " .. results.filesWithIssues)
    table.insert(report, "- Total issues found: " .. results.totalIssues)
    table.insert(report, "")
    table.insert(report, "## Detailed Findings")
    
    for filePath, issues in pairs(results.issues) do
        table.insert(report, "### " .. filePath)
        table.insert(report, "")
        
        for _, issue in ipairs(issues) do
            table.insert(report, "- Line " .. issue.line .. " - " .. issue.pattern .. ":")
            table.insert(report, "  ```lua")
            table.insert(report, "  " .. issue.code)
            table.insert(report, "  ```")
            table.insert(report, "  Suggested replacement:")
            table.insert(report, "  ```lua")
            table.insert(report, "  " .. issue.replacement)
            table.insert(report, "  ```")
            table.insert(report, "")
        end
    end
    
    table.insert(report, "## Next Steps")
    table.insert(report, "1. Replace all unsafe WaitForChild calls with SafeWaitForChild.waitForChild")
    table.insert(report, "2. Add proper error handling for cases where children might not exist")
    table.insert(report, "3. Consider adding the SafeWaitForChild module to all scripts that need it")
    table.insert(report, "")
    table.insert(report, "## SafeWaitForChild Import")
    table.insert(report, "Add this line at the top of your scripts:")
    table.insert(report, "```lua")
    table.insert(report, "local SafeWaitForChild = require(game:GetService(\"ReplicatedStorage\"):WaitForChild(\"shared\"):WaitForChild(\"SafeWaitForChild\"))")
    table.insert(report, "```")
    
    fileHandle:write(table.concat(report, "\n"))
    fileHandle:close()
    
    print("Report generated: " .. CONFIG.outputFile)
end

-- Main function
local function main(args)
    if not args[1] then
        print("Usage: lua WaitForChildFinder.lua <directory>")
        return
    end
    
    local directory = args[1]
    print("Scanning directory: " .. directory)
    
    scanDirectory(directory)
    
    print("Scan complete:")
    print("- Files scanned: " .. results.filesScanned)
    print("- Files with issues: " .. results.filesWithIssues)
    print("- Total issues found: " .. results.totalIssues)
    
    if results.totalIssues > 0 then
        generateReport()
    else
        print("No issues found.")
    end
end

-- Run the main function with command line arguments
main(arg)
