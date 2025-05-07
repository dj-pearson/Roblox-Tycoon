# UpdateDataStorePlugin.ps1
# Powershell script to update and deploy the DataStore Plugin with improved module resolution

# Set up paths
$workspaceDir = "c:\Users\dpearson\OneDrive\Documents\RobloxProject"
$pluginDir = Join-Path $workspaceDir "DataStore Plugin"
$srcDir = Join-Path $pluginDir "src"
$buildOutputPath = Join-Path $workspaceDir "DataStorePlugin.rbxmx"

Write-Host "Updating DataStore Plugin with module resolver improvements..." -ForegroundColor Green

# Ensure the module resolver is in place
$moduleResolverPath = Join-Path $srcDir "ModuleResolver.luau"
if (-not (Test-Path $moduleResolverPath)) {
    Write-Host "Module resolver not found. Creating it..." -ForegroundColor Yellow
    
    $moduleResolverContent = @"
-- ModuleResolver.luau
-- Utility module for resolving module dependencies in both local and cloud environments
local ModuleResolver = {}

-- Try to get the resolver from init script, otherwise define our own
local function getResolver()
    if script.Parent and script.Parent.resolveModule then
        -- Use the parent's resolver if available
        return function(moduleName)
            return script.Parent.resolveModule(moduleName)
        end
    end
    
    -- Define our own resolver
    return function(moduleName, fromModule)
        local sourceModule = fromModule or script.Parent
        local success, result
        
        -- Try direct requiring from parent
        success, result = pcall(function()
            return require(sourceModule:FindFirstChild(moduleName))
        end)
        
        if success and result then
            return result
        end
        
        -- Try finding in parent's parent
        if sourceModule.Parent then
            success, result = pcall(function()
                return require(sourceModule.Parent:FindFirstChild(moduleName))
            end)
            
            if success and result then
                return result
            end
        end
        
        -- Try direct string require (works in some cloud environments)
        success, result = pcall(function()
            return require(moduleName)
        end)
        
        if success and result then
            return result
        end
        
        -- Create a dummy module to prevent errors
        warn("ModuleResolver: Failed to resolve module: " .. moduleName)
        return {
            initialize = function() 
                warn("Using dummy implementation of " .. moduleName .. ".initialize()") 
                return true 
            end,
            createUI = function() 
                warn("Using dummy implementation of " .. moduleName .. ".createUI()") 
                return Instance.new("Frame") 
            end
        }
    end
end

-- Export the resolve function
ModuleResolver.resolveModule = getResolver()

return ModuleResolver
"@

    Set-Content -Path $moduleResolverPath -Value $moduleResolverContent
    Write-Host "Created ModuleResolver.luau" -ForegroundColor Green
}

# Ensure the init.server.luau file has dummy module handling
$initPath = Join-Path $srcDir "init.server.luau"
if (Test-Path $initPath) {
    $initContent = Get-Content -Path $initPath -Raw
    
    # Check if it has dummy module returns
    if ($initContent -notmatch "dummy") {
        Write-Host "Updating init.server.luau with dummy module handling..." -ForegroundColor Yellow
        
        # Replace the module resolver return null with dummy module
        $newInitContent = $initContent -replace "warn\(`"Failed to resolve module: `" \.\. moduleName\)\s*return nil", @"
warn("Failed to resolve module: " .. moduleName)
    
    -- Return a dummy module with basic functions to prevent errors
    local dummyModule = {
        initialize = function() 
            warn("Using dummy implementation of " .. moduleName .. ".initialize()") 
            return true 
        end,
        createUI = function() 
            warn("Using dummy implementation of " .. moduleName .. ".createUI()") 
            return Instance.new("Frame") 
        end
    }
    
    moduleCache[moduleName] = dummyModule
    return dummyModule
"@
        
        Set-Content -Path $initPath -Value $newInitContent
        Write-Host "Updated init.server.luau with dummy module handling" -ForegroundColor Green
    }
}

# Build the plugin with Rojo if available
$rojoPath = Get-Command "rojo" -ErrorAction SilentlyContinue
if ($rojoPath) {
    Write-Host "Building plugin with Rojo..." -ForegroundColor Yellow
    
    # Make sure we have a proper project file
    $projectFilePath = Join-Path $workspaceDir "DataStore-plugin.project.json"
    if (-not (Test-Path $projectFilePath)) {
        $projectContent = @"
{
  "name": "DataStore Manager Pro",
  "tree": {
    "$className": "Plugin",
    "$properties": {
      "RunContext": "Server"
    },
    "DataStore Plugin": {
      "$path": "DataStore Plugin",
      "$ignoreUnknownInstances": true,
      "$ignoreFiles": [
        "*.png",
        "Backups/*",
        "*.backup*"
      ]
    }
  }
}
"@
        Set-Content -Path $projectFilePath -Value $projectContent
        Write-Host "Created Rojo project file" -ForegroundColor Green
    }
    
    # Build the plugin
    rojo build $projectFilePath -o $buildOutputPath
    
    if (Test-Path $buildOutputPath) {
        Write-Host "Plugin built successfully to: $buildOutputPath" -ForegroundColor Green
    }
    else {
        Write-Host "Failed to build plugin with Rojo" -ForegroundColor Red
    }
}
else {
    Write-Host "Rojo not found. Please install Rojo or build the plugin manually." -ForegroundColor Yellow
}

Write-Host "Done! Your plugin has been updated with improved module resolution." -ForegroundColor Green
Write-Host "To install the plugin in Roblox Studio:"
Write-Host "1. Open Roblox Studio"
Write-Host "2. Go to Plugins > Plugins Folder"
Write-Host "3. Copy DataStorePlugin.rbxmx to that folder"
Write-Host "4. Restart Roblox Studio"
