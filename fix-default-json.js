const fs = require('fs');
const path = require('path');

// Helper function to write a clean JSON file
function writeCleanJsonFile(filePath, data) {
    const jsonString = JSON.stringify(data, null, 2);
    fs.writeFileSync(filePath, jsonString, 'utf8');
    console.log(`Created clean file: ${filePath}`);
}

// Default project configuration
const defaultProject = {
    name: "RobloxProject",
    tree: {
        $className: "DataModel",
        ReplicatedStorage: {
            shared: {
                $path: "src/shared"
            },
            DataStorePlugin: {
                $path: "DataStore Plugin"
            }
        },
        ServerScriptService: {
            server: {
                $path: "src/server"
            }
        },
        StarterPlayer: {
            StarterPlayerScripts: {
                client: {
                    $path: "src/client"
                }
            }
        }
    }
};

// Write the file
writeCleanJsonFile("default.project.json", defaultProject);
console.log("Done!");
