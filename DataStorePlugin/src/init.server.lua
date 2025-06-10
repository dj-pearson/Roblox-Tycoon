-- DataStore Manager Pro Plugin Entry Point
-- This is the main entry point referenced in plugin.project.json

-- Require the main server module that contains all the plugin logic
local ServerModule = require(script.server)

-- Initialize the plugin
if ServerModule and ServerModule.initialize then
    ServerModule.initialize()
end

-- Return the server module for external access
return ServerModule
