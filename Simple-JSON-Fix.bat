@echo off
echo Simple JSON Fix Tool
echo =================
echo.

echo This tool will create fresh JSON files without BOM characters
echo.

echo Fixing default.project.json...
echo { > default.project.json
echo   "name": "RobloxProject", >> default.project.json
echo   "tree": { >> default.project.json
echo     "$className": "DataModel", >> default.project.json
echo     "ReplicatedStorage": { >> default.project.json
echo       "shared": { >> default.project.json
echo         "$path": "src/shared" >> default.project.json
echo       }, >> default.project.json
echo       "DataStorePlugin": { >> default.project.json
echo         "$path": "DataStore Plugin" >> default.project.json
echo       } >> default.project.json
echo     }, >> default.project.json
echo     "ServerScriptService": { >> default.project.json
echo       "server": { >> default.project.json
echo         "$path": "src/server" >> default.project.json
echo       } >> default.project.json
echo     }, >> default.project.json
echo     "StarterPlayer": { >> default.project.json
echo       "StarterPlayerScripts": { >> default.project.json
echo         "client": { >> default.project.json
echo           "$path": "src/client" >> default.project.json
echo         } >> default.project.json
echo       } >> default.project.json
echo     } >> default.project.json
echo   } >> default.project.json
echo } >> default.project.json

echo Fixing DataStore-plugin.project.json...
echo { > DataStore-plugin.project.json
echo   "name": "DataStorePlugin", >> DataStore-plugin.project.json
echo   "tree": { >> DataStore-plugin.project.json
echo     "$className": "DataModel", >> DataStore-plugin.project.json
echo     "ReplicatedStorage": { >> DataStore-plugin.project.json
echo       "DataStorePlugin": { >> DataStore-plugin.project.json
echo         "$path": "DataStore Plugin" >> DataStore-plugin.project.json
echo       } >> DataStore-plugin.project.json
echo     } >> DataStore-plugin.project.json
echo   } >> DataStore-plugin.project.json
echo } >> DataStore-plugin.project.json

echo Fixing clean-default.project.json...
echo { > clean-default.project.json
echo   "name": "RobloxProject-Clean", >> clean-default.project.json
echo   "tree": { >> clean-default.project.json
echo     "$className": "DataModel", >> clean-default.project.json
echo     "ReplicatedStorage": { >> clean-default.project.json
echo       "shared": { >> clean-default.project.json
echo         "$path": "src/shared" >> clean-default.project.json
echo       } >> clean-default.project.json
echo     }, >> clean-default.project.json
echo     "ServerScriptService": { >> clean-default.project.json
echo       "server": { >> clean-default.project.json
echo         "$path": "src/server" >> clean-default.project.json
echo       } >> clean-default.project.json
echo     }, >> clean-default.project.json
echo     "StarterPlayer": { >> clean-default.project.json
echo       "StarterPlayerScripts": { >> clean-default.project.json
echo         "client": { >> clean-default.project.json
echo           "$path": "src/client" >> clean-default.project.json
echo         } >> clean-default.project.json
echo       } >> clean-default.project.json
echo     } >> clean-default.project.json
echo   } >> clean-default.project.json
echo } >> clean-default.project.json

echo Fixing clean-plugin.project.json...
echo { > clean-plugin.project.json
echo   "name": "CleanPlugin", >> clean-plugin.project.json
echo   "tree": { >> clean-plugin.project.json
echo     "$className": "DataModel", >> clean-plugin.project.json
echo     "ReplicatedStorage": { >> clean-plugin.project.json
echo       "DataStorePlugin": { >> clean-plugin.project.json
echo         "$path": "DataStore Plugin/clean" >> clean-plugin.project.json
echo       } >> clean-plugin.project.json
echo     } >> clean-plugin.project.json
echo   } >> clean-plugin.project.json
echo } >> clean-plugin.project.json

echo Fixing enhanced.project.json...
echo { > enhanced.project.json
echo     "name": "RobloxProject-Enhanced", >> enhanced.project.json
echo     "tree": { >> enhanced.project.json
echo         "$className": "DataModel", >> enhanced.project.json
echo         "ReplicatedStorage": { >> enhanced.project.json
echo             "shared": { >> enhanced.project.json
echo                 "$path": "src/shared" >> enhanced.project.json
echo             }, >> enhanced.project.json
echo             "DataStorePlugin": { >> enhanced.project.json
echo                 "$path": "DataStore Plugin" >> enhanced.project.json
echo             } >> enhanced.project.json
echo         }, >> enhanced.project.json
echo         "ServerScriptService": { >> enhanced.project.json
echo             "server": { >> enhanced.project.json
echo                 "$path": "src/server" >> enhanced.project.json
echo             } >> enhanced.project.json
echo         }, >> enhanced.project.json
echo         "StarterPlayer": { >> enhanced.project.json
echo             "StarterPlayerScripts": { >> enhanced.project.json
echo                 "client": { >> enhanced.project.json
echo                     "$path": "src/client" >> enhanced.project.json
echo                 } >> enhanced.project.json
echo             } >> enhanced.project.json
echo         } >> enhanced.project.json
echo     } >> enhanced.project.json
echo } >> enhanced.project.json

echo.
echo JSON files have been recreated with clean formatting.
echo Try running Argon now.
echo.
pause
