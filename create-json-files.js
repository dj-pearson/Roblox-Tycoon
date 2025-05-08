// create-json-files.js
// This script creates clean JSON files directly from JavaScript objects

const fs = require('fs');
const path = require('path');

// Helper function to write a clean JSON file
function writeCleanJsonFile(filePath, data) {
    try {
        // Convert to JSON string with proper formatting
        const jsonString = JSON.stringify(data, null, 2);

        // Write to file
        fs.writeFileSync(filePath, jsonString, 'utf8');
        console.log(`Created clean file: ${filePath}`);
        return true;
    } catch (err) {
        console.error(`Error writing ${filePath}: ${err.message}`);
        return false;
    }
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

// DataStore plugin configuration
const dataStorePlugin = {
    name: "DataStorePlugin",
    tree: {
        $className: "DataModel",
        ReplicatedStorage: {
            DataStorePlugin: {
                $path: "DataStore Plugin"
            }
        }
    }
};

// Clean default project configuration
const cleanDefaultProject = {
    name: "RobloxProject-Clean",
    tree: {
        $className: "DataModel",
        ReplicatedStorage: {
            shared: {
                $path: "src/shared"
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

// Clean plugin configuration
const cleanPlugin = {
    name: "CleanPlugin",
    tree: {
        $className: "DataModel",
        ReplicatedStorage: {
            DataStorePlugin: {
                $path: "DataStore Plugin/clean"
            }
        }
    }
};

// Enhanced project configuration
const enhancedProject = {
    name: "RobloxProject-Enhanced",
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
        },
        Workspace: {
            $properties: {
                FilteringEnabled: true
            }
        }
    }
};

console.log("Creating clean JSON files...");

// Create all JSON files
writeCleanJsonFile("default.project.json", defaultProject);
writeCleanJsonFile("DataStore-plugin.project.json", dataStorePlugin);
writeCleanJsonFile("clean-default.project.json", cleanDefaultProject);
writeCleanJsonFile("clean-plugin.project.json", cleanPlugin);
writeCleanJsonFile("enhanced.project.json", enhancedProject);

console.log("\nAll JSON files have been created successfully!");
console.log("You can now try running Argon again.");
